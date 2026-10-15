import 'package:in_vogue/app/bootstrap.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/firebase_options_development.dart';

Future<void> main() => bootstrap(
  environment: AppEnvironment.development,
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
);
