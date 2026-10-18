import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/feedback/notice.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/running_rule.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// What a [PhotoStage] shows.
enum PhotoStageState {
  /// The outfit photo.
  ready,

  /// The person's own photo, faded, with a waiting message.
  waiting,

  /// The person's own photo, faded, while the outfit is looked up: a
  /// [RunningRule] runs along the bottom, with no words.
  looking,

  /// The person's own photo, faded, with a retry notice below.
  failed,

  /// The person's own photo, faded, with nothing over it.
  idle,
}

/// A full-length photo, contained on paper.
///
/// While waiting, a [RunningRule] runs along the bottom of the message.
/// Going from [PhotoStageState.waiting] to ready reveals the outfit top to
/// bottom; a new outfit photo crossfades in with a small upward settle.
class PhotoStage extends StatefulWidget {
  const PhotoStage({
    required this.state,
    required this.height,
    this.outfit,
    this.photo,
    this.outfitLabel,
    this.progress,
    this.onRetry,
    super.key,
  }) : assert(
         state != PhotoStageState.ready || outfit != null,
         'a ready stage needs its outfit photo',
       );

  final PhotoStageState state;

  /// Stage height; see [heightFor].
  final double height;

  /// The outfit photo.
  final ImageProvider? outfit;

  /// The person's own photo, shown faded while waiting or after a failure.
  final ImageProvider? photo;

  /// Describes [outfit] for screen readers.
  final String? outfitLabel;

  /// A line under the waiting message, such as how far the try-on is.
  final String? progress;

  /// Retry action for [PhotoStageState.failed].
  final VoidCallback? onRetry;

  /// [available] height clamped between `stageMin` and [width] × 5 / 4.
  static double heightFor({required double available, required double width}) {
    final upper = width * 5 / 4;
    return available.clamp(math.min(InVogueLayout.stageMin, upper), upper);
  }

  @override
  State<PhotoStage> createState() => _PhotoStageState();
}

class _PhotoStageState extends State<PhotoStage> with TickerProviderStateMixin {
  // Preserve: the reduced-motion crossfades keep their full length.
  late final AnimationController _reveal;
  late final AnimationController _swap;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      value: 1,
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener(_onAnimationStatus);
    _swap = AnimationController(
      vsync: this,
      duration: InVogueMotion.base,
      value: 1,
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener(_onAnimationStatus);
  }

  bool _crossfade = false;
  ImageProvider? _previous;

  // Rebuilds when a reveal or swap ends, dropping the photo underneath.
  void _onAnimationStatus(AnimationStatus status) {
    if (status.isCompleted && mounted) setState(() => _previous = null);
  }

  @override
  void didUpdateWidget(PhotoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ready = widget.state == PhotoStageState.ready;
    if (ready && oldWidget.state == PhotoStageState.waiting) {
      _crossfade = context.reduceMotion;
      _reveal.duration = _crossfade ? InVogueMotion.base : InVogueMotion.reveal;
      _reveal.forward(from: 0);
    } else if (ready &&
        oldWidget.state == PhotoStageState.ready &&
        oldWidget.outfit != widget.outfit) {
      _previous = oldWidget.outfit;
      _swap.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _swap.dispose();
    super.dispose();
  }

  Widget _contained(ImageProvider image, {String? label}) => Image(
    image: image,
    fit: BoxFit.contain,
    gaplessPlayback: true,
    semanticLabel: label,
    excludeFromSemantics: label == null,
    errorBuilder: (context, error, stack) => const SizedBox.expand(),
  );

  Widget _faded() => widget.photo == null
      ? const SizedBox.expand()
      : Opacity(
          opacity: InVogueLayout.opacityWaiting,
          child: _contained(widget.photo!, label: context.translated.yourPhoto),
        );

  Widget _outfit() {
    final current = _contained(widget.outfit!, label: widget.outfitLabel);
    if (!_reveal.isCompleted) {
      return AnimatedBuilder(
        animation: _reveal,
        child: current,
        builder: (context, child) {
          if (_crossfade) {
            return Opacity(
              opacity: InVogueMotion.standard.transform(_reveal.value),
              child: child,
            );
          }
          return ClipRect(
            clipper: _CurtainClipper(
              InVogueMotion.curtain.transform(_reveal.value),
            ),
            child: child,
          );
        },
      );
    }
    if (_previous == null || _swap.isCompleted) return current;
    final previous = _contained(_previous!);
    return AnimatedBuilder(
      animation: _swap,
      builder: (context, _) {
        final t = InVogueMotion.standard.transform(_swap.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: 1 - t, child: previous),
            Transform.translate(
              offset: Offset(0, InVogueMotion.settleDistance * (1 - t)),
              child: Opacity(opacity: t, child: current),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.state == PhotoStageState.ready;
    final waiting = widget.state == PhotoStageState.waiting;
    final looking = widget.state == PhotoStageState.looking;
    final failed = widget.state == PhotoStageState.failed;
    final revealing = ready && !_reveal.isCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRect(
            child: ColoredBox(
              color: InVogueColors.paper,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!ready || revealing) _faded(),
                  if (ready) _outfit(),
                  if (waiting) _WaitingMessage(progress: widget.progress),
                  if (looking)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: RunningRule(),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (failed)
          Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s3),
            child: Notice.tryOnFailed(
              context: context,
              onRetry: widget.onRetry ?? () {},
            ),
          ),
      ],
    );
  }
}

class _WaitingMessage extends StatelessWidget {
  const _WaitingMessage({this.progress});

  final String? progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(InVogueSpace.s6),
    child: Center(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: InVogueColors.accent),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.translated.gettingOutfitReady,
                      textAlign: TextAlign.center,
                      style: InVogueType.bodyStrong.copyWith(
                        color: InVogueColors.onAccent,
                      ),
                    ),
                    if (progress != null)
                      Text(
                        progress!,
                        textAlign: TextAlign.center,
                        style: InVogueType.meta.copyWith(
                          color: InVogueColors.onAccent,
                          fontFeatures: InVogueType.tabularFigures,
                        ),
                      ),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: RunningRule(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Shows the top [fraction] of its child.
class _CurtainClipper extends CustomClipper<Rect> {
  const _CurtainClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_CurtainClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
