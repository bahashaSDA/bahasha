import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The first-run guided tour: a coach-mark walk through the REAL interface —
/// the rest of the screen is dimmed, the actual control is cut out and
/// outlined, and a short card explains it. Shown once per install; finishing
/// or skipping persists completion (SharedPreferences, the app's existing
/// first-run mechanism), so it never reappears on later launches.

/// Where a step's target lives. The tour host navigates there itself.
enum TourScreen { home, category, send, menu, settings, none }

/// Anchors on the real widgets the tour points at. Each is attached to
/// exactly one widget on one screen.
class TourKeys {
  TourKeys._();
  static final homeAmount = GlobalKey(debugLabel: 'tour.homeAmount');
  static final homeKeypad = GlobalKey(debugLabel: 'tour.homeKeypad');
  static final homeCategory = GlobalKey(debugLabel: 'tour.homeCategory');
  static final categoryCard = GlobalKey(debugLabel: 'tour.categoryCard');
  static final homeSend = GlobalKey(debugLabel: 'tour.homeSend');
  static final homeMenu = GlobalKey(debugLabel: 'tour.homeMenu');
  static final sendVendor = GlobalKey(debugLabel: 'tour.sendVendor');
  static final sendTotal = GlobalKey(debugLabel: 'tour.sendTotal');
  static final sendButton = GlobalKey(debugLabel: 'tour.sendButton');
  static final sendPrayer = GlobalKey(debugLabel: 'tour.sendPrayer');
  static final menuSettings = GlobalKey(debugLabel: 'tour.menuSettings');
  static final settingsPersonal = GlobalKey(debugLabel: 'tour.settingsPersonal');
}

@immutable
class TourStep {
  const TourStep(this.screen, this.target, this.title, this.body);
  final TourScreen screen;
  final GlobalKey? target;
  final String title;
  final String body;
}

final List<TourStep> tourSteps = <TourStep>[
  TourStep(TourScreen.home, TourKeys.homeAmount, 'Welcome to Bahasha',
      'This is where you give. The category you are giving to is shown at the top, with your amount right below it.'),
  TourStep(TourScreen.home, TourKeys.homeCategory, 'Choose a category',
      'Tap here to choose what you are giving to: tithe, offering, church budget, mission and more.'),
  TourStep(TourScreen.category, TourKeys.categoryCard, 'Pick from the list',
      'Scroll the list, then tap the arrow to select. Each category keeps its own amount, so one gift can cover several.'),
  TourStep(TourScreen.home, TourKeys.homeKeypad, 'Enter your offering',
      'Type your amount on the keypad. The key on the right removes the last digit.'),
  TourStep(TourScreen.home, TourKeys.homeSend, 'Review your offering',
      'When you are ready, tap here to review everything you are giving.'),
  TourStep(TourScreen.send, TourKeys.sendVendor, 'Your church collector',
      'Your offering goes from you to your church’s Bahasha collector. A blue line means a collector is nearby; red means none has been found yet, and your offering waits safely on your phone. Tap the collector to see who it is.'),
  TourStep(TourScreen.send, TourKeys.sendTotal, 'Check each category',
      'Scroll here to see each category and the total before you give.'),
  TourStep(TourScreen.send, TourKeys.sendButton, 'Send',
      'Tap Send. Before your offering goes, you can add a silent prayer, or skip it. Then tap Send once more to give.'),
  TourStep(TourScreen.send, TourKeys.sendPrayer, 'Prayer request (optional)',
      'You can add a silent prayer with your offering. It is anonymous (no name goes with it) and your church’s prayer team prays over it this Sabbath. Tap the bubble to add or change it.'),
  TourStep(TourScreen.home, TourKeys.homeMenu, 'Menu',
      'The menu is here, at the top left.'),
  TourStep(TourScreen.menu, TourKeys.menuSettings, 'Settings',
      'Open Settings from the gear in the menu.'),
  TourStep(TourScreen.settings, TourKeys.settingsPersonal, 'Personal info',
      'View or update your name and phone number here. History has your receipts, and Mode lets you give anonymously.'),
  const TourStep(TourScreen.home, null, 'You’re all set',
      'You can now use Bahasha normally. Be blessed.'),
];

const _kDone = 'bahasha.tour.v2.done';

/// Whether this install has completed (or skipped) the guided tour.
final tourDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kDone) ?? false;
});

/// The running tour's step index, or null when no tour is showing.
class TourController extends Notifier<int?> {
  @override
  int? build() => null;

  bool get running => state != null;

  void start() {
    if (state == null) state = 0;
  }

  void next() {
    final s = state;
    if (s == null) return;
    if (s >= tourSteps.length - 1) {
      finish();
    } else {
      state = s + 1;
    }
  }

  void back() {
    final s = state;
    if (s == null || s == 0) return;
    state = s - 1;
  }

  /// Finish or skip: persist completion so the tour never shows again.
  Future<void> finish() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDone, true);
    ref.invalidate(tourDoneProvider);
  }
}

final tourProvider = NotifierProvider<TourController, int?>(TourController.new);
