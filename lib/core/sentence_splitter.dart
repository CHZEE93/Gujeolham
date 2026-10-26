/// OCR 결과를 문장 단위로 나눈다.
///
/// 1. 줄을 순서대로 공백 하나로 이어 붙이고 중복 공백을 없앤다.
/// 2. `.` `!` `?` `…` 뒤에 이어지는 종결부호·닫는 따옴표/괄호까지 한 문장으로 본다.
/// 3. 숫자 사이의 `.`(3.14)과 영문 약어(Mr. Dr. etc.)에서는 나누지 않는다.
/// 4. 각 문장을 trim하고, 2글자 이하 조각은 앞 문장에 붙인다.
/// 5. 종결부호 없이 끝나는 마지막 조각도 한 문장으로 포함한다.
abstract final class SentenceSplitter {
  static const _terminators = {'.', '!', '?', '…'};
  static const _closers = {
    '"', "'", '”', '’', ')', ']', '}', '」', '』', '》', '〉', '）', '］',
  };
  static const _abbreviations = {
    'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr', 'st', 'mt', 'etc', 'vs',
    'e.g', 'i.e', 'cf', 'no', 'vol', 'p', 'pp', 'ed', 'eds', 'fig', 'inc',
    'ltd', 'co', 'corp', 'approx', 'dept', 'est', 'u.s', 'a.m', 'p.m',
    'jan', 'feb', 'mar', 'apr', 'jun', 'jul', 'aug', 'sep', 'sept', 'oct',
    'nov', 'dec',
  };
  static final _spaces = RegExp(r'\s+');
  static final _asciiAlnum = RegExp(r'[A-Za-z0-9]');
  static final _asciiLetterOrDot = RegExp(r'[A-Za-z.]');
  static final _upper = RegExp(r'^[A-Z]$');
  static final _digit = RegExp(r'[0-9]');

  /// OCR 줄 목록 → 문장 목록.
  static List<String> fromLines(Iterable<String> lines) => split(join(lines));

  /// 규칙 1: 공백 하나로 잇고 중복 공백 제거.
  static String join(Iterable<String> lines) =>
      lines.join(' ').replaceAll(_spaces, ' ').trim();

  static List<String> split(String input) {
    final s = input.replaceAll(_spaces, ' ').trim();
    if (s.isEmpty) return const [];

    final raw = <String>[];
    var start = 0;
    var i = 0;
    while (i < s.length) {
      if (_terminators.contains(s[i]) && !_isNonBreakingDot(s, i)) {
        var j = i + 1;
        while (j < s.length &&
            (_terminators.contains(s[j]) || _closers.contains(s[j]))) {
          j++;
        }
        // "간다."라고 / 『끝.』하고 처럼 인용 뒤에 조사가 바로 붙으면 이어지는 문장이다.
        if (j < s.length && s[j] != ' ' && _endsWithQuote(s, i + 1, j)) {
          i = j;
          continue;
        }
        raw.add(s.substring(start, j));
        start = j;
        i = j;
        continue;
      }
      i++;
    }
    if (start < s.length) raw.add(s.substring(start));

    return _mergeShort(
      raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );
  }

  /// 규칙 3: 숫자 사이, 영문 단어 내부, 약어 뒤의 `.`은 문장 끝이 아니다.
  static bool _isNonBreakingDot(String s, int i) {
    if (s[i] != '.') return false;
    final hasNext = i + 1 < s.length;
    final hasPrev = i > 0;

    if (hasPrev && hasNext && _digit.hasMatch(s[i - 1]) &&
        _digit.hasMatch(s[i + 1])) {
      return true;
    }
    // e.g / www.example.com 처럼 영문·숫자가 바로 붙는 경우
    if (hasPrev && hasNext && _asciiAlnum.hasMatch(s[i - 1]) &&
        _asciiAlnum.hasMatch(s[i + 1])) {
      return true;
    }

    var k = i - 1;
    while (k >= 0 && _asciiLetterOrDot.hasMatch(s[k])) {
      k--;
    }
    final word = s.substring(k + 1, i);
    if (word.isEmpty) return false;
    if (_upper.hasMatch(word)) return true; // 이니셜: J. K. Rowling
    return _abbreviations.contains(word.toLowerCase());
  }

  /// 규칙 4: 2글자 이하 조각은 앞 문장에 병합(첫 조각이면 다음 문장 앞에 붙임).
  static List<String> _mergeShort(List<String> parts) {
    final out = <String>[];
    String? carry;
    for (var part in parts) {
      if (carry != null) {
        part = '$carry $part';
        carry = null;
      }
      if (part.runes.length > 2) {
        out.add(part);
      } else if (out.isEmpty) {
        carry = part;
      } else {
        final glue = _isPunctuationOnly(part) ? '' : ' ';
        out[out.length - 1] = '${out.last}$glue$part';
      }
    }
    if (carry != null) out.add(carry);
    return out;
  }

  static const _quoteClosers = {'"', "'", '”', '’', '」', '』'};

  static bool _endsWithQuote(String s, int from, int to) =>
      to > from && _quoteClosers.contains(s[to - 1]);

  static bool _isPunctuationOnly(String s) => s.split('').every(
    (c) => _terminators.contains(c) || _closers.contains(c),
  );
}
