/// The units spent and their limit.
abstract final class UnitBudgetModel {
  /// The development budget, in units.
  static const developmentLimit = 30;

  /// Whether [units] more fit in [limit] after [spent].
  static bool allows({
    required int spent,
    required int limit,
    required int units,
  }) => units > 0 && spent + units <= limit;
}
