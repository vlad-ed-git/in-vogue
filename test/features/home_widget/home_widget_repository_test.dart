import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_picture_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/data/repositories/home_widget_repository_impl.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
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

@GenerateMocks([
  HomeWidgetDataSource,
  WidgetPictureDataSource,
  WidgetRefreshScheduler,
])
void main() {
  late MockHomeWidgetDataSource widget;
  late MockWidgetPictureDataSource pictures;
  late MockWidgetRefreshScheduler scheduler;
  late HomeWidgetRepositoryImpl repository;
  final now = DateTime(2026, 10, 18, 21, 12);

  setUp(() {
    widget = MockHomeWidgetDataSource();
    pictures = MockWidgetPictureDataSource();
    scheduler = MockWidgetRefreshScheduler();
    repository = HomeWidgetRepositoryImpl(
      dataSource: widget,
      pictures: pictures,
      scheduler: scheduler,
      environment: 'development',
      logMessages: LogMessagesImpl(),
    );
    when(scheduler.schedule(any)).thenAnswer((_) async {});
    when(widget.save(any, any)).thenAnswer((_) async {});
    when(widget.update()).thenAnswer((_) async {});
    when(widget.schedule(any)).thenAnswer((_) async {});
    when(widget.canPin()).thenAnswer((_) async => true);
    when(widget.pin()).thenAnswer((_) async {});
    when(pictures.share(any)).thenAnswer(
      (invocation) async => {
        for (final path in invocation.positionalArguments.single as Set<String>)
          path: '/group/widget/${path.split('/').last}',
      },
    );
    when(pictures.clear()).thenAnswer((_) async {});
  });

  test(
    'saves the days for the widget with their pictures where it reads '
    'them, redraws it and has it change at the next turns of the day',
    () async {
      expect(
        await withClock(Clock.fixed(now), () => repository.publish(_content)),
        const Right<Failure, Unit>(unit),
      );
      final calls = verifyInOrder([
        pictures.share({'/support/photos/body-1.jpg'}),
        widget.save(HomeWidgetDataSourceImpl.contentKey, captureAny),
        widget.update(),
        widget.schedule(WidgetSchedule.changesAfter(now)),
      ]);
      final saved = calls[1].captured.single as String;
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
            'waitingPhoto': '/group/widget/body-1.jpg',
            'gettingReady': 'Getting ready',
            'spokenToday': 'Today, 54 degrees.',
            'spokenTomorrow': 'Tomorrow, 54 degrees.',
            'link': 'invogue://home?date=2026-10-19&occasion=work&homeWidget',
          },
        ],
      });
    },
  );

  test(
    'publishes one at a time, so two never share pictures at once',
    () async {
      final first = Completer<Map<String, String>>();
      var sharing = 0;
      var mostAtOnce = 0;
      when(pictures.share(any)).thenAnswer((_) async {
        mostAtOnce = math.max(mostAtOnce, ++sharing);
        final shared = sharing == 1 && !first.isCompleted
            ? await first.future
            : const <String, String>{};
        sharing--;
        return shared;
      });
      final publishing = [
        withClock(Clock.fixed(now), () => repository.publish(_content)),
        withClock(Clock.fixed(now), () => repository.publish(_content)),
      ];
      await pumpEventQueue();
      expect(mostAtOnce, 1);
      first.complete(const {});
      expect(await Future.wait(publishing), [
        const Right<Failure, Unit>(unit),
        const Right<Failure, Unit>(unit),
      ]);
      expect(mostAtOnce, 1);
      verify(pictures.share(any)).called(2);
    },
  );

  test('a publish that fails does not stop the next', () async {
    when(
      pictures.share(any),
    ).thenThrow(CacheException(Exception(), StackTrace.current));
    final failed = await withClock(
      Clock.fixed(now),
      () => repository.publish(_content),
    );
    expect(failed.isLeft(), isTrue);
    when(pictures.share(any)).thenAnswer((_) async => const {});
    expect(
      await withClock(Clock.fixed(now), () => repository.publish(_content)),
      const Right<Failure, Unit>(unit),
    );
  });

  test('leaves out a picture the widget has no copy of', () async {
    when(pictures.share(any)).thenAnswer((_) async => {});
    await repository.publish(_content);
    final saved =
        verify(
              widget.save(HomeWidgetDataSourceImpl.contentKey, captureAny),
            ).captured.single
            as String;
    final days = (jsonDecode(saved) as Map<String, Object?>)['days']! as List;
    expect((days.single as Map)['waitingPhoto'], isNull);
  });

  test(
    'keeps what the morning refresh needs, and has it run at 05:30',
    () async {
      final refresh = WidgetRefreshContext(
        place: const UserLocation(
          latitude: 48.86,
          longitude: 2.35,
          city: 'Paris',
          countryCode: 'FR',
        ),
        language: SupportedLanguages.spanish,
        preferred: ForecastDay.today,
        bodyPhoto: '/photos/body-1.jpg',
        occasions: {DateTime.utc(2026, 10, 19): Occasion.goingOut},
      );
      await withClock(
        Clock.fixed(now),
        () => repository.publish(_content, refresh: refresh),
      );
      final saved =
          verify(
                widget.save(HomeWidgetDataSourceImpl.refreshKey, captureAny),
              ).captured.single
              as String;
      expect(jsonDecode(saved), {
        'version': 1,
        'environment': 'development',
        'latitude': 48.86,
        'longitude': 2.35,
        'city': 'Paris',
        'countryCode': 'FR',
        'language': 'es',
        'preferred': 'today',
        'bodyPhoto': '/photos/body-1.jpg',
        'occasions': {'2026-10-19': 'goingOut'},
      });
      verify(scheduler.schedule(WidgetSchedule.untilRefresh(now))).called(1);

      when(
        widget.read(HomeWidgetDataSourceImpl.refreshKey),
      ).thenAnswer((_) async => saved);
      final read = await repository.savedRefresh();
      expect(read?.environment, 'development');
      expect(read?.context, refresh);
    },
  );

  test('forgets the days and their pictures, and redraws the widget '
      'empty', () async {
    expect(await repository.clear(), const Right<Failure, Unit>(unit));
    verifyInOrder([
      widget.save(HomeWidgetDataSourceImpl.contentKey, null),
      widget.update(),
      pictures.clear(),
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
      (_) async => Uri.parse(
        'invogue://home?date=2026-10-18&occasion=casual&homeWidget',
      ),
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
