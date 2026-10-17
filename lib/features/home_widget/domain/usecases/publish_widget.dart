import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';

/// Keeps the widget's content and redraws it.
class PublishWidget implements UseCase<Unit, WidgetContent> {
  const PublishWidget(this._repository);

  final HomeWidgetRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(WidgetContent content) =>
      _repository.publish(content);
}
