import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

// ======================================================
// ABERTURA DO APP
// Arte em JPEG (estilo editorial) com o resumo do app, em duas versões:
//   assets/images/abertura_mobile.jpg  (tela em pé: celular)
//   assets/images/abertura_desktop.jpg (tela deitada: computador)
// As imagens são geradas a partir de design/abertura/abertura.html pelo
// script design/abertura/gerar.py, que roda sozinho antes de cada publicação.
// A arte surge com um efeito leve e, em seguida, aparece a dica "Toque para
// continuar" (no computador, "Clique"). A tela só vira para o app (login ou
// página inicial) quando o usuário toca. A duração do efeito segue a
// aparência escolhida; com "remover animações" ligado, a arte aparece parada.
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

  // Cor de fundo das artes (as bordas da imagem se esfumam nela).
  static const background = Color(0xFF0E0B1F);
  static const _hintColor = Color(0xFFA79FD1);

  static const mobileArt = 'assets/images/abertura_mobile.jpg';
  static const desktopArt = 'assets/images/abertura_desktop.jpg';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this);
  bool started = false;
  // A dica "Toque para continuar" aparece quando a arte termina de surgir.
  bool ready = false;
  bool leaving = false;

  late Animation<double> fade;
  late Animation<double> scale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;

    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Sem animação: arte parada, já esperando o toque.
    if (reduce) {
      fade = const AlwaysStoppedAnimation<double>(1);
      scale = const AlwaysStoppedAnimation<double>(1);
      ready = true;
      return;
    }

    final level = context.motion;
    controller.duration = Duration(
      milliseconds: switch (level) {
        MotionLevel.rich => 1400,
        MotionLevel.normal => 1000,
        MotionLevel.simple => 600,
      },
    );

    fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    scale = Tween<double>(
      begin: level == MotionLevel.simple ? 1.0 : 1.04,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => ready = true);
      }
    });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Toque em qualquer ponto da tela: vira para o app (uma vez só).
  void _continue() {
    if (leaving) return;
    leaving = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > size.height;
    final hint = wide ? 'Clique para continuar' : 'Toque para continuar';

    return Scaffold(
      backgroundColor: SplashScreen.background,
      body: Semantics(
        button: true,
        label: hint,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _continue,
          child: Stack(
            children: [
              // A arte inteira sempre visível (sem cortar texto); o que
              // sobrar da tela fica na cor de fundo da própria arte.
              Positioned.fill(
                child: FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: scale,
                    child: Image.asset(
                      wide ? SplashScreen.desktopArt : SplashScreen.mobileArt,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              // Dica no rodapé, surge quando a arte está completa.
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: SafeArea(
                  top: false,
                  child: AnimatedOpacity(
                    opacity: ready ? 1 : 0,
                    duration: motionDuration(context, base: 400),
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SplashScreen._hintColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
