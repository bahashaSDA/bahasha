import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/icon.dart';
import '../../core/design/type.dart';
import '../../core/theme/app_colors.dart';
import '../contribution/application/basket_controller.dart';
import '../contribution/presentation/menu_screen.dart';
import '../contribution/presentation/send_screen.dart';
import '../settings/presentation/settings_screen.dart';
import 'tour_controller.dart';

/// The app-wide navigator, so the tour can walk the giver through real
/// screens (Home → wheel → Send → Menu → Settings) and back.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Hosts the guided tour above the whole app (MaterialApp.builder). While a
/// step is showing, the app below is dimmed and not interactive; the step's
/// real target is cut out of the scrim and outlined in the design blue.
class TourHost extends ConsumerStatefulWidget {
  const TourHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<TourHost> createState() => _TourHostState();
}

class _TourHostState extends ConsumerState<TourHost> {
  /// Routes the tour pushed, bottom-up (Home is the root and never pushed).
  final List<TourScreen> _stack = [];
  Rect? _hole;
  Timer? _measure;
  bool _moving = false;

  @override
  void dispose() {
    _measure?.cancel();
    super.dispose();
  }

  static List<TourScreen> _pathTo(TourScreen s) => switch (s) {
    TourScreen.send => [TourScreen.send],
    TourScreen.menu => [TourScreen.menu],
    TourScreen.settings => [TourScreen.menu, TourScreen.settings],
    _ => const [],
  };

  Future<void> _goTo(TourStep step) async {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    setState(() {
      _moving = true;
      _hole = null;
    });
    ref.read(homePickingProvider.notifier).state =
        step.screen == TourScreen.category;

    final target = _pathTo(step.screen);
    var common = 0;
    while (common < _stack.length &&
        common < target.length &&
        _stack[common] == target[common]) {
      common++;
    }
    while (_stack.length > common) {
      nav.pop();
      _stack.removeLast();
    }
    for (final s in target.skip(common)) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => switch (s) {
            TourScreen.send => const SendScreen(preview: true),
            TourScreen.menu => const MenuScreen(),
            _ => const SettingsScreen(),
          },
        ),
      );
      _stack.add(s);
    }
    // Let the route transition settle before measuring the target.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _moving = false);
    _startMeasuring(step);
  }

  void _startMeasuring(TourStep step) {
    _measure?.cancel();
    void measure() {
      final rect = _rectOf(step.target);
      if (rect != _hole && mounted) setState(() => _hole = rect);
    }

    measure();
    _measure = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => measure(),
    );
  }

  Rect? _rectOf(GlobalKey? key) {
    final ctx = key?.currentContext;
    final box = ctx?.findRenderObject();
    final host = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached || host is! RenderBox) {
      return null;
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: host);
    return topLeft & box.size;
  }

  Future<void> _finish() async {
    _measure?.cancel();
    final nav = appNavigatorKey.currentState;
    while (_stack.isNotEmpty) {
      nav?.pop();
      _stack.removeLast();
    }
    ref.read(homePickingProvider.notifier).state = false;
    setState(() => _hole = null);
    await ref.read(tourProvider.notifier).finish();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(tourProvider, (_, index) {
      if (index == null) return;
      unawaited(_goTo(tourSteps[index]));
    });

    final index = ref.watch(tourProvider);
    if (index == null) return widget.child;
    final step = tourSteps[index];
    final last = index == tourSteps.length - 1;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              final s = c.maxWidth / 420;
              final hole = _hole?.inflate(8 * s);
              return Stack(
                children: [
                  // Scrim with the target cut out; absorbs every tap beneath.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedOpacity(
                        opacity: _moving ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: CustomPaint(
                          painter: _ScrimPainter(
                            hole: hole,
                            radius: 17 * s,
                            scale: s,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_moving)
                    _Card(
                      scale: s,
                      area: c.biggest,
                      hole: hole,
                      step: step,
                      position: '${index + 1} of ${tourSteps.length}',
                      last: last,
                      onNext: last
                          ? _finish
                          : () => ref.read(tourProvider.notifier).next(),
                      onBack: index == 0
                          ? null
                          : () => ref.read(tourProvider.notifier).back(),
                      onSkip: _finish,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.hole,
    required this.radius,
    required this.scale,
  });
  final Rect? hole;
  final double radius;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final scrim = Paint()..color = const Color(0xB3000000);
    if (hole == null) {
      canvas.drawPath(full, scrim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(hole!, Radius.circular(radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, Path()..addRRect(rrect)),
      scrim,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.radius != radius;
}

/// The explanation card — the design's own card (white, radius 17, #D9D9D9
/// border) in Elms Sans, placed below the target or above it if there is no
/// room, with Skip / Back / Next in the design's text-action style.
class _Card extends StatelessWidget {
  const _Card({
    required this.scale,
    required this.area,
    required this.hole,
    required this.step,
    required this.position,
    required this.last,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final double scale;
  final Size area;
  final Rect? hole;
  final TourStep step;
  final String position;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final gap = 16 * s;
    final margin = 32 * s;
    final edge = 24 * s + MediaQuery.of(context).padding.vertical / 2;

    // Put the card on whichever side of the target has more room, and never
    // let it run off-screen (its buttons must stay tappable).
    double? top;
    double? bottom;
    double maxHeight;
    if (hole == null) {
      maxHeight = area.height - 2 * edge;
      top = null;
    } else if (area.height - hole!.bottom >= hole!.top) {
      top = hole!.bottom + gap;
      maxHeight = area.height - top - edge;
    } else {
      bottom = area.height - hole!.top + gap;
      maxHeight = hole!.top - gap - edge;
    }

    Widget action(String label, VoidCallback? onTap, Color color) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 6 * s),
          child: Text(label, style: BType.elms(16 * s, color: color)),
        ),
      ),
    );

    final card = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight < 120 * s ? 120 * s : maxHeight,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: EdgeInsets.fromLTRB(22 * s, 18 * s, 16 * s, 8 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17 * s),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position,
                  style: BType.elms(13 * s, color: AppColors.wheelGrey),
                ),
                SizedBox(height: 6 * s),
                Text(
                  step.title,
                  style: BType.elms(20 * s, weight: BType.regular),
                ),
                SizedBox(height: 8 * s),
                Text(step.body, style: BType.elms(16 * s, height: 1.35)),
                SizedBox(height: 8 * s),
                Row(
                  children: [
                    if (!last) action('Skip', onSkip, AppColors.wheelGrey),
                    const Spacer(),
                    // Scales down rather than overflow on narrow cards / large text.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onBack != null)
                              action('Back', onBack, AppColors.wheelGrey),
                            SizedBox(width: 4 * s),
                            Semantics(
                              button: true,
                              label: last ? 'Start giving' : 'Next',
                              excludeSemantics: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onNext,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10 * s,
                                    horizontal: 6 * s,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        last ? 'Start giving' : 'Next',
                                        style: BType.elms(
                                          16 * s,
                                          color: AppColors.blue,
                                        ),
                                      ),
                                      SizedBox(width: 8 * s),
                                      DesignIcon(
                                        'arrow_right_circle_blue',
                                        scale: s,
                                        tint: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (hole == null) {
      return Positioned.fill(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: card,
          ),
        ),
      );
    }
    return Positioned(
      left: margin,
      right: margin,
      top: top,
      bottom: bottom,
      child: card,
    );
  }
}
