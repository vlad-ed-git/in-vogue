import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/publish_widget.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
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
    build: () => HomeWidgetBloc(publishWidget: PublishWidget(repository)),
    act: (bloc) => bloc.add(const HomeWidgetContentChanged(_content)),
    expect: () => const <HomeWidgetState>[],
    verify: (_) => verify(repository.publish(_content)).called(1),
  );
}
