import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';

/// The home-screen widget where it isn't built yet: it cannot be placed,
/// and there is nothing to keep for it.
class UnavailableHomeWidgetRepository implements HomeWidgetRepository {
  const UnavailableHomeWidgetRepository();

  @override
  Future<bool> requestPin() async => false;

  @override
  Future<Either<Failure, Unit>> publish(WidgetContent content) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> clear() async => const Right(unit);

  @override
  Stream<WidgetTap> taps() => const Stream.empty();
}
