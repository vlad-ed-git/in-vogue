abstract interface class HomeWidgetRepository {
  /// Asks the launcher to place the widget; false when it cannot.
  Future<bool> requestPin();
}
