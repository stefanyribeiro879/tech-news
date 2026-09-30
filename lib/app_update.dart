import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ======================================================
// ATUALIZAÇÃO DO APP (ANDROID)
// Cada pacote de atualização é publicado como Release no GitHub (ver
// .github/workflows/release-android.yml). O app compara a versão
// instalada com a última Release e, se houver uma mais nova, exige a
// atualização: baixa o APK e entrega ao instalador do Android.
// ======================================================

const String _latestReleaseUrl =
    'https://api.github.com/repos/stefanyribeiro879/tech-news/releases/latest';

// Segurança: o APK só é baixado deste endereço (Releases do repositório).
const String _trustedDownloadPrefix =
    'https://github.com/stefanyribeiro879/tech-news/releases/download/';

// Código nativo em MainActivity.kt (permissão "Instalar apps desconhecidos").
const _installer = MethodChannel('technews/installer');

class AppRelease {
  final String version;
  final String apkUrl;
  final String? sha256;

  const AppRelease({required this.version, required this.apkUrl, this.sha256});
}

bool get appUpdateSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<String> installedVersion() async =>
    (await PackageInfo.fromPlatform()).version;

// Retorna a Release mais nova que a instalada, ou null se já está em dia.
Future<AppRelease?> fetchNewerRelease() async {
  final response = await http
      .get(
        Uri.parse(_latestReleaseUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) return null;

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final version = (json['tag_name'] as String).replaceFirst('v', '');
  if (!isNewerVersion(version, await installedVersion())) return null;

  final apk = (json['assets'] as List)
      .cast<Map<String, dynamic>>()
      .where((asset) => (asset['name'] as String).endsWith('.apk'))
      .firstOrNull;
  if (apk == null) return null;

  final apkUrl = apk['browser_download_url'] as String;
  if (!apkUrl.startsWith(_trustedDownloadPrefix)) return null;

  // O GitHub informa o hash do arquivo ("sha256:..."); usamos para
  // conferir que o download chegou inteiro.
  final digest = apk['digest'] as String?;

  return AppRelease(
    version: version,
    apkUrl: apkUrl,
    sha256: digest != null && digest.startsWith('sha256:')
        ? digest.substring('sha256:'.length)
        : null,
  );
}

// Compara versões "1.2.3". Ignora o que vier depois de "+" ou "-".
bool isNewerVersion(String candidate, String current) {
  List<int> parts(String version) => version
      .split(RegExp(r'[+-]'))
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final a = parts(candidate);
  final b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

// Chamado ao abrir o app (silencioso) e pelo botão no Perfil (manual).
Future<void> checkForAppUpdate(BuildContext context, {bool manual = false}) async {
  if (!appUpdateSupported) return;

  AppRelease? release;
  try {
    release = await fetchNewerRelease();
  } catch (_) {
    release = null;
    if (manual && context.mounted) {
      _showSnack(context, 'Não foi possível verificar atualizações agora.');
      return;
    }
  }
  if (!context.mounted) return;

  if (release == null) {
    if (manual) _showSnack(context, 'Você já está na versão mais recente.');
    return;
  }

  // Atualização obrigatória: o diálogo não fecha até instalar.
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(release: release!),
  );
}

// O FilledButton do tema ocupa a largura toda; no diálogo, tamanho do texto.
Widget _primaryButton(String label, VoidCallback onPressed) => FilledButton(
  onPressed: onPressed,
  style: FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20),
  ),
  child: Text(label),
);

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _canInstall() async {
  try {
    return await _installer.invokeMethod<bool>('canInstall') ?? true;
  } catch (_) {
    return true; // sem o canal (versão antiga): tenta instalar mesmo assim
  }
}

// ======================================================
// DIÁLOGO DE ATUALIZAÇÃO
// Etapas: pedir → (permissão) → baixar → instalar → (erro com saídas).
// ======================================================

enum _Step { ask, permission, downloading, installing, error }

class _UpdateDialog extends StatefulWidget {
  final AppRelease release;

  const _UpdateDialog({required this.release});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with WidgetsBindingObserver {
  StreamSubscription<OtaEvent>? subscription;
  _Step step = _Step.ask;
  double? progress;
  String? error;

  // A janela de instalação do Android apareceu e a pessoa voltou ao app sem
  // concluir: mostramos as opções de tentar de novo.
  bool installerClosed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    super.dispose();
  }

