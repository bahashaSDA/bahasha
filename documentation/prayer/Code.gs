/**
 * Bahasha — prayer requests → the prayer team's Google Sheet.
 *
 * Bound to a private Google Sheet (Extensions → Apps Script). Deployed as a
 * web app ("Execute as: Me", "Who has access: Anyone"), it is the endpoint the
 * Bahasha app posts silent prayers to (--dart-define=PRAYER_ENDPOINT=<url>).
 *
 *  - ANONYMOUS: a row holds only the prayer, its Sabbath and the date it
 *    arrived. No name, phone, church, offering reference or time of day is
 *    stored — even if an older app version sends such fields, they are
 *    ignored — so nobody reading the sheet can tell who prayed.
 *  - WRITE-ONLY: doPost appends a prayer; nothing here ever returns stored
 *    prayers. Only people the Sheet is shared with (the prayer team) can
 *    read them. No Google credential exists in the app — the script runs on
 *    Google's servers with the Sheet owner's authority.
 *  - WEEKLY SABBATH CYCLE (Africa/Nairobi): a prayer belongs to the Saturday
 *    it will be prayed for (Sunday 00:00 → Saturday 23:59 EAT). The
 *    "Active" tab is this Sabbath's list.
 *  - AUTOMATIC CLEANUP: a daily time trigger (installTriggers) runs
 *    archiveEndedCycles, which moves every row whose Sabbath is before today
 *    to "Archive" (or deletes it, if RETENTION = 'delete'). On Sunday that
 *    clears the Sabbath just ended; on other days it is a no-op. Running it
 *    daily (not only on Sunday) means a missed run is caught up next day.
 *  - IDEMPOTENT: prayers are de-duplicated on requestId (app retries are
 *    safe); cleanup only ever moves ended cycles, so running it twice — or
 *    on a Saturday — can never touch the current Sabbath.
 *
 * Mirrors bahasha-mobile/lib/features/prayer/domain/prayer_cycle.dart.
 */

var TZ = 'Africa/Nairobi';
var ACTIVE = 'Active';
var ARCHIVE = 'Archive';
var LOG = 'Log';
var HEADERS = ['Sabbath', 'Prayer', 'Received', 'Status', 'Request ID'];
var STATUS_COL = 4; // 1-based column of Status
var ID_COL = 5;     // 1-based column of Request ID (random; for de-duplication only)
var MAX_PRAYER = 1000;

/**
 * 'archive' (default, recommended): ended cycles move to the Archive tab.
 * 'delete': ended cycles are permanently removed.
 * Set in Project Settings → Script properties → RETENTION.
 */
function retention_() {
  var v = PropertiesService.getScriptProperties().getProperty('RETENTION');
  return v === 'delete' ? 'delete' : 'archive';
}

// --- Cycle rule ---------------------------------------------------------------

/** 'yyyy-MM-dd' of the Saturday the instant `date` belongs to, in EAT. */
function sabbathFor(date) {
  var dow = Number(Utilities.formatDate(date, TZ, 'u')); // 1 = Mon … 6 = Sat, 7 = Sun
  var daysUntilSaturday = (6 - dow + 7) % 7;             // Sun → 6 (next Saturday)
  var sat = new Date(date.getTime() + daysUntilSaturday * 24 * 3600 * 1000);
  return Utilities.formatDate(sat, TZ, 'yyyy-MM-dd');
}

function todayEat_() {
  return Utilities.formatDate(new Date(), TZ, 'yyyy-MM-dd');
}

// --- Web app endpoint ---------------------------------------------------------

function doPost(e) {
  var lock = LockService.getScriptLock();
  try {
    lock.waitLock(20000);
    var body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    var id = String(body.requestId || '').trim();
    var prayer = String(body.prayer || '').trim();
    if (!/^[0-9a-f-]{36}$/i.test(id)) return json_({ ok: false, error: 'bad_request_id' });
    if (!prayer) return json_({ ok: false, error: 'empty_prayer' });
    if (prayer.length > MAX_PRAYER) prayer = prayer.substring(0, MAX_PRAYER);

    // Idempotent: a retry of an already-received prayer is acknowledged.
    if (exists_(ACTIVE, id) || exists_(ARCHIVE, id)) return json_({ ok: true, duplicate: true });

    var now = new Date();
    // The prayer is for the Sabbath current when it ARRIVES: a prayer written
    // offline on Saturday and delivered Monday is still prayed over (next
    // Sabbath) rather than landing straight in an ended cycle.
    var cycle = sabbathFor(now);

    var sheet = tab_(ACTIVE);
    // Only these columns, whatever else the request contains.
    var row = [cycle, prayer, Utilities.formatDate(now, TZ, 'yyyy-MM-dd'), 'active', id];
    var r = sheet.getLastRow() + 1;
    var range = sheet.getRange(r, 1, 1, row.length);
    range.setNumberFormat('@'); // keep dates/refs as plain text
    range.setValues([row]);
    return json_({ ok: true, cycle: cycle });
  } catch (err) {
    log_('doPost', String(err));
    return json_({ ok: false, error: 'server_error' });
  } finally {
    lock.releaseLock();
  }
}

