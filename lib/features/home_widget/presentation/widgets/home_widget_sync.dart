import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
import 'package:in_vogue/features/home_widget/presentation/widget_content_text.dart';

/// Gives the home-screen widget Home's days whenever they change, and
/// their words again when the language does.
class HomeWidgetSync extends StatefulWidget {
  const HomeWidgetSync({required this.child, super.key});

  final Widget child;

  @override
  State<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends State<HomeWidgetSync> {
  SupportedLanguages? _language;

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<HomeBloc, HomeState>(
    listenWhen: (before, after) =>
        before.status != after.status ||
        before.days != after.days ||
        before.photo != after.photo ||
        before.place != after.place ||
        before.preferred != after.preferred,
    listener: (context, state) => _publish(state),
    child: widget.child,
  );
}
