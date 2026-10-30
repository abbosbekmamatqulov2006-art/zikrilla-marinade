import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'api/backend.dart' show apiUrl;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data.dart';
import 'l10n.dart';

// ============================================================
// Brand tokens (from the Zikrilla Marinade brand book UI kit)
// ============================================================
class C {
  static const red = Color(0xFFD50C05);
  static const redCard = Color(0xFFDA2D28);
  static const redDark = Color(0xFFA81F1B);
  static const black = Color(0xFF202020);
  static const white = Colors.white;
  static const soft = Color(0xFFF4F3F1);
  static const border = Color(0xFFE6E4E0);
  static const text2 = Color(0xFF6E6E6E);
  static const text3 = Color(0xFFA3A3A3);
  static const green = Color(0xFF1F8A4C);
  static const greenSoft = Color(0xFFE3F2E8);
  static const amber = Color(0xFFC07A0B);
  static const amberSoft = Color(0xFFF8ECD9);
}

const double kSide = 20;

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.red, primary: C.red, surface: C.white),
    scaffoldBackgroundColor: C.white,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(bodyColor: C.black, displayColor: C.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white),
    ),
    datePickerTheme: const DatePickerThemeData(backgroundColor: C.white, surfaceTintColor: Colors.transparent),
    dialogTheme: const DialogThemeData(backgroundColor: C.white, surfaceTintColor: Colors.transparent),
    sliderTheme: const SliderThemeData(
      activeTrackColor: C.red,
      inactiveTrackColor: C.border,
      thumbColor: Colors.white,
      overlayColor: Color(0x22D50C05),
      trackHeight: 5,
    ),
  );
}

// ============================================================
// Text helpers
// ============================================================
TextStyle tsx(double size, {FontWeight w = FontWeight.w600, Color c = C.black, double? h, double ls = 0}) =>
    GoogleFonts.nunito(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

TextStyle get tTitle => tsx(28, w: FontWeight.w900, h: 1.1);
TextStyle get tBlock => tsx(18, w: FontWeight.w900, h: 1.2);
TextStyle get tBody => tsx(14, w: FontWeight.w600, h: 1.35);
TextStyle get tMuted => tsx(13.5, w: FontWeight.w500, c: C.text2, h: 1.35);
TextStyle get tPrice => tsx(18, w: FontWeight.w900).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// "16 000" style thousands separator.
String fmt(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${neg ? '−' : ''}$b';
}

String money(BuildContext context, int n) => '${fmt(n)} ${context.t('currency')}';

/// "12 pcs lamb skewer, coal 3 kg ×1".
String itemsText(BuildContext context, Map<String, int> items) => items.entries
    .map((e) {
      final p = productById(e.key);
      final name = p.name.of(context).toLowerCase();
      return p.isExtra ? '$name ×${e.value}' : '${e.value} ${context.t('pcs')} $name';
    })
    .join(', ');

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1600)));
}

// ============================================================
// Components
// ============================================================
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const SectionLabel(this.text, {super.key, this.color = C.text3});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: tsx(12, w: FontWeight.w800, c: color, ls: 1.6),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool inverted;
  final double height;
  final bool loading;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.outlined = false,
    this.inverted = false,
    this.height = 54,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = outlined || inverted ? C.white : C.red;
    final fg = outlined || inverted ? C.red : C.white;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: onTap == null ? C.border : bg,
        shape: StadiumBorder(side: outlined ? const BorderSide(color: C.red, width: 2) : BorderSide.none),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null || loading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: loading
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: fg))
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        style: tsx(14.5, w: FontWeight.w900, c: onTap == null ? C.text3 : fg, ls: 1.1),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;
  final bool disabled;
  const AppChip(this.label, {super.key, this.selected = false, this.onTap, this.dense = false, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? C.red : (disabled ? const Color(0xFFF9F8F7) : C.soft),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 16, vertical: dense ? 8 : 10),
          child: Text(
            label,
            style: tsx(14.5, w: FontWeight.w800, c: selected ? C.white : (disabled ? C.text3 : C.black)),
          ),
        ),
      ),
    );
  }
}

