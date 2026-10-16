import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

/// One picture, whole on the page, with a close button; pinch to look
/// closer.
class PictureScreen extends StatelessWidget {
  const PictureScreen({
    required this.picture,
    required this.label,
    required this.onClose,
    super.key,
  });

  final ImageProvider picture;

  /// What the picture shows, for screen readers.
  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: InVogueColors.paper,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageMargin(child: BackBar.close(onClose: onClose)),
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image(
                  image: picture,
                  fit: BoxFit.contain,
                  semanticLabel: label,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
