import 'package:in_vogue/features/outfits/domain/entities/day.dart';

/// Who makes a day's outfit when several phones share an account.
abstract final class DayRules {
  /// How long a making may go without a change before another install
  /// takes it over.
  static const lease = Duration(minutes: 10);

  /// Claiming [current] for [device] at [now], with [proposal] when the day
  /// has no outfit yet: what to write, if anything, and the outcome.
  ///
  /// A new day takes the proposal. A made day stays. A failed day is tried
  /// again with its outfit. A making stays with its install until it is
  /// [stale], then [device] takes it over.
  static ({Day? write, DayClaim claim}) claim({
    required Day? current,
    required Day? proposal,
    required String device,
    required DateTime now,
  }) {
    if (current == null) {
      if (proposal == null) return (write: null, claim: const DayConflict());
      final made = proposal.makingBy(device);
      return (write: made, claim: DayClaimed(made));
    }
    switch (current.status) {
      case DayStatus.ready:
        return (write: null, claim: DayKept(current));
      case DayStatus.failed:
        final again = current.makingBy(device);
        return (write: again, claim: DayClaimed(again));
      case DayStatus.making:
        if (current.device == device) {
          return (write: null, claim: DayClaimed(current));
        }
        if (stale(current, now)) {
          final taken = current.makingBy(device);
          return (write: taken, claim: DayClaimed(taken));
        }
        return (write: null, claim: DayKept(current));
    }
  }

  /// Whether [day]'s making has gone [lease] without a change by [now].
  static bool stale(Day day, DateTime now) {
    final updatedAt = day.updatedAt;
    return day.status == DayStatus.making &&
        updatedAt != null &&
        !now.isBefore(updatedAt.add(lease));
  }
}
