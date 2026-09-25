import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/prayer_sheet.dart';
import '../theme.dart';

/// Dashboard card: opens this Sabbath's anonymous prayer requests (the prayer
/// team's Google Sheet) so the deacon and prayer team can pray over them.
/// The first time, it asks for the Sheet link and remembers it.
class PrayerRequestsCard extends ConsumerWidget {
  const PrayerRequestsCard({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String? url) async {
    final link = url ?? await _askForLink(context, ref);
    if (link == null) return;
    final ok = await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the prayer requests. Check the link and try again.')),
      );
    }
  }

  Future<String?> _askForLink(BuildContext context, WidgetRef ref, {String? current}) async {
    final controller = TextEditingController(text: current ?? '');
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Prayer requests link'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Paste the link of the prayer requests Google Sheet '
              '(in the Sheet: Share → Copy link).',
              style: TextStyle(color: HubColors.inkMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://docs.google.com/spreadsheets/d/…',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final url = PrayerSheet.normalise(controller.text);
                if (url == null) {
                  setState(() => error = 'That is not a Google Sheets link');
                  return;
                }
                Navigator.pop(ctx, url);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
    controller.dispose();
    if (result == null) return null;
    await PrayerSheet.save(result);
    ref.invalidate(prayerSheetUrlProvider);
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(prayerSheetUrlProvider).valueOrNull;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context, ref, url),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HubColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: HubColors.panel, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.volunteer_activism_outlined, color: HubColors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Prayer requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: HubColors.ink)),
                const SizedBox(height: 2),
                Text(
                  url == null
                      ? 'Tap to add the prayer sheet link'
                      : 'This Sabbath’s silent prayers — all anonymous',
                  style: const TextStyle(fontSize: 13, color: HubColors.inkMuted),
                ),
              ]),
            ),
            if (url != null)
              IconButton(
                tooltip: 'Change link',
                icon: const Icon(Icons.edit_outlined, size: 20, color: HubColors.inkMuted),
                onPressed: () => _askForLink(context, ref, current: url),
              ),
            const Icon(Icons.open_in_new, size: 20, color: HubColors.green),
          ]),
        ),
      ),
    );
  }
}
