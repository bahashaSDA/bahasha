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
