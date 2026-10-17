import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';

/// A day as the home-screen widget shows it, its words already in the
/// person's language.
class WidgetSnapshot extends Equatable {
  const WidgetSnapshot({
    required this.date,
    required this.occasion,
    required this.today,
    required this.tomorrow,
    required this.dateLine,
    required this.temperature,
    required this.condition,
    required this.feelsLike,
    required this.glyph,
    required this.gettingReady,
    required this.spokenToday,
    required this.spokenTomorrow,
    this.picture,
    this.waitingPhoto,
  });

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The kicker when [date] is today, and when it is tomorrow, as shown:
  /// in capitals where the language has them.
  final String today;
  final String tomorrow;

  /// Such as "Thu 16 Oct · Workday".
  final String dateLine;

  /// In the person's unit.
  final int temperature;
  final String condition;

  /// Such as "Feels like 49°".
  final String feelsLike;

  /// The weather glyph's name, such as "cloud-rain".
  final String glyph;

  /// The outfit's picture on the phone; null until it is made.
  final String? picture;

  /// The person's photo, shown faded under [gettingReady] while there is no
  /// [picture].
  final String? waitingPhoto;
  final String gettingReady;

  /// The whole widget read aloud, with [today] or with [tomorrow].
  final String spokenToday;
  final String spokenTomorrow;

  @override
  List<Object?> get props => [
    date,
    occasion,
    today,
    tomorrow,
    dateLine,
    temperature,
    condition,
    feelsLike,
    glyph,
    picture,
    waitingPhoto,
    gettingReady,
    spokenToday,
    spokenTomorrow,
  ];
}

/// What the widget keeps: the days it may show and how it picks one.
class WidgetContent extends Equatable {
  const WidgetContent({
    required this.days,
    required this.preferred,
    required this.savedLine,
  });

  final List<WidgetSnapshot> days;

  /// The day Home opens on: tomorrow with the morning rule, or always today.
  final ForecastDay preferred;

  /// Such as "Saved Sun 18 Oct at 9:12 pm": the date line when the widget
  /// has no snapshot for the day it should show.
  final String savedLine;

  @override
  List<Object?> get props => [days, preferred, savedLine];
}
