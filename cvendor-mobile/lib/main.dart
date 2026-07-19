import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'features/pairing_screen.dart';
import 'features/hub_dashboard_screen.dart';
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
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paired = ref.watch(isPairedProvider);
    return paired.when(
      loading: () => const Scaffold(
        backgroundColor: HubColors.panelGreen,
        body: Center(child: CircularProgressIndicator(color: HubColors.indigo)),
      ),
      error: (_, _) => const PairingScreen(),
      data: (isPaired) => isPaired ? const HubDashboardScreen() : const PairingScreen(),
    );
  }
}
