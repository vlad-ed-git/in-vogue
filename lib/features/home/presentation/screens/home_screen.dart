import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';

/// The Home tab: the day's weather and the person in the day's outfit,
/// with Shop, all in the first view; the photo shrinks to fit, down to the
/// stage's minimum. Swiping or the day switch moves between today and
/// tomorrow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onYourPicks,
    required this.onShop,
    super.key,
  });

  final VoidCallback onYourPicks;

  /// Opens the pieces of the outfit on screen.
  final ValueChanged<DayOutfit> onShop;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  /// Heights of what shares the first view with the photo, once laid out.
  double? _headerHeight;
  double? _shopHeight;

  /// A fling faster than this, in logical pixels a second, switches days.
  static const _swipeSpeed = 300.0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<HomeBloc>().add(const HomeStarted()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  HomeBloc get _bloc => context.read<HomeBloc>();

  void _swipe(DragEndDetails details) {
    final speed = details.primaryVelocity ?? 0;
    if (speed.abs() < _swipeSpeed) return;
    _bloc.add(
      HomeDaySelected(speed < 0 ? ForecastDay.tomorrow : ForecastDay.today),
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeBloc, HomeState>(
    builder: (context, state) => SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, viewport) => GestureDetector(
          onHorizontalDragEnd: _swipe,
          child: SingleChildScrollView(
            child: PageMargin(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizeReporter(
                    onSize: (size) =>
                        setState(() => _headerHeight = size.height),
                    child: _header(context, state),
                  ),
                  ..._stage(context, state, viewport),
                  ..._about(context, state.shown.outfit),
                  const SizedBox(height: InVogueSpace.s10),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context, HomeState state) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    final day = state.shown;
    final report = day.report;
    final date =
        report?.weather.date ?? state.selected.dateFrom(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopBar(city: state.place?.city ?? '', onYourPicks: widget.onYourPicks),
        DaySwitch(
          labels: [l10n.today, l10n.tomorrow],
          selectedIndex: state.selected.index,
          onSelected: (index) =>
              _bloc.add(HomeDaySelected(ForecastDay.values[index])),
          date: InVogueFormat.shortDate(date, language),
        ),
        if (report != null)
          ..._weather(context, state, report)
        else if (day.weatherFailed || state.status == HomeStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s4),
            child: Notice(
              icon: InVogueIcons.warning,
              alert: true,
              message: l10n.weatherUnavailable,
              action: InVogueButton.secondary(
                label: l10n.retry,
                icon: InVogueIcons.retry,
                onRose: true,
                onPressed: () => _bloc.add(const HomeRetried()),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _weather(
    BuildContext context,
    HomeState state,
    WeatherReport report,
  ) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    final weather = report.weather;
    final unit = TemperatureUnit.forCountry(state.place?.countryCode);
    final savedAt = report.fetchedAt.toLocal();
    return [
      if (report.isSaved)
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s3),
          child: Notice(
            icon: InVogueIcons.offline,
            message: l10n.weatherSaved(
              l10n.savedAt(
                InVogueFormat.shortDate(savedAt, language),
                InVogueFormat.time(savedAt, language),
              ),
            ),
          ),
        ),
      WeatherLine(
        temperature: unit.degrees(weather.temperature),
        feelsLike: unit.degrees(weather.feelsLike),
        condition: weather.condition(l10n, language),
        glyph: weather.sky.glyph,
        highlight: weather.highlight,
        dayLabel: report.day == ForecastDay.today ? l10n.today : l10n.tomorrow,
        playKey: report.day,
      ),
      OccasionLine(
        occasion: weather.occasion,
        onChange: () async {
          final chosen = await showOccasionSheet(
            context: context,
            current: weather.occasion,
            day: report.day,
            date: InVogueFormat.shortDate(weather.date, language),
          );
          if (chosen != null) _bloc.add(HomeOccasionChanged(chosen));
        },
      ),
    ];
  }

  List<Widget> _stage(
    BuildContext context,
    HomeState state,
    BoxConstraints viewport,
  ) {
    final l10n = context.translated;
    final outfit = state.shown.outfit;
    final photo = state.photo == null ? null : FileImage(File(state.photo!));
    final width = viewport.maxWidth - context.pageMargin * 2;
    final shop = _shopHeight ?? InVogueSpace.s3 + InVogueLayout.controlHeight;
    final height = PhotoStage.heightFor(
      available:
          viewport.maxHeight - (_headerHeight ?? 0) - shop - InVogueSpace.s3,
      width: width,
    );
    final notice = _notice(context, state);
    return [
      const SizedBox(height: InVogueSpace.s3),
      switch (outfit) {
        OutfitShown(:final outfit) => PhotoStage(
          state: PhotoStageState.ready,
          height: height,
          outfit: FileImage(File(outfit.picture)),
          photo: photo,
          outfitLabel: l10n.outfitPhotoSpoken(outfit.reason ?? ''),
        ),
        OutfitMaking(:final piece, :final pieces) => PhotoStage(
          state: PhotoStageState.waiting,
          height: height,
          photo: photo,
          progress: piece == 0 ? null : l10n.tryOnPiece(piece, pieces),
        ),
        _ => PhotoStage(
          state: PhotoStageState.idle,
          height: height,
          photo: photo,
        ),
      },
      SizeReporter(
        onSize: (size) {
          if (size.height > 0) setState(() => _shopHeight = size.height);
        },
        child: switch (outfit) {
          OutfitShown(:final outfit) => Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s3),
            child: InVogueButton.primary(
              label: l10n.shop,
              onPressed: () => widget.onShop(outfit),
            ),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
      if (notice != null) ...[const SizedBox(height: InVogueSpace.s3), notice],
    ];
  }

  /// What is said below the photo when there is no outfit to show.
  Widget? _notice(BuildContext context, HomeState state) {
    final l10n = context.translated;
    final day = state.selected;
    return switch (state.shown.outfit) {
      OutfitMissing() => Notice(
        icon: InVogueIcons.image,
        message: l10n.noOutfitForDay(day.name),
      ),
      OutfitFailed(failure: TryOnFailure(problem: TryOnProblem.everySeen)) =>
        Notice.everyLookSeen(context: context, day: day),
      OutfitFailed(
        failure: TryOnFailure(
              problem: TryOnProblem.budgetSpent ||
                  TryOnProblem.unavailable ||
                  TryOnProblem.photo,
            ) &&
            final failure,
      ) =>
        Notice(
          icon: InVogueIcons.warning,
          alert: true,
          message: failure.uiFriendlyMessage(context),
        ),
      OutfitFailed(:final failure) => Notice(
        icon: InVogueIcons.warning,
        alert: true,
        message: failure.uiFriendlyMessage(context),
        action: InVogueButton.secondary(
          label: l10n.retry,
          icon: InVogueIcons.retry,
          onRose: true,
          onPressed: () => _bloc.add(const HomeRetried()),
        ),
      ),
      _ => null,
    };
  }

  List<Widget> _about(BuildContext context, OutfitView outfit) {
    final reason = switch (outfit) {
      OutfitShown(:final outfit) => outfit.reason,
      _ => null,
    };
    if (reason == null) return const [];
    return [
      SectionHeading(context.translated.aboutThisOutfit),
      Text(reason, style: InVogueType.body),
    ];
  }
}
