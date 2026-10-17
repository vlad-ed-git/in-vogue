import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/publish_widget.dart';

sealed class HomeWidgetEvent extends Equatable {
  const HomeWidgetEvent();

  @override
  List<Object?> get props => [];
}

/// What the widget should show changed.
final class HomeWidgetContentChanged extends HomeWidgetEvent {
  const HomeWidgetContentChanged(this.content);
  final WidgetContent content;

  @override
  List<Object?> get props => [content];
}

class HomeWidgetState extends Equatable {
  const HomeWidgetState();

  @override
  List<Object?> get props => [];
}

/// Keeps the home-screen widget showing Home's days; the latest content
/// wins.
class HomeWidgetBloc extends Bloc<HomeWidgetEvent, HomeWidgetState> {
  HomeWidgetBloc({required this._publishWidget})
    : super(const HomeWidgetState()) {
    on<HomeWidgetContentChanged>(_publish, transformer: restartable());
  }

  final PublishWidget _publishWidget;

  Future<void> _publish(
    HomeWidgetContentChanged event,
    Emitter<HomeWidgetState> emit,
  ) async {
    // A widget that cannot be written keeps what it showed.
    await _publishWidget(event.content);
  }
}
