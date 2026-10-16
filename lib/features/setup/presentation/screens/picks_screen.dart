import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:in_vogue/features/weather/presentation/widgets/day_weather_header.dart';

/// Setup step 3: tomorrow's weather, then pieces that suit it to love, so
/// outfits lean towards the person's taste. Zero picks is fine.
class PicksScreen extends StatelessWidget {
  const PicksScreen({
    required this.onBack,
    required this.onProceed,
    this.imageFor = networkImage,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onProceed;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// A photo from the web, cached on the phone.
  static ImageProvider networkImage(String url) =>
      CachedNetworkImageProvider(url);

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ForecastBloc, ForecastState>(
        listenWhen: (previous, current) =>
            current.status == ForecastStatus.ready &&
            previous.report != current.report,
        listener: (context, state) => context.read<PicksBloc>().add(
          PicksRequested(
            WarmthBand.forFeelsLike(state.report!.weather.feelsLike),
          ),
        ),
      ),
      BlocListener<PicksBloc, PicksState>(
        listenWhen: (previous, current) =>
            current.failure != null && previous.failure != current.failure,
        listener: (context, state) => context.showSnack(
          message: state.failure!.uiFriendlyMessage(context),
          isError: true,
        ),
      ),
    ],
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageMargin(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BackBar(
                      onBack: onBack,
                      step: SetupStep.picks.folio,
                      total: SetupStepFolio.total,
                    ),
                    BlocBuilder<ForecastBloc, ForecastState>(
                      builder: (context, state) => _weather(context, state),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<PicksBloc, PicksState>(
              builder: (context, state) => state.pieces.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : _pieces(context, state),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: InVogueSpace.s6)),
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<PicksBloc, PicksState>(
        buildWhen: (previous, current) =>
            previous.picks.length != current.picks.length,
        builder: (context, state) => PicksBar(
          count: state.picks.length,
          action: PicksBarAction.proceed,
          onPressed: onProceed,
        ),
      ),
    ),
  );

  Widget _weather(BuildContext context, ForecastState state) =>
      switch (state.status) {
        ForecastStatus.ready => DayWeatherHeader(
          report: state.report!,
          place: state.place,
        ),
        ForecastStatus.failed => Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s1),
          child: Notice(
            icon: InVogueIcons.warning,
            alert: true,
            message: context.translated.weatherUnavailable,
            action: InVogueButton.secondary(
              label: context.translated.retry,
              icon: InVogueIcons.retry,
              onRose: true,
              onPressed: () =>
                  context.read<ForecastBloc>().add(const ForecastRequested()),
            ),
          ),
        ),
        ForecastStatus.loading => const SizedBox.shrink(),
      };

  Widget _pieces(BuildContext context, PicksState state) {
    final rows = (state.pieces.length / 2).ceil();
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
      sliver: SliverList.builder(
        itemCount: rows + 1,
        itemBuilder: (context, index) {
          if (index == 0) return const _Prompt();
          final row = state.pieces.skip((index - 1) * 2).take(2).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: InVogueSpace.s6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tile(context, row.first, state.picks)),
                const SizedBox(width: InVogueLayout.gutter),
                Expanded(
                  child: row.length > 1
                      ? _tile(context, row.last, state.picks)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Piece piece, Set<String> picks) {
    final bloc = context.read<PicksBloc>();
    final loved = [
      for (final colourway in piece.colourways)
        if (picks.contains(colourway.id)) colourway,
    ];
    final shown = loved.isEmpty ? piece.colourways.first : loved.first;
    return ProductTile(
      photo: imageFor(shown.photoUrl),
      name: piece.name,
      colours: [for (final colourway in piece.colourways) Color(colourway.hex)],
      loved: loved.isNotEmpty,
      onLoveChanged: (love) {
        for (final colourway in love ? [shown] : loved) {
          bloc.add(PickToggled(colourway.id, loved: love));
        }
      },
      onTap: () => showColourSheet(
        context: context,
        pieceName: piece.name,
        colours: [
          for (final colourway in piece.colourways)
            PieceColour(
              name: colourway.name,
              color: Color(colourway.hex),
              wornPhoto: imageFor(colourway.photoUrl),
              flatPhoto: colourway.flatUrl == null
                  ? null
                  : imageFor(colourway.flatUrl!),
            ),
        ],
        lovedIndexes: {
          for (var i = 0; i < piece.colourways.length; i++)
            if (picks.contains(piece.colourways[i].id)) i,
        },
        onLoveChanged: (index, love) =>
            bloc.add(PickToggled(piece.colourways[index].id, loved: love)),
      ),
    );
  }
}

/// The heading and the one-line instruction, with its heart.
class _Prompt extends StatelessWidget {
  const _Prompt();

  @override
  Widget build(BuildContext context) {
    final translated = context.translated;
    const mark = '\u{FFFC}';
    final parts = translated.picksLine(mark).split(mark);
    return Padding(
      padding: const EdgeInsets.only(bottom: InVogueSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(translated.picksTitle),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: parts.first),
                if (parts.length > 1) ...[
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(InVogueIcons.heart, size: 16),
                  ),
                  TextSpan(text: parts.last),
                ],
              ],
            ),
            semanticsLabel: translated.picksLine(translated.heartSpoken),
            style: InVogueType.body.copyWith(color: InVogueColors.graphite),
          ),
        ],
      ),
    );
  }
}
