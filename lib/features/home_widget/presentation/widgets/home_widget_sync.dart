import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
import 'package:in_vogue/features/home_widget/presentation/widget_content_text.dart';

/// Gives the home-screen widget Home's days whenever they change, and
/// their words again when the language does. A tap on the widget opens
/// Home on the day it showed, once Home is ready.
class HomeWidgetSync extends StatefulWidget {
  const HomeWidgetSync({
    required this.onOpenHome,
    required this.child,
    super.key,
  });

  /// Shows the Home tab.
  final void Function(BuildContext context) onOpenHome;
  final Widget child;

  @override
  State<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends State<HomeWidgetSync> {
  SupportedLanguages? _language;

  /// A tap that came before Home was ready.
  WidgetTap? _pending;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.language;
    if (_language != null && language != _language) {
      _publish(context.read<HomeBloc>().state);
    }
    _language = language;
  }

  void _publish(HomeState state) {
    if (state.status != HomeStatus.ready) return;
    context.read<HomeWidgetBloc>().add(
      HomeWidgetContentChanged(
        WidgetContentText.of(
          days: [
            for (final day in ForecastDay.values)
              if (state.day(day).report case final report?)
                (
                  report: report,
                  outfit: switch (state.day(day).outfit) {
                    OutfitShown(:final outfit) => outfit,
                    _ => null,
                  },
                ),
          ],
          preferred: state.preferred,
          countryCode: state.place?.countryCode,
          bodyPhoto: state.photo,
          l10n: context.translated,
          language: context.language,
          now: clock.now(),
        ),
        refresh: switch (state.place) {
          final place? => WidgetRefreshContext(
            place: place,
            language: context.language,
            preferred: state.preferred,
            bodyPhoto: state.photo,
            occasions: {
              for (final day in state.days.values)
                if (day.report?.weather case final weather?)
                  weather.date: weather.occasion,
            },
          ),
          null => null,
        },
      ),
    );
  }

  void _open(WidgetTap tap) {
    widget.onOpenHome(context);
    final home = context.read<HomeBloc>();
    if (home.state.status == HomeStatus.ready) {
      _show(home, tap);
    } else {
      _pending = tap;
    }
  }

  /// Selects the day of [tap] in its occasion; nothing when Home no longer
  /// has that date.
  static void _show(HomeBloc home, WidgetTap tap) {
    final day = ForecastDay.values
        .where((day) => home.state.day(day).report?.weather.date == tap.date)
        .firstOrNull;
    if (day == null) return;
    home.add(HomeDaySelected(day));
    if (home.state.day(day).report?.weather.occasion != tap.occasion) {
      home.add(HomeOccasionChanged(tap.occasion));
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<HomeBloc, HomeState>(
        listenWhen: (before, after) =>
            before.status != after.status ||
            before.days != after.days ||
            before.photo != after.photo ||
            before.place != after.place ||
            before.preferred != after.preferred,
        listener: (context, state) {
          _publish(state);
          if (state.status == HomeStatus.ready && _pending != null) {
            _show(context.read<HomeBloc>(), _pending!);
            _pending = null;
          }
        },
      ),
      BlocListener<HomeWidgetBloc, HomeWidgetState>(
        listenWhen: (before, after) =>
            after.opened != null && before.opens != after.opens,
        listener: (context, state) => _open(state.opened!),
      ),
    ],
    child: widget.child,
  );
}
