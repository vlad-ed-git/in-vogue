import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';

/// What the morning refresh needs to redraw the widget while the app is
/// closed.
class WidgetRefreshContext extends Equatable {
  const WidgetRefreshContext({
    required this.place,
    required this.language,
    required this.preferred,
    this.bodyPhoto,
    this.accountId,
    this.bodyPhotoRevision,
    this.occasions = const {},
  });

  final UserLocation place;
  final SupportedLanguages language;

  /// The widget's saved default day, respected at every hour.
  final ForecastDay preferred;

  /// Shown faded while a day has no outfit.
  final String? bodyPhoto;
  final String? accountId;
  final int? bodyPhotoRevision;

  /// Occasions set for dates, midnight UTC, so each day keeps its own.
  final Map<DateTime, Occasion> occasions;

  @override
  List<Object?> get props => [
    place,
    language,
    preferred,
    bodyPhoto,
    occasions,
    accountId,
    bodyPhotoRevision,
  ];
}
