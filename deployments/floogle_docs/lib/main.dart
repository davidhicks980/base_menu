import 'package:base_menu_demo/floogle_docs/floogle_docs.dart' as floogle_docs;
import 'package:firebase_core/firebase_core.dart';
import 'package:floogle_docs/firebase_options.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SemanticsBinding.instance.ensureSemantics();
  floogle_docs.main();
}
