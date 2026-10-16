import 'package:equatable/equatable.dart';

/// The progress of making one makeup look, kept so that a look cut short
/// goes on without paying again for what is already done.
class MakeupJob extends Equatable {
  const MakeupJob({
    required this.accountId,
    required this.outfitSignature,
    required this.faceRevision,
    required this.updatedAt,
    this.before,
    this.analysisReserved = false,
    this.analysisTask,
    this.recipeKey,
    this.tasks = const [],
    this.pictures = const [],
    this.reservedStep,
  });

  final String accountId;
  final String outfitSignature;

  /// Revision of the face photo the look is made on.
  final int faceRevision;

  /// Name of the kept picture of the face as the service takes it.
  final String? before;

  /// Units for the analysis are reserved, but its task may not have
  /// started.
  final bool analysisReserved;

  /// The analysis task started and not yet finished.
  final String? analysisTask;

  /// The recipe chosen once the face's colours are known.
  final String? recipeKey;

  /// The task of each step started, in order.
  final List<String> tasks;

  /// Names of the pictures of the steps made, in order.
  final List<String> pictures;

  /// A step whose units are reserved but whose task may not have started.
  final int? reservedStep;
  final DateTime updatedAt;

  String get key => keyFor(accountId, outfitSignature);

  /// Identifies the job of [accountId]'s look for [outfitSignature].
  static String keyFor(String accountId, String outfitSignature) =>
      '$accountId|$outfitSignature';

  /// The face's picture is kept as [name].
  MakeupJob withBefore(String name, DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: reservedStep,
    before: name,
  );

  /// Units for the analysis are reserved.
  MakeupJob reservingAnalysis(DateTime at) => _copy(
    at: at,
    analysisReserved: true,
    analysisTask: null,
    reservedStep: reservedStep,
  );

  /// The analysis's reservation was given back.
  MakeupJob unreservedAnalysis(DateTime at) => _copy(
    at: at,
    analysisReserved: false,
    analysisTask: null,
    reservedStep: reservedStep,
  );

  /// The analysis started as [task], using its reservation.
  MakeupJob analysing(String task, DateTime at) => _copy(
    at: at,
    analysisReserved: false,
    analysisTask: task,
    reservedStep: reservedStep,
  );

  /// The analysis is over, done or failed.
  MakeupJob analysed(DateTime at) => _copy(
    at: at,
    analysisReserved: false,
    analysisTask: null,
    reservedStep: reservedStep,
  );

  MakeupJob withRecipe(String key, DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: reservedStep,
    recipeKey: key,
  );

  /// Units for [step] are reserved.
  MakeupJob reservingStep(int step, DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: step,
  );

  /// The step's reservation was given back.
  MakeupJob unreservedStep(DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: null,
  );

  /// The next step started as [task], using its reservation.
  MakeupJob started(String task, DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: null,
    tasks: [...tasks, task],
  );

  /// Only the first [count] steps' tasks are kept.
  MakeupJob keeping(int count, DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: reservedStep,
    tasks: tasks.take(count).toList(),
  );

  /// The next step's picture is kept as [name].
  MakeupJob kept(String name, DateTime at) => _copy(
    at: at,
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    reservedStep: reservedStep,
    pictures: [...pictures, name],
  );

  MakeupJob _copy({
    required DateTime at,
    required bool analysisReserved,
    required String? analysisTask,
    required int? reservedStep,
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
    analysisReserved: analysisReserved,
    analysisTask: analysisTask,
    recipeKey: recipeKey ?? this.recipeKey,
    tasks: tasks ?? this.tasks,
    pictures: pictures ?? this.pictures,
    reservedStep: reservedStep,
  );

  @override
  List<Object?> get props => [
    accountId,
    outfitSignature,
    faceRevision,
    before,
    analysisReserved,
    analysisTask,
    recipeKey,
    tasks,
    pictures,
    reservedStep,
    updatedAt,
  ];
}
