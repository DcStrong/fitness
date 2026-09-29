import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_motion.dart';

class AuthScreenLayout extends StatefulWidget {
  const AuthScreenLayout({
    required this.heroTagline,
    required this.child,
    super.key,
  });

  final String heroTagline;
  final Widget child;

  @override
  State<AuthScreenLayout> createState() => _AuthScreenLayoutState();
}

class _AuthScreenLayoutState extends State<AuthScreenLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<double> _panelFade;
  late final Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: FyMotion.panel,
    );
    _panelFade = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOut,
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (fyReduceMotion(context)) {
        _panelController.value = 1;
      } else {
        _panelController.forward();
      }
    });
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final heroFraction = keyboardOpen ? 0.28 : 0.41;
        final heroHeight = (constraints.maxHeight * heroFraction)
            .clamp(keyboardOpen ? 140.0 : 210.0, 340.0)
            .toDouble();
        final panelMinHeight = constraints.maxHeight - heroHeight;

        final panel = ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: panelMinHeight > 0 ? panelMinHeight : 0,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: widget.child,
          ),
        );

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: _AuthHero(tagline: widget.heroTagline),
              ),
              FadeTransition(
                opacity: _panelFade,
                child: SlideTransition(position: _panelSlide, child: panel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.tagline});

  final String tagline;

  static const _heroAsset = 'assets/images/brand/fy-auth-hero.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.canvas),
        Positioned.fill(
          child: Image.asset(
            _heroAsset,
            fit: BoxFit.cover,
            alignment: const Alignment(0.15, -0.1),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66F7F5F0), Color(0xCCF7F5F0)],
              ),
            ),
          ),
        ),
        const Positioned(
          left: -44,
          bottom: -70,
          child: _HeroCircle(size: 190, color: AppColors.mintSoft),
        ),
        Positioned(
          right: -30,
          top: 38,
          child: _HeroCircle(
            size: 136,
            color: AppColors.secondary.withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          right: 52,
          bottom: 34,
          child: _HeroCircle(
            size: 58,
            color: AppColors.mint.withValues(alpha: 0.18),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 48,
          child: CustomPaint(painter: _HeroWavePainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: LayoutBuilder(
            builder: (context, constraints) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'Fitness '),
                            TextSpan(
                              text: 'Yoda',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  const _HeroWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, size.height * 0.45);
    for (var x = 0.0; x <= size.width; x += 1) {
      final y =
          size.height * 0.45 + math.sin(x / size.width * math.pi * 2) * 6 + 4;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
