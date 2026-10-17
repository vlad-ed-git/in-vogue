import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// The JSON form of a [TryOnJob].
abstract final class TryOnJobModel {
  static Map<String, Object?> toJson(TryOnJob job) => {
    'accountId': job.accountId,
    'date': TryOnJob.dateKey(job.date),
    'occasion': job.occasion.name,
    'cell': job.cell,
    'outfitId': job.outfitId,
    'photoRevision': job.photoRevision,
    'tasks': job.tasks,
    'updatedAt': job.updatedAt.toUtc().toIso8601String(),
  };

  /// Throws [FormatException] when [json] is not a job.
  static TryOnJob fromJson(Object? json) => switch (json) {
    {
      'accountId': final String accountId,
      'date': final String date,
      'occasion': final String occasion,
      'cell': final String cell,
      'outfitId': final String outfitId,
      'photoRevision': final int photoRevision,
      'tasks': final List<Object?> tasks,
      'updatedAt': final String updatedAt,
    } =>
      TryOnJob(
        accountId: accountId,
        date: DateTime.parse('${date}T00:00:00Z'),
        occasion:
            Occasion.values.asNameMap()[occasion] ??
            (throw FormatException('Unknown occasion', occasion)),
        cell: cell,
        outfitId: outfitId,
        photoRevision: photoRevision,
        tasks: tasks.cast<String>(),
        updatedAt: DateTime.parse(updatedAt),
      ),
    _ => throw const FormatException('Not a try-on job'),
  };
}
