import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/first_outfit_bloc.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';

/// Setup step 3: the day's weather at once, then the person in their first
/// outfit with why it suits the day. No Shop, day switch or sign-up yet.
class FirstOutfitScreen extends StatelessWidget {
  const FirstOutfitScreen({
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;

  /// Height the rest of the screen takes around the stage at the design
  /// size, while waiting and once the outfit is ready.
  static const double _aroundWaitingStage = 344;
  static const double _aroundReadyStage = 384;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: PageMargin(
            child: BlocBuilder<FirstOutfitBloc, FirstOutfitState>(
              builder: (context, state) => _content(context, state, viewport),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _content(
    BuildContext context,
    FirstOutfitState state,
    BoxConstraints viewport,
  ) {
    final l10n = context.translated;
    final bloc = context.read<FirstOutfitBloc>();
    final report = state.report;
    final outfit = state.triedOn;
    final ready = state.outfit == Progress.ready && outfit != null;
    final photo = state.photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BackBar(
          onBack: onBack,
          step: SetupStep.firstOutfit.folio,
          total: SetupStepFolio.total,
        ),
        if (state.weather == Progress.failed) ...[
          const SizedBox(height: InVogueSpace.s1),
          Notice(
            icon: InVogueIcons.warning,
            alert: true,
            message: l10n.weatherUnavailable,
            action: InVogueButton.secondary(
              label: l10n.retry,
              icon: InVogueIcons.retry,
              onRose: true,
              onPressed: () => bloc.add(const FirstOutfitWeatherRetried()),
            ),
          ),
        ] else ...[
          if (report != null) _Weather(report: report, place: state.location),
          PhotoStage(
            state: ready
                ? PhotoStageState.ready
                : state.outfit == Progress.failed
                ? PhotoStageState.failed
                : PhotoStageState.waiting,
            height: PhotoStage.heightFor(
              available:
                  viewport.maxHeight -
                  (ready ? _aroundReadyStage : _aroundWaitingStage),
              width: viewport.maxWidth - 2 * context.pageMargin,
            ),
            outfit: ready ? FileImage(File(outfit.imagePath)) : null,
            photo: photo == null ? null : FileImage(File(photo.path)),
            outfitLabel: outfit?.description,
            onRetry: () => bloc.add(const FirstOutfitTryOnRetried()),
          ),
          if (ready) ...[
            const SizedBox(height: InVogueSpace.s3),
            Text(outfit.reason, style: InVogueType.body),
            const SizedBox(height: InVogueSpace.s4),
            InVogueButton.primary(label: l10n.next, onPressed: onNext),
          ],
        ],
        const SizedBox(height: InVogueSpace.s6),
      ],
    );
  }
}

/// The day, date and place, then the weather line and the occasion.
class _Weather extends StatelessWidget {
  const _Weather({required this.report, required this.place});

  final WeatherReport report;
  final UserLocation? place;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    final weather = report.weather;
    final unit = TemperatureUnit.forCountry(place?.countryCode);
    final day = report.day == ForecastDay.today ? l10n.today : l10n.tomorrow;
    final date = InVogueFormat.shortDate(weather.date, language);
    final city = place?.city;
    final savedAt = report.fetchedAt.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: InVogueSpace.s1),
        Text(
          city == null
              ? l10n.dayDate(day, date)
              : l10n.dayDatePlace(day, date, city),
          style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
        ),
        if (report.isSaved) ...[
          const SizedBox(height: InVogueSpace.s3),
          Notice(
            icon: InVogueIcons.offline,
            message: l10n.weatherSaved(
              l10n.savedAt(
                InVogueFormat.shortDate(savedAt, language),
                InVogueFormat.time(savedAt, language),
              ),
            ),
          ),
        ],
        WeatherLine(
          temperature: unit.degrees(weather.temperature),
          feelsLike: unit.degrees(weather.feelsLike),
          condition: weather.condition(l10n, language),
          glyph: weather.sky.glyph,
          highlight: weather.highlight,
          dayLabel: day,
        ),
        OccasionLine(occasion: weather.occasion),
      ],
    );
  }
}
