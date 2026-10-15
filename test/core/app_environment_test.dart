import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/config/app_environment.dart';

void main() {
  for (final environment in AppEnvironment.values) {
    test(
      '${environment.name} accepts its native flavor and Firebase project',
      () {
        expect(
          () => environment.validate(
            nativeFlavor: environment.name,
            projectId: environment.firebaseProjectId,
          ),
          returnsNormally,
        );
      },
    );
    test(
      '${environment.name} rejects a missing or mismatched native flavor',
      () {
        for (final flavor in [
          null,
          'unknown',
          ...AppEnvironment.values
              .where((value) => value != environment)
              .map((value) => value.name),
        ]) {
          expect(
            () => environment.validate(
              nativeFlavor: flavor,
              projectId: environment.firebaseProjectId,
            ),
            throwsStateError,
          );
        }
      },
    );
    test('${environment.name} rejects the other Firebase project', () {
      expect(
        () => environment.validate(
          nativeFlavor: environment.name,
          projectId: AppEnvironment.values
              .firstWhere((value) => value != environment)
              .firebaseProjectId,
        ),
        throwsStateError,
      );
    });
  }
}
