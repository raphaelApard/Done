import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/logo_mark.dart';

/// Shows the logo being drawn on the app background, then fades to [child].
///
/// The ring is drawn first, then the check breaks out of it (600 ms in
/// total), and the finished mark rests for a moment. The splash is skipped
/// when the system asks to reduce animations.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  static const _ringMs = 360;
  static const _drawMs = 600;
  static const _totalMs = 900;
  static const fade = Duration(milliseconds: 250);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: SplashGate._totalMs),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() => _done = true);
    });

  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, SplashGate._ringMs / SplashGate._totalMs, curve: Curves.easeInOut),
  );
  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      SplashGate._ringMs / SplashGate._totalMs,
      SplashGate._drawMs / SplashGate._totalMs,
      curve: Curves.easeOut,
    ),
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSplash = !_done && !MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: SplashGate.fade,
      child: showSplash
          ? _Splash(key: const ValueKey('splash'), ring: _ring, check: _check)
          : KeyedSubtree(key: const ValueKey('app'), child: widget.child),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key, required this.ring, required this.check});

  final Animation<double> ring;
  final Animation<double> check;

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).shortestSide * .34, 160.0);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([ring, check]),
          builder: (context, _) => LogoMark.themed(
            context,
            size: size,
            ringProgress: ring.value,
            checkProgress: check.value,
          ),
        ),
      ),
    );
  }
}
