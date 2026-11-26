import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'logo.dart';
import 'motion.dart';
import 'theme.dart';

// ======================================================
// ABERTURA DO APP
// Tela desenhada em código (sem imagem), copiada da arte de referência:
// fundo azul-noite com brilhos azul e roxo, estrelinhas, a marca "NT" com
// "Tech News" ao lado e o texto "As notícias de tecnologia que importam para
// você." embaixo.
//
// As medidas vêm da arte de referência (900 x 1600) e são convertidas para
// a tela por [_Metrics].
//
// Animação de entrada (a duração segue a aparência escolhida):
//   1. o fundo surge, os brilhos respiram e as estrelas cintilam;
//   2. a marca "NT" surge crescendo, com um brilho azul atrás;
//   3. "Tech" e depois "News" deslizam da direita para o lugar;
//   4. o texto de baixo sobe suavemente.
// Depois de um instante parada, a tela vira para o app (login ou página
// inicial) sozinha; um toque em qualquer ponto também pula a abertura.
// Com "remover animações" ligado, a tela aparece pronta e parada.
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

  // Quando false, usa a fonte do tema em vez de baixar a fonte da marca
  // (os testes não acessam a internet).
  static bool useWebFonts = true;

  // Tempo que a tela fica parada depois da animação, antes de abrir o app.
  static const holdAfterAnimation = Duration(milliseconds: 900);

  // Cores tiradas da arte de referência.
  static const background = Color(0xFF050722);
  static const markColor = Color(0xFF3B2FFF);
  static const newsColor = Color(0xFF5C54FE);
  static const taglineColor = Color(0xFFC7CBF0);
  static const highlightFrom = Color(0xFF8A7CFF);
  static const highlightTo = Color(0xFF38BDF8);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Linha do tempo da entrada (0 a 1).
  late final entrance = AnimationController(vsync: this);
  // Respiração dos brilhos e cintilar das estrelas (repete sem parar).
  late final ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  bool started = false;
  bool leaving = false;
  Timer? holdTimer;

  late Animation<double> background;
  late Animation<double> mark;
  late Animation<double> markScale;
  late Animation<double> tech;
  late Animation<double> news;
  late Animation<double> tagline;
  bool twinkle = false;

  Animation<double> _step(double from, double to, Curve curve) =>
      CurvedAnimation(parent: entrance, curve: Interval(from, to, curve: curve));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;

    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    const still = AlwaysStoppedAnimation<double>(1);

    // Sem animação: tudo pronto e parado; só espera o tempo de abertura.
    if (reduce) {
      background = mark = markScale = tech = news = tagline = still;
      holdTimer = Timer(SplashScreen.holdAfterAnimation, _continue);
      return;
    }

    final level = context.motion;
    twinkle = level != MotionLevel.simple;

    entrance.duration = Duration(
      milliseconds: switch (level) {
        MotionLevel.rich => 2200,
        MotionLevel.normal => 1700,
        MotionLevel.simple => 900,
      },
    );

    if (level == MotionLevel.simple) {
      // Nível simples: tudo surge junto, só esmaecendo.
      background = _step(0, 0.6, Curves.easeOut);
      mark = tech = news = tagline = _step(0.1, 0.8, Curves.easeOut);
      markScale = still;
    } else {
      final pop =
          level == MotionLevel.rich ? Curves.easeOutBack : Curves.easeOutCubic;
      background = _step(0.0, 0.35, Curves.easeOut);
      mark = _step(0.08, 0.5, Curves.easeOut);
      markScale = Tween<double>(
        begin: 0.82,
        end: 1.0,
      ).animate(_step(0.08, 0.55, pop));
      tech = _step(0.28, 0.68, Curves.easeOutCubic);
      news = _step(0.38, 0.78, Curves.easeOutCubic);
      tagline = _step(0.58, 1.0, Curves.easeOutCubic);
    }

    entrance.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        holdTimer = Timer(SplashScreen.holdAfterAnimation, _continue);
      }
    });
    entrance.forward();
    if (twinkle) ambient.repeat();
  }

  @override
  void dispose() {
    holdTimer?.cancel();
    entrance.dispose();
    ambient.dispose();
    super.dispose();
  }

  // Vira para o app (uma vez só): sozinho no fim ou com um toque.
  void _continue() {
    if (leaving || !mounted) return;
    leaving = true;
    widget.onFinished();
  }

  TextStyle _wordmarkStyle(double size) {
    final base = TextStyle(
      fontSize: size,
      height: 1.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -size * 0.02,
    );
    if (!SplashScreen.useWebFonts) return base;
    return GoogleFonts.outfit(textStyle: base);
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return Scaffold(
      backgroundColor: SplashScreen.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: Semantics(
          button: true,
          label: 'Tech News. As notícias de tecnologia que importam para você.',
          child: LayoutBuilder(
            builder: (context, box) {
              final m = _Metrics(box.maxWidth, box.maxHeight);
              return AnimatedBuilder(
                animation: Listenable.merge([entrance, ambient]),
                builder: (context, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Fundo: brilhos e estrelas.
                    Positioned.fill(
                      child: Opacity(
                        opacity: background.value.clamp(0.0, 1.0),
                        child: CustomPaint(
                          painter: _SkyPainter(
                            m: m,
                            t: ambient.value,
                            twinkle: twinkle,
                            glowAt: mark.value.clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                    ),
                    // Marca + "Tech News".
                    Positioned(
                      left: m.logoLeft,
                      top: m.logoTop,
                      width: m.groupWidth,
                      height: m.markHeight,
                      child: _logoGroup(m),
                    ),
                    // Texto de baixo.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: m.taglineTop,
                      child: Opacity(
                        opacity: tagline.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - tagline.value) * 18 * m.u),
                          child: _tagline(bodyStyle, m),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _logoGroup(_Metrics m) {
    final techStyle = _wordmarkStyle(m.wordmarkFont).copyWith(color: Colors.white);
    final newsStyle =
        _wordmarkStyle(m.wordmarkFont).copyWith(color: SplashScreen.newsColor);

    Widget word(String text, TextStyle style, double width, Animation<double> a) {
      return Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset((1 - a.value) * 36 * m.u, 0),
          child: SizedBox(
            width: width,
            height: m.wordmarkFont,
            // Se a fonte sair mais larga que na arte, encolhe para caber.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(text, style: style, maxLines: 1, softWrap: false),
            ),
          ),
        ),
      );
    }

    final markWidget = LogoMark(
      height: m.markHeight,
      colors: const [SplashScreen.markColor],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Marca com brilho azul atrás.
        Positioned(
          left: 0,
          top: 0,
          child: Opacity(
            opacity: mark.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: markScale.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: 0.55,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 22 * m.u,
                        sigmaY: 22 * m.u,
                      ),
                      child: markWidget,
                    ),
                  ),
                  markWidget,
                ],
              ),
            ),
          ),
        ),
        // "Tech" (branco) e "News" (azul), um embaixo do outro.
        Positioned(
          left: m.textLeft,
          top: m.techTop,
          child: word('Tech', techStyle, m.techWidth, tech),
        ),
        Positioned(
          left: m.textLeft,
          top: m.newsTop,
          child: word('News', newsStyle, m.newsWidth, news),
        ),
      ],
    );
  }

  Widget _tagline(TextStyle base, _Metrics m) {
    final normal = base.copyWith(
      fontSize: m.taglineFont,
      height: m.taglineHeight,
      fontWeight: FontWeight.w400,
      color: SplashScreen.taglineColor,
    );
    final bold = normal.copyWith(fontWeight: FontWeight.w800);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('As notícias de tecnologia', style: normal),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('que ', style: normal),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [SplashScreen.highlightFrom, SplashScreen.highlightTo],
              ).createShader(bounds),
              child: Text(
                'importam para você',
                style: bold.copyWith(color: Colors.white),
              ),
            ),
            Text('.', style: normal),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------
