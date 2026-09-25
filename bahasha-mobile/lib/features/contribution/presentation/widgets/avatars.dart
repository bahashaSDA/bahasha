import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/providers.dart';

/// The giver's circular profile photo (Menu/Settings top-right ⌀48, Send
/// top-left ⌀37). Falls back to a neutral person glyph until a photo is
/// chosen. With [editable], tapping picks a new photo from the gallery; it is
/// copied into the app's documents directory and saved on the local user.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.editable = false});

  final bool editable;

  Future<void> _pick(WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'avatar${p.extension(picked.path)}');
    await File(picked.path).copy(dest);
    // Evict the old image so the same file path re-renders the new photo.
    imageCache.evict(FileImage(File(dest)));
    await ref.read(localDatabaseProvider).setAvatarPath(dest);
    ref.invalidate(currentUserProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final path = user?.avatarPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();

    final circle = LayoutBuilder(builder: (context, c) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE9E9EF),
          image: hasPhoto ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
        ),
        child: hasPhoto ? null : Icon(Icons.person, color: const Color(0xFF9A9AAE), size: c.maxWidth * 0.6),
      );
    });

    if (!editable) return circle;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(onTap: () => _pick(ref), child: circle),
    );
  }
}
