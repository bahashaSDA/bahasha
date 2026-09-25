// Named constructor params map to private fields; see registration_repository.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ble/ble_transport.dart';
import '../../../core/ble/hub_protocol.dart';
import '../../../core/data/contribution_repository.dart';
import '../../../core/data/local_database.dart';
import '../../../core/data/registration_repository.dart';
import '../../../core/providers.dart';
import '../../prayer/data/prayer_outbox.dart';

/// What one hub session achieved.
class RelayReport {
  const RelayReport({
    this.hubFound = false,
    this.church,
    this.registered = false,
    this.registrationPending = false,
    this.registrationRefused = false,
    this.offeringsHanded = 0,
    this.offeringsWaiting = 0,
    this.prayersHanded = 0,
  });

  final bool hubFound;

  /// The collecting church, as the hub announced it.
  final String? church;

  /// This session registered (or re-registered) the giver with the backend.
  final bool registered;

  /// Registration is still needed (the hub was offline) — offerings wait.
  final bool registrationPending;

  /// The backend refused the giver's details (e.g. phone already in use).
  final bool registrationRefused;
  final int offeringsHanded;

  /// Offerings still on the phone after this session.
  final int offeringsWaiting;
  final int prayersHanded;

  static const nothingToDo = RelayReport();
}

/// Hands everything waiting on the phone to a CVendor hub, over BLE only.
///
///   1. connect + read the hub's single-use challenge;
///   2. register first if the backend doesn't know this giver yet (or their
///      details changed) — the hub relays it to /register and returns the
///      server user id; offerings can't be signed without it;
///   3. sign each queued offering NOW (fresh counter, timestamp and the hub's
///      nonce) and hand it over; the hub uploads it to /ingest;
///   4. hand over queued prayers (anonymous; the hub forwards them to the
///      prayer sheet).
///
/// Nothing is lost at any step: an offering stays queued until a hub acks it,
/// and a retried offering keeps its idempotency key, so it is never charged
/// twice. Concurrent calls share one session.
class GivingRelay {
  GivingRelay({
    required LocalDatabase db,
    required ContributionRepository contributions,
    required RegistrationRepository registration,
    required PrayerOutbox prayers,
    required HubConnector connector,
  })  : _db = db,
        _contributions = contributions,
        _registration = registration,
        _prayers = prayers,
        _connector = connector;

  final LocalDatabase _db;
  final ContributionRepository _contributions;
  final RegistrationRepository _registration;
  final PrayerOutbox _prayers;
  final HubConnector _connector;
  Future<RelayReport>? _inFlight;
  Future<RelayReport>? _next;

  /// Anything waiting to be handed to a hub?
  Future<bool> hasWork() async {
    final user = await _db.currentUser();
    if (user == null) return false;
    return !user.synced ||
        user.serverUserId == null ||
        (await _contributions.awaitingHandover()).isNotEmpty ||
        (await _prayers.pending()).isNotEmpty;
  }

  /// Run one hub session. A call made while a session is running waits for
  /// it and then runs one more, so an offering queued mid-session (e.g. a
  /// background hand-over was already under way when Send was tapped) is
  /// never left behind.
  Future<RelayReport> drain() {
    final current = _inFlight;
    if (current != null) return _next ??= current.then((_) => _start());
    return _start();
  }

  Future<RelayReport> _start() {
    _next = null;
    return _inFlight = _run().whenComplete(() => _inFlight = null);
  }

  Future<RelayReport> _run() async {
    var user = await _db.currentUser();
    if (user == null || !await hasWork()) return RelayReport.nothingToDo;

    final link = await _connector.connect();
    if (link == null) {
      return RelayReport(offeringsWaiting: (await _contributions.awaitingHandover()).length);
    }

    var registered = false;
    var registrationPending = false;
    var refused = false;
    var handed = 0;
    var prayersHanded = 0;
    try {
      // --- 2. Registration (only when needed) --------------------------------
      if (!user.synced || user.serverUserId == null) {
        final body = await _registration.registrationBody();
        final ack = await link.send(HubProtocol.register(body!));
        if (ack.status == HubProtocol.ackAccepted && ack.userId != null) {
          await _registration.markRegistered(ack.userId!);
          user = await _db.currentUser();
          registered = true;
        } else if (ack.status == HubProtocol.ackRefused) {
          refused = true;
        } else {
          registrationPending = true;
        }
      }

      // --- 3. Offerings --------------------------------------------------------
      final canGive = user != null && user.synced && user.serverUserId != null;
      if (canGive) {
        final rows = await _contributions.awaitingHandover();
        for (var i = 0; i < rows.length; i++) {
          final envelope = await _contributions.envelopeFor(rows[i], user, '${link.challenge.nonce}-$i');
          final ack = await link.send(HubProtocol.contribution(envelope));
          if (ack.accepted) {
            await _contributions.updateStatus(rows[i].id, 'sent');
            handed++;
          } else {
            await _contributions.updateStatus(rows[i].id, 'queued', failureReason: 'collector did not accept it (code ${ack.status})');
            break;
          }
        }
      }

      // --- 4. Prayers (anonymous; no registration needed) ----------------------
      for (final p in await _prayers.pending()) {
        final ack = await link.send(HubProtocol.prayer(requestId: p.id, prayer: p.text));
        if (!ack.accepted) break;
        await _prayers.remove(p.id);
        prayersHanded++;
      }
    } catch (_) {
      // Walked out of range / radio hiccup: whatever was mid-flight goes back
      // to the queue and is re-signed next time (same idempotency key).
    } finally {
      for (final r in await _contributions.awaitingHandover()) {
        if (r.status == 'transmitting') await _contributions.updateStatus(r.id, 'queued');
      }
      await link.close();
    }

    return RelayReport(
      hubFound: true,
      church: link.challenge.church,
      registered: registered,
      registrationPending: registrationPending,
      registrationRefused: refused,
      offeringsHanded: handed,
      offeringsWaiting: (await _contributions.awaitingHandover()).length,
      prayersHanded: prayersHanded,
    );
  }
}

final hubConnectorProvider = Provider<HubConnector>((ref) => BleTransport());

final givingRelayProvider = Provider<GivingRelay>((ref) => GivingRelay(
      db: ref.watch(localDatabaseProvider),
      contributions: ref.watch(contributionRepositoryProvider),
      registration: ref.watch(registrationRepositoryProvider),
      prayers: ref.watch(prayerOutboxProvider),
      connector: ref.watch(hubConnectorProvider),
    ));
