import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';

void main() {
  test('refreshes in the background at 05:30, before the morning change', () {
    expect(
      WidgetSchedule.untilRefresh(DateTime(2026, 10, 18, 5)),
      const Duration(minutes: 30),
    );
    expect(
      WidgetSchedule.untilRefresh(DateTime(2026, 10, 18, 7)),
      const Duration(hours: 22, minutes: 30),
    );
  });

  test('changes at 06:00, 09:00 and midnight, two days ahead', () {
    expect(WidgetSchedule.changesAfter(DateTime(2026, 10, 18, 7, 30)), [
      DateTime(2026, 10, 18, 9),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 19, 6),
      DateTime(2026, 10, 19, 9),
      DateTime(2026, 10, 20),
      DateTime(2026, 10, 20, 6),
    ]);
    expect(
      WidgetSchedule.changesAfter(DateTime(2026, 10, 18, 6)).first,
      DateTime(2026, 10, 18, 9),
      reason: 'a change at this very time is already shown',
    );
  });
}
