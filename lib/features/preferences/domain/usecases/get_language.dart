import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';

class GetLanguage implements UseCase<SupportedLanguages, NoParams> {
  const GetLanguage(this._repository);
  final PreferencesRepository _repository;

  @override
  Future<Either<Failure, SupportedLanguages>> call(NoParams params) =>
      _repository.getLanguage();
}
