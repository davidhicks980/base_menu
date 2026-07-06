import 'package:base_menu_samples/app/app.dart';
import 'package:base_menu_samples_explorer/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SemanticsBinding.instance.ensureSemantics();
  runApp(const App());
}
