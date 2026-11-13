import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';

void main() {
  test('starts shortly after onboarding and refreshes throughout the day', () {
    expect(
      WidgetSchedule.untilRefresh(DateTime(2026, 10, 18, 7)),
      const Duration(minutes: 15),
    );
    expect(WidgetSchedule.refreshEvery, const Duration(hours: 6));
  });

  test('redraws at six local midnights even without a network refresh', () {
    expect(WidgetSchedule.changesAfter(DateTime(2026, 10, 18, 7, 30)), [
      for (var day = 19; day <= 24; day++) DateTime(2026, 10, day),
    ]);
    expect(
      WidgetSchedule.changesAfter(DateTime(2026, 12, 31)).first,
      DateTime(2027),
    );
  });
}
