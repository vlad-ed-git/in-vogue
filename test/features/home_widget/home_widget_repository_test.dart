import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/repositories/home_widget_repository_impl.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_widget_repository_test.mocks.dart';

final _snapshot = WidgetSnapshot(
  date: DateTime.utc(2026, 10, 19),
  occasion: Occasion.work,
  today: 'Today',
  tomorrow: 'Tomorrow',
  dateLine: 'Mon 19 Oct · Workday',
  temperature: 54,
  condition: 'Showers after 3 pm',
  feelsLike: 'Feels like 49°',
  glyph: 'cloud-rain',
  waitingPhoto: '/support/photos/body-1.jpg',
  gettingReady: 'Getting ready',
  spokenToday: 'Today, 54 degrees.',
  spokenTomorrow: 'Tomorrow, 54 degrees.',
);

final _content = WidgetContent(
  days: [_snapshot],
  preferred: ForecastDay.tomorrow,
  savedLine: 'Saved Sun 18 Oct at 9:12 pm',
);

@GenerateMocks([HomeWidgetDataSource])
void main() {
  late MockHomeWidgetDataSource widget;
  late HomeWidgetRepositoryImpl repository;
  final now = DateTime(2026, 10, 18, 21, 12);

  setUp(() {
    widget = MockHomeWidgetDataSource();
    repository = HomeWidgetRepositoryImpl(
      dataSource: widget,
      logMessages: LogMessagesImpl(),
    );
    when(widget.save(any, any)).thenAnswer((_) async {});
    when(widget.update()).thenAnswer((_) async {});
    when(widget.schedule(any)).thenAnswer((_) async {});
    when(widget.canPin()).thenAnswer((_) async => true);
    when(widget.pin()).thenAnswer((_) async {});
  });

  test('saves the days for the widget, redraws it and has it change at '
      'the next turns of the day', () async {
    expect(
      await withClock(Clock.fixed(now), () => repository.publish(_content)),
      const Right<Failure, Unit>(unit),
    );
    final calls = verifyInOrder([
      widget.save(HomeWidgetDataSourceImpl.contentKey, captureAny),
      widget.update(),
      widget.schedule(WidgetSchedule.changesAfter(now)),
    ]);
    final saved = calls.first.captured.single as String;
    expect(jsonDecode(saved), {
      'version': 1,
      'preferred': 'tomorrow',
      'savedLine': 'Saved Sun 18 Oct at 9:12 pm',
      'days': [
        {
          'date': '2026-10-19',
          'occasion': 'work',
          'today': 'Today',
          'tomorrow': 'Tomorrow',
          'dateLine': 'Mon 19 Oct · Workday',
          'temperature': 54,
          'condition': 'Showers after 3 pm',
          'feelsLike': 'Feels like 49°',
          'glyph': 'cloud-rain',
          'picture': null,
          'waitingPhoto': '/support/photos/body-1.jpg',
          'gettingReady': 'Getting ready',
          'spokenToday': 'Today, 54 degrees.',
          'spokenTomorrow': 'Tomorrow, 54 degrees.',
          'link': 'invogue://home?date=2026-10-19&occasion=work',
        },
      ],
    });
  });

  test('forgets the days and redraws the widget empty', () async {
    expect(await repository.clear(), const Right<Failure, Unit>(unit));
    verifyInOrder([
      widget.save(HomeWidgetDataSourceImpl.contentKey, null),
      widget.update(),
    ]);
  });

  test('says when the widget cannot be written', () async {
    when(
      widget.save(any, any),
    ).thenThrow(CacheException(Exception('no widget'), StackTrace.current));
    expect(
      await repository.publish(_content),
      const Left<Failure, Unit>(CacheFailure()),
    );
    verifyNever(widget.update());
  });

  test('tells which day a tap on the widget opened, the tap that started '
      'the app first, and skips links it cannot read', () async {
    when(widget.launchedWith()).thenAnswer(
      (_) async => Uri.parse('invogue://home?date=2026-10-18&occasion=casual'),
    );
    when(widget.clicks()).thenAnswer(
      (_) => Stream.fromIterable([
        Uri.parse('invogue://home?date=2026-10-19&occasion=goingOut'),
        Uri.parse('invogue://home?date=someday&occasion=work'),
        Uri.parse('https://example.com/home?date=2026-10-19&occasion=work'),
        null,
      ]),
    );
    expect(await repository.taps().toList(), [
      WidgetTap(date: DateTime.utc(2026, 10, 18), occasion: Occasion.casual),
      WidgetTap(date: DateTime.utc(2026, 10, 19), occasion: Occasion.goingOut),
    ]);
  });

  test('asks the launcher to place the widget when it can', () async {
    expect(await repository.requestPin(), isTrue);
    verify(widget.pin()).called(1);

    when(widget.canPin()).thenAnswer((_) async => false);
    expect(await repository.requestPin(), isFalse);
    verifyNever(widget.pin());
  });
}