// MEDIDAS (da arte de referência de 900 x 1600)
// ------------------------------------------------------

class _Metrics {
  final double width;
  final double height;

  // Unidade: 1 px da arte. Pela largura no celular; em telas largas
  // (computador) pela altura, para a composição não estourar.
  final double u;

  _Metrics(this.width, this.height) : u = math.min(width / 900, height / 1600);

  // Marca "NT": 182 x 195 na arte.
  double get markHeight => 195 * u;

  // Grupo marca + texto: de x = 170 até x = 641 na arte (o conjunto fica
  // um pouco à esquerda do centro, como na referência).
  double get groupWidth => (641 - 170) * u;
  double get logoLeft => width / 2 - (450 - 170) * u;
  // Centro vertical do conjunto: y = 676 de 1600.
  double get logoTop => height * (676 / 1600) - markHeight / 2;

  // Texto ao lado da marca (relativo ao grupo).
  double get textLeft => (387 - 170) * u;
  double get techWidth => (597 - 387) * u;
  double get newsWidth => (639 - 392) * u;
  double get wordmarkFont => 111 * u;
  // Topo de cada linha em relação ao topo da marca (y = 578); a letra
  // maiúscula começa cerca de 22 px abaixo do topo da caixa de texto.
  double get techTop => (593 - 578 - 22) * u;
  double get newsTop => (689 - 578 - 22) * u;

  // Texto de baixo: duas linhas centradas em y = 953 de 1600.
  double get taglineFont => 35 * u;
  double get taglineHeight => 50 / 35;
  double get taglineTop => height * (953 / 1600) - 50 * u;
}

