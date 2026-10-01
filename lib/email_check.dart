import 'dart:convert';

import 'package:http/http.dart' as http;

// ======================================================
// VALIDAÇÃO DE E-MAIL NO CADASTRO
// Só vale para contas novas: o login e o "esqueci a senha" continuam com a
// conferência simples, então quem já tem conta não é afetado.
// 1. Formato (emailFormatError): rígido, sem consultar a internet.
// 2. Domínio (emailDomainError): pergunta ao DNS se o domínio recebe e-mail.
// O banco repete as regras de formato (supabase/email-validation.sql).
// ======================================================

// Partes permitidas pela RFC 5321, sem os casos exóticos (aspas, IP...).
final _localPartRe = RegExp(r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*$");
final _domainLabelRe = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$');
final _tldRe = RegExp(r'^[A-Za-z]{2,24}$');

// Serviços de e-mail temporário (a conta some em minutos).
const disposableEmailDomains = {
  '10minutemail.com', '10minutemail.net', '20minutemail.com', 'anonbox.net',
  'burnermail.io', 'byom.de', 'dispostable.com', 'dropmail.me', 'emailondeck.com',
  'fakeinbox.com', 'fakemail.net', 'getairmail.com', 'getnada.com',
  'guerrillamail.com', 'guerrillamail.net', 'guerrillamail.org',
  'guerrillamailblock.com', 'harakirimail.com', 'inboxkitten.com',
  'incognitomail.org', 'mail.tm', 'mailcatch.com', 'maildrop.cc',
  'mailinator.com', 'mailinator.net', 'mailnesia.com', 'mailpoof.com',
  'mintemail.com', 'moakt.com', 'mohmal.com', 'mytemp.email', 'nada.email',
  'sharklasers.com', 'spam4.me', 'spamgourmet.com', 'temp-mail.io',
  'temp-mail.org', 'tempail.com', 'tempmail.com', 'tempmail.dev',
  'tempmail.net', 'tempmailo.com', 'tempr.email', 'throwawaymail.com',
  'trashmail.com', 'trashmail.de', 'yopmail.com', 'yopmail.fr', 'yopmail.net',
};

// Erros de digitação comuns nos provedores mais usados no Brasil.
const _domainTypos = {
  'gmail.con': 'gmail.com', 'gmail.co': 'gmail.com', 'gmail.cm': 'gmail.com',
  'gmail.com.br': 'gmail.com', 'gmial.com': 'gmail.com', 'gmai.com': 'gmail.com',
  'gamil.com': 'gmail.com', 'gnail.com': 'gmail.com', 'gmaill.com': 'gmail.com',
  'hotmail.con': 'hotmail.com', 'hotmial.com': 'hotmail.com',
  'hotmal.com': 'hotmail.com', 'hotmai.com': 'hotmail.com',
  'hotamil.com': 'hotmail.com', 'outlok.com': 'outlook.com',
  'outlook.con': 'outlook.com', 'outloo.com': 'outlook.com',
  'yahoo.con': 'yahoo.com', 'yaho.com': 'yahoo.com',
  'yahoo.com.br.br': 'yahoo.com.br', 'icloud.con': 'icloud.com',
  'iclod.com': 'icloud.com', 'live.con': 'live.com', 'uol.com': 'uol.com.br',
  'bol.com': 'bol.com.br', 'terra.com': 'terra.com.br',
};

String _domainOf(String email) => email.substring(email.lastIndexOf('@') + 1).toLowerCase();

// null = formato válido. Não acessa a internet (usado no validator do campo).
String? emailFormatError(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Informe seu e-mail';
  if (email.length > 254 || email.contains(' ')) return 'Informe um e-mail válido';

  final at = email.lastIndexOf('@');
  if (at <= 0 || at != email.indexOf('@')) return 'Informe um e-mail válido';

  final local = email.substring(0, at);
  final domain = _domainOf(email);
  final labels = domain.split('.');

  if (local.length > 64 || !_localPartRe.hasMatch(local)) {
    return 'Informe um e-mail válido';
  }
  if (labels.length < 2 ||
      !labels.every(_domainLabelRe.hasMatch) ||
      !_tldRe.hasMatch(labels.last)) {
    return 'Informe um e-mail válido';
  }

  final fixed = _domainTypos[domain];
  if (fixed != null) return 'Você quis dizer $local@$fixed?';

  if (disposableEmailDomains.contains(domain)) {
    return 'E-mails temporários não são aceitos. Use seu e-mail pessoal.';
  }
  return null;
}

// Pergunta ao DNS público do Google se o domínio existe e recebe e-mail
// (registro MX). Só o domínio é enviado, nunca o endereço completo.
// Sem internet ou se o DNS falhar, não bloqueia (retorna null): o Supabase
// ainda confere o formato e o e-mail de confirmação prova que ele existe.
Future<String?> emailDomainError(
  String email, {
  http.Client? client,
}) async {
  final domain = _domainOf(email.trim());
  final httpClient = client ?? http.Client();

  Future<Map<String, dynamic>?> lookup(String type) async {
    final response = await httpClient
        .get(Uri.https('dns.google', '/resolve', {'name': domain, 'type': type}))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  final notFound = 'O domínio "@$domain" não recebe e-mails. '
      'Confira se digitou certo.';

  try {
    final mx = await lookup('MX');
    if (mx == null) return null;

    // 3 = NXDOMAIN: o domínio não existe.
    if (mx['Status'] == 3) return notFound;
    if (mx['Status'] != 0) return null;

    final records = ((mx['Answer'] as List?) ?? const [])
        .whereType<Map>()
        .where((answer) => answer['type'] == 15)
        .map((answer) => '${answer['data']}'.trim())
        .toList();

    // "0 ." = MX nulo (RFC 7505): o domínio declara que não recebe e-mail.
    if (records.isNotEmpty) {
      return records.every((data) => data == '0 .' || data == '0')
          ? notFound
          : null;
    }

    // Sem MX, o e-mail ainda pode ir para o endereço do próprio domínio (A).
    final a = await lookup('A');
    if (a == null || a['Status'] != 0) return null;
    final hasAddress = ((a['Answer'] as List?) ?? const []).isNotEmpty;
    return hasAddress ? null : notFound;
  } catch (_) {
    return null;
  } finally {
    if (client == null) httpClient.close();
  }
}
