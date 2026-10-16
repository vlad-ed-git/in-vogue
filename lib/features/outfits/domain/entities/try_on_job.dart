import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';

/// The progress of making one day's outfit, kept so that a try-on cut
/// short resumes without paying again for passes already made.
class TryOnJob extends Equatable {
  const TryOnJob({
    required this.accountId,
    required this.date,
    required this.occasion,
    required this.cell,
    required this.outfitId,
    required this.photoRevision,
    required this.updatedAt,
    this.tasks = const [],
    this.reservedPass,
  });

  final String accountId;

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The knowledge-base cell the outfit was chosen for.
  final String cell;
  final String outfitId;

  /// Revision of the body photo being dressed.
  final int photoRevision;

  /// The try-on task of each pass started, in order.
  final List<String> tasks;

  /// A pass whose units are reserved but whose task may not have started.
  final int? reservedPass;
  final DateTime updatedAt;

  String get key => keyFor(accountId, date, occasion);

  /// Identifies the job of [accountId]'s outfit for [date] and [occasion].
  static String keyFor(String accountId, DateTime date, Occasion occasion) =>
      '$accountId|${dateKey(date)}|${occasion.name}';

  /// [date] as "2026-10-17".
  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Units for [pass] are reserved.
  TryOnJob reserving(int pass, DateTime at) =>
      _copy(tasks: tasks, reservedPass: pass, at: at);

  /// The reservation was given back.
  TryOnJob unreserved(DateTime at) => _copy(tasks: tasks, at: at);

  /// The next pass started as [task].
  TryOnJob started(String task, DateTime at) =>
      _copy(tasks: [...tasks, task], at: at);

  /// Only the first [count] passes' tasks are kept.
  TryOnJob keeping(int count, DateTime at) =>
      _copy(tasks: tasks.take(count).toList(), at: at);

  TryOnJob _copy({
    required List<String> tasks,
    required DateTime at,
    int? reservedPass,
  }) => TryOnJob(
    accountId: accountId,
    date: date,
    occasion: occasion,
    cell: cell,
    outfitId: outfitId,
    photoRevision: photoRevision,
    updatedAt: at,
    tasks: tasks,
    reservedPass: reservedPass,
  );

  @override
  List<Object?> get props => [
    accountId,
    date,
    occasion,
    cell,
    outfitId,
    photoRevision,
    tasks,
    reservedPass,
    updatedAt,
  ];
}
