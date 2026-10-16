import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';

/// The home-screen widget before it is built: it cannot be placed.
class UnavailableHomeWidgetRepository implements HomeWidgetRepository {
  const UnavailableHomeWidgetRepository();

  @override
  Future<bool> requestPin() async => false;
}
