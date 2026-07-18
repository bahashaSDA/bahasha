# Bahasha BLE Contribution Protocol (v1)

This document is the authoritative specification of how a contribution travels
from a church member's phone, over Bluetooth Low Energy, through a church hub,
to settlement on MPESA. The Flutter apps and the backend MUST agree on every
byte described here; the canonical encoding in
[`backend/src/lib/crypto.ts`](../../backend/src/lib/crypto.ts) and the payload
schema in [`backend/src/domain/payload.ts`](../../backend/src/domain/payload.ts)
are the executable form of this spec.

## 1. Why this exists

Church members switch mobile data **off** during service. Manual Paybill entry
is slow and error-prone. Bahasha lets a member choose categories and amounts
offline; the metadata crosses to a church hub over BLE; the hub (which has
internet) hands it to the backend; the backend triggers an MPESA STK Push that
reaches the member's handset over **GSM**, requiring no personal mobile data.

The member's phone never needs internet. The hub never touches the member's
money directly. The backend is the only component that talks to Safaricom.

## 2. Roles

| Actor      | App              | Trust                                                        |
|------------|------------------|-------------------------------------------------------------|
| Giver      | Bahasha (member) | Holds a device **private key**. Signs every contribution.   |
| Hub        | CVendor (deacon) | Relays packets. **Not trusted** to vouch for their content. |
| Backend    | Node/Express     | Verifies signatures, enforces freshness, triggers Daraja.   |

The single most important rule: **the hub is a transport, not an authority.**
Every security decision is made by the backend against the giver's registered
device key. A hub that is compromised can drop or delay packets; it cannot forge
a contribution, bill a stranger, or replay an old one.

## 3. Keys and enrolment

At first launch, the Bahasha app:

1. Generates an **Ed25519** keypair in the platform secure keystore
   (Android Keystore). The private key is non-exportable.
2. Registers the **public key** (SPKI DER, base64) with the backend via
   `POST /api/v1/register`, together with the member's profile and a stable
   `deviceUuid`.

The backend stores the public key in `public.devices`. From this point on, the
device proves its identity by signing, never by presenting a secret.

ECDSA P-256 is supported as an alternative for devices that can only produce
WebCrypto EC keys; Ed25519 is the default and strongly preferred.

## 4. The payload

When the giver taps **Send contributions**, the app builds this logical object:

```jsonc
{
  "idempotencyKey": "uuid",     // minted per contribution; the pipeline-wide dedupe key
  "deviceUuid":     "uuid",     // identifies the registered device
  "userId":         "uuid",     // the giver, as registered
  "churchId":       "uuid",     // the receiving church
  "msisdn":         "+2547...", // payer number, E.164
  "totalAmount":    1700,       // whole shillings, == sum(allocations)
  "allocations": [
    { "categoryCode": "tithe",                 "amount": 1000 },
    { "categoryCode": "conference_evangelism", "amount": 500  },
    { "categoryCode": "church_building",       "amount": 200  }
  ],
  "counter":         10,          // strictly-increasing per-device replay counter
  "nonce":           "…",         // single-use, from the hub handshake
  "deviceTimestamp": "2026-07-18T09:00:00.000Z", // ISO-8601 UTC
  "anonymous":       false
}
```

### 4.1 Canonical signing bytes

The signature is **not** over the JSON — JSON key ordering is not guaranteed
across platforms, and a signature over a non-canonical encoding is worthless.
It is over this exact byte string (`\n`-joined, UTF-8, no trailing newline):

```
bahasha.v1
<idempotencyKey>
<deviceUuid>
<userId>
<churchId>
<msisdn>
<totalAmount>        # integer, no decimals
<counter>            # integer
<nonce>
<deviceTimestamp>    # ISO-8601 UTC
<anonymous>          # "1" or "0"
```

Field order is part of the wire contract and MUST NOT change within v1. A new
field or a reordering requires `bahasha.v2` and a parallel verification path.

The device signs these bytes with its private key and base64-encodes the
detached signature.

### 4.2 Encryption

