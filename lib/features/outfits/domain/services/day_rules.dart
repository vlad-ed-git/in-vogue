import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';

/// Who makes a day's outfit when several phones share an account.
abstract final class DayRules {
  /// How long a making may go without a change before another install
  /// takes it over.
  static const lease = Duration(minutes: 10);

  /// Claiming [current] for [device] at [now], with [proposal] when the day
  /// needs a new outfit: what to write, if anything, and the outcome.
  ///
  /// A new day takes the proposal. A made day stays. A failed day is tried
  /// again with its outfit, unless it is [replaceable]: then it takes the
  /// proposal. A making stays with its install until it is [stale], then
  /// [device] takes it over; its own install gives it the proposal when
  /// [replacing] its outfit.
  static ({Day? write, DayClaim claim}) claim({
    required Day? current,
    required Day? proposal,
    required String device,
    required DateTime now,
    String? replacing,
  }) {
    if (current == null) return _propose(proposal, device);
    switch (current.status) {
      case DayStatus.ready:
        return (write: null, claim: DayKept(current));
      case DayStatus.failed when replaceable(current):
        return _propose(proposal, device);
      case DayStatus.failed:
        final again = current.makingBy(device);
        return (write: again, claim: DayClaimed(again));
      case DayStatus.making:
        if (current.device == device) {
          if (replacing != null && current.outfitId == replacing) {
            return _propose(proposal, device);
          }
          return (write: null, claim: DayClaimed(current));
        }
        if (stale(current, now)) {
          final taken = current.makingBy(device);
          return (write: taken, claim: DayClaimed(taken));
        }
        return (write: null, claim: DayKept(current));
    }
  }

  /// Whether [day] failed on a piece's photo, so it takes a new outfit.
  static bool replaceable(Day day) =>
      day.status == DayStatus.failed && day.problem == TryOnProblem.reference;

  /// [proposal], made by [device]; a conflict when there is none.
  static ({Day? write, DayClaim claim}) _propose(Day? proposal, String device) {
    if (proposal == null) return (write: null, claim: const DayConflict());
    final made = proposal.makingBy(device);
    return (write: made, claim: DayClaimed(made));
  }

  /// Whether [day]'s making has gone [lease] without a change by [now].
  static bool stale(Day day, DateTime now) {
    final updatedAt = day.updatedAt;
    return day.status == DayStatus.making &&
        updatedAt != null &&
        !now.isBefore(updatedAt.add(lease));
  }
}
