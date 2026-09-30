import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'appearance_page.dart';
import 'install_hint.dart';
import 'app_update.dart';
import 'supabase_service.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA PERFIL
// ======================================================

class ProfilePage extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditTopics;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.profile,
    required this.onEditTopics,
    required this.onLogout,
  });

  Future<void> confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Seus salvos e temas continuam guardados. É só entrar de novo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout();
  }

  // Exclusão definitiva: conta, perfil, temas e salvos (LGPD).
  Future<void> confirmDeleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: context.colors.error),
        title: const Text('Excluir sua conta?'),
        content: const Text(
          'Sua conta, seus temas e suas notícias salvas serão apagados para '
          'sempre. Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.error,
            ),
            child: const Text(
              'Excluir conta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await SupabaseService.deleteAccount();
      messenger.showSnackBar(
        const SnackBar(content: Text('Sua conta foi excluída.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir a conta. Tente de novo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) => ListView(
          padding: pagePadding(context, top: 16),
          children: [
            const Text(
              'Perfil',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 18),

            // Cartão do usuário
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: context.accentGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.onPrimary,
                    child: Text(
                      profile.initial,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isNotEmpty ? profile.name : 'Leitor(a)',
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email,
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            SectionHeader(
              title: 'Seus temas',
              actionLabel: 'Editar',
              onAction: onEditTopics,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.favoriteCategories
                  .map((category) => TopicPill(category: category))
                  .toList(),
            ),

            const SizedBox(height: 28),

            const SectionHeader(title: 'Preferências'),

            _SettingsCard(
              children: [
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppearancePage()),
                  ),
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text(
                    'Aparência',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(appSettings.look.label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  value: appSettings.rememberLogin,
                  onChanged: appSettings.setRememberLogin,
                  secondary: const Icon(Icons.verified_user_outlined),
                  title: const Text(
                    'Manter conectado',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Se desligar, pedimos login da próxima vez que abrir o app',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text(
                    'Sobre o Tech News',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: installedVersion(),
                    builder: (context, snapshot) => Text(
                      'Projeto A3 - Tech News · '
                      'v${snapshot.data ?? '...'}',
                    ),
                  ),
                ),
                if (installSuggestion != null) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    onTap: () => showInstallInstructions(context),
                    leading: const Icon(Icons.install_mobile_rounded),
                    title: const Text(
                      'Instalar o app',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Ícone na tela de início, em tela cheia'),
                  ),
                ],
                if (appUpdateSupported) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    onTap: () => checkForAppUpdate(context, manual: true),
                    leading: const Icon(Icons.system_update_rounded),
                    title: const Text(
                      'Procurar atualização',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  onTap: () => confirmDeleteAccount(context),
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                  title: const Text(
                    'Excluir minha conta',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Apaga seus dados de forma definitiva'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  onTap: () => confirmLogout(context),
                  leading: Icon(Icons.logout_rounded, color: colors.error),
                  title: Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
