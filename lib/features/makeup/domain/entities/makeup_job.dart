import 'package:equatable/equatable.dart';

/// The progress of making one makeup look, kept so that a look cut short
/// goes on without doing again what is already done.
class MakeupJob extends Equatable {
  const MakeupJob({
    required this.accountId,
    required this.outfitSignature,
    required this.faceRevision,
    required this.updatedAt,
    this.before,
    this.analysisTask,
    this.recipeKey,
    this.tasks = const [],
    this.pictures = const [],
  });

  final String accountId;
  final String outfitSignature;

  /// Revision of the face photo the look is made on.
  final int faceRevision;

  /// Name of the kept picture of the face as the service takes it.
  final String? before;

  /// The analysis task started and not yet finished.
  final String? analysisTask;

  /// The recipe chosen once the face's colours are known.
  final String? recipeKey;

  /// The task of each step started, in order.
  final List<String> tasks;

  /// Names of the pictures of the steps made, in order.
  final List<String> pictures;
  final DateTime updatedAt;

  String get key => keyFor(accountId, outfitSignature);

  /// Identifies the job of [accountId]'s look for [outfitSignature].
  static String keyFor(String accountId, String outfitSignature) =>
      '$accountId|$outfitSignature';

  /// The face's picture is kept as [name].
  MakeupJob withBefore(String name, DateTime at) =>
      _copy(at: at, analysisTask: analysisTask, before: name);

  /// The analysis started as [task].
  MakeupJob analysing(String task, DateTime at) =>
      _copy(at: at, analysisTask: task);

  /// The analysis is over, done or failed.
  MakeupJob analysed(DateTime at) => _copy(at: at, analysisTask: null);

  MakeupJob withRecipe(String key, DateTime at) =>
      _copy(at: at, analysisTask: analysisTask, recipeKey: key);

  /// The next step started as [task].
  MakeupJob started(String task, DateTime at) =>
      _copy(at: at, analysisTask: analysisTask, tasks: [...tasks, task]);

  /// Only the first [count] steps' tasks are kept.
  MakeupJob keeping(int count, DateTime at) => _copy(
    at: at,
    analysisTask: analysisTask,
    tasks: tasks.take(count).toList(),
  );

  /// The next step's picture is kept as [name].
  MakeupJob kept(String name, DateTime at) =>
      _copy(at: at, analysisTask: analysisTask, pictures: [...pictures, name]);

  MakeupJob _copy({
    required DateTime at,
    required String? analysisTask,
    String? before,
    String? recipeKey,
    List<String>? tasks,
    List<String>? pictures,
  }) => MakeupJob(
    accountId: accountId,
    outfitSignature: outfitSignature,
    faceRevision: faceRevision,
    updatedAt: at,
    before: before ?? this.before,
    analysisTask: analysisTask,
    recipeKey: recipeKey ?? this.recipeKey,
    tasks: tasks ?? this.tasks,
    pictures: pictures ?? this.pictures,
  );

  @override
  List<Object?> get props => [
    accountId,
    outfitSignature,
    faceRevision,
    before,
    analysisTask,
    recipeKey,
    tasks,
    pictures,
    updatedAt,
  ];
}