The signed payload is additionally encrypted to the **church public key**
(`churches.public_key`) before transmission, so a packet captured off the air is
unreadable to anyone but that church's hub. The hub decrypts, then uploads the
plaintext envelope fields **plus** the original `ciphertext` and `signature` to
the backend for verification and forensic retention.

> Encryption protects confidentiality in transit. The **signature** — not the
> encryption — is what proves authenticity, because the hub necessarily sees the
> plaintext and must not be able to tamper with it undetected.

## 5. Transport (BLE)

- The hub advertises a Bahasha GATT service with a well-known UUID.
- The giver's app scans, connects, and performs a challenge-response handshake:
  the hub issues a fresh `nonce`; the app includes it in the signed payload. A
  nonce is single-use (enforced by a unique index), so a captured packet cannot
  be replayed even against a hub that reissued the same challenge.
- The payload is written in chunks over a characteristic (BLE MTU is small;
  payloads are a few hundred bytes and fragment cleanly).
- On any BLE failure the app retries with backoff and keeps the contribution in
  its local **outbox** until a hub acknowledges receipt. Nothing is lost if the
  member walks out of range mid-transfer.

## 6. Backend verification (the gate)

`POST /api/v1/ingest` (hub-authenticated) runs these checks in order,
cheapest-rejection-first, in
[`backend/src/services/ingest.ts`](../../backend/src/services/ingest.ts):

1. **Church match** — payload's `churchId` equals the hub's church.
2. **Idempotency** — if `(userId, idempotencyKey)` already exists, return the
   prior result. Never charge twice.
3. **Device identity** — `deviceUuid` resolves to a registered, non-revoked
   device whose `userId` matches, and whose registered `msisdn` matches the
   payload. *This is the check that stops a crafted packet from billing a
   stranger.*
4. **Freshness** — `deviceTimestamp` within `PAYLOAD_MAX_AGE_SECONDS`; `counter`
   strictly greater than the device's stored `last_counter`.
5. **Signature** — verify against the registered public key over the canonical
   bytes. A failure here discards the packet before it can reach the payment
   path.
6. **Persist atomically** — one transactional RPC records the packet, creates
   the contribution and allocations, and advances the device counter. A crash
   mid-way leaves either a complete contribution or nothing.
7. **Settle** — issue the STK Push; record the transaction.

Rejected packets are stored in `public.bluetooth_payloads` with a reason. They
are **evidence** (of a bug or an attack) and are never silently dropped.

## 7. Settlement (MPESA)

```
verified payload ─▶ contribution (pending)
                 └▶ STK Push (Daraja) ─▶ contribution (processing)
                                       └▶ handset prompt over GSM
                                          └▶ member enters PIN
                                             └▶ Daraja callback ─▶ contribution (completed | failed | cancelled)
```

Callbacks are idempotent (Safaricom redelivers) and matched on
`checkoutRequestId`. Result code `1032` (user cancelled) is distinguished from a
hard failure so the dashboard can show it accurately.

## 8. Threat model summary

| Threat                                        | Defence                                                        |
|-----------------------------------------------|----------------------------------------------------------------|
| Bystander bills a stranger's phone            | Signature + device↔user↔msisdn binding (step 3, 5)             |
| Replay of a captured packet                   | Strictly-increasing counter + single-use nonce (unique index) |
| Compromised hub tampering with amounts        | Signature covers the canonical bytes; tamper invalidates it    |
| Duplicate upload / retry storm                | `(userId, idempotencyKey)` idempotency + rate limiting         |
| Eavesdropping off the air                     | Payload encrypted to the church public key                     |
| Stale packet resurrected days later           | `deviceTimestamp` freshness window                             |
| Forged MPESA callback                         | Unguessable callback path secret + (prod) Safaricom IP allowlist |
| Anonymous giver de-anonymised                 | `visibility_snapshot` + masking views + RLS (see schema docs)  |

## 9. Versioning

This is protocol **v1**, identified by the `bahasha.v1` prefix in the canonical
bytes. Any change to field set, order, or encoding increments the version and
ships as a parallel path; the backend verifies the version it is told and
refuses unknown versions.
