import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../history/presentation/history_screen.dart';
import '../../customize/presentation/customize_screen.dart';

/// Account & settings. Shows the giver's profile and lets them switch between
/// Secret Giving and Give Openly. Switching affects only FUTURE giving — past
/// contributions keep the visibility they were made under (enforced server-side
/// by visibility_snapshot), so this can never retroactively expose prior gifts.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.panelGreen,
      appBar: AppBar(
        backgroundColor: AppColors.panelGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Account', style: AppTypography.title.copyWith(fontSize: 24)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.indigo)),
        error: (e, _) => Center(child: Text('$e', style: AppTypography.description)),
        data: (user) {
          if (user == null) {
            return Center(child: Text('Not registered yet', style: AppTypography.description));
          }
          final secret = user.visibility == 'secret';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              _ProfileHeader(name: user.fullName, phone: user.phone),
              const SizedBox(height: 24),

              _SectionLabel('Giving visibility'),
              _VisibilityToggle(
                secret: secret,
                onChanged: (toSecret) async {
                  await ref
                      .read(registrationRepositoryProvider)
                      .setVisibility(toSecret ? 'secret' : 'open');
                  ref.invalidate(currentUserProvider);
                },
              ),
              const SizedBox(height: 24),

              _SectionLabel('More'),
              _Tile(
                icon: Icons.receipt_long_outlined,
                title: 'Contribution history',
                subtitle: 'View, share and manage your giving',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
              _Tile(
                icon: Icons.palette_outlined,
                title: 'Customize',
                subtitle: 'Colours, theme and appearance',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CustomizeScreen())),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.phone});
  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Row(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initial, style: AppTypography.title.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(name, style: AppTypography.title.copyWith(fontSize: 22)),
              const SizedBox(height: 2),
              Text(phone, style: AppTypography.description.copyWith(color: AppColors.inkMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.secret, required this.onChanged});
  final bool secret;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: <Widget>[
          _option('Give openly', 'Visible to your church', !secret, () => onChanged(false)),
          _option('Secret giving', 'Hidden from church reports', secret, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _option(String title, String sub, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppTypography.rowLabel.copyWith(
                  fontSize: 16,
                  color: active ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: AppTypography.description.copyWith(
                  fontSize: 12,
                  color: active ? Colors.white70 : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text, style: AppTypography.rowLabel.copyWith(fontSize: 15, color: AppColors.inkMuted)),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.indigo),
        title: Text(title, style: AppTypography.rowLabel.copyWith(fontSize: 16)),
        subtitle: Text(subtitle, style: AppTypography.description.copyWith(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
