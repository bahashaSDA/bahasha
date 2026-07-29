import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/design/icon.dart';
import '../../../../core/design/pixel_canvas.dart';
import '../../../../core/providers.dart';
import '../menu_screen.dart';

/// The header shared by every offertory screen: the hamburger menu (opens the
/// account/history/customize area), the "Offerings" wordmark, and the circular
/// profile photo in the top-right — exactly at the Figma positions
/// (menu 57,75 · "Offerings" 93,74 · avatar 304,54 ⌀64).
List<Widget> offeringsHeader(BuildContext context, Px px) {
  return [
    px.at(57, 75, width: 24, height: 24, child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      ),
      child: DesignIcon('menu', scale: px.scale, color: Colors.black),
    )),
    px.text(93, 74, 'Offerings', size: 20, weight: FontWeight.w300,
        color: Colors.black, fontFamily: 'Inter'),
    px.at(304, 54, width: 64, height: 64, child: const AvatarButton()),
  ];
}

/// Circular profile photo. Tap to pick one from the gallery; it is copied into
/// the app's documents directory and persisted on the local user so it survives
/// relaunches. Falls back to a neutral person glyph until a photo is chosen.
class AvatarButton extends ConsumerWidget {
  const AvatarButton({super.key});

  Future<void> _pick(WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'avatar${p.extension(picked.path)}');
    await File(picked.path).copy(dest);
    await ref.read(localDatabaseProvider).setAvatarPath(dest);
    ref.invalidate(currentUserProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final path = user?.avatarPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();

    return GestureDetector(
      onTap: () => _pick(ref),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE9E9EF),
          image: hasPhoto
              ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)
              : null,
        ),
        child: hasPhoto
            ? null
            : const Icon(Icons.person, color: Color(0xFF9A9AAE), size: 34),
      ),
    );
  }
}
