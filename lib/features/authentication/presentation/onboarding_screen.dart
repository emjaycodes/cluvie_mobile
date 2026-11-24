import 'dart:math' as math;

import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:cluvie_mobile/features/authentication/data/launch_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// First-run onboarding: value prop → genre picker → watch parties.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  final Set<String> _genres = {};

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await LaunchState.markOnboardingSeen();
    if (_genres.isNotEmpty) await LaunchState.saveFavoriteGenres(_genres);
    if (mounted) context.goNamed(RouteNames.welcome);
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    final motion = AppMotion.of(context);
    if (motion.reduced) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(duration: motion.standard, curve: AppMotion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    return Scaffold(
      body: AuthBackdrop(
        child: SafeArea(
          child: Column(children: [
            // Top bar: logo + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(children: [
                const ClLogo(size: 24),
                const Spacer(),
                AnimatedOpacity(
                  duration: AppMotion.of(context).quick,
                  opacity: isLast ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: isLast,
                    child: TextButton(onPressed: _finish, child: const Text('Skip')),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardingPage(
                    index: 0,
                    controller: _controller,
                    visual: const _PosterFan(),
                    line1: 'Movie night,',
                    line2: 'decided together.',
                    body: 'Suggest films, vote as a club and watch the winner together.',
                  ),
                  _OnboardingPage(
                    index: 1,
                    controller: _controller,
                    visual: _GenrePicker(
                      selected: _genres,
                      onToggle: (g) => setState(() => _genres.contains(g) ? _genres.remove(g) : _genres.add(g)),
                    ),
                    line1: 'What do you',
                    line2: 'love watching?',
                    body: 'Pick a few genres and we\'ll tune Discover for you. You can change this later.',
                  ),
                  _OnboardingPage(
                    index: 2,
                    controller: _controller,
                    visual: const _PartyPreview(),
                    line1: 'Watch parties,',
                    line2: 'anywhere.',
                    body: 'RSVP, count down together and keep the conversation going after the credits.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xl),
              child: Column(children: [
                _PageDots(count: _pageCount, current: _page),
                const SizedBox(height: AppSpacing.xl),
                ClButton(
                  label: isLast ? 'Get started' : (_page == 1 && _genres.isNotEmpty ? 'Continue (${_genres.length})' : 'Next'),
                  icon: isLast ? AppIcons.ticket : null,
                  onPressed: _next,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.index,
    required this.controller,
    required this.visual,
    required this.line1,
    required this.line2,
    required this.body,
  });

  final int index;
  final PageController controller;
  final Widget visual;
  final String line1;
  final String line2;
  final String body;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.of(context).reduced;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(children: [
        Expanded(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              if (reduced || !controller.hasClients || !controller.position.haveDimensions) return child!;
              // Parallax: the visual drifts slower than the page.
              final delta = (controller.page ?? index.toDouble()) - index;
              return Transform.translate(offset: Offset(delta * -60, 0), child: child);
            },
            child: Center(child: visual),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Align(alignment: Alignment.centerLeft, child: AuthHeading(line1: line1, line2: line2, body: body)),
      ]),
    );
  }
}

/// Animated pill indicator (active dot stretches).
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    return Semantics(
      label: 'Page ${current + 1} of $count',
      excludeSemantics: true,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: motion.quick,
            curve: AppMotion.emphasized,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? AppColors.purpleText : AppColors.borderStrong,
              borderRadius: AppRadius.pillAll,
            ),
          ),
      ]),
    );
  }
}

// ── Page visuals ─────────────────────────────────────────────────────────────

const _posters = [
  'https://image.tmdb.org/t/p/w342/kAellTx1ukNtc42BP1kcnHPCG5e.jpg', // Past Lives
  'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', // Oppenheimer
  'https://image.tmdb.org/t/p/w342/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', // Everything Everywhere
];