// ------------------------------------------------------
// FUNDO: azul-noite com brilhos e estrelas
// ------------------------------------------------------

class _SkyPainter extends CustomPainter {
  final _Metrics m;
  final double t;
  final bool twinkle;
  // Força do brilho atrás da marca (acompanha a entrada da marca).
  final double glowAt;

  _SkyPainter({
    required this.m,
    required this.t,
    required this.twinkle,
    required this.glowAt,
  });

  // Estrelas: x e y em fração da tela, raio (px da arte) e brilho (0 a 1).
  static const _stars = <(double, double, double, double)>[
    (0.419, 0.005, 1.2, 0.6),
    (0.724, 0.031, 2.0, 1.0),
    (0.540, 0.049, 1.0, 0.3),
    (0.922, 0.075, 2.2, 1.0),
    (0.443, 0.095, 1.2, 0.3),
    (0.163, 0.100, 1.4, 0.4),
    (0.331, 0.205, 1.6, 0.7),
    (0.137, 0.218, 2.0, 0.9),
    (0.996, 0.238, 1.0, 0.6),
    (0.421, 0.251, 1.4, 0.6),
    (0.972, 0.264, 1.2, 0.6),
    (0.696, 0.284, 2.0, 0.9),
    (0.436, 0.312, 2.2, 0.9),
    (0.662, 0.316, 1.3, 0.4),
    (0.454, 0.323, 1.5, 0.9),
    (0.985, 0.325, 1.2, 0.4),
    (0.557, 0.334, 1.0, 0.3),
    (0.769, 0.650, 1.2, 0.5),
    (0.923, 0.668, 2.0, 0.7),
    (0.822, 0.728, 1.8, 1.0),
    (0.216, 0.739, 1.0, 0.8),
    (0.577, 0.772, 1.5, 0.6),
    (0.797, 0.778, 1.4, 0.5),
    (0.202, 0.780, 1.5, 0.4),
    (0.471, 0.811, 1.5, 0.7),
    (0.287, 0.828, 1.0, 0.5),
    (0.817, 0.914, 1.8, 0.5),
    (0.626, 0.916, 1.2, 0.7),
    (0.496, 0.948, 1.2, 0.4),
  ];

  void _glow(
    Canvas canvas,
    Size size, {
    required double cx,
    required double cy,
    required double radius,
    required Color color,
    double stretch = 1.0,
  }) {
    final center = Offset(size.width * cx, size.height * cy);
    final alpha = color.a;
    canvas.save();
    // Estica o círculo para virar uma elipse (brilhos mais "em pé").
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, stretch);
    canvas.translate(-center.dx, -center.dy);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          color,
          color.withValues(alpha: alpha * 0.45),
          color.withValues(alpha: 0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(
      Rect.fromCircle(center: center, radius: radius * 1.05),
      paint,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Base bem escura.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = SplashScreen.background,
    );

    // Respiração suave dos brilhos (0 a 1 e volta).
    final breathe = twinkle ? (0.5 - 0.5 * math.cos(t * 2 * math.pi)) : 0.5;
    final r = math.max(size.width, 0.62 * size.height);

    // Brilho azul forte no alto.
    _glow(
      canvas,
      size,
      cx: 0.40,
      cy: 0.13 + 0.01 * breathe,
      radius: r * 0.82,
      color: const Color(0xFF17139C).withValues(alpha: 0.95),
      stretch: 1.25,
    );
    // Brilho roxo à direita, na altura da logo.
    _glow(
      canvas,
      size,
      cx: 0.86,
      cy: 0.36 - 0.01 * breathe,
      radius: r * 0.5,
      color: const Color(0xFF2E1170).withValues(alpha: 0.95),
      stretch: 1.1,
    );
    // Brilho azul-marinho embaixo.
    _glow(
      canvas,
      size,
      cx: 0.52,
      cy: 0.86 + 0.01 * breathe,
      radius: r * 0.85,
      color: const Color(0xFF0F2878).withValues(alpha: 0.95),
      stretch: 1.1,
    );
    // Névoa azul atrás da marca.
    _glow(
      canvas,
      size,
      cx: 0.22,
      cy: 0.43,
      radius: r * 0.34,
      color: const Color(0xFF2A24D0).withValues(alpha: 0.38 * glowAt),
    );

    // Estrelas.
    final paint = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final (x, y, radius, strength) = _stars[i];
      var alpha = 0.25 + 0.6 * strength;
      if (twinkle) {
        final phase = t * 2 * math.pi * (1 + i % 3) + i * 1.7;
        alpha *= 0.55 + 0.45 * math.sin(phase);
      }
      paint.color = const Color(
        0xFFDCE4FF,
      ).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        radius * m.u,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.t != t ||
      old.glowAt != glowAt ||
      old.m.width != m.width ||
      old.m.height != m.height;
}
