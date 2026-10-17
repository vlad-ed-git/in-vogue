import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/account/data/models/account_model.dart';

void main() {
  final rules = File('firestore.rules').readAsStringSync();

  test('a new account may start only on the plan the app gives it', () {
    final plans = RegExp(
      r"request\.resource\.data\.plan == '(\w+)'",
    ).allMatches(rules).map((match) => match[1]);
    expect(plans, [AccountModel.demoPlan]);
  });

  test('an update cannot change the plan', () {
    expect(rules, contains("affectedKeys().hasAny(['plan'])"));
  });
}
