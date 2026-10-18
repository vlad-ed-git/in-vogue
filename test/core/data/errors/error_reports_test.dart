import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/error_report_remote_data_source.dart';
import 'package:in_vogue/core/data/errors/error_reports.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/data/errors/uncaught_errors.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';

class _FakeRemote implements ErrorReportRemoteDataSource {
  final sent = <Map<String, Object?>>[];
  Object? failure;

  @override
  Future<void> send(Map<String, Object?> report) async {
    if (failure case final Object failure) throw failure;
    sent.add(report);
  }
}

class _RecordingLog implements LogMessages {
  final logged = <(String, String, Object)>[];

  @override
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  }) => logged.add((callerClass, callerMethod, error));
}

const _origin = ErrorReportOrigin(
  flavor: 'development',
  platform: 'ios',
  version: '1.0.0+7',
  build: 'release',
  install: 'install-1',
);

void main() {
  late _FakeRemote remote;
  late StreamController<String?> accounts;
  late ErrorReports reports;
  final at = DateTime.utc(2026, 10, 18, 9, 30);

  setUp(() {
    remote = _FakeRemote();
    accounts = StreamController<String?>();
    reports = ErrorReports(
      remote: remote,
      accounts: accounts.stream,
      origin: _origin,
    );
  });

  tearDown(() async {
    await reports.close();
    await accounts.close();
  });

  Future<void> signIn([String? account = 'uid-1']) async {
    accounts.add(account);
    await pumpEventQueue();
  }

  void report(String where, {String error = 'StateError', String? stack}) =>
      withClock(
        Clock.fixed(at),
        () => reports.add(
          where: where,
          error: error,
          stackTrace: stack == null ? null : StackTrace.fromString(stack),
        ),
      );

  test('files a report for the person signed in: where, what, when, the '
      'stack and the app', () async {
    await signIn();
    report(
      'DayRepositoryImpl.watch',
      error: 'FirebaseException cloud_firestore/unavailable',
      stack: '#0 main (package:in_vogue/main.dart:1)',
    );
    await pumpEventQueue();
    expect(remote.sent, [
      {
        'account': 'uid-1',
        'at': at,
        'where': 'DayRepositoryImpl.watch',
        'error': 'FirebaseException cloud_firestore/unavailable',
        'stack': '#0 main (package:in_vogue/main.dart:1)',
        'flavor': 'development',
        'platform': 'ios',
        'version': '1.0.0+7',
        'build': 'release',
        'install': 'install-1',
      },
    ]);
  });

  test('keeps the reports made before sign-in until someone signs in, and '
      'again after sign-out', () async {
    report('LocationRepositoryImpl.locate');
    await pumpEventQueue();
    expect(remote.sent, isEmpty);
    await signIn();
    expect(remote.sent.single['account'], 'uid-1');
    expect(remote.sent.single['where'], 'LocationRepositoryImpl.locate');

    await signIn(null);
    report('WeatherRepositoryImpl.report');
    await pumpEventQueue();
    expect(remote.sent, hasLength(1));
    await signIn('uid-2');
    expect(remote.sent.last['account'], 'uid-2');
  });

  test('files each error once a run, and at most ${ErrorReports.perRun} in '
      'all', () async {
    await signIn();
    report('A.b');
    report('A.b');
    report('A.b', error: 'TypeError');
    await pumpEventQueue();
    expect(remote.sent, hasLength(2));
    for (var i = 0; i < 100; i++) {
      report('A.c$i');
    }
    await pumpEventQueue();
    expect(remote.sent, hasLength(ErrorReports.perRun));
  });

  test('cuts long fields and stacks to what the rules take', () async {
    await signIn();
    report('A.${'x' * 300}', error: 'E' * 400, stack: 'frame\n' * 2000);
    await pumpEventQueue();
    final sent = remote.sent.single;
    expect((sent['where']! as String).length, 200);
    expect((sent['error']! as String).length, 300);
    expect(
      (sent['stack']! as String).length,
      lessThanOrEqualTo(ErrorReports.stackLimit),
    );
  });

  test('a report that cannot be filed is dropped quietly', () async {
    await signIn();
    remote.failure = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    report('A.b');
    await pumpEventQueue();
    expect(remote.sent, isEmpty);
  });

  group('LogMessagesImpl', () {
    test('reports where an error happened and its kind and code, never its '
        'message', () async {
      await signIn();
      LogMessagesImpl(reports: reports)
        ..logError(
          callerClass: 'DayRepositoryImpl',
          callerMethod: 'watch',
          error: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'maya@example.com',
          ),
        )
        ..logError(
          callerClass: 'PhotoRepositoryImpl',
          callerMethod: 'keep',
          error: StateError('/photos/maya.jpg'),
        );
      await pumpEventQueue();
      expect(
        [for (final sent in remote.sent) (sent['where'], sent['error'])],
        [
          (
            'DayRepositoryImpl.watch',
            'FirebaseException cloud_firestore/unavailable',
          ),
          ('PhotoRepositoryImpl.keep', 'StateError'),
        ],
      );
      expect(remote.sent.toString(), isNot(contains('maya')));
    });

    test('without reports, it only writes to the console', () {
      expect(
        () => const LogMessagesImpl().logError(
          callerClass: 'A',
          callerMethod: 'b',
          error: StateError('x'),
        ),
        returnsNormally,
      );
    });
  });

  test("uncaught errors, the framework's and the platform's, are logged "
      'too', () {
    final framework = FlutterError.onError;
    final platform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = framework;
      PlatformDispatcher.instance.onError = platform;
    });
    FlutterError.onError = (_) {};
    final log = _RecordingLog();
    reportUncaughtErrors(log);
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('build'),
        library: 'widgets library',
      ),
    );
    expect(
      PlatformDispatcher.instance.onError!(
        StateError('async'),
        StackTrace.empty,
      ),
      isTrue,
    );
    expect(
      [for (final (where, how, _) in log.logged) '$where.$how'],
      ['Flutter.widgets library', 'Uncaught.error'],
    );
  });
}
