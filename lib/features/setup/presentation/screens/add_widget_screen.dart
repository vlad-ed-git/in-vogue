import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';

/// Setup step 6: the home-screen widget as a print, with tomorrow's weather
/// and the person's photo waiting for their first outfit. Android places it
/// through the launcher; iPhone shows the three steps on the same screen.
class AddWidgetScreen extends StatefulWidget {
  const AddWidgetScreen({
    required this.onBack,
    required this.onFinish,
    required this.onAddWidget,
    super.key,
  });

  final VoidCallback onBack;

  /// Finishes setup.
  final VoidCallback onFinish;

  /// Asks the launcher to place the widget; false when it cannot.
  final Future<bool> Function() onAddWidget;

  @override
  State<AddWidgetScreen> createState() => _AddWidgetScreenState();
}

class _AddWidgetScreenState extends State<AddWidgetScreen> {
  bool _adding = false;

  /// The launcher can't place the widget from the app.
  bool _byHand = false;

  Future<void> _add() async {
    setState(() => _adding = true);
    final placed = await widget.onAddWidget();
    if (!mounted) return;
    setState(() {
      _adding = false;
      _byHand = !placed;
    });
    if (placed) widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageMargin(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BackBar(
                        onBack: widget.onBack,
                        step: SetupStep.widget.folio,
                        total: SetupStepFolio.total,
                      ),
                      const SizedBox(height: InVogueSpace.s3),
                      ScreenTitle(l10n.addWidgetTitle),
                      const SizedBox(height: InVogueSpace.s3),
                      Text(
                        l10n.addWidgetLine,
                        style: InVogueType.body.copyWith(
                          color: InVogueColors.graphite,
                        ),
                      ),
                      const SizedBox(height: InVogueSpace.s5),
                    ],
                  ),
                ),
                _preview(context, viewport.maxWidth),
                PageMargin(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: context.isApplePlatform
                        ? _iPhone(context)
                        : _android(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, double width) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    return BlocBuilder<ForecastBloc, ForecastState>(
      builder: (context, forecast) {
        final report = forecast.report;
        if (report == null) return const SizedBox.shrink();
        final weather = report.weather;
        final unit = TemperatureUnit.forCountry(forecast.place?.countryCode);
        final day = report.day == ForecastDay.today
            ? l10n.today
            : l10n.tomorrow;
        final temperature = unit.degrees(weather.temperature);
        final feelsLike = unit.degrees(weather.feelsLike);
        final condition = weather.condition(l10n, language);
        return BlocBuilder<PhotoBloc, PhotoState>(
          builder: (context, photo) => HomeWidgetPreview(
            width: width,
            kicker: day,
            dateLine:
                '${InVogueFormat.shortDate(weather.date, language)} · '
                '${weather.occasion.kicker(l10n)}',
            temperature: temperature,
            feelsLike: feelsLike,
            condition: condition,
            glyph: weather.sky.glyph,
            waitingPhoto: photo.path == null
                ? null
                : FileImage(File(photo.path!)),
            semanticLabel: l10n.widgetPreviewSpoken(
              l10n.weatherSpokenWithDay(day, temperature, condition, feelsLike),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _iPhone(BuildContext context) => [
    SectionHeading(context.translated.widgetStepsTitle),
    const WidgetSteps(),
    const SizedBox(height: InVogueSpace.s6),
    InVogueButton.primary(
      label: context.translated.done,
      icon: InVogueIcons.check,
      onPressed: widget.onFinish,
    ),
    const SizedBox(height: InVogueSpace.s6),
  ];

  List<Widget> _android(BuildContext context) => [
    const SizedBox(height: InVogueSpace.s5),
    if (_byHand) ...[
      Notice(
        icon: InVogueIcons.handTap,
        message: context.translated.widgetAddByHand,
      ),
      const SizedBox(height: InVogueSpace.s4),
    ],
    InVogueButton.primary(
      label: context.translated.addToHomeScreen,
      onPressed: _add,
      busy: _adding,
    ),
    const SizedBox(height: InVogueSpace.s4),
    Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextLink(label: context.translated.skip, onTap: widget.onFinish),
    ),
    const SizedBox(height: InVogueSpace.s6),
  ];
}
