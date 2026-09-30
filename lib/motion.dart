import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

// ======================================================
// ANIMAÇÕES
// Tudo aqui respeita o MotionLevel da aparência escolhida:
// rich = completo, normal = suave, simple = quase nada.
// Também respeita "remover animações" do Android (acessibilidade).
// ======================================================

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Duration motionDuration(BuildContext context, {int base = 300}) {
  if (_reduceMotion(context)) return Duration.zero;
  return switch (context.motion) {
    MotionLevel.rich => Duration(milliseconds: (base * 1.4).round()),
    MotionLevel.normal => Duration(milliseconds: base),
    MotionLevel.simple => Duration(milliseconds: (base * 0.5).round()),
  };
}

// ------------------------------------------------------
// ENTRADA: o item surge deslizando e esmaecendo, em sequência (index).
// ------------------------------------------------------

class Appear extends StatefulWidget {
  final int index;
  final Widget child;

  const Appear({super.key, this.index = 0, required this.child});

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this);
  Animation<double> progress = const AlwaysStoppedAnimation(1);
  Animation<double> shaped = const AlwaysStoppedAnimation(1);
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;

    final level = context.motion;
    final duration = motionDuration(context, base: 380);
    if (duration == Duration.zero) return;

    // Itens seguintes entram um pouco depois (efeito cascata): o atraso fica
    // no começo da própria animação, sem temporizador.
    final step = switch (level) {
      MotionLevel.rich => 70,
      MotionLevel.normal => 45,
      MotionLevel.simple => 0,
    };
    final delay = step * widget.index.clamp(0, 8);
    final total = delay + duration.inMilliseconds;
    final start = delay / total;

    controller.duration = Duration(milliseconds: total);
    progress = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    shaped = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        1,
        curve: level == MotionLevel.rich
            ? Curves.easeOutBack
            : Curves.easeOutCubic,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = context.motion;
    final distance = switch (level) {
      MotionLevel.rich => 28.0,
      MotionLevel.normal => 14.0,
      MotionLevel.simple => 0.0,
    };

    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, child) {
        final t = shaped.value;
        return Opacity(
          opacity: progress.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * distance),
            child: level == MotionLevel.rich
                ? Transform.scale(scale: 0.96 + 0.04 * t, child: child)
                : child,
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------
// TOQUE: o cartão "afunda" levemente enquanto está pressionado.
// Usa Listener para não atrapalhar o InkWell de dentro.
// ------------------------------------------------------

class Pressable extends StatefulWidget {
  final Widget child;

  const Pressable({super.key, required this.child});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool pressed = false;

  void setPressed(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final depth = switch (context.motion) {
      MotionLevel.rich => 0.955,
      MotionLevel.normal => 0.98,
      MotionLevel.simple => 1.0,
    };

    return Listener(
      onPointerDown: (_) => setPressed(true),
      onPointerUp: (_) => setPressed(false),
      onPointerCancel: (_) => setPressed(false),
      child: AnimatedScale(
        scale: pressed ? depth : 1,
        duration: motionDuration(context, base: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ------------------------------------------------------
// FUNDO AMBIENTE: manchas de luz que se movem devagar atrás do conteúdo.
// Só nas aparências "vivas" (motion rich); nas outras, fundo liso.
// ------------------------------------------------------

class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = context.motion == MotionLevel.rich && !_reduceMotion(context);
    if (!active) {
      controller.stop();
      return widget.child;
    }
    if (!controller.isAnimating) controller.repeat();

    final accent = context.palette.accent;
    final strength = context.isDark ? 0.20 : 0.12;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AmbientPainter(
                controller,
                accent.map((c) => c.withValues(alpha: strength)).toList(),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;

  _AmbientPainter(this.animation, this.colors) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    final radius = size.shortestSide * 0.75;

    for (var i = 0; i < colors.length; i++) {
      final phase = t + i * 2.1;
      final center = Offset(
        size.width * (0.5 + 0.45 * math.cos(phase)),
        size.height * (0.25 + 0.2 * math.sin(phase * 0.8)),
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [colors[i], colors[i].withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.colors != colors;
}
