import 'dart:async';

import 'package:clock/clock.dart';
import 'package:in_vogue/core/data/errors/error_report_remote_data_source.dart';

/// The app a report comes from.
class ErrorReportOrigin {
  const ErrorReportOrigin({
    required this.flavor,
    required this.platform,
    required this.version,
    required this.build,
    required this.install,
  });

  /// "development" or "production".
  final String flavor;

  /// "android" or "ios".
  final String platform;

  /// Such as "1.0.0+7".
  final String version;

  /// "debug", "profile" or "release".
  final String build;

  /// The install id, the same in every report from one installation.
  final String install;

  Map<String, Object?> toJson() => {
    'flavor': flavor,
    'platform': platform,
    'version': version,
    'build': build,
    'install': install,
  };
}

/// Files error reports in Firestore for the person signed in, so testers'
/// errors reach the team. Each distinct error is filed once a run, at most
/// [perRun] in all; reports made while nobody is signed in wait for
/// someone. Filing never throws and never logs, so a report that fails
/// can't report itself.
class ErrorReports {
  ErrorReports({
    required this._remote,
    required Stream<String?> accounts,
    required this._origin,
  }) {
    _accounts = accounts.listen(_signedIn, onError: (Object _) {});
  }

  final ErrorReportRemoteDataSource _remote;
  final ErrorReportOrigin _origin;
  late final StreamSubscription<String?> _accounts;

  /// The most reports one run files.
  static const perRun = 50;

  /// The most reports kept while nobody is signed in.
  static const waitingLimit = 20;

  /// The longest stack filed, as the rules allow.
  static const stackLimit = 4000;

  String? _account;
  final _filed = <String>{};
  final _waiting = <Map<String, Object?>>[];

  /// Files the error [error] (its kind and code, never its message) that
  /// happened in [where].
  void add({
    required String where,
    required String error,
    StackTrace? stackTrace,
  }) {
    if (_filed.length >= perRun || !_filed.add('$where|$error')) return;
    final report = {
      'at': clock.now(),
      'where': _cut(where, 200),
      'error': _cut(error, 300),
      'stack': _cut(stackTrace?.toString() ?? '', stackLimit),
      ..._origin.toJson(),
    };
    final account = _account;
    if (account != null) {
      _send(report, account);
    } else if (_waiting.length < waitingLimit) {
      _waiting.add(report);
    }
  }

  /// Stops following who is signed in.
  Future<void> close() => _accounts.cancel();

  void _signedIn(String? account) {
    _account = account;
    if (account == null) return;
    for (final report in _waiting) {
      _send(report, account);
    }
    _waiting.clear();
  }

  void _send(Map<String, Object?> report, String account) {
    try {
      _remote.send({'account': account, ...report}).ignore();
    } on Object {
      // Dropped: a report must never fail the app.
    }
  }

  static String _cut(String text, int limit) =>
      text.length <= limit ? text : text.substring(0, limit);
}
