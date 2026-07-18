import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/theme/app_colors.dart';
import 'features/contribution/presentation/home_screen.dart';
import 'features/registration/presentation/registration_screen.dart';

/// The root gate. Reads the local profile: if registration has not happened it
/// shows the one-time registration flow, otherwise it goes straight to Home.
/// This is what makes "next launches skip registration" true — the decision is
/// data-driven off the local database, not a flag that can drift.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

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
