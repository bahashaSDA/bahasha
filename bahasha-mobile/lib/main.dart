// Bahasha — offline-first church giving.
// Copyright © 2026 Bahasha. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'app_root.dart';
import 'features/tour/tour_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The offertory redesign is white edge to edge; keep the system bars white
  // with dark icons so the chrome disappears into the design on every phone.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: BahashaApp()));
}

class BahashaApp extends StatelessWidget {
  const BahashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bahasha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: appNavigatorKey,
      // The first-run guided tour sits above every route so it can dim the
      // real screens and point at their controls.
      builder: (context, child) => TourHost(child: child ?? const SizedBox.shrink()),
      home: const AppRoot(),
    );
  }
}
