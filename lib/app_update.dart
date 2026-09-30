import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ======================================================
// ATUALIZAÇÃO DO APP (ANDROID)
// Cada versão nova é publicada como Release no GitHub (ver
// .github/workflows/release-android.yml). O app compara a versão
// instalada com a última Release e, se houver uma mais nova, baixa
// o APK e abre o instalador do Android.
// ======================================================

const String _latestReleaseUrl =
    'https://api.github.com/repos/stefanyribeiro879/tech-news/releases/latest';

class AppRelease {
  final String version;
  final String apkUrl;
  final String notes;
  final String? sha256;

  const AppRelease({
    required this.version,
    required this.apkUrl,
    required this.notes,
    this.sha256,
  });
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

  // O GitHub informa o hash do arquivo ("sha256:..."); usamos para
  // conferir que o download chegou inteiro.
  final digest = apk['digest'] as String?;

  return AppRelease(
    version: version,
    apkUrl: apk['browser_download_url'] as String,
    notes: (json['body'] as String?)?.trim() ?? '',
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

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(release: release!),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _UpdateDialog extends StatefulWidget {
  final AppRelease release;

  const _UpdateDialog({required this.release});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  StreamSubscription<OtaEvent>? subscription;
  bool downloading = false;
  double? progress;
  String? error;

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void startUpdate() {
    setState(() {
      downloading = true;
      progress = null;
      error = null;
    });

    subscription = OtaUpdate()
        .execute(
          widget.release.apkUrl,
          destinationFilename: 'tech-news-${widget.release.version}.apk',
          sha256checksum: widget.release.sha256,
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
      case OtaStatus.INSTALLATION_DONE:
        // O instalador do Android assume daqui.
        Navigator.of(context).pop();
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        fail('Permita que o Tech News instale apps e tente de novo.');
      case OtaStatus.CHECKSUM_ERROR:
        fail('O download veio corrompido. Tente de novo.');
      case OtaStatus.ALREADY_RUNNING_ERROR:
        break;
      default:
        fail('Não foi possível baixar a atualização. Tente de novo.');
    }
  }

  void fail(String message) {
    subscription?.cancel();
    setState(() {
      downloading = false;
      error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;

    return AlertDialog(
      title: Text('Nova versão ${release.version}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              release.notes.isNotEmpty
                  ? release.notes
                  : 'Uma nova versão do Tech News está disponível.',
            ),
            if (downloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                progress == null
                    ? 'Preparando download...'
                    : 'Baixando... ${(progress! * 100).round()}%',
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
        TextButton(
          onPressed: downloading ? null : startUpdate,
          child: const Text(
            'Atualizar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