enum BadgeKind { red, green, amber, white, grey }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeKind kind;
  final bool upper;
  const StatusBadge(this.text, {super.key, this.kind = BadgeKind.red, this.upper = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      BadgeKind.red => (C.red, C.white),
      BadgeKind.green => (C.greenSoft, C.green),
      BadgeKind.amber => (C.amberSoft, C.amber),
      BadgeKind.white => (C.white, C.amber),
      BadgeKind.grey => (C.soft, C.text2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        upper ? text.toUpperCase() : text,
        style: tsx(11.5, w: FontWeight.w900, c: fg, ls: upper ? 0.8 : 0),
      ),
    );
  }
}

/// White card with the soft brand shadow, radius 22.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Border? border;
  final double radius;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = C.white,
    this.border,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: r,
        border: border,
        boxShadow: color == C.white
            ? const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SoftBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SoftBox({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(22)),
    child: child,
  );
}

class Photo extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final double radius;
  final BorderRadius? borderRadius;
  const Photo(this.asset, {super.key, this.width, this.height, this.radius = 14, this.borderRadius});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.circular(radius),
    child: smartImage(asset, width: width, height: height),
  );
}

/// "assets/..." -> ilova ichidan; "/uploads/..." yoki "http..." -> serverdan.
Widget smartImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('http') || path.startsWith('/')) {
    final url = path.startsWith('http') ? path : '$apiUrl$path';
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset('assets/img/logo.png', width: width, height: height, fit: BoxFit.contain),
    );
  }
  return Image.asset(path, width: width, height: height, fit: fit);
}

/// Screen title with optional subtitle and circular back button.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool back;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  const ScreenHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.back = false,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(kSide, 12, kSide, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (back) ...[const CircleBackButton(), const SizedBox(width: 14)],
              Expanded(
                child: Text(title, style: back ? tsx(24, w: FontWeight.w900) : tTitle),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: tsx(15, w: FontWeight.w500, c: C.text2),
            ),
          ],
        ],
      ),
    );
  }
}

class CircleBackButton extends StatelessWidget {
  final bool light;
  const CircleBackButton({super.key, this.light = false});
  @override
  Widget build(BuildContext context) =>
      CircleIconButton(icon: Icons.arrow_back_rounded, light: light, onTap: () => Navigator.of(context).maybePop());
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool light;
  final Color? iconColor;
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.light = false, this.iconColor});
  @override
  Widget build(BuildContext context) => Material(
    color: light ? Colors.white.withValues(alpha: 0.92) : C.white,
    shape: CircleBorder(side: light ? BorderSide.none : const BorderSide(color: C.black, width: 2)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 22, color: iconColor ?? C.black)),
    ),
  );
}

class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final Color bg;
  final double height;
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.bg = C.soft,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, Color c, VoidCallback? f) => InkResponse(
      onTap: f == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              f();
            },
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(i, size: 20, color: f == null ? C.border : c),
      ),
    );
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, C.text2, value > min ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: tsx(19, w: FontWeight.w700),
            ),
          ),
          btn(Icons.add_rounded, C.red, () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

class RoundAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  const RoundAddButton({super.key, required this.onTap, this.size = 36});
  @override
  Widget build(BuildContext context) => Material(
    color: C.red,
    shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
    clipBehavior: Clip.antiAlias,
    elevation: 2,
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.add_rounded, color: Colors.white, size: size * 0.6),
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool red;
  final bool ring;
  const Avatar(this.initials, {super.key, this.size = 48, this.red = false, this.ring = false});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: red ? C.red : (ring ? C.white : C.soft),
      border: ring ? Border.all(color: C.red, width: 2) : null,
    ),
    child: Text(
      initials,
      style: tsx(size * 0.34, w: FontWeight.w900, c: red ? C.white : (ring ? C.red : C.text2)),
    ),
  );
}