/// Three posters fanned out over a purple glow, with a vote chip on the winner.
class _PosterFan extends StatelessWidget {
  const _PosterFan();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Three film posters; the club\'s pick has 7 of 9 votes',
      excludeSemantics: true,
      child: _fan(),
    );
  }

  Widget _fan() {
    return LayoutBuilder(builder: (context, c) {
      final h = math.min(c.maxHeight * 0.86, 340.0);
      final w = h * 2 / 3;
      Widget poster(int i, double angle, double dx, double scale) => Transform.translate(
            offset: Offset(dx * w, 0),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: const BoxDecoration(borderRadius: AppRadius.lgAll, boxShadow: AppShadows.float),
                  child: ClPosterImage(url: _posters[i], width: w, height: h, radius: AppRadius.lg),
                ),
              ),
            ),
          );
      return SizedBox(
        width: c.maxWidth,
        height: h + 40,
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          Container(
            width: w * 2.2,
            height: w * 2.2,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow),
          ),
          poster(0, -0.14, -0.55, 0.82),
          poster(2, 0.14, 0.55, 0.82),
          poster(1, 0, 0, 1),
          Positioned(
            bottom: 0,
            child: ClGlass(
              blur: false,
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.pillAll,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(AppIcons.crown, size: 16, color: AppColors.purpleText),
                const SizedBox(width: 6),
                Text('7 of 9 votes', style: AppTextStyles.label.copyWith(fontSize: 13)),
              ]),
            ),
          ),
        ]),
      );
    });
  }
}

const _genreOptions = [
  'Drama', 'Comedy', 'Thriller', 'Sci-Fi', 'Horror', 'Romance', //
  'Animation', 'Documentary', 'Action', 'Indie', 'Crime', 'Fantasy',
];

class _GenrePicker extends StatelessWidget {
  const _GenrePicker({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < _genreOptions.length; i++)
            ClEntrance(
              index: i,
              child: ClChip(
                label: _genreOptions[i],
                isSelected: selected.contains(_genreOptions[i]),
                onTap: () => onToggle(_genreOptions[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ticket-stub watch-party card (Kiosk reference) as a product preview.
class _PartyPreview extends StatelessWidget {
  const _PartyPreview();

  @override
  Widget build(BuildContext context) {
    // Illustration only: not interactive, announced as one image.
    return Semantics(
      image: true,
      label: 'Example watch party card: Oppenheimer tonight at 8 PM, 9 people going',
      excludeSemantics: true,
      child: IgnorePointer(child: _card()),
    );
  }

  Widget _card() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Transform.scale(
            scale: 1.4,
            child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow)),
          ),
        ),
        ClCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                ClPosterImage(url: _posters[1], radius: 0, scrim: ClScrim.bottom),
                const Positioned(top: 12, left: 12, child: ClBadge('Tonight', tone: ClBadgeTone.purpleSolid)),
                Positioned(
                  left: 14,
                  bottom: 10,
                  right: 14,
                  child: Text('Oppenheimer', style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(children: [
                const Icon(AppIcons.clock, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('8:00 PM · Nolan Nerds', style: AppTextStyles.bodySm),
              ]),
            ),
            const _TicketDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(children: [
                const Expanded(
                  child: ClAvatarStack(
                    people: [
                      (name: 'Ada Obi', imageUrl: null),
                      (name: 'Tunde Bello', imageUrl: null),
                      (name: 'Mira Chen', imageUrl: null),
                    ],
                    total: 9,
                  ),
                ),
                ClButton(
                  label: 'RSVP',
                  variant: ClButtonVariant.inverse,
                  size: ClButtonSize.sm,
                  expand: false,
                  onPressed: _noop,
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Dashed divider with ticket notches.
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        Positioned.fill(child: CustomPaint(painter: _DashPainter())),
        const Positioned(left: -8, child: _Notch()),
        const Positioned(right: -8, child: _Notch()),
      ]),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) =>
      Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle));
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (double x = 14; x < size.width - 14; x += 9) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

// The preview card is wrapped in IgnorePointer; this only keeps the button
// in its enabled visual state.
void _noop() {}
