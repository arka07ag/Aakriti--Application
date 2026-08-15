import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full splash screen shown on app start.
///
/// The petal mark is your exact source artwork
/// (`assets/images/aakriti_logo.png`) throughout — nothing is redrawn or
/// approximated, so it always matches the reference design pixel for
/// pixel.
///
/// Sequence:
///   1. The petal mark blooms open (scales up from center) at the
///      middle of the screen.
///   2. "AAKRITI" types itself on, letter by letter — and with every
///      letter typed, the mark eases further toward the left, making
///      room for the wordmark and tagline beside it.
///   3. The tagline ("Exclusive Fashion Boutique") fades in beneath the
///      wordmark, then everything holds for a beat.
///   4. Outro: the mark scales up dramatically and recenters, bursting
///      outward past the edges of the screen — a bloom-burst transition
///      in the spirit of the Netflix intro — before [onFinished] fires
///      so the caller can navigate on.
class AakritiSplashScreen extends StatelessWidget {
  const AakritiSplashScreen({
    super.key,
    this.onFinished,
    this.backgroundColor = const Color(0xFFFFFFFF),
  });

  final VoidCallback? onFinished;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox.expand(
        child: _AakritiSplashSequence(
          onFinished: onFinished,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

/// Orchestrates the bloom-in -> type-on/shift-left -> tagline -> hold ->
/// bloom-out sequence using a single master timeline, so every phase
/// stays perfectly in sync.
class _AakritiSplashSequence extends StatefulWidget {
  const _AakritiSplashSequence({
    this.onFinished,
    required this.backgroundColor,
  });

  final VoidCallback? onFinished;
  final Color backgroundColor;

  @override
  State<_AakritiSplashSequence> createState() =>
      _AakritiSplashSequenceState();
}

class _AakritiSplashSequenceState extends State<_AakritiSplashSequence>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------
  // Timeline (all in milliseconds). Tweak these to change pacing without
  // touching any of the layout logic below.
  // ---------------------------------------------------------------------
  static const int _beatMs = 150; // tiny beat before the bloom starts
  static const int _growMs = 1100; // mark blooms open at center
  static const int _typeMs = 1000; // "AAKRITI" types on + mark eases left
  static const int _taglineMs = 500; // tagline fades in under the wordmark
  static const int _holdMs = 500; // hold on the finished lockup
  static const int _outroMs = 1200; // mark bursts outward, Netflix-style

  static const int _beatEnd = _beatMs;
  static const int _growEnd = _beatEnd + _growMs;
  static const int _typeEnd = _growEnd + _typeMs;
  static const int _taglineEnd = _typeEnd + _taglineMs;
  static const int _holdEnd = _taglineEnd + _holdMs;
  static const int _totalMs = _holdEnd + _outroMs;

  static const String _wordmark = 'AAKRITI';
  static const String _tagline = 'Exclusive Fashion Boutique';

  late final AnimationController _controller;
  bool _finishedCalled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..addListener(_handleTick);
    _controller.forward();
  }

  void _handleTick() {
    if (!_finishedCalled && _controller.value >= 1.0) {
      _finishedCalled = true;
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTick);
    _controller.dispose();
    super.dispose();
  }

  /// Maps the master [0,1] progress onto a [0,1] progress for a phase
  /// that runs between [startMs] and [endMs] of the total timeline.
  double _phaseProgress(double masterValue, int startMs, int endMs) {
    final double ms = masterValue * _totalMs;
    return ((ms - startMs) / (endMs - startMs)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double centerY = height / 2;
        final double centerX = width / 2;
        final double leftX = width * 0.26;
        const double logoBox = 180;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = _controller.value;

            // --- Phase progresses ------------------------------------
            final double growProgress = _phaseProgress(t, _beatEnd, _growEnd);
            final double typeProgress = _phaseProgress(t, _growEnd, _typeEnd);
            final double taglineProgress = _phaseProgress(
              t,
              _typeEnd,
              _taglineEnd,
            );
            final double outroProgress = _phaseProgress(
              t,
              _holdEnd,
              _totalMs,
            );

            // --- Letter typing ------------------------------------------
            final int visibleLetters = (typeProgress * _wordmark.length)
                .ceil()
                .clamp(0, _wordmark.length);
            final bool typingActive = typeProgress > 0 && typeProgress < 1.0;
            final bool showCursor =
                typingActive && ((t * _totalMs) ~/ 260) % 2 == 0;

            // --- Logo scale ------------------------------------------
            // Pops in with a slight overshoot so the branches feel like
            // they're bursting outward, then during the outro it scales
            // up big and bursts past the edges of the screen.
            final double bloomIn = Curves.easeOutBack.transform(
              growProgress,
            );
            final double outroEase = Curves.easeInCubic.transform(
              outroProgress,
            );
            final double logoScale = growProgress < 1.0
                ? bloomIn.clamp(0.0, 3.0)
                : 1.0 + outroEase * 3.2;

            // --- Logo horizontal position ---------------------------------
            // Eases toward the left in lock-step with the typing, then
            // eases back toward center during the outro burst.
            final double shiftLeft = Curves.easeInOutCubic.transform(
              typeProgress,
            );
            final double recenter = Curves.easeInCubic.transform(
              outroProgress,
            );
            double logoCenterX = centerX + (leftX - centerX) * shiftLeft;
            logoCenterX = logoCenterX + (centerX - logoCenterX) * recenter;

            // --- Outro spin / fade ----------------------------------------
            final double outroRotation = outroEase * 0.35;
            final double overlayOpacity = ((outroProgress - 0.62) / 0.38)
                .clamp(0.0, 1.0);

            // --- Text opacity ----------------------------------------------
            final double textFadeOut = growProgress >= 1.0
                ? 1.0 - (outroProgress / 0.22).clamp(0.0, 1.0)
                : 1.0;
            final double wordmarkOpacity =
                (typeProgress > 0 ? 1.0 : 0.0) * textFadeOut;
            final double taglineOpacity = taglineProgress * textFadeOut;

            const double textGap = 20;
            final double textLeftX = logoCenterX + logoBox / 2 + textGap;

            return Stack(
              children: [
                // Petal mark — your exact source artwork.
                Positioned(
                  left: logoCenterX - logoBox / 2,
                  top: centerY - logoBox / 2,
                  width: logoBox,
                  height: logoBox,
                  child: Opacity(
                    opacity: growProgress > 0 ? 1.0 : 0.0,
                    child: Transform.rotate(
                      angle: outroRotation,
                      child: Transform.scale(
                        scale: logoScale,
                        child: Image.asset(
                          'assets/images/aakriti_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                // Wordmark + tagline
                Positioned(
                  left: textLeftX,
                  top: centerY - 34,
                  child: Opacity(
                    opacity: wordmarkOpacity,
                    child: _Wordmark(
                      text: _wordmark,
                      visibleLetters: visibleLetters,
                      showCursor: showCursor,
                    ),
                  ),
                ),
                Positioned(
                  left: textLeftX + 3,
                  top: centerY + 14,
                  child: Opacity(
                    opacity: taglineOpacity,
                    child: Transform.translate(
                      offset: Offset(0, (1 - taglineProgress) * 8),
                      child: Text(
                        _tagline,
                        style: GoogleFonts.greatVibes(
                          fontSize: 24,
                          color: const Color(0xFF3E8E8A),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                // Smooth crossfade to the next screen at the very end of
                // the outro burst.
                if (overlayOpacity > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: widget.backgroundColor.withValues(
                          alpha: overlayOpacity,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Renders the "AAKRITI" wordmark in a bold blackletter display face,
/// typing itself on letter by letter as [visibleLetters] increases.
class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.text,
    required this.visibleLetters,
    required this.showCursor,
  });

  final String text;
  final int visibleLetters;
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final String visible = text.substring(0, visibleLetters);

    final TextStyle style = GoogleFonts.pirataOne(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: const Color(0xFF1B1B1B),
      height: 1,
    );

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(visible, style: style),
          AnimatedOpacity(
            opacity: showCursor ? 1 : 0,
            duration: const Duration(milliseconds: 80),
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Container(
                width: 3,
                height: 30,
                color: const Color(0xFF3E8E8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
