# Bahasha — Payments (M-Pesa) plan & what I need to provide

> Status: **ON HOLD** — implementation paused until I (platform owner) have the
> Daraja credentials ready. When ready, tell Claude "build the Till mode" and
> hand over the env vars in section 3.

## 1. The two payment models we agreed on

**A. Shared "Till mode" (convenient — church gives only a till number)**
- The backend signs the STK Push with **the platform's own** Daraja credentials
  (consumer key/secret + store shortcode + passkey).
- It sets **`PartyB` = the church's Till number**, using
  `TransactionType: CustomerBuyGoodsOnline`.
- Money settles into the **church's till**, using our credentials to initiate.
- ⚠️ Only works if the church's till is **linked under our Safaricom
  merchant/org** (aggregator/store setup). If tills aren't linked, Safaricom
  rejects a foreign `PartyB`. **Must be verified with a KSh 1 test.**

**B. Direct mode (guaranteed fallback — church gives paybill/till + passkey)**
- The church provides **their own shortcode + passkey** (one-time Safaricom
  "Go Live"). Our shared Daraja app can still do the *initiating*.
- Money goes **directly** to the church, 0%, we never hold it.
- Already implemented in the app today.

The payments page should offer **both**; a church picks whichever fits.

## 2. Key M-Pesa facts (why it's built this way)

- **Only Buy Goods (Till)** has a separate `PartyB` = it can route money to a
  different destination than the signing shortcode.
- **PayBill + account number does NOT route to a third party.** For a paybill,
  `BusinessShortCode = PartyB = the same paybill`, and the account number is only
  a *reconciliation label inside that one paybill*. So a paybill church must use
  **Direct mode** (their paybill + passkey).
- The passkey is tied to one shortcode; you can't STK-push to a shortcode you
  don't hold the passkey for (unless via the linked-till `PartyB` route above).

## 2b. Creating MY OWN platform credentials on m-pesaforbusiness.co.ke

When registering the platform's own merchant account (to "Go Live"):

- **Product → M-PESA Business Till (Buy Goods Till)** — NOT Short-Term Paybill.
  Buy Goods gives a Store/HO number + Till + the online passkey and supports the
  `CustomerBuyGoodsOnline` STK with a separate `PartyB` (needed for Till mode).
  Short-Term Paybill is a temporary fundraising paybill and can't route `PartyB`.
- **Settlement → "Settle to owner's Bank"** — NOT "Settle to owner's M-PESA".
  Bank settlement avoids the ~KSh 500,000 wallet cap.
- Register under the **business/organization** (Bahasha) if offered, with the
  business registration cert + KRA PIN + bank account.
- **Then** on Daraja (developer.safaricom.co.ke): create an app → **Go Live** →
  verification type **Till (Buy Goods)** → link this till → obtain the production
  **Consumer Key, Consumer Secret, Passkey** (the env vars in §3).
- To route money to OTHER churches' tills via `PartyB`, Safaricom must **link
  those tills under our merchant/aggregator** — a separate, later step.

## 3. What I MUST provide when ready (server env vars on the Vercel backend)

These already exist as keys in `backend/.env` / `src/config/env.ts`:

- `DARAJA_CONSUMER_KEY` — from my Daraja app
- `DARAJA_CONSUMER_SECRET` — from my Daraja app
- `DARAJA_SHORTCODE` — my **store / head-office** number (Buy Goods) or paybill
- `DARAJA_PASSKEY` — my Lipa na M-Pesa Online passkey
- `DARAJA_CALLBACK_URL` — `https://bahasha-backend.vercel.app/api/v1/mpesa/callback`
- `DARAJA_CALLBACK_SECRET` — any strong random string
- `DARAJA_ENV` — `sandbox` to test, `production` to go live

Set these in Vercel → backend project → Settings → Environment Variables, then redeploy.

## 4. What each CHURCH provides

- **Till mode:** just their **Till (Buy Goods) number**.
- **Direct mode:** their **paybill/till number + passkey**.

## 5. Limits to design around (confirm current values with Safaricom — they change)

- **Per transaction:** ~KSh **250,000** max (the giver's side).
- **Per day, per giver:** ~KSh **500,000**.
- **M-Pesa wallet cap:** ~KSh **500,000** held at once. A *basic* till stops
  receiving when its balance hits the cap — so for a church collecting big
  offerings, use a **business till that auto-settles to a bank**, or a **PayBill**
  (built for high-volume org collection, settles to bank). A church receiving
  from *many* givers isn't limited by the per-giver limits — each giver has their
  own — the constraint is the **receiving wallet cap / settlement**.

## 6. Test plan (once env vars are set)

1. Add Till mode to the payments page (church types a till).
2. Fire the existing **KSh 1 test** to a **real church till**.
3. Watch where the KSh 1 lands:
   - Church's till → ✅ `PartyB` routing works for our setup.
   - Rejected / our till → tills aren't linked to our org → use Direct mode, or
     get aggregator onboarding from Safaricom.

## 7. To confirm with Safaricom before scaling

- Are churches' tills onboarded under our merchant so `PartyB` routes?
- Current per-transaction / daily limits.
- Whether our account needs aggregator/partner authorization to collect for others.

## 8. How a church gets a business Till (Buy Goods, settling to a BANK)

> Get a **business till that settles to a bank account** — not a basic personal
> till — so it never stalls at the ~KSh 500,000 M-Pesa wallet cap on a big
> offering day.

**Where to apply (any one):**
- The **M-PESA Business app** (download from Play Store / App Store), or
- **lipa.m-pesa.com** (Lipa na M-PESA online application), or
- A **Safaricom shop** (walk in — easiest for organizations).

**Documents the church needs (as an organization):**
- **Registration certificate** — church/society registration (Registrar of
  Societies), or NGO/company registration certificate.
- **KRA PIN certificate** of the church/organization.
- **National IDs** of the authorized signatories/officials.
- **Bank account details** of the church (for settlement).
- Passport photos of signatories (sometimes requested).
- A **phone number** to be the till administrator.

**Steps:**
1. Apply for **"Lipa na M-PESA → Buy Goods (Till Number)"** as an
   **Organization/Business** (not personal).
2. Submit the documents above.
3. **Choose settlement to the BANK ACCOUNT** (critical — this is what avoids the
   wallet cap and lets it receive high volume all day).
4. Safaricom reviews (usually a few business days) and issues a **Till number**
   plus a **Store / Head-office number**.
5. Set the **Lipa na M-PESA Manager PIN**; manage the till via the **M-PESA
   Business app** or the **Business Portal** (org.m-pesa.com).
6. Give Bahasha the **Till number** (that's all that's needed for *Till mode*).

**Notes:**
- Registration itself is free. Buy Goods transactions carry Safaricom **merchant
  tariffs** (a small fee on amounts received) — confirm current rates with
  Safaricom.
- For **Direct mode** instead (paybill/till + passkey), the church additionally
  does a one-time **Daraja "Go Live"** to obtain the passkey.
- For **very high-volume** churches, a **PayBill** (also org-registered, settles
  to bank) is the sturdiest option — but that uses **Direct mode**, not the
  shared-Till trick.
