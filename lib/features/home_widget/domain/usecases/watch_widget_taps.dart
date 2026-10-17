import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';

/// The taps on the widget, the one that started the app first.
class WatchWidgetTaps {
  const WatchWidgetTaps(this._repository);

  final HomeWidgetRepository _repository;

  Stream<WidgetTap> call() => _repository.taps();
}
