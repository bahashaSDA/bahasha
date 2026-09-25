# Prayer requests → Google Sheet

Givers can add an optional **silent prayer** with an offering. Prayers go to a
private Google Sheet that the church's prayer team reads. They open it from
the **CVendor** hub app (dashboard → **Prayer requests**). Each Sunday the
Sabbath that just ended is archived automatically.

**Every prayer is anonymous.** The app sends only the prayer text, a random
ID (used only so a retry isn't stored twice) and the Sabbath date. No name,
phone, church, offering reference or time of day is sent. The script also
stores only those fields and ignores anything else, so an older app version
that still sends a name can't put one in the Sheet.

```
Bahasha app ──POST──▶ Apps Script web app ──▶ Google Sheet "Active" tab
 (queued on the phone      (Code.gs, runs as          │  shared privately with
  until delivered)          the sheet owner)          │  the prayer team
                                                       ▼
                         daily 00:15 EAT trigger ──▶ "Archive" tab (or delete)
```

This needs no Bahasha backend or database change, and no Google credential
goes into the app. The web app URL can only *add* prayers. Nothing in it
returns stored prayers.

## The weekly cycle (Africa/Nairobi, UTC+3)

| Submitted (EAT)            | Belongs to Sabbath |
|----------------------------|--------------------|
| Sun 00:00 → Sat 23:59      | that Saturday      |

- **Active** holds the current Sabbath's prayers. The prayer team prays over
  them on Saturday.
- **Cleanup:** once a day, just after midnight EAT, every row whose Sabbath is
  *before today* moves to **Archive**. On Sunday that clears the Sabbath that
  just ended. On other days it does nothing. Because it runs daily, a missed
  run is caught up the next day, and running it twice is harmless.
- A prayer that reaches the sheet late (for example, written offline on
  Saturday and delivered on Monday) joins the Sabbath that is current when it
  arrives, so it is still prayed over.
- **Retention:** archiving is the default. To delete ended prayers
  permanently instead, set the script property `RETENTION` = `delete`.

## One-time setup (about 10 minutes)

1. Create a Google Sheet, for example "Bahasha – Prayer requests", in the
   church's Google account.
2. In the Sheet, open **Extensions → Apps Script**. Replace the contents of
   `Code.gs` with [Code.gs](Code.gs).
3. Open **Project Settings**:
   - Tick "Show appsscript.json", then replace that file with
     [appsscript.json](appsscript.json). This sets the time zone to
     Africa/Nairobi.
4. In the editor, select `installTriggers` and click **Run**. Approve the
   permissions prompt. This creates the `Active`, `Archive` and `Log` tabs
   and the daily cleanup trigger.
5. Click **Deploy → New deployment → Web app**:
   - Execute as: **Me**
   - Who has access: **Anyone**. The app has no Google login. The endpoint
     accepts prayers but never returns them.

   Copy the **Web app URL** (`https://script.google.com/macros/s/…/exec`).
6. Put that URL in the app. The church's URL is already set as the default
   (`PrayerOutbox.defaultEndpoint` in
   `bahasha-mobile/lib/features/prayer/data/prayer_outbox.dart`), so every
   build, including the GitHub APK workflow, uses it. To point a build at a
   different sheet, add:

   ```
   --dart-define=PRAYER_ENDPOINT=https://script.google.com/macros/s/…/exec
   ```

   If you change `Code.gs`, update the deployment in place so the URL stays
   the same: **Deploy → Manage deployments → ✏️ → Version: New version →
   Deploy**.

7. Share the Sheet (**Viewer** access) with the prayer team only. Do not
   publish it to the web or create a "link sharing" link.

Google's reply page for web apps is sometimes unreachable for a moment
(tested against the live endpoint: about one read in three). The app re-sends
up to 4 times. This is safe because the sheet de-duplicates on Request ID.
Anything still undelivered stays queued on the phone and is retried when the
network returns.

## Checking it works

- Give with a prayer. A row should appear in **Active** within seconds, or as
  soon as the phone is online.
- **Executions** (the Apps Script sidebar) and the **Log** tab record every
  cleanup run, including failures. Apps Script also e-mails the owner when a
  trigger fails.
- To test cleanup on demand, run `archiveEndedCycles` from the editor. Only
  rows from past Sabbaths move.

## What is stored

| Column     | Value                                                                  |
|------------|------------------------------------------------------------------------|
| Sabbath    | The Saturday the prayer is for (computed on the server, in EAT)        |
| Prayer     | The text (trimmed, at most 1000 characters; never empty)               |
| Received   | The date only (no time, so it can't be matched to an offering)         |
| Status     | `active`, then `archived <date>`                                       |
| Request ID | A random ID for this prayer only. Not linked to the giver or offering. |

## Opening the prayers in CVendor

1. In the Sheet, click **Share**, choose who can open it, then click
   **Copy link**.
   - **Anyone with the link** (the current setting): opens on any phone,
     with no Google account needed. The prayers carry no names, but anyone
     who gets the link (it is inside the CVendor app) can read them.
   - **Restricted** (more private): only the accounts you add as **Viewer**
     can open it. Add the prayer team and the Google account on the CVendor
     phone.
   You can switch between these at any time; the app needs no change.
2. On the CVendor dashboard, tap **Prayer requests**, paste the link, and tap
   **Save**. The link is remembered, and the pencil icon changes it later.
   To build the link into the app instead, use
   `--dart-define=PRAYER_SHEET_URL=<link>`.
3. From then on, tapping **Prayer requests** opens the **Active** tab in the
   Google Sheets app (or the browser). Only accounts the Sheet is shared with
   can open it.

## Upgrading from the first version of Code.gs

1. Paste the new `Code.gs` over the old one and press **Ctrl+S**.
2. Run **installTriggers** once. It converts the existing tabs to the
   anonymous layout, deleting the Giver, Home church, Offering ref and time
   columns.
3. Click **Deploy → Manage deployments → ✏️ → Version: New version →
   Deploy**. The URL stays the same, so the app needs no change.
