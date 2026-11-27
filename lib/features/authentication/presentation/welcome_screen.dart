import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Apple / Google sign-in have no backend yet. They stay hidden until they
/// work (UX audit P0-4: no controls that do nothing).
const bool kSocialAuthEnabled = false;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        child: Stack(
          children: [
            const Positioned.fill(child: _PosterWall()),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimTop))),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder:
                    (context, c) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.xl),
                              const Align(alignment: Alignment.centerLeft, child: ClLogo(size: 32)),
                              const Spacer(),
                              // Text never sits on the poster wall: a fixed 56dp fade, then a
                              // solid 96% bg panel under all copy at any text size (round 3, B2).
                              const SizedBox(
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, AppColors.bgPanel],
                                    ),
                                  ),
                                ),
                              ),
                              ColoredBox(
                                key: const ValueKey('welcome-panel'),
                                color: AppColors.bgPanel,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const ClEntrance(
                                        child: AuthHeading(
                                          line1: 'Join the club.',
                                          line2: 'Pick the film together.',
                                          body:
                                              'Suggest what to watch, vote with friends and plan watch parties in one place.',
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxl),
                                      ClEntrance(
                                        index: 2,
                                        child: ClButton(
                                          label: 'Continue with email',
                                          icon: AppIcons.email,
                                          onPressed: () => context.pushNamed(RouteNames.signup),
                                        ),
                                      ),
                                      if (kSocialAuthEnabled) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        _SocialButton(
                                          label: 'Continue with Google',
                                          asset: 'assets/icons/google.svg',
                                          onPressed: () {},
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        _SocialButton(
                                          label: 'Continue with Apple',
                                          asset: 'assets/icons/apple.svg',
                                          onPressed: () {},
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.lg),
                                      ClEntrance(
                                        index: 3,
                                        child: AuthSwitchLink(
                                          prompt: 'Already have an account?',
                                          action: 'Log in',
                                          onTap: () => context.pushNamed(RouteNames.login),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _wallPosters = [
  'https://image.tmdb.org/t/p/w342/kAellTx1ukNtc42BP1kcnHPCG5e.jpg',
  'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
  'https://image.tmdb.org/t/p/w342/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
  'https://image.tmdb.org/t/p/w342/74xTEgt7R36Fpooo50r9T25onhq.jpg',
  'https://image.tmdb.org/t/p/w342/d5NXSklXo0qyIYkgV94XAgMIckC.jpg',
  'https://image.tmdb.org/t/p/w342/8QVDXDiOGHRcAD4oM6MXjE0osSj.jpg',
  'https://image.tmdb.org/t/p/w342/hUu9zyZmDd8VZegKi1iK1Vk0RYS.jpg',
  'https://image.tmdb.org/t/p/w342/r46leE6PSzLR3pnVzaxx5Q30yUF.jpg',
  'https://image.tmdb.org/t/p/w342/kCGlIMHnOm8JPXq3rXM84hre9Mh.jpg',
];

/// Tilted, dimmed poster wall in the top half that dissolves into the
/// background so the heading below stays on a flat, high-contrast surface.
class _PosterWall extends StatelessWidget {
  const _PosterWall();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width * 0.34;
    final h = w * 1.5;
    Widget column(int start, double dy) => Transform.translate(
      offset: Offset(0, dy),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.all(5),
              child: ClPosterImage(url: _wallPosters[(start + i) % _wallPosters.length], width: w, height: h),
            ),
        ],
      ),
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: ShaderMask(
          // Fade the wall out well above the heading (text sits on flat bg).
          shaderCallback:
              (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.textPrimary, AppColors.textPrimary, Colors.transparent],
                stops: [0, 0.32, 0.56],
              ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: Opacity(
            opacity: 0.55,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxWidth: size.width * 1.6,
              maxHeight: double.infinity,
              child: Transform.rotate(
                angle: -0.14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [column(0, -h * 0.35), column(3, 0), column(6, -h * 0.55), column(1, -h * 0.15)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.asset, required this.onPressed});

  final String label;
  final String asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(asset, width: 20, height: 20, excludeFromSemantics: true),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.button.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
