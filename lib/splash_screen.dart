import 'dart:async';

import 'package:flutter/material.dart';

import 'logo.dart';
import 'motion.dart';
import 'theme.dart';

// ======================================================
// ABERTURA DO APP
// Ao abrir, o logo aparece com um efeito (surge crescendo, um halo se
// expande e um brilho passa por cima) e, em seguida, a tela vira para o app
// (login ou página inicial). Respeita a aparência escolhida:
//   rich   = efeito completo (~2,4 s)
//   normal = surge e brilha (~1,8 s)
//   simple = só aparece (~1,0 s)
// Com "remover animações" ligado no Android, mostra o logo parado e segue.
// ======================================================

class SplashGate extends StatefulWidget {
  // O que abre depois da abertura (o porteiro de autenticação).
  final Widget child;

  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool finished = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionDuration(context, base: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: finished
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () {
                if (mounted) setState(() => finished = true);
              },
            ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this);
  Timer? timer;
  bool started = false;
  bool animated = true;

  late Animation<double> fade;
  late Animation<double> scale;
  late Animation<double> halo;
  late Animation<double> shine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;

    final level = context.motion;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Sem animação: logo parado por um instante e segue para o app.
    if (reduce) {
      animated = false;
      fade = const AlwaysStoppedAnimation<double>(1);
      scale = const AlwaysStoppedAnimation<double>(1);
      halo = const AlwaysStoppedAnimation<double>(1);
      shine = const AlwaysStoppedAnimation<double>(1);
      timer = Timer(const Duration(milliseconds: 700), widget.onFinished);
      return;
    }

    final total = switch (level) {
      MotionLevel.rich => 2400,
      MotionLevel.normal => 1800,
      MotionLevel.simple => 1000,
    };
    controller.duration = Duration(milliseconds: total);

    CurvedAnimation interval(double a, double b, Curve curve) =>
        CurvedAnimation(parent: controller, curve: Interval(a, b, curve: curve));

    fade = interval(0.0, 0.35, Curves.easeOut);
    scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      interval(
        0.0,
        0.5,
        level == MotionLevel.rich ? Curves.easeOutBack : Curves.easeOutCubic,
      ),
    );
    halo = level == MotionLevel.simple
        ? const AlwaysStoppedAnimation<double>(1)
        : interval(0.1, 0.75, Curves.easeOutCubic);
    shine = level == MotionLevel.simple
        ? const AlwaysStoppedAnimation<double>(1)
        : interval(0.5, 0.9, Curves.easeInOut);

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Pequena pausa com o logo completo antes de virar a tela.
        timer = Timer(const Duration(milliseconds: 150), widget.onFinished);
      }
    });
    controller.forward();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = context.colors.primary;

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final haloValue = halo.value;
            final shineValue = shine.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Halo: um círculo de luz que se expande e some devagar.
                if (animated)
                  IgnorePointer(
                    child: Container(
                      width: 120 + 280 * haloValue,
                      height: 120 + 280 * haloValue,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tint.withValues(alpha: 0.30 * (1 - haloValue * 0.7)),
                            tint.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Opacity(
                  opacity: fade.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        // Brilho: uma faixa clara atravessa o logo da esquerda
                        // para a direita (fora da tela quando está em 0 ou em 1).
                        child: ShaderMask(
                          blendMode: BlendMode.srcATop,
                          shaderCallback: (rect) {
                            final t = shineValue.clamp(0.0, 1.0);
                            return LinearGradient(
                              begin: Alignment(-3 + 4 * t, -0.3),
                              end: Alignment(-2 + 4 * t, 0.3),
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ).createShader(rect);
                          },
                          child: const TechNewsLogo(height: 76),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
