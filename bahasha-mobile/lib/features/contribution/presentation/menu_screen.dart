import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../history/presentation/history_screen.dart';
import '../../customize/presentation/customize_screen.dart';
import 'widgets/offerings_header.dart';

/// The menu, redesigned to sit hand-in-hand with the offertory look: a white
/// canvas, the Inter face, and the offertory green (#008805). It carries the
/// giver's profile (photo, name, phone), a "give secretly" switch, and links
/// into History and Customize.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  static const _green = Color(0xFF008805);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final name = (user?.fullName ?? '').trim();
    final phone = user?.phone ?? '';
    final secret = user?.visibility == 'secret';
    final avatar = user?.avatarPath;
    final hasPhoto = avatar != null && avatar.isNotEmpty && File(avatar).existsSync();

    Future<void> toggleSecret(bool v) async {
      await ref.read(registrationRepositoryProvider).setVisibility(v ? 'secret' : 'open');
      ref.invalidate(currentUserProvider);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          children: [
            Row(children: [
              _CircleIcon(icon: Icons.close, onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
              const SizedBox(width: 56, height: 56, child: AvatarButton()),
            ]),
            const SizedBox(height: 20),
            const Text('Menu', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300, fontSize: 28, color: Colors.black)),
            const SizedBox(height: 20),

            // Profile card.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE9E9EF),
                    image: hasPhoto ? DecorationImage(image: FileImage(File(avatar)), fit: BoxFit.cover) : null,
                  ),
                  child: hasPhoto ? null : const Icon(Icons.person, color: Color(0xFF9A9AAE), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isEmpty ? 'Your profile' : name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(phone.isEmpty ? 'Tap the photo to add yours' : phone,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B6B76))),
                ])),
              ]),
            ),
            const SizedBox(height: 24),

            // Give secretly switch.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: Row(children: [
                _IconBadge(icon: secret ? Icons.visibility_off : Icons.visibility),
                const SizedBox(width: 14),
                const Expanded(child: Text('Give secretly',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black))),
                Switch.adaptive(value: secret, onChanged: toggleSecret, activeTrackColor: _green),
              ]),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('When on, your name and phone are hidden from church reports. Only a super admin can ever unmask a secret gift, and it is audited.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF8A8A93), height: 1.35)),
            ),
            const SizedBox(height: 12),

            _MenuTile(icon: Icons.receipt_long, label: 'History', subtitle: 'Your past giving',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()))),
            const SizedBox(height: 12),
            _MenuTile(icon: Icons.palette_outlined, label: 'Customize', subtitle: 'Colours and look',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomizeScreen()))),

            const SizedBox(height: 40),
            const Center(child: Text('Made by calemaley  ·  © 2026 Bahasha',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0x73000000)))),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.subtitle, required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Row(children: [
          _IconBadge(icon: icon),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
            Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF8A8A93))),
          ])),
          const Icon(Icons.chevron_right, color: Color(0xFFBDBDC7)),
        ]),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(color: const Color(0x1A008805), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: const Color(0xFF008805), size: 22),
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
