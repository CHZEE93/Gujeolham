import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 촬영 원본을 앱 문서 디렉토리에 보관한다.
/// DB에는 문서 디렉토리 기준 상대 경로를 저장한다(iOS 컨테이너 경로가 바뀌어도 유지되도록).
class ImageStore {
  static const _dir = 'images';

  Future<Directory> _root() => getApplicationDocumentsDirectory();

  /// [sourcePath]를 복사하고 상대 경로를 돌려준다.
  Future<String> save(String sourcePath, String id) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, _dir));
    await dir.create(recursive: true);
    final ext = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath).toLowerCase();
    final relative = p.join(_dir, '$id$ext');
    await File(sourcePath).copy(p.join(root.path, relative));
    return relative;
  }

  /// 상대 경로를 실제 파일로. 파일이 없으면 null.
  Future<File?> resolve(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    final root = await _root();
    final file = File(p.join(root.path, relativePath));
    return await file.exists() ? file : null;
  }
}
