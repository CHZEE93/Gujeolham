import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'image_store.dart';
import 'quotes_dao.dart';

/// 화면에서 입력받는 구절 필드.
class QuoteInput {
  const QuoteInput({
    required this.content,
    this.bookTitle,
    this.author,
    this.page,
    this.memo,
  });

  final String content;
  final String? bookTitle;
  final String? author;
  final int? page;
  final String? memo;
}

/// 로컬 DB가 기준. 변경이 끝나면 [onChanged]로 동기화를 요청한다.
class QuoteRepository {
  QuoteRepository(this._dao, this._images, {this.onChanged});

  final QuotesDao _dao;
  final ImageStore _images;
  final void Function()? onChanged;
  static const _uuid = Uuid();

  Future<String> create(QuoteInput input, {String? sourceImagePath}) async {
    final id = _uuid.v4();
    String? imagePath;
    if (sourceImagePath != null) {
      try {
        imagePath = await _images.save(sourceImagePath, id);
      } catch (_) {
        // 이미지 복사 실패는 구절 저장을 막지 않는다.
      }
    }
    final now = nowIso();
    await _dao.insertQuote(
      QuotesCompanion.insert(
        id: id,
        content: input.content,
        bookTitle: Value(_blankToNull(input.bookTitle)),
        author: Value(_blankToNull(input.author)),
        page: Value(input.page),
        memo: Value(_blankToNull(input.memo)),
        imagePath: Value(imagePath),
        createdAt: now,
        updatedAt: now,
      ),
    );
    onChanged?.call();
    return id;
  }

  Future<void> update(String id, QuoteInput input) async {
    await _dao.updateQuote(
      id,
      QuotesCompanion(
        content: Value(input.content),
        bookTitle: Value(_blankToNull(input.bookTitle)),
        author: Value(_blankToNull(input.author)),
        page: Value(input.page),
        memo: Value(_blankToNull(input.memo)),
      ),
    );
    onChanged?.call();
  }

  Future<void> setCherished(String id, bool cherished) async {
    await _dao.setCherished(id, cherished);
    onChanged?.call();
  }

  Future<void> delete(String id) async {
    await _dao.softDelete(id);
    onChanged?.call();
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
