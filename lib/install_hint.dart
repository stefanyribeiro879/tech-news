import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'install_mode_stub.dart'
    if (dart.library.js_interop) 'install_mode_web.dart';
import 'theme.dart';

// ======================================================
// INSTALAR O APP (versão web)
// No iPhone o app é usado pelo site: o Safari permite "Adicionar à Tela de
// Início", que abre em tela cheia como um app. Este aviso ensina o passo a
// passo para quem abriu pelo navegador. No Android, indica o APK.
// ======================================================

const _androidDownloadUrl =
    'https://github.com/stefanyribeiro879/tech-news/releases/latest';

enum InstallTarget { iphone, android }

// null = não sugerir (app nativo, já instalado ou computador).
InstallTarget? get installSuggestion {
  if (!kIsWeb || isInstalledWebApp) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => InstallTarget.iphone,
    TargetPlatform.android => InstallTarget.android,
    _ => null,
  };
}

// Fechar o aviso vale até recarregar a página.
bool _bannerDismissed = false;

class InstallAppBanner extends StatefulWidget {
  const InstallAppBanner({super.key});

  @override
  State<InstallAppBanner> createState() => _InstallAppBannerState();
}

class _InstallAppBannerState extends State<InstallAppBanner> {
  @override
  Widget build(BuildContext context) {
    final target = installSuggestion;
    if (target == null || _bannerDismissed) return const SizedBox.shrink();

    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.install_mobile_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target == InstallTarget.iphone
                      ? 'Instale o Tech News no iPhone'
                      : 'Baixe o app para Android',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                TextButton(
                  onPressed: () => showInstallInstructions(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Ver como'),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => setState(() => _bannerDismissed = true),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

Future<void> showInstallInstructions(BuildContext context) {
  final target = installSuggestion ?? InstallTarget.iphone;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.install_mobile_rounded),
      title: Text(
        target == InstallTarget.iphone
            ? 'Instalar no iPhone'
            : 'Instalar no Android',
      ),
      content: target == InstallTarget.iphone
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step(
                  number: 1,
                  icon: Icons.ios_share_rounded,
                  text: 'No Safari, toque em Compartilhar (quadrado com a '
                      'seta para cima), na barra de baixo.',
                ),
                _Step(
                  number: 2,
                  icon: Icons.add_box_outlined,
                  text: 'Role a lista e toque em "Adicionar à Tela de Início".',
                ),
                _Step(
                  number: 3,
                  icon: Icons.check_circle_outline_rounded,
                  text: 'Toque em "Adicionar". O Tech News aparece na tela '
                      'de início e abre em tela cheia.',
                ),
                SizedBox(height: 4),
                Text(
                  'Precisa ser pelo Safari. As atualizações chegam sozinhas.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ],
            )
          : const Text(
              'Baixe o arquivo "tech-news.apk" da última versão e abra para '
              'instalar. Se o Android pedir, permita instalar desta fonte.',
            ),
      actions: [
        if (target == InstallTarget.android)
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(_androidDownloadUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Baixar o app'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  final int number;
  final IconData icon;
  final String text;

  const _Step({required this.number, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: colors.primary,
            child: Text(
              '$number',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
          const SizedBox(width: 8),
          Icon(icon, color: colors.primary),
        ],
      ),
    );
  }
}
