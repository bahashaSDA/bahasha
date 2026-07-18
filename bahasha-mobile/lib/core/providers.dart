import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crypto/payload_signer.dart';
import 'data/local_database.dart';
import 'data/registration_repository.dart';
import 'data/contribution_repository.dart';
import 'network/api_client.dart';

/// Dependency wiring for the app. Single instances of the database, API client,
/// and signer are shared through the tree; repositories compose them. Keeping
/// this in one place makes the object graph explicit and swappable in tests.

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final payloadSignerProvider = Provider<PayloadSigner>((ref) => PayloadSigner());

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(
    db: ref.watch(localDatabaseProvider),
    api: ref.watch(apiClientProvider),
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
