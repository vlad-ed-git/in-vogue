import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

abstract interface class PreferencesRepository {
  Future<Either<Failure, SupportedLanguages>> getLanguage();
  Future<Either<Failure, SupportedLanguages>> setLanguage(
    SupportedLanguages language,
  );
}
