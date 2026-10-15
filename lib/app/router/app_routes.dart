import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

/// Paths of the app's screens.
///
/// Each setup step's path nests in the path of the step before it, so a
/// reopened step has the earlier steps beneath it and Back returns to them.
abstract final class AppRoutes {
  static const home = '/home';
  static const makeup = '/makeup';
  static const settings = '/settings';

  /// Path segment of each setup step, in order.
  static const _segments = <SetupStep, String>{
    SetupStep.welcome: 'setup',
    SetupStep.photo: 'photo',
    SetupStep.firstOutfit: 'outfit',
    SetupStep.picks: 'picks',
    SetupStep.signIn: 'sign-in',
    SetupStep.name: 'name',
    SetupStep.facePhoto: 'face',
    SetupStep.widget: 'widget',
    SetupStep.widgetSteps: 'steps',
  };

  static final Map<SetupStep, String> _paths = () {
    final paths = <SetupStep, String>{};
    var path = '';
    for (final MapEntry(key: step, value: segment) in _segments.entries) {
      path = '$path/$segment';
      paths[step] = path;
    }
    return paths;
  }();

  static final Map<String, SetupStep> _steps = {
    for (final MapEntry(key: step, value: path) in _paths.entries) path: step,
  };

  /// Setup steps that have a screen, in order.
  static Iterable<SetupStep> get setupSteps => _segments.keys;

  /// The last segment of [step]'s path.
  static String segment(SetupStep step) => _segments[step]!;

  /// The path of [step]'s screen; Home once setup is done.
  static String forStep(SetupStep step) => _paths[step] ?? home;

  /// The setup step whose screen is at [path].
  static SetupStep? stepAt(String path) => _steps[path];

  /// Whether [path] is a setup screen.
  static bool isSetup(String path) => _steps.containsKey(path);

  static String forTab(InVogueTab tab) => switch (tab) {
    InVogueTab.home => home,
    InVogueTab.makeup => makeup,
    InVogueTab.settings => settings,
  };
}
