import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';

/// A tap on the widget, opening Home on the day it showed.
class WidgetTap extends Equatable {
  const WidgetTap({required this.date, required this.occasion});

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  @override
  List<Object?> get props => [date, occasion];
}