  // Volta das Configurações ou do instalador do Android.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    if (step == _Step.permission) {
      start(); // confere a permissão de novo e segue sozinho se liberada
    } else if (step == _Step.installing) {
      setState(() => installerClosed = true);
    }
  }

  Future<void> start() async {
    if (!await _canInstall()) {
      if (mounted) setState(() => step = _Step.permission);
      return;
    }
    if (!mounted) return;

    setState(() {
      step = _Step.downloading;
      progress = null;
      error = null;
      installerClosed = false;
    });

    await subscription?.cancel();
    subscription = OtaUpdate()
        .execute(
          widget.release.apkUrl,
          destinationFilename: 'tech-news-${widget.release.version}.apk',
          sha256checksum: widget.release.sha256,
          // Instalação pelo PackageInstaller do Android: mostra a
          // confirmação e devolve o resultado (sucesso ou o erro real).
          usePackageInstaller: true,
        )
        .listen(onEvent);
  }

  void onEvent(OtaEvent event) {
    if (!mounted) return;
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final percent = double.tryParse(event.value ?? '');
        setState(() => progress = percent == null ? null : percent / 100);
      case OtaStatus.INSTALLING:
        if (step != _Step.installing) {
          setState(() {
            step = _Step.installing;
            installerClosed = false;
          });
        }
      case OtaStatus.INSTALLATION_DONE:
        // O Android substitui o app; normalmente ele é reaberto sozinho.
        break;
      case OtaStatus.ALREADY_RUNNING_ERROR:
        break;
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        setState(() => step = _Step.permission);
      case OtaStatus.CHECKSUM_ERROR:
        fail('O download veio incompleto. Tente de novo.');
      case OtaStatus.INSTALLATION_ERROR:
        fail(installErrorMessage(event.value));
      default:
        fail('Não foi possível baixar a atualização. Verifique sua internet.');
    }
  }

  String installErrorMessage(String? detail) {
    final text = (detail ?? '').toLowerCase();
    if (text.contains('abort') || text.contains('cancel')) {
      return 'A instalação foi cancelada. Toque em "Tentar de novo" e depois '
          'em "Atualizar" na janela do Android.';
    }
    if (text.contains('incompatible') || text.contains('signature')) {
      return 'Esta versão não pode substituir a instalada. Desinstale o app '
          'e instale pelo navegador.';
    }
    return 'O Android não concluiu a instalação.';
  }

  void fail(String message) {
    subscription?.cancel();
    setState(() {
      step = _Step.error;
      error = message;
    });
  }

  Future<void> downloadInBrowser() async {
    await launchUrl(
      Uri.parse(widget.release.apkUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = TextStyle(color: colors.onSurfaceVariant, height: 1.4);

    final Widget body = switch (step) {
      _Step.ask => Text(
        'Há uma nova versão do Tech News (v${widget.release.version}). '
        'Atualize para continuar usando o app.',
        style: const TextStyle(height: 1.4),
      ),
      _Step.permission => Text(
        'Para instalar, o Android precisa da sua permissão.\n\n'
        'Toque em "Permitir", ative "Permitir desta fonte" e volte para o app. '
        'A atualização continua sozinha.',
        style: const TextStyle(height: 1.4),
      ),
      _Step.downloading => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 10),
          Text(
            progress == null
                ? 'Preparando download...'
                : 'Baixando... ${(progress! * 100).round()}%',
          ),
        ],
      ),
      _Step.installing => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Text(
            installerClosed
                ? 'A instalação não foi concluída. Se a janela do Android não '
                      'apareceu, tente de novo.'
                : 'Instalando... Confirme em "Atualizar" na janela do Android.',
            style: const TextStyle(height: 1.4),
          ),
        ],
      ),
      _Step.error => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error ?? '',
            style: TextStyle(color: colors.error, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Em celulares Samsung, confira se o "Bloqueador automático" está '
            'desligado (Configurações > Segurança e privacidade). Se preferir, '
            'baixe pelo navegador e instale por cima.',
            style: muted,
          ),
        ],
      ),
    };

    final List<Widget> actions = switch (step) {
      _Step.ask => [
        _primaryButton('Atualizar agora', start),
      ],
      _Step.permission => [
        TextButton(onPressed: start, child: const Text('Já permiti')),
        _primaryButton(
          'Permitir',
          () => _installer.invokeMethod('openInstallSettings'),
        ),
      ],
      _Step.downloading => const [],
      _Step.installing => installerClosed
          ? [
              TextButton(
                onPressed: downloadInBrowser,
                child: const Text('Baixar pelo navegador'),
              ),
              _primaryButton('Tentar de novo', start),
            ]
          : const [],
      _Step.error => [
        TextButton(
          onPressed: downloadInBrowser,
          child: const Text('Baixar pelo navegador'),
        ),
        _primaryButton('Tentar de novo', start),
      ],
    };

    // PopScope: o botão "voltar" não fecha (atualização obrigatória).
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(Icons.system_update_rounded, color: colors.primary),
        title: const Text('Atualização disponível'),
        content: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: body,
        ),
        actionsOverflowButtonSpacing: 8,
        actions: actions,
      ),
    );
  }
}
