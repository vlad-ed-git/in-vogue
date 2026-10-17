import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/publish_widget.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/watch_widget_taps.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_widget_bloc_test.mocks.dart';

const _content = WidgetContent(
  days: [],
  preferred: ForecastDay.tomorrow,
  savedLine: 'Saved Sun 18 Oct at 9:12 pm',
);

@GenerateMocks([HomeWidgetRepository])
void main() {
  late MockHomeWidgetRepository repository;

  setUp(() {
    repository = MockHomeWidgetRepository();
    when(repository.publish(any)).thenAnswer((_) async => const Right(unit));
  });

  blocTest<HomeWidgetBloc, HomeWidgetState>(
    'publishes the content it is given for the widget',
    build: () => HomeWidgetBloc(
      publishWidget: PublishWidget(repository),
      watchWidgetTaps: WatchWidgetTaps(repository),
    ),
    act: (bloc) => bloc.add(const HomeWidgetContentChanged(_content)),
    expect: () => const <HomeWidgetState>[],
    verify: (_) => verify(repository.publish(_content)).called(1),
  );

  final refresh = WidgetRefreshContext(
    place: const UserLocation(latitude: 48.86, longitude: 2.35),
    language: SupportedLanguages.english,
    preferred: ForecastDay.tomorrow,
    occasions: {DateTime.utc(2026, 10, 18): Occasion.casual},
  );

  blocTest<HomeWidgetBloc, HomeWidgetState>(
    'keeps what the morning refresh needs with the content',
    setUp: () => when(
      repository.publish(any, refresh: anyNamed('refresh')),
    ).thenAnswer((_) async => const Right(unit)),
    build: () => HomeWidgetBloc(
      publishWidget: PublishWidget(repository),
      watchWidgetTaps: WatchWidgetTaps(repository),
    ),
    act: (bloc) =>
        bloc.add(HomeWidgetContentChanged(_content, refresh: refresh)),
    verify: (_) =>
        verify(repository.publish(_content, refresh: refresh)).called(1),
  );

  final tap = WidgetTap(
    date: DateTime.utc(2026, 10, 18),
    occasion: Occasion.casual,
  );

  blocTest<HomeWidgetBloc, HomeWidgetState>(
    'tells each tap on the widget, even the same day twice',
    setUp: () => when(
      repository.taps(),
    ).thenAnswer((_) => Stream.fromIterable([tap, tap])),
    build: () => HomeWidgetBloc(
      publishWidget: PublishWidget(repository),
      watchWidgetTaps: WatchWidgetTaps(repository),
    ),
    act: (bloc) => bloc.add(const HomeWidgetStarted()),
    expect: () => [
      HomeWidgetState(opened: tap, opens: 1),
      HomeWidgetState(opened: tap, opens: 2),
    ],
  );
}
