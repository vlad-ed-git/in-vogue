import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/widgets/piece_grid.dart';
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
              builder: (context, state) => state.pieces.isNotEmpty
                  ? _pieces(context, state)
                  : SliverToBoxAdapter(
                      child:
                          state.status == PicksStatus.loading &&
                              context.select<ForecastBloc, bool>(
                                (bloc) =>
                                    bloc.state.status == ForecastStatus.ready,
                              )
                          ? const PageMargin(child: RunningRule.content())
                          : const SizedBox.shrink(),
                    ),
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
        ForecastStatus.loading => const RunningRule.content(),
      };

  Widget _pieces(BuildContext context, PicksState state) => SliverMainAxisGroup(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
        sliver: const SliverToBoxAdapter(child: _Prompt()),
      ),
      SliverPieceGrid(
        pieces: state.pieces,
        picks: state.picks,
        imageFor: imageFor,
      ),
    ],
  );
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
