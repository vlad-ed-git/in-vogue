import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:in_vogue/features/weather/presentation/widgets/day_weather_header.dart';

/// Setup step 3: tomorrow's weather, then pieces that suit it to pick from.
class PicksScreen extends StatelessWidget {
  const PicksScreen({required this.onBack, required this.onProceed, super.key});

  final VoidCallback onBack;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
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
                builder: (context, state) => switch (state.status) {
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
                        onPressed: () => context.read<ForecastBloc>().add(
                          const ForecastRequested(),
                        ),
                      ),
                    ),
                  ),
                  ForecastStatus.loading => const SizedBox.shrink(),
                },
              ),
              const SizedBox(height: InVogueSpace.s6),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: PicksBar(
      count: 0,
      action: PicksBarAction.proceed,
      onPressed: onProceed,
    ),
  );
}
