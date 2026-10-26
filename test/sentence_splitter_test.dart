import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/core/sentence_splitter.dart';

void main() {
  List<String> split(String s) => SentenceSplitter.split(s);

  group('규칙 1: 줄 잇기', () {
    test('줄을 공백 하나로 잇고 중복 공백을 제거한다', () {
      expect(
        SentenceSplitter.join(['  나는 오늘도  ', '길을 걷는다.', '', '\t바람이 분다.']),
        '나는 오늘도 길을 걷는다. 바람이 분다.',
      );
    });

    test('fromLines는 이어 붙인 뒤 문장으로 나눈다', () {
      expect(
        SentenceSplitter.fromLines(['죽는 날까지 하늘을 우러러', '한 점 부끄럼이 없기를.', '잎새에 이는 바람에도']),
        ['죽는 날까지 하늘을 우러러 한 점 부끄럼이 없기를.', '잎새에 이는 바람에도'],
      );
    });

    test('빈 입력은 빈 목록', () {
      expect(split(''), isEmpty);
      expect(split('   \n  '), isEmpty);
      expect(SentenceSplitter.fromLines([]), isEmpty);
    });
  });

  group('규칙 2: 종결부호 분리', () {
    test('. ! ? … 로 나눈다', () {
      expect(split('첫 문장이다. 정말인가? 그렇다! 그런데… 끝이다.'), [
        '첫 문장이다.',
        '정말인가?',
        '그렇다!',
        '그런데…',
        '끝이다.',
      ]);
    });

    test('닫는 따옴표·괄호는 앞 문장에 포함한다', () {
      expect(split('그가 말했다. "가자." 그리고 웃었다. 끝이라고.”'), [
        '그가 말했다.',
        '"가자."',
        '그리고 웃었다.',
        '끝이라고.”',
      ]);
      // 인용 뒤에 조사가 바로 붙으면 나누지 않는다.
      expect(split('“나는 간다.”라고 했다. 정말이다.'), [
        '“나는 간다.”라고 했다.',
        '정말이다.',
      ]);
      expect(split('“사랑이란 무엇인가?” 그녀가 물었다.'), [
        '“사랑이란 무엇인가?”',
        '그녀가 물었다.',
      ]);
      expect(split('어서 오세요.) 다음 문장입니다.'), [
        '어서 오세요.)',
        '다음 문장입니다.',
      ]);
    });

    test('연속된 종결부호는 하나로 본다', () {
      expect(split('정말이야?! 그럴 리가... 믿을 수 없어!!'), [
        '정말이야?!',
        '그럴 리가...',
        '믿을 수 없어!!',
      ]);
    });

    test('공백 없이 이어진 한글 문장도 나눈다', () {
      expect(split('하늘이 맑다.바람이 분다.'), ['하늘이 맑다.', '바람이 분다.']);
    });
  });

  group('규칙 3: 나누지 않는 마침표', () {
    test('숫자 사이 마침표', () {
      expect(split('원주율은 3.14이다. 무리수다.'), ['원주율은 3.14이다.', '무리수다.']);
      expect(split('버전 1.2.3을 쓴다.'), ['버전 1.2.3을 쓴다.']);
    });

    test('영문 약어', () {
      expect(split('Mr. Kim met Dr. Lee yesterday. 그리고 헤어졌다.'), [
        'Mr. Kim met Dr. Lee yesterday.',
        '그리고 헤어졌다.',
      ]);
      expect(split('사과, 배 etc. 과일이 많다.'), ['사과, 배 etc. 과일이 많다.']);
      expect(split('예를 들어 e.g. 이런 것. 끝이다.'), ['예를 들어 e.g. 이런 것.', '끝이다.']);
    });

    test('이니셜과 주소', () {
      expect(split('J. K. Rowling wrote it. 놀랍다.'), [
        'J. K. Rowling wrote it.',
        '놀랍다.',
      ]);
      expect(split('www.example.com 에서 봤다. 좋았다.'), [
        'www.example.com 에서 봤다.',
        '좋았다.',
      ]);
    });
  });

  group('규칙 4: trim과 짧은 조각 병합', () {
    test('2글자 이하 조각은 앞 문장에 병합한다', () {
      expect(split('그는 고개를 끄덕였다. 응. 그리고 떠났다.'), [
        '그는 고개를 끄덕였다. 응.',
        '그리고 떠났다.',
      ]);
      expect(split('목차를 본다. 1. 서론을 읽는다.'), [
        '목차를 본다. 1.',
        '서론을 읽는다.',
      ]);
    });

    test('3글자 조각은 병합하지 않는다', () {
      expect(split('먼저 말한다. 그래. 끝이다.'), ['먼저 말한다.', '그래.', '끝이다.']);
    });

    test('첫 조각이 짧으면 다음 문장 앞에 붙인다', () {
      expect(split('아. 오늘은 비가 온다.'), ['아. 오늘은 비가 온다.']);
      expect(split('응.'), ['응.']);
    });

    test('각 문장은 trim된다', () {
      expect(split('   첫째 문장.    둘째 문장.   '), ['첫째 문장.', '둘째 문장.']);
    });
  });

  group('규칙 5: 종결부호 없는 마지막 조각', () {
    test('마지막 조각도 문장으로 포함한다', () {
      expect(split('첫 문장이다. 끝나지 않은 문장'), ['첫 문장이다.', '끝나지 않은 문장']);
      expect(split('종결부호가 전혀 없는 글'), ['종결부호가 전혀 없는 글']);
    });

    test('짧은 마지막 조각은 앞 문장에 병합된다', () {
      expect(split('긴 문장이 여기 있다. 끝'), ['긴 문장이 여기 있다. 끝']);
    });
  });
}