/** Nothing is readable over the web. */
function doGet() {
  return ContentService.createTextOutput('');
}

// --- Weekly cleanup -------------------------------------------------------------

/** Archive (or delete) every prayer whose Sabbath has ended. Safe to re-run. */
function archiveEndedCycles() {
  var lock = LockService.getScriptLock();
  lock.waitLock(60000);
  try {
    var active = tab_(ACTIVE);
    var last = active.getLastRow();
    if (last < 2) return log_('cleanup', 'nothing active');
    var today = todayEat_();
    var values = active.getRange(2, 1, last - 1, HEADERS.length).getDisplayValues();
    var ended = [];
    var endedRows = [];
    for (var i = 0; i < values.length; i++) {
      var sabbath = values[i][0];
      // Only cycles strictly before today's EAT date — the current Sabbath
      // (including all of Saturday) is never touched.
      if (sabbath && sabbath < today) {
        ended.push(values[i]);
        endedRows.push(i + 2);
      }
    }
    if (!ended.length) return log_('cleanup', 'no ended cycles (today ' + today + ')');

    var mode = retention_();
    if (mode === 'archive') {
      var archive = tab_(ARCHIVE);
      var stamp = Utilities.formatDate(new Date(), TZ, 'yyyy-MM-dd HH:mm');
      var rows = ended
        .filter(function (v) { return !exists_(ARCHIVE, v[ID_COL - 1]); }) // idempotent
        .map(function (v) { var c = v.slice(); c[STATUS_COL - 1] = 'archived ' + stamp; return c; });
      if (rows.length) {
        var range = archive.getRange(archive.getLastRow() + 1, 1, rows.length, HEADERS.length);
        range.setNumberFormat('@');
        range.setValues(rows);
      }
    }
    // Remove from Active bottom-up so row numbers stay valid.
    for (var j = endedRows.length - 1; j >= 0; j--) active.deleteRow(endedRows[j]);
    log_('cleanup', mode + 'd ' + ended.length + ' prayer(s) from cycles before ' + today);
  } catch (err) {
    log_('cleanup FAILED', String(err));
    throw err; // surfaces in Apps Script's failure e-mails / Executions view
  } finally {
    lock.releaseLock();
  }
}

/**
 * Run once from the editor: creates the tabs and the daily cleanup trigger.
 * Re-running is safe; it also converts tabs made by the earlier version
 * (which had Giver / Home church / Offering ref / time columns) to the
 * anonymous layout, deleting those identifying columns.
 */
function installTriggers() {
  tab_(ACTIVE); tab_(ARCHIVE); tab_(LOG);
  migrateToAnonymous_(ACTIVE);
  migrateToAnonymous_(ARCHIVE);
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (t.getHandlerFunction() === 'archiveEndedCycles') ScriptApp.deleteTrigger(t);
  });
  // Daily just after midnight EAT (the project time zone, appsscript.json).
  ScriptApp.newTrigger('archiveEndedCycles').timeBased().everyDays(1).atHour(0).nearMinute(15).create();
  log_('setup', 'daily cleanup trigger installed');
}

// --- Helpers --------------------------------------------------------------------

function tab_(name) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
    if (name === LOG) sheet.appendRow(['When (EAT)', 'What', 'Detail']);
    else sheet.appendRow(HEADERS);
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function exists_(name, id) {
  var sheet = tab_(name);
  if (sheet.getLastRow() < 2) return false;
  return sheet.getRange(2, ID_COL, sheet.getLastRow() - 1, 1)
    .createTextFinder(id).matchEntireCell(true).findNext() !== null;
}

/** Old layout → anonymous layout, dropping every identifying column. */
function migrateToAnonymous_(name) {
  var sheet = tab_(name);
  var width = sheet.getLastColumn();
  var header = sheet.getRange(1, 1, 1, width).getDisplayValues()[0];
  if (header.join('|') === HEADERS.join('|')) return;
  var old = ['Request ID', 'Sabbath', 'Prayer', 'Giver', 'Home church', 'Offering ref',
             'Submitted (EAT)', 'Received (EAT)', 'Status'];
  var rows = sheet.getLastRow() > 1
    ? sheet.getRange(2, 1, sheet.getLastRow() - 1, width).getDisplayValues() : [];
  var converted = rows.map(function (r) {
    var at = function (col) { var i = old.indexOf(col); return i < 0 ? '' : String(r[i] || ''); };
    return [at('Sabbath'), at('Prayer'), at('Received (EAT)').substring(0, 10), at('Status'), at('Request ID')];
  });
  sheet.clear();
  sheet.getRange(1, 1, 1, HEADERS.length).setValues([HEADERS]);
  if (converted.length) {
    var range = sheet.getRange(2, 1, converted.length, HEADERS.length);
    range.setNumberFormat('@');
    range.setValues(converted);
  }
  log_('migrate', name + ': converted ' + converted.length + ' row(s) to the anonymous layout');
}

function log_(what, detail) {
  tab_(LOG).appendRow([Utilities.formatDate(new Date(), TZ, 'yyyy-MM-dd HH:mm:ss'), what, detail]);
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
