import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';

abstract interface class HomeWidgetRepository {
  /// Asks the launcher to place the widget; false when it cannot.
  Future<bool> requestPin();

  /// Keeps [content] for the widget and redraws it.
  Future<Either<Failure, Unit>> publish(WidgetContent content);

  /// Forgets what the widget shows and redraws it empty.
  Future<Either<Failure, Unit>> clear();

  /// The taps on the widget, the one that started the app first.
  Stream<WidgetTap> taps();
}
