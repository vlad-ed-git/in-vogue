import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

abstract interface class PreferencesRepository {
  Future<Either<Failure, SupportedLanguages>> getLanguage();
  Future<Either<Failure, SupportedLanguages>> setLanguage(
    SupportedLanguages language,
  );

  /// The day Home opens on: tomorrow (today from 06:00 to 08:59) unless
  /// the person chose today.
  Future<Either<Failure, ForecastDay>> defaultDay();
  Future<Either<Failure, ForecastDay>> setDefaultDay(ForecastDay day);

  /// The occasion the person chose for each date, from today on.
  Future<Either<Failure, Map<DateTime, Occasion>>> occasions();

  /// Keeps [occasion] as the one chosen for [date], forgetting dates gone
  /// by.
  Future<Either<Failure, Unit>> setOccasion(DateTime date, Occasion occasion);
}
