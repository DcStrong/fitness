import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_motion.dart';

/// Auth screens (DS v2): a soft illustration fading into the canvas, the
/// brand line, the form in a card and an optional footer action.
class AuthScreenLayout extends StatefulWidget {
  const AuthScreenLayout({
    required this.heroTagline,
    required this.child,
    this.footer,
    super.key,
  });

  final String heroTagline;
  final Widget child;
  final Widget? footer;

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
        final heroHeight = (constraints.maxHeight * (keyboardOpen ? 0.16 : 0.3))
            .clamp(keyboardOpen ? 96.0 : 170.0, 300.0)
            .toDouble();

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: heroHeight, child: const _AuthHero()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _BrandLine(tagline: widget.heroTagline),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _panelFade,
                  child: SlideTransition(
                    position: _panelSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FyCard(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
                if (widget.footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: widget.footer,
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  static const _heroAsset = 'assets/images/brand/fy-auth-hero-soft.webp';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _heroAsset,
          fit: BoxFit.cover,
          alignment: const Alignment(-0.4, 0.2),
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        // Fade the illustration into the canvas so the form reads first.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.55, 1],
              colors: [Color(0x00F3F7F5), Color(0x33F3F7F5), AppColors.canvas],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandLine extends StatelessWidget {
  const _BrandLine({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
