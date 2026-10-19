import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';

/// An outfit the person owns: its photo, then its name. Opens [onTap] when
/// given.
class WardrobeOutfitTile extends StatelessWidget {
  const WardrobeOutfitTile({
    required this.outfit,
    this.onTap,
    this.imageFor = networkImage,
    super.key,
  });

  final WardrobeOutfit outfit;
  final VoidCallback? onTap;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// A photo from the web, cached on the phone.
  static ImageProvider networkImage(String url) =>
      CachedNetworkImageProvider(url);

  /// [outfit]'s photo: the phone's copy, else the account's.
  static ImageProvider photoOf(
    WardrobeOutfit outfit, {
    ImageProvider Function(String url) imageFor = networkImage,
  }) => switch (outfit.photoPath) {
    final path? => FileImage(File(path)),
    null => imageFor(outfit.photoUrl),
  };

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhotoSlot(
          image: photoOf(outfit, imageFor: imageFor),
          showLoading: outfit.photoPath == null,
        ),
        const SizedBox(height: InVogueSpace.s2),
        Text(outfit.details.name, style: InVogueType.item),
      ],
    );
    final tap = onTap;
    if (tap == null) {
      return Semantics(
        label: outfit.details.name,
        excludeSemantics: true,
        child: content,
      );
    }
    return Pressable(
      onTap: tap,
      semanticLabel: outfit.details.name,
      excludeSemantics: true,
      expandTapTarget: false,
      builder: (context, state) => content,
    );
  }
}