class ProgressLine extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;
  const ProgressLine(this.value, {super.key, this.color = C.red, this.track = C.border, this.height = 5});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: height, color: color, backgroundColor: track),
  );
}

/// Faint repeating "Z" brand pattern (Plus block / cashback card only).
class ZPattern extends StatelessWidget {
  final Color color;
  const ZPattern({super.key, this.color = const Color(0x1AD50C05)});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _ZPainter(color), size: Size.infinite),
  );
}

class _ZPainter extends CustomPainter {
  final Color color;
  _ZPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const w = 58.0, h = 50.0, t = 12.0;
    for (double y = -10; y < size.height + h; y += h + 6) {
      final offset = ((y / (h + 6)).round().isOdd) ? w / 2 : 0.0;
      for (double x = -w + offset; x < size.width + w; x += w + 4) {
        final path = Path()
          // top bar
          ..moveTo(x + 6, y)
          ..lineTo(x + w, y)
          ..lineTo(x + w - 4, y + t)
          // diagonal
          ..lineTo(x + t + 10, y + h - t)
          // bottom bar
          ..lineTo(x + w - 6, y + h - t)
          ..lineTo(x + w - 10, y + h)
          ..lineTo(x - 4, y + h)
          ..lineTo(x, y + h - t)
          ..lineTo(x + w - t - 14, y + t)
          ..lineTo(x + 2, y + t)
          ..close();
        canvas.save();
        canvas.translate(x + w / 2, y + h / 2);
        canvas.skew(-0.18, 0);
        canvas.translate(-(x + w / 2), -(y + h / 2));
        canvas.drawPath(path, p);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ZPainter old) => old.color != color;
}

/// Decorative pseudo-QR code for the loyalty card.
class FakeQr extends StatelessWidget {
  final double size;
  const FakeQr({super.key, this.size = 84});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _QrPainter());
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final cell = size.width / n;
    final black = Paint()..color = C.black;
    final white = Paint()..color = Colors.white;
    final rnd = math.Random(4700);
    bool finder(int x, int y) => (x < 8 && y < 8) || (x > n - 9 && y < 8) || (x < 8 && y > n - 9);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (!finder(x, y) && rnd.nextDouble() < 0.48) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.3, cell + 0.3), black);
        }
      }
    }
    for (final o in [const Offset(0, 0), Offset((n - 7) * cell, 0), Offset(0, (n - 7) * cell)]) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 7 * cell, 7 * cell), black);
      canvas.drawRect(Rect.fromLTWH(o.dx + cell, o.dy + cell, 5 * cell, 5 * cell), white);
      canvas.drawRect(Rect.fromLTWH(o.dx + 2 * cell, o.dy + 2 * cell, 3 * cell, 3 * cell), black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom action area with a top hairline, used by detail screens.
class BottomBar extends StatelessWidget {
  final Widget child;
  const BottomBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: C.white,
      border: Border(top: BorderSide(color: C.border)),
    ),
    padding: EdgeInsets.fromLTRB(kSide, 12, kSide, 12 + MediaQuery.of(context).padding.bottom),
    child: child,
  );
}

class SegmentedSwitch extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const SegmentedSwitch({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(999)),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: tsx(14.5, w: FontWeight.w900, c: i == index ? C.white : C.text2, ls: 1.1),
                            child: Text(labels[i].toUpperCase()),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final double height;
  const Logo({super.key, this.height = 34});
  @override
  Widget build(BuildContext context) => Image.asset('assets/img/logo.png', height: height);
}

/// Soft filled text field decoration used across forms.
InputDecoration fieldDecoration(String hint, {String? error, Widget? prefix, Widget? suffix}) => InputDecoration(
  hintText: hint,
  hintStyle: tsx(15, w: FontWeight.w500, c: C.text3),
  errorText: error,
  errorStyle: tsx(12.5, w: FontWeight.w700, c: C.red),
  filled: true,
  fillColor: C.soft,
  isDense: true,
  prefixIcon: prefix,
  suffixIcon: suffix,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: C.red, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: C.red, width: 1.5),
  ),
);
