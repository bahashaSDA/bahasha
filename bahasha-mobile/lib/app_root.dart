import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/theme/app_colors.dart';
import 'features/contribution/presentation/home_screen.dart';
import 'features/registration/presentation/registration_screen.dart';

/// The root gate: the one-time registration, thereafter straight to Home. The
/// decision is data-driven (the local profile), never a runtime flag that can
/// drift. The first-run guided tour then runs on Home itself (see
/// features/tour/), pointing at the real controls.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  @override
  void initState() {
    super.initState();
    // Deliver any prayer requests still waiting on this phone, now and
    // whenever the network returns.
    ref.read(prayerOutboxProvider).start();
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.blue, strokeWidth: 1.5),
      ),
    );
  }
}
