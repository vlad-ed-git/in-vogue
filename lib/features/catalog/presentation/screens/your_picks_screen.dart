import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';

/// The person's loved outfits. Unloving one asks first.
class YourPicksScreen extends StatelessWidget {
  const YourPicksScreen({
    required this.onBack,
    this.imageFor = networkImage,
    super.key,
  });

  final VoidCallback onBack;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// A photo from the web, cached on the phone.
  static ImageProvider networkImage(String url) =>
      CachedNetworkImageProvider(url);

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocListener<YourPicksBloc, YourPicksState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous.failure != current.failure,
      listener: (context, state) => context.showSnack(
        message: state.failure!.uiFriendlyMessage(context),
        isError: true,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<YourPicksBloc, YourPicksState>(
            builder: (context, state) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PageMargin(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BackBar(onBack: onBack),
                        const SizedBox(height: InVogueSpace.s3),
                        ScreenTitle(l10n.yourPicks),
                        const SizedBox(height: InVogueSpace.s6),
                        if (state.status == YourPicksStatus.loading)
                          const RunningRule.content(),
                        if (state.status == YourPicksStatus.ready &&
                            state.picks.isEmpty)
                          Text(
                            l10n.noPicks,
                            style: InVogueType.body.copyWith(
                              color: InVogueColors.graphite,
                            ),
                          ),
                        if (state.status == YourPicksStatus.failed)
                          Notice(
                            icon: InVogueIcons.warning,
                            alert: true,
                            message: l10n.serverFailure,
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
                  sliver: SliverList.builder(
                    itemCount: (state.picks.length / 2).ceil(),
                    itemBuilder: (context, index) {
                      final row = state.picks.skip(index * 2).take(2).toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: InVogueSpace.s6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _tile(context, row.first)),
                            const SizedBox(width: InVogueLayout.gutter),
                            Expanded(
                              child: row.length > 1
                                  ? _tile(context, row.last)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: InVogueSpace.s10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, CatalogOutfit pick) => ProductTile(
    photo: imageFor(pick.imageUrl),
    name: pick.name,
    colours: [for (final piece in pick.pieces) Color(piece.hex)],
    loved: true,
    onLoveChanged: (loved) async {
      if (loved) return;
      final bloc = context.read<YourPicksBloc>();
      if (await confirmRemovePick(context, pick.name)) {
        bloc.add(YourPickRemoved(pick.id));
      }
    },
    onTap: null,
  );
}

/// Asks whether to remove [name] from the picks; true when the person
/// confirms.
Future<bool> confirmRemovePick(BuildContext context, String name) async {
  final remove = await showInVogueSheet<bool>(
    context: context,
    builder: (context) {
      final l10n = context.translated;
      return InVogueSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InVogueSheetHeader(title: l10n.removePickTitle, subtitle: name),
            InVogueButton.primary(
              label: l10n.remove,
              icon: InVogueIcons.trash,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: InVogueSpace.s3),
            InVogueButton.secondary(
              label: l10n.keep,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return remove ?? false;
}
