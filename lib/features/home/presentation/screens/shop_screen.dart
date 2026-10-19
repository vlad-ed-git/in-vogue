import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/home/presentation/bloc/shop_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// Every piece of the outfit, outer layer first, each with a link to that
/// exact piece and colour at the partner. Never a price.
class ShopScreen extends StatelessWidget {
  const ShopScreen({
    required this.onBack,
    this.openLink = openInBrowser,
    this.imageFor = networkImage,
    super.key,
  });

  final VoidCallback onBack;

  /// Opens a product page; false when it cannot.
  final Future<bool> Function(Uri link) openLink;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// Opens [link] in the browser or the partner's app.
  static Future<bool> openInBrowser(Uri link) =>
      launchUrl(link, mode: LaunchMode.externalApplication);

  /// A photo from the web, cached on the phone.
  static ImageProvider networkImage(String url) =>
      CachedNetworkImageProvider(url);

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: PageMargin(
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BackBar(onBack: onBack),
                  const SizedBox(height: InVogueSpace.s3),
                  ScreenTitle(l10n.shopThisOutfit),
                  const SizedBox(height: InVogueSpace.s4),
                  if (state.status == ShopStatus.loading)
                    const RunningRule.content(),
                  if (state.status == ShopStatus.failed)
                    Notice(
                      icon: InVogueIcons.warning,
                      alert: true,
                      message: l10n.serverFailure,
                    ),
                  for (final item in state.pieces)
                    ShopItem(
                      // The flat-lay shows exactly what is bought.
                      photo: imageFor(
                        item.colourway.flatUrl ?? item.colourway.photoUrl,
                      ),
                      name: item.piece.name,
                      colourName: item.colourway.name,
                      colour: Color(item.colourway.hex),
                      brand: state.brand,
                      material: item.colourway.material,
                      onBuy: () {
                        context.read<ShopBloc>().add(const ShopBought());
                        unawaited(
                          openLink(Uri.parse(item.colourway.productUrl)),
                        );
                      },
                    ),
                  const SizedBox(height: InVogueSpace.s10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
