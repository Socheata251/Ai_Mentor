import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/brand_logo.dart';
import '../data/repositories/user_session.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/home/screens/home_screen.dart';

class OnboardData {
  final String bold, light, subtitle;
  const OnboardData(this.bold, this.light, this.subtitle);
}

const _pages = [
  OnboardData(
    'Learn IT',
    'Your Way',
    'Courses and roadmaps built around your pace and goals.',
  ),
  OnboardData(
    'Your Personal',
    'AI Tutor',
    'Get quick answers, smart summaries, and personalized study support.',
  ),
  OnboardData(
    'Track Your',
    'Progress',
    'Stay motivated with streaks, quizzes and clear milestones.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController(initialPage: 1);

  /// FAST: only the dots listen to this, so changing page no longer
  /// rebuilds the whole screen (it used to call setState on everything).
  final ValueNotifier<int> _index = ValueNotifier<int>(1);

  /// Pointer position in GLOBAL screen coordinates (null = no pointer).
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the logo before it is needed -> no pop-in on the first frame.
    precacheImage(AssetImage("assets/logo.png"), context);
  }

  /// FAST: ignore tiny moves so the glow is not rebuilt for every pixel.
  void _setPointer(Offset p) {
    final prev = _pointer.value;
    if (prev == null || (p - prev).distance > 3) _pointer.value = p;
  }

  void onStart() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UserSession.instance.isSignedIn
            ? DashboardScreen(userName: UserSession.instance.name)
            : const SignInScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _index.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onExit: (_) => _pointer.value = null,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (e) => _setPointer(e.position),
          onPointerDown: (e) => _setPointer(e.position),
          onPointerMove: (e) => _setPointer(e.position),
          onPointerUp: (e) {
            if (e.kind == PointerDeviceKind.touch) _pointer.value = null;
          },
          onPointerCancel: (_) => _pointer.value = null,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: _pages.length,
                          onPageChanged: (i) => _index.value = i,
                          itemBuilder: (_, i) =>
                              _OnboardPage(data: _pages[i], pointer: _pointer),
                        ),
                      ),
                      _Dots(count: _pages.length, current: _index),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _PressableButton(
                          label: 'Get Started',
                          onTap: onStart,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top: big logo with glow + light beam. Bottom: title + subtitle.
class _OnboardPage extends StatelessWidget {
  final OnboardData data;
  final ValueNotifier<Offset?> pointer;
  const _OnboardPage({required this.data, required this.pointer});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _FadeSlideIn(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => _LightLogo(
                areaWidth: box.maxWidth,
                areaHeight: box.maxHeight,
                pointer: pointer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${data.bold} ',
                        style: TextStyle(
                          color: c.textStrong,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: data.light,
                        style: TextStyle(
                          color: c.textSoft,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// FAST entrance animation: FadeTransition + a transform only touch the GPU
/// layer. The page content below is built once, not on every frame
/// (the old Opacity + TweenAnimationBuilder rebuilt it ~42 times).
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child});
  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final CurvedAnimation _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 30 * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}

class _LightLogo extends StatefulWidget {
  final double areaWidth, areaHeight;
  final ValueNotifier<Offset?> pointer;
  const _LightLogo({
    required this.areaWidth,
    required this.areaHeight,
    required this.pointer,
  });

  @override
  State<_LightLogo> createState() => _LightLogoState();
}

class _LightLogoState extends State<_LightLogo>
    with SingleTickerProviderStateMixin {
  static const _maxLean = 40.0;

  final _logoKey = GlobalKey();

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  // FAST: all "breathing" is done with compositor-only animations
  // (FadeTransition / SlideTransition). Nothing is repainted per frame.
  late final CurvedAnimation _eased = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOut,
  );
  late final Animation<double> _pulse = Tween<double>(
    begin: 0.7,
    end: 1.0,
  ).animate(_eased);
  late final Animation<Offset> _float = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -0.05), // fraction of the logo's own size
  ).animate(_eased);

  @override
  void dispose() {
    _eased.dispose();
    _c.dispose();
    super.dispose();
  }

  Offset _leanTowards(Offset pointer) {
    final box = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return Offset.zero;

    final center = box.localToGlobal(box.size.center(Offset.zero));
    final delta = pointer - center;
    final dist = delta.distance;
    if (dist == 0) return Offset.zero;
    return delta / dist * math.min(dist * 0.25, _maxLean);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = widget.areaWidth;
    final h = widget.areaHeight;

    // BIG logo: up to 260px, scales with the space available
    final size = (h * 0.45)
        .clamp(110.0, math.max(110.0, math.min(260.0, w * 0.7)))
        .toDouble();

    final logoTop = h * 0.08;
    final logoCenterY = logoTop + size / 2;
    final beamTop = logoTop + size * 0.72;
    final beamHeight = math.max(0.0, h - beamTop);
    final glowSize = size * 2.2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1) Light beam: blurred ONCE, then only faded.
        Positioned(
          top: beamTop,
          left: 0,
          right: 0,
          height: beamHeight,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _pulse,
                child: CustomPaint(
                  painter: _BeamPainter(
                    color: c.glowActive,
                    alpha: c.glowAlpha,
                    topWidth: size * 0.42,
                    bottomWidth: math.min(w, size * 1.8),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2) Round glow (follows the pointer). Only a Transform changes
        //    while the mouse moves; the gradient itself is cached.
        Positioned(
          top: logoCenterY - glowSize / 2,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ValueListenableBuilder<Offset?>(
              valueListenable: widget.pointer,
              builder: (context, pointer, _) {
                final active = pointer != null;
                final lean = active ? _leanTowards(pointer) : Offset.zero;
                return TweenAnimationBuilder<Offset>(
                  tween: Tween<Offset>(end: lean),
                  duration: const Duration(milliseconds: 150),
                  builder: (context, offset, _) => Transform.translate(
                    offset: offset,
                    child: RepaintBoundary(
                      child: FadeTransition(
                        opacity: _pulse,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _GlowDisc(
                              size: glowSize,
                              color: c.glowIdle,
                              alpha: c.glowAlpha,
                            ),
                            // brighter blue fades in on hover (no color lerp)
                            AnimatedOpacity(
                              opacity: active ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: _GlowDisc(
                                size: glowSize,
                                color: c.glowActive,
                                alpha: c.glowAlpha,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 3) The logo: built once, floats with SlideTransition.
        Positioned(
          top: logoTop,
          left: 0,
          right: 0,
          child: Center(
            child: RepaintBoundary(
              child: SlideTransition(
                position: _float,
                child: SizedBox(
                  key: _logoKey,
                  width: size,
                  height: size,
                  child: BrandLogo(size: size),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowDisc extends StatelessWidget {
  const _GlowDisc({
    required this.size,
    required this.color,
    required this.alpha,
  });
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Soft trapezoid of light that fades out toward the bottom.
/// Painted once (and cached by the RepaintBoundary above it).
class _BeamPainter extends CustomPainter {
  final Color color;
  final double alpha, topWidth, bottomWidth;

  const _BeamPainter({
    required this.color,
    required this.alpha,
    required this.topWidth,
    required this.bottomWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx - topWidth / 2, 0)
      ..lineTo(cx + topWidth / 2, 0)
      ..lineTo(cx + bottomWidth / 2, size.height)
      ..lineTo(cx - bottomWidth / 2, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: alpha * 1.2),
          color.withValues(alpha: alpha * 0.4),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      old.color != color ||
      old.alpha != alpha ||
      old.topWidth != topWidth ||
      old.bottomWidth != bottomWidth;
}

class _Dots extends StatelessWidget {
  final int count;
  final ValueListenable<int> current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<int>(
      valueListenable: current,
      builder: (context, index, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? c.dotActive : c.dotInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PressableButton({required this.label, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: context.colors.buttonGradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}