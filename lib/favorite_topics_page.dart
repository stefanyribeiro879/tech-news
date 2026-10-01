import 'package:flutter/material.dart';

import 'motion.dart';
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

  bool get allSelected => selected.length == topics.length;

  void toggle(String category) {
    setState(() {
      if (!selected.remove(category)) selected.add(category);
    });
  }

  void toggleAll() {
    setState(() {
      if (allSelected) {
        selected.clear();
      } else {
        selected.addAll(topics.map((topic) => topic.category));
      }
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
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                      children: [
                        Appear(
                          child: _Header(
                            isOnboarding: widget.isOnboarding,
                            firstName: widget.firstName,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Appear(
                          index: 1,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${selected.length} de ${topics.length} temas',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: saving ? null : toggleAll,
                                icon: Icon(
                                  allSelected
                                      ? Icons.remove_done_rounded
                                      : Icons.done_all_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  allSelected
                                      ? 'Desmarcar todos'
                                      : 'Marcar todos',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        _TopicGrid(
                          selected: selected,
                          onToggle: saving ? null : toggle,
                        ),

                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
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

// Selo com ícone (no degradê da aparência), saudação, título e explicação.
class _Header extends StatelessWidget {
  final bool isOnboarding;
  final String firstName;

  const _Header({required this.isOnboarding, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: context.accentGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isOnboarding ? Icons.waving_hand_rounded : Icons.tune_rounded,
            color: colors.onPrimary,
            size: 28,
          ),
        ),

        const SizedBox(height: 18),

        if (isOnboarding) ...[
          Text(
            firstName.isNotEmpty
                ? 'Que bom ter você aqui, $firstName!'
                : 'Que bom ter você aqui!',
            style: TextStyle(
              color: colors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
        ],

        Text(
          isOnboarding ? 'Quais temas você curte?' : 'Seus temas favoritos',
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
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
        ),
      ],
    );
  }
}

// Cartões em 2 colunas (1 em telas muito estreitas). Cada linha fica com a
// altura do cartão mais alto, para a grade ficar alinhada.
class _TopicGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String>? onToggle;

  const _TopicGrid({required this.selected, required this.onToggle});

  static const gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 300 ? 2 : 1;
        final rows = <Widget>[];

        for (var start = 0; start < topics.length; start += columns) {
          final rowTopics = topics.skip(start).take(columns).toList();
          final cells = <Widget>[];

          for (var i = 0; i < columns; i++) {
            if (i > 0) cells.add(const SizedBox(width: gap));
            if (i >= rowTopics.length) {
              cells.add(const Expanded(child: SizedBox()));
              continue;
            }
            final topic = rowTopics[i];
            cells.add(
              Expanded(
                child: Appear(
                  index: 2 + start + i,
                  child: _TopicCard(
                    topic: topic,
                    checked: selected.contains(topic.category),
                    onTap: onToggle == null
                        ? null
                        : () => onToggle!(topic.category),
                  ),
                ),
              ),
            );
          }

          if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final bool checked;
  final VoidCallback? onTap;

  const _TopicCard({
    required this.topic,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = motionDuration(context, base: 180);
    final accent = topic.foreground(context);

    return Semantics(
      checked: checked,
      child: Pressable(
        child: Material(
          color: checked
              ? topic.background(context)
              : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: duration,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: checked ? topic.tint(context) : colors.outlineVariant,
                  width: checked ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone do tema: fica "cheio" quando marcado.
                      AnimatedContainer(
                        duration: duration,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: checked ? accent : topic.background(context),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          topic.icon,
                          size: 26,
                          color: checked ? colors.surface : accent,
                        ),
                      ),
                      const Spacer(),
                      _CheckMark(checked: checked, color: accent),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    topic.category,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.35,
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

// Círculo de seleção: contorno vazio ou preenchido com o "check".
class _CheckMark extends StatelessWidget {
  final bool checked;
  final Color color;

  const _CheckMark({required this.checked, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: motionDuration(context, base: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? color : Colors.transparent,
        border: Border.all(
          color: checked ? color : colors.outlineVariant,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: checked ? 1 : 0,
        duration: motionDuration(context, base: 180),
        curve: Curves.easeOutBack,
        child: Icon(Icons.check_rounded, size: 16, color: colors.surface),
      ),
    );
  }
}
