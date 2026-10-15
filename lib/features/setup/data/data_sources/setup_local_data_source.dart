import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

abstract interface class SetupLocalDataSource {
  SetupStep getStep();
  Future<void> saveStep(SetupStep step);
}

class SetupLocalDataSourceImpl implements SetupLocalDataSource {
  SetupLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const stepKey = 'setup_step';

  @override
  SetupStep getStep() =>
      SetupStep.values.asNameMap()[_store.readString(stepKey)] ??
      SetupStep.welcome;

  @override
  Future<void> saveStep(SetupStep step) =>
      _store.writeString(stepKey, step.name);
}
