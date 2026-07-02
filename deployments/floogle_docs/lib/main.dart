import 'package:example/floogle_docs/floogle_docs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:floogle_docs/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  assert(() {
    SemanticsBinding.instance.ensureSemantics();
    return true;
  }());
  runApp(const FloogleDocsApp());
}
