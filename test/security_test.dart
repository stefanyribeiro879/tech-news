// Regras de segurança do app. Rodar com: flutter test

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_news/app_update.dart';
import 'package:tech_news/email_check.dart';
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

  test('cadastro: formato do e-mail', () {
    expect(emailFormatError('fulano@gmail.com'), isNull);
    expect(emailFormatError('  Nome.Sobrenome+news@empresa.com.br '), isNull);
    expect(emailFormatError(''), isNotNull);
    expect(emailFormatError('fulano'), isNotNull);
    expect(emailFormatError('fulano@gmail'), isNotNull); // sem .com
    expect(emailFormatError('fulano@@gmail.com'), isNotNull);
    expect(emailFormatError('ful ano@gmail.com'), isNotNull);
    expect(emailFormatError('.fulano@gmail.com'), isNotNull);
    expect(emailFormatError('ful..ano@gmail.com'), isNotNull);
    expect(emailFormatError('fulano@-gmail.com'), isNotNull);
    expect(emailFormatError('fulano@gmail.c'), isNotNull);
    expect(emailFormatError('fulano@gmail.123'), isNotNull);
  });

  test('cadastro: sugere correção e barra e-mail temporário', () {
    expect(emailFormatError('fulano@gmial.com'), contains('fulano@gmail.com'));
    expect(emailFormatError('fulano@hotmail.con'), contains('hotmail.com'));
    expect(emailFormatError('teste@mailinator.com'), contains('temporários'));
    expect(emailFormatError('teste@YOPMAIL.com'), contains('temporários'));
  });

  group('cadastro: domínio recebe e-mail (DNS)', () {
    MockClient dns(Map<String, Object> byType) => MockClient((request) async {
      final type = request.url.queryParameters['type']!;
      return http.Response(jsonEncode(byType[type] ?? {'Status': 0}), 200);
    });

    test('domínio com MX passa', () async {
      final client = dns({
        'MX': {
          'Status': 0,
          'Answer': [
            {'type': 15, 'data': '5 gmail-smtp-in.l.google.com.'},
          ],
        },
      });
      expect(await emailDomainError('a@gmail.com', client: client), isNull);
    });

    test('domínio inexistente é barrado', () async {
      final client = dns({'MX': {'Status': 3}});
      expect(await emailDomainError('a@naoexiste.com', client: client), isNotNull);
    });

    test('MX nulo (não recebe e-mail) é barrado', () async {
      final client = dns({
        'MX': {
          'Status': 0,
          'Answer': [
            {'type': 15, 'data': '0 .'},
          ],
        },
      });
      expect(await emailDomainError('a@example.com', client: client), isNotNull);
    });

    test('sem MX e sem endereço é barrado; com endereço passa', () async {
      final semNada = dns({'MX': {'Status': 0}, 'A': {'Status': 0}});
      expect(await emailDomainError('a@x.com', client: semNada), isNotNull);

      final comA = dns({
        'MX': {'Status': 0},
        'A': {
          'Status': 0,
          'Answer': [
            {'type': 1, 'data': '1.2.3.4'},
          ],
        },
      });
      expect(await emailDomainError('a@x.com', client: comA), isNull);
    });

    test('sem internet não bloqueia o cadastro', () async {
      final offline = MockClient((_) async => throw Exception('offline'));
      expect(await emailDomainError('a@gmail.com', client: offline), isNull);
    });
  });
}
