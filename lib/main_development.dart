import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_vogue/app/bootstrap.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/config/development_keys.dart';
import 'package:in_vogue/firebase_options_development.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(
    environment: AppEnvironment.development,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    youCamApiKey: await DevelopmentKeys.youCam(rootBundle),
  );
}
