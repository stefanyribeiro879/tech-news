import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'logo.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA APARÊNCIA (Perfil > Aparência)
// Cada opção mostra uma prévia com as cores e a logo daquela aparência.
// Tocar aplica na hora; o MaterialApp anima a troca de cores.
// ======================================================

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) => ListView(
          padding: pagePadding(context, top: 4),
          children: [
            Text(
              'Escolha as cores e o quanto o app se movimenta.',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < AppLook.values.length; i++)
              Appear(
                index: i,
                child: _LookOption(
                  look: AppLook.values[i],
                  selected: appSettings.look == AppLook.values[i],
                  onTap: () => appSettings.setLook(AppLook.values[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LookOption extends StatelessWidget {
  final AppLook look;
  final bool selected;
  final VoidCallback onTap;

  const _LookOption({
    required this.look,
    required this.selected,
    required this.onTap,
  });

  String get motionLabel => switch (look.motion) {
    MotionLevel.rich => 'Animações completas',
    MotionLevel.normal => 'Animações suaves',
    MotionLevel.simple => 'Animações simples',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Pressable(
        child: Material(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: motionDuration(context, base: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  _LookPreview(look: look),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          look.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          look.description,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.animation_rounded,
                              size: 15,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                motionLabel,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: motionDuration(context, base: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('on'),
                            color: colors.primary,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            key: const ValueKey('off'),
                            color: colors.outlineVariant,
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

// Miniatura da aparência: fundo, logo, um "cartão" e a barra de destaque.
class _LookPreview extends StatelessWidget {
  final AppLook look;

  const _LookPreview({required this.look});

  @override
  Widget build(BuildContext context) {
    final p = look.palette;
    final accent = p.accent.length == 1 ? [p.accent.first, p.accent.first] : p.accent;

    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TechNewsLogo(height: 18, palette: p),
          const Spacer(),
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: p.chip,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.inkSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: accent),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
