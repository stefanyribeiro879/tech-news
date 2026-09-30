// Regras de segurança do app. Rodar com: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_news/app_update.dart';
import 'package:tech_news/login_page.dart';
import 'package:tech_news/news_api.dart';

void main() {
  test('links: só http(s) são abertos', () {
    expect(safeWebUri('https://g1.globo.com/tecnologia'), isNotNull);
    expect(safeWebUri('http://exemplo.com'), isNotNull);
    expect(safeWebUri('javascript:alert(1)'), isNull);
    expect(safeWebUri('data:text/html,oi'), isNull);
    expect(safeWebUri('file:///etc/passwd'), isNull);
    expect(safeWebUri('https://'), isNull);
    expect(safeWebUri(null), isNull);
  });

  test('senha nova: 8+ caracteres com letras e números', () {
    expect(weakPasswordReason('123456'), isNotNull);
    expect(weakPasswordReason('12345678'), isNotNull); // sem letra
    expect(weakPasswordReason('abcdefgh'), isNotNull); // sem número
    expect(weakPasswordReason('abc12'), isNotNull); // curta
    expect(weakPasswordReason('techNews2026'), isNull);
  });

  test('atualização: compara versões', () {
    expect(isNewerVersion('1.1.1', '1.1.0'), isTrue);
    expect(isNewerVersion('1.2.0', '1.10.0'), isFalse);
    expect(isNewerVersion('1.1.0', '1.1.0'), isFalse);
  });
}
