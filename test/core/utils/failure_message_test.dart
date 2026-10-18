import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/utils/failure_message.dart';

import '../../helpers/pump_in_vogue.dart';

void main() {
  Future<String> messageOf(WidgetTester tester, Failure failure) async {
    late String message;
    await pumpInVogue(
      tester,
      Builder(
        builder: (context) {
          message = failure.uiFriendlyMessage(context);
          return const SizedBox.shrink();
        },
      ),
    );
    return message;
  }

  testWidgets('a photo YouCam refused says what to change', (tester) async {
    expect(
      await messageOf(
        tester,
        const AnalysisFailure(
          AnalysisProblem.photo,
          advice: PhotoAdvice.lookStraight,
        ),
      ),
      'Your face is turned or tilted in this photo. Choose one where you '
      'look straight ahead.',
    );
    expect(
      await messageOf(
        tester,
        const AnalysisFailure(
          AnalysisProblem.photo,
          advice: PhotoAdvice.moveCloser,
        ),
      ),
      'Your face is too small in this photo. Choose a closer one.',
    );
    expect(
      await messageOf(
        tester,
        const TryOnFailure(TryOnProblem.photo, advice: PhotoAdvice.onlyYou),
      ),
      'There’s more than one person in this photo. Choose one of just you.',
    );
  });

  testWidgets('never says the photo is fine when the photo is the problem', (
    tester,
  ) async {
    for (final advice in [null, ...PhotoAdvice.values]) {
      for (final failure in [
        AnalysisFailure(AnalysisProblem.photo, advice: advice),
        TryOnFailure(TryOnProblem.photo, advice: advice),
      ]) {
        expect(
          await messageOf(tester, failure),
          isNot(contains('Your photo is fine')),
          reason: '$failure',
        );
      }
    }
  });
}
