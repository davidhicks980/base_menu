import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    assert(() {
      SemanticsBinding.instance.ensureSemantics();
      return true;
    }());
  }
  runApp(const App());
}
