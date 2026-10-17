import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';

/// The JSON form of a [MakeupJob].
abstract final class MakeupJobModel {
  static Map<String, Object?> toJson(MakeupJob job) => {
    'accountId': job.accountId,
    'outfitSignature': job.outfitSignature,
    'faceRevision': job.faceRevision,
    'before': job.before,
    'analysisTask': job.analysisTask,
    'recipeKey': job.recipeKey,
    'tasks': job.tasks,
    'pictures': job.pictures,
    'updatedAt': job.updatedAt.toUtc().toIso8601String(),
  };

  /// Throws [FormatException] when [json] is not a job.
  static MakeupJob fromJson(Object? json) => switch (json) {
    {
      'accountId': final String accountId,
      'outfitSignature': final String outfitSignature,
      'faceRevision': final int faceRevision,
      'before': final String? before,
      'analysisTask': final String? analysisTask,
      'recipeKey': final String? recipeKey,
      'tasks': final List<Object?> tasks,
      'pictures': final List<Object?> pictures,
      'updatedAt': final String updatedAt,
    } =>
      MakeupJob(
        accountId: accountId,
        outfitSignature: outfitSignature,
        faceRevision: faceRevision,
        before: before,
        analysisTask: analysisTask,
        recipeKey: recipeKey,
        tasks: tasks.cast<String>(),
        pictures: pictures.cast<String>(),
        updatedAt: DateTime.parse(updatedAt),
      ),
    _ => throw const FormatException('Not a makeup job'),
  };
}
