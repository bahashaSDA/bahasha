import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/local_database.dart';
import '../../../core/providers.dart';
import '../../history/domain/contribution_view.dart';
import 'widgets/offerings_header.dart';

/// The menu — a swipeable carousel of three fruit-backed cards that sits
/// hand-in-hand with the offertory design: User details, History, and Give
/// secretly. Slide between them; the header names the current card. History
/// opens a full overview in place (you never leave the menu).
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  static const _green = Color(0xFF008805);
  static const _titles = ['User details', 'History', 'Give secretly'];

  final _pc = PageController(viewportFraction: 0.82);
  int _page = 0;
  bool _historyOpen = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    _CircleIcon(icon: Icons.close, onTap: () => Navigator.of(context).maybePop()),
                    const Spacer(),
                    const SizedBox(width: 52, height: 52, child: AvatarButton()),
                  ]),
                ),
                const SizedBox(height: 8),
                // Header names the current card (replaces the mockup's wordmark).
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(_titles[_page], key: ValueKey(_page),
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300, fontSize: 26, color: Colors.black)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView(
                    controller: _pc,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _UserCard(user: user),
                      _HistoryCard(onOpen: () => setState(() => _historyOpen = true)),
                      _SecretCard(
                        secret: user?.visibility == 'secret',
                        onToggle: (v) async {
                          await ref.read(registrationRepositoryProvider).setVisibility(v ? 'secret' : 'open');
                          ref.invalidate(currentUserProvider);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 22 : 8, height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? _green : const Color(0x33008805),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
                const Text('© 2026 Bahasha', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0x73000000))),
                const SizedBox(height: 12),
              ],
            ),

            // Full history overview — slides over the menu; you never leave it.
            if (_historyOpen)
              Positioned.fill(child: _HistoryOverview(onClose: () => setState(() => _historyOpen = false))),
          ],
        ),
      ),
    );
  }
}

/// A rounded fruit-backed card: a light green field with a translucent fruit
/// bleeding off one corner, a title, and its content — matching the design.
class _FruitCard extends StatelessWidget {
  const _FruitCard({required this.title, required this.fruit, required this.child, this.onTap});
  final String title;
  final String fruit;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFF2FBF3), Color(0xFFE3F3E7)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(children: [
              Positioned(right: -34, bottom: -26, child: Opacity(
                opacity: 0.22, child: Image.asset(fruit, width: 210, fit: BoxFit.contain))),
              Positioned(left: -30, top: -30, child: Opacity(
                opacity: 0.12, child: Image.asset(fruit, width: 120, fit: BoxFit.contain))),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 22, color: Colors.black)),
                  const SizedBox(height: 20),
                  Expanded(child: child),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final LocalUser? user;

  @override
  Widget build(BuildContext context) {
    final name = (user?.fullName ?? '').trim();
    final phone = user?.phone ?? '';
    return _FruitCard(
      title: 'User details',
      fruit: 'assets/fruits/tithe.png',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        _row(Icons.person_outline, 'Name', name.isEmpty ? '—' : name),
        const SizedBox(height: 18),
        _row(Icons.phone_outlined, 'Phone', phone.isEmpty ? '—' : phone),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0x1A008805), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF008805), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF8A8A93))),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, color: Colors.black)),
        ])),
      ]);
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _FruitCard(
      title: 'History',
      fruit: 'assets/fruits/offering.png',
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('All your past giving, in one place.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFF5A5A66), height: 1.4)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF008805), borderRadius: BorderRadius.circular(40)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Tap to view', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 15, color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 17, color: Colors.white),
          ]),
        ),
      ]),
    );
  }
}

class _SecretCard extends StatelessWidget {
  const _SecretCard({required this.secret, required this.onToggle});
  final bool secret;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return _FruitCard(
      title: 'Give secretly',
      fruit: 'assets/fruits/mission.png',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Expanded(child: Text(secret ? 'Secret giving is on' : 'Giving openly',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 17, color: Colors.black))),
          Switch.adaptive(value: secret, onChanged: onToggle, activeTrackColor: const Color(0xFF008805)),
        ]),
        const SizedBox(height: 12),
        const Text('When on, your name and phone are hidden from church reports. Only a super admin can ever unmask a secret gift, and it is audited.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF5A5A66), height: 1.4)),
      ]),
    );
  }
}

/// The full history list, shown over the menu (no navigation — still the menu).
class _HistoryOverview extends ConsumerWidget {
  const _HistoryOverview({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(localDatabaseProvider).watchHistory();
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 20, 8),
            child: Row(children: [
              _CircleIcon(icon: Icons.arrow_back, onTap: onClose),
              const SizedBox(width: 12),
              const Text('History', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300, fontSize: 24, color: Colors.black)),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Contribution>>(
              stream: stream,
              builder: (context, snap) {
                final rows = snap.data ?? const <Contribution>[];
                if (rows.isEmpty) {
                  return const Center(child: Text('No giving yet.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFF8A8A93))));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _HistoryTile(view: ContributionView(rows[i])),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.view});
  final ContributionView view;

  @override
  Widget build(BuildContext context) {
    final chip = view.statusChip;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(view.dateLabel,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF8A8A93)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: chip.bg, borderRadius: BorderRadius.circular(20)),
            child: Text(chip.label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: chip.color)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(view.amountLabel,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xFF008805))),
        const SizedBox(height: 6),
        Text(view.allocations.map((a) => a.name).join(' · '),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF5A5A66))),
      ]),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x1F000000))),
        child: Icon(icon, size: 22, color: Colors.black),
      ),
    );
  }
}
