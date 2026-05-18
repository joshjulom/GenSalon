import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from gallery (or camera), copies it to app docs/photos,
  /// returns the persisted absolute path. Returns null if cancelled.
  static Future<String?> pickAndPersist({bool fromCamera = false}) async {
    final XFile? f = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (f == null) return null;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = p.extension(f.path).isEmpty ? '.jpg' : p.extension(f.path);
    final dest = p.join(
      dir.path,
      'photo_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(f.path).copy(dest);
    return dest;
  }
}
