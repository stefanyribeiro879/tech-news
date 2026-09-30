import 'package:flutter/material.dart';

import 'supabase_service.dart';
import 'theme.dart';

// ======================================================
// TEMAS FAVORITOS
// Obrigatória no primeiro acesso (isOnboarding) e editável pelo Perfil.
// Salva em profiles.favorite_categories, separado para cada usuário, e
// chama onSaved com a lista escolhida.
// ======================================================

class FavoriteTopicsPage extends StatefulWidget {
  final List<String> initial;
  final bool isOnboarding;
  final String firstName;
  final ValueChanged<List<String>> onSaved;

  const FavoriteTopicsPage({
    super.key,
    required this.initial,
    required this.onSaved,
    this.isOnboarding = false,
    this.firstName = '',
  });

  @override
  State<FavoriteTopicsPage> createState() => _FavoriteTopicsPageState();
}

class _FavoriteTopicsPageState extends State<FavoriteTopicsPage> {
  late final Set<String> selected = {...widget.initial};
  bool saving = false;
  String? error;

  void toggle(String category) {
    setState(() {
      if (!selected.remove(category)) selected.add(category);
    });
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });

    // Mantém a mesma ordem da lista de temas.
    final chosen = topics
        .map((topic) => topic.category)
        .where(selected.contains)
        .toList();

    try {
      await SupabaseService.updateFavoriteCategories(chosen);
      if (mounted) widget.onSaved(chosen);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = 'Não foi possível salvar. Verifique sua internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopScope(
      // No primeiro acesso é preciso escolher antes de continuar.
      canPop: !widget.isOnboarding,
      child: Scaffold(
        appBar: widget.isOnboarding ? null : AppBar(),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                      children: [
                        if (widget.isOnboarding) ...[
                          const Text('👋', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 10),
                          Text(
                            widget.firstName.isNotEmpty
                                ? 'Que bom ter você aqui, ${widget.firstName}!'
                                : 'Que bom ter você aqui!',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        Text(
                          widget.isOnboarding
                              ? 'Quais temas você curte?'
                              : 'Seus temas favoritos',
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Eles aparecem em destaque na sua tela inicial. '
                          'Marque quantos quiser e mude quando quiser no Perfil.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        ...topics.map(
                          (topic) => _TopicOption(
                            topic: topic,
                            checked: selected.contains(topic.category),
                            onTap: saving ? null : () => toggle(topic.category),
                          ),
                        ),

                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                    child: FilledButton(
                      onPressed: (saving || selected.isEmpty) ? null : save,
                      child: saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: context.colors.onPrimary,
                              ),
                            )
                          : Text(
                              selected.isEmpty
                                  ? 'Escolha pelo menos 1 tema'
                                  : widget.isOnboarding
                                  ? 'Começar a ler (${selected.length})'
                                  : 'Salvar (${selected.length})',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicOption extends StatelessWidget {
  final Topic topic;
  final bool checked;
  final VoidCallback? onTap;

  const _TopicOption({
    required this.topic,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: checked ? topic.background(context) : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: checked ? topic.tint(context) : colors.outlineVariant,
                width: checked ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: topic.background(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(topic.icon, color: topic.foreground(context)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topic.description,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: checked,
                  onChanged: onTap == null ? null : (_) => onTap!(),
                  activeColor: topic.foreground(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
