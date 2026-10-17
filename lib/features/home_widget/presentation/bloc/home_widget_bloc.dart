import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/publish_widget.dart';
import 'package:in_vogue/features/home_widget/domain/usecases/watch_widget_taps.dart';

sealed class HomeWidgetEvent extends Equatable {
  const HomeWidgetEvent();

  @override
  List<Object?> get props => [];
}

/// Starts telling the taps on the widget.
final class HomeWidgetStarted extends HomeWidgetEvent {
  const HomeWidgetStarted();
}

/// What the widget should show changed.
final class HomeWidgetContentChanged extends HomeWidgetEvent {
  const HomeWidgetContentChanged(this.content);
  final WidgetContent content;

  @override
  List<Object?> get props => [content];
}

class HomeWidgetState extends Equatable {
  const HomeWidgetState({this.opened, this.opens = 0});

  /// The latest tap on the widget.
  final WidgetTap? opened;

  /// How many taps there have been, so the same day tapped twice counts.
  final int opens;

  @override
  List<Object?> get props => [opened, opens];
}

/// Keeps the home-screen widget showing Home's days, the latest content
/// winning, and tells the taps on it.
class HomeWidgetBloc extends Bloc<HomeWidgetEvent, HomeWidgetState> {
  HomeWidgetBloc({required this._publishWidget, required this._watchWidgetTaps})
    : super(const HomeWidgetState()) {
    on<HomeWidgetStarted>(_start, transformer: droppable());
    on<HomeWidgetContentChanged>(_publish, transformer: restartable());
  }

  final PublishWidget _publishWidget;
  final WatchWidgetTaps _watchWidgetTaps;

  Future<void> _start(HomeWidgetStarted event, Emitter<HomeWidgetState> emit) =>
      emit.forEach(
        _watchWidgetTaps(),
        onData: (tap) => HomeWidgetState(opened: tap, opens: state.opens + 1),
      );

  Future<void> _publish(
    HomeWidgetContentChanged event,
    Emitter<HomeWidgetState> emit,
  ) async {
    // A widget that cannot be written keeps what it showed.
    await _publishWidget(event.content);
  }
}
