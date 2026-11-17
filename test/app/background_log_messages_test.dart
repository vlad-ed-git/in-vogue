import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/app/background_log_messages.dart';
import 'package:in_vogue/core/data/errors/error_report_remote_data_source.dart';
import 'package:in_vogue/core/data/errors/error_reports.dart';

class _FakeRemote implements ErrorReportRemoteDataSource {
  final sent = <Map<String, Object?>>[];

  @override
  Future<void> send(Map<String, Object?> report) async => sent.add(report);
}

void main() {
  test('files errors once its reports are set, as the background\'s', () async {
    final remote = _FakeRemote();
    final log = BackgroundLogMessages()
      ..logError(
        callerClass: 'WeatherRepositoryImpl',
        callerMethod: 'forecast',
        error: StateError('before Firebase'),
      );
    log.reports = ErrorReports(
      remote: remote,
      accounts: Stream.value('uid-1'),
      origin: const ErrorReportOrigin(
        flavor: 'development',
        platform: 'ios',
        version: '1.0.0+7',
        build: 'release',
        install: 'install-1',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    log.logError(
      callerClass: 'WeatherRepositoryImpl',
      callerMethod: 'forecast',
      error: TimeoutException('after Firebase'),
    );
    expect(remote.sent, hasLength(1));
    expect(remote.sent.single, containsPair('account', 'uid-1'));
    expect(
      remote.sent.single,
      containsPair('where', 'background WeatherRepositoryImpl.forecast'),
    );
    expect(remote.sent.single, containsPair('error', 'TimeoutException'));
  });
}
