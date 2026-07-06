import 'package:flutter/widgets.dart';

import 'app/app.dart';

export 'app/app.dart' show App;
export 'floogle_docs/floogle_docs.dart' show FloogleDocsApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
