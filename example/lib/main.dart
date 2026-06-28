import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'firebase_options.dart';
import 'testapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    assert(() {
      SemanticsBinding.instance.ensureSemantics();
      return true;
    }());
  }
  runApp(const TestApp());
}
