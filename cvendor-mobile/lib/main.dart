import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'features/pairing_screen.dart';
import 'features/hub_dashboard_screen.dart';
import 'features/onboarding_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: CVendorApp()));
}

class CVendorApp extends StatelessWidget {
  const CVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CVendor — Bahasha Hub',
      debugShowCheckedModeBanner: false,
      theme: hubTheme(),
      home: const _Gate(),
    );
  }
}

/// Routes to pairing (unpaired) or the dashboard (paired), data-driven off the
/// stored credential so a paired hub reopens straight to operations.
class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> {
  bool? _seen;

  @override
  void initState() {
    super.initState();
    HubOnboardingScreen.seen().then((v) {
      if (mounted) setState(() => _seen = v);
    });
  }

  static const _loading = Scaffold(
    backgroundColor: HubColors.surface,
    body: Center(child: CircularProgressIndicator(color: HubColors.green)),
  );

  @override
  Widget build(BuildContext context) {
    if (_seen == null) return _loading;
    if (_seen == false) {
      return HubOnboardingScreen(onDone: () async {
        await HubOnboardingScreen.markSeen();
        if (mounted) setState(() => _seen = true);
      });
    }
    final paired = ref.watch(isPairedProvider);
    return paired.when(
      loading: () => _loading,
      error: (_, _) => const PairingScreen(),
      data: (isPaired) => isPaired ? const HubDashboardScreen() : const PairingScreen(),
    );
  }
}
