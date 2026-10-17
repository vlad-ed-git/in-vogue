import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';

/// What the widget shows, and what its morning refresh needs when known.
typedef WidgetPublication = ({
  WidgetContent content,
  WidgetRefreshContext? refresh,
});

/// Keeps the widget's content and redraws it.
class PublishWidget implements UseCase<Unit, WidgetPublication> {
  const PublishWidget(this._repository);

  final HomeWidgetRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(WidgetPublication publication) =>
      _repository.publish(publication.content, refresh: publication.refresh);
}
