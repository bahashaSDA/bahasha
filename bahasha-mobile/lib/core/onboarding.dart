import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the giver has seen the first-run walkthrough. Persisted so the
/// tutorial shows exactly once, on the very first open.
const _kSeen = 'bahasha.onboarding.seen.v1';

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kSeen) ?? false;
});

Future<void> markOnboardingSeen(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kSeen, true);
  ref.invalidate(onboardingSeenProvider);
}
