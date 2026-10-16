import 'dart:async';

/// Updates broadcast to every listener, each new listener getting the
/// latest one first; after [close], new listeners get only the last one.
class LatestUpdates<T> {
  final _updates = StreamController<T>.broadcast(sync: true);
  T? _latest;
  bool _closed = false;

  void add(T update) {
    _latest = update;
    _updates.add(update);
  }

  void close() {
    _closed = true;
    unawaited(_updates.close());
  }

  Stream<T> watch() => Stream.multi((listener) {
    final latest = _latest;
    if (latest != null) listener.addSync(latest);
    if (_closed) return listener.closeSync();
    final subscription = _updates.stream.listen(
      listener.addSync,
      onDone: listener.closeSync,
    );
    listener.onCancel = subscription.cancel;
  });
}
