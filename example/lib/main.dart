import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_state_manager.dart';
import 'firebase_options.dart';
import 'toolbar.dart';
import 'widgets/action_reflector.dart';
import 'widgets/editor.dart';
import 'widgets/floogle_docs_logo.dart';
import 'widgets/menus/document_menu_bar.dart';
import 'widgets/title_field.dart';
import 'widgets/title_icon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      textStyle: const TextStyle(
        fontFamily: 'RobotoFlex',
        color: Color.fromRGBO(68, 71, 70, 1),
        fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
      ),
      onGenerateRoute: (settings) {
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return IconTheme.merge(
                  data: const IconThemeData(
                    size: 18,
                    color: Color.fromRGBO(68, 71, 70, 1),
                    // Fonts look slightly anemic on web, so compensate with a heavier weight.
                    weight: kIsWeb ? 550 : 400,
                  ),
                  child: const ActionReflector(child: AppStateManager(child: Main())),
                );
              },
        );
      },
      color: const Color(0xFFF8FAFD),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    value: 1,
  );
  bool _isHeaderShown = true;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      setState(() {
        _isHeaderShown = !_controller.isDismissed;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool isHeaderShown = AppStateManager.isHeaderShownOf(context);
    if (isHeaderShown != _controller.isForwardOrCompleted) {
      if (isHeaderShown) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_isHeaderShown)
            FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: FadeTransition(
                opacity: _controller,
                child: MatrixTransition(
                  animation: _controller,
                  onTransform: (double animationValue) {
                    return Matrix4.translationValues(0, -30 * (1 - animationValue), 0);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(17, 15, 3, 0),
                        child: FloogleDocsLogoButton(),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              const Positioned(
                                top: 6,
                                left: 1,
                                right: 0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 3,
                                  children: [
                                    Flexible(child: TitleField()),
                                    TitleIconButton(
                                      child: Icon(Symbols.star_border, weight: kIsWeb ? 500 : 350),
                                    ),
                                    TitleIconButton(child: Icon(Symbols.add_to_drive)),
                                    TitleIconButton(child: _CloudIcon()),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 32,
                                left: 0,
                                right: 0,
                                child: MatrixTransition(
                                  animation: _controller,
                                  onTransform: (animationValue) {
                                    return Matrix4.translationValues(
                                      0,
                                      30 * (1 - animationValue),
                                      0,
                                    );
                                  },
                                  child: const DocumentMenuBar(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 4),
            child: Toolbar(),
          ),
          const Expanded(child: EditorView()),
        ],
      ),
    );
  }
}

class _CloudIcon extends StatelessWidget {
  const _CloudIcon();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Symbols.cloud, opticalSize: 20, size: 20, weight: kIsWeb ? 350 : 250),
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Symbols.check, opticalSize: 20, size: 10, weight: kIsWeb ? 800 : 600),
        ),
      ],
    );
  }
}
