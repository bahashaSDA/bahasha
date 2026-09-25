import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crypto/payload_signer.dart';
import 'data/local_database.dart';
import 'data/registration_repository.dart';
import 'data/contribution_repository.dart';
import '../features/prayer/data/prayer_outbox.dart';

/// Dependency wiring for the app. Single instances of the database and
/// signer are shared through the tree; repositories compose them. Keeping
/// this in one place makes the object graph explicit and swappable in tests.

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final payloadSignerProvider = Provider<PayloadSigner>((ref) => PayloadSigner());

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(
    db: ref.watch(localDatabaseProvider),
    signer: ref.watch(payloadSignerProvider),
  );
});

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepository(
    db: ref.watch(localDatabaseProvider),
    signer: ref.watch(payloadSignerProvider),
  );
});

/// The current local user, or null if registration has not happened. Drives the
/// root gate between the registration flow and the home screen.
final currentUserProvider = FutureProvider<LocalUser?>((ref) {
  return ref.watch(localDatabaseProvider).currentUser();
});

/// Anonymous prayers waiting on the phone to be handed to a hub over BLE.
final prayerOutboxProvider = Provider<PrayerOutbox>((ref) => PrayerOutbox());
