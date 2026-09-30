import 'package:flutter/material.dart';

import 'theme.dart';

// ======================================================
// LOGO (versão de teste: opção 1, marca "NT" + "Tech News")
// Desenhada em vetor a partir da arte original (caixa de 230 x 248), para
// ficar nítida em qualquer tamanho e trocar de cor em cada aparência.
// ======================================================

class TechNewsLogo extends StatelessWidget {
  final double height;
  final bool showText;

  // Sem paleta: usa a da aparência atual (ex.: prévias usam outra).
  final AppPalette? palette;

  const TechNewsLogo({
    super.key,
    this.height = 40,
    this.showText = true,
    this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette ?? context.palette;
    final mark = LogoMark(height: height, colors: p.logoMark);
    if (!showText) return mark;

    final fontSize = height * 0.58;
    final style = TextStyle(
      fontSize: fontSize,
      height: 0.86,
      fontWeight: FontWeight.w900,
      letterSpacing: -fontSize * 0.03,
    );

    return Semantics(
      label: 'Tech News',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: height * 0.14),
          ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tech', style: style.copyWith(color: p.logoTech)),
                _GradientText('News', style: style, colors: p.logoNews),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Color> colors;

  const _GradientText(this.text, {required this.style, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (colors.length == 1) {
      return Text(text, style: style.copyWith(color: colors.first));
    }
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(
        bounds,
      ),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

// Só a marca "NT".
class LogoMark extends StatelessWidget {
  final double height;
  final List<Color> colors;

  const LogoMark({super.key, required this.height, required this.colors});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * _LogoMarkPainter.width / _LogoMarkPainter.height, height),
      painter: _LogoMarkPainter(colors),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  final List<Color> colors;

  _LogoMarkPainter(this.colors);

  static const width = 230.0;
  static const height = 248.0;

  // Faixa diagonal do "N" + haste esquerda.
  static const _left = [
    Offset(0, 8),
    Offset(188, 196),
    Offset(188, 248),
    Offset(180, 248),
    Offset(42, 110),
    Offset(42, 248),
    Offset(0, 248),
  ];

  // Barra do "T" + haste que desce em diagonal até a barra da direita.
  static const _right = [
    Offset(18, 0),
    Offset(230, 0),
    Offset(230, 41),
    Offset(181, 41),
    Offset(181, 105),
    Offset(230, 154),
    Offset(230, 248),
    Offset(188, 248),
    Offset(188, 170),
    Offset(140, 122),
    Offset(140, 41),
    Offset(59, 41),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / width, size.height / height);

    final paint = Paint()..isAntiAlias = true;
    if (colors.length == 1) {
      paint.color = colors.first;
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    }

    for (final points in [_left, _right]) {
      canvas.drawPath(Path()..addPolygon(points, true), paint);
    }
  }

  @override
  bool shouldRepaint(_LogoMarkPainter old) => old.colors != colors;
}
