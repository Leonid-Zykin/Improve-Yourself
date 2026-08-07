import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves photos under app documents (local-only, no cloud).
class PhotoStore {
  Future<Directory> _artifactsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'artifacts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies [sourcePath] to `artifacts/{id}.ext`. Returns absolute path.
  Future<String> savePhoto({
    required String id,
    required String sourcePath,
  }) async {
    final dir = await _artifactsDir();
    final ext = p.extension(sourcePath);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final dest = p.join(dir.path, '$id$safeExt');
    await File(sourcePath).copy(dest);
    return dest;
  }
}
