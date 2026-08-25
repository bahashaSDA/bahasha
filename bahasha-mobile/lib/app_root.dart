import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/onboarding.dart';
import 'core/theme/app_colors.dart';
import 'features/contribution/presentation/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/registration/presentation/registration_screen.dart';

/// The root gate. On the very first open it shows the one-time walkthrough; then
/// the one-time registration; thereafter it goes straight to Home. Each decision
/// is data-driven (a persisted flag / the local profile), never a runtime flag
/// that can drift.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingSeenProvider);
    final user = ref.watch(currentUserProvider);

    if (seen.valueOrNull == false) {
      return OnboardingScreen(onDone: () => markOnboardingSeen(ref));
    }

    return user.when(
      loading: () => const _Splash(),
      error: (_, _) => const _Splash(),
      data: (u) {
        if (u == null) {
          return RegistrationScreen(
            onComplete: () => ref.invalidate(currentUserProvider),
          );
        }
        return const HomeScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.panelGreen,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.indigo),
      ),
    );
  }
}
