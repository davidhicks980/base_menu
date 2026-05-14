import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'app_state_manager.dart';
import 'firebase_options.dart';
import 'model/enum.dart';
import 'toolbar.dart';
import 'utilities/colors.dart';
import 'widgets/action_reflector.dart';
import 'widgets/editor.dart';
import 'widgets/floogle_docs_logo.dart';
import 'widgets/menus/document_menu_bar.dart';
import 'widgets/title_field.dart';
import 'widgets/title_icon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  SemanticsBinding.instance.ensureSemantics();
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
        color: FloogleColors.grey,
        fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
      ),
      onGenerateRoute: (settings) {
        return PageRouteBuilder<void>(settings: settings, pageBuilder: _buildPage);
      },
      color: FloogleColors.surfaceColor,
    );
  }

  Widget _buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return const ActionReflector(child: AppStateManager(child: Main()));
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final WidgetOrderTraversalPolicy _headerTraversal = WidgetOrderTraversalPolicy();
  bool _isHeaderExpanded = true;
  bool _isHeaderVisible = true;

  void _handleHeaderAnimationEnd() {
    if (!_isHeaderExpanded) {
      setState(() {
        _isHeaderVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isHeaderExpanded = AppStateManager.isHeaderShownOf(context);
    if (_isHeaderExpanded) {
      _isHeaderVisible = true;
    }
    final child = IconTheme(
      data: const IconThemeData(
        size: 18,
        color: FloogleColors.grey,
        // Fonts look slightly anemic on web, so compensate with a heavier weight.
        weight: kIsWeb ? 550 : 400,
      ),
      child: ColoredBox(
        color: FloogleColors.surfaceColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FocusTraversalGroup(
              policy: _headerTraversal,
              child: AnimatedOpacity(
                opacity: _isHeaderExpanded ? 1 : 0,
                duration: const Duration(milliseconds: 100),
                onEnd: _handleHeaderAnimationEnd,
                child: Visibility(
                  visible: _isHeaderVisible,
                  maintainState: true,
                  child: SizedBox(
                    height: 62,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          top: _isHeaderExpanded ? 16 : 16 - 40,
                          left: 17,
                          duration: const Duration(milliseconds: 100),
                          child: const FloogleDocsLogoButton(),
                        ),
                        AnimatedPositioned(
                          top: _isHeaderExpanded ? 7 : 7 - 40,
                          left: 55,
                          duration: const Duration(milliseconds: 100),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            spacing: 3,
                            children: [
                              Flexible(child: TitleField()),
                              TitleIconButton(
                                tooltip: TextSpan(text: 'Star'),
                                child: Icon(Symbols.star_border, weight: kIsWeb ? 500 : 350),
                              ),
                              TitleIconButton(
                                tooltip: TextSpan(text: 'Add shortcut to drive'),
                                child: Icon(Symbols.add_to_drive),
                              ),
                              TitleIconButton(
                                tooltip: TextSpan(text: 'See document status'),
                                child: _CloudIcon(),
                              ),
                            ],
                          ),
                        ),

                        const Positioned(top: 34, left: 54, right: 0, child: DocumentMenuBar()),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 2, top: 2),
              child: Toolbar(),
            ),

            const Expanded(child: EditorView()),
          ],
        ),
      ),
    );

    return Builder(
      builder: (context) {
        final documentState = AppStateManager.documentStateOf(context);
        final isMenuAimAssistEnabled = documentState[SelectionKey.menuAimAssist] == true;
        final isMenuAimAssistDebugPaintEnabled =
            documentState[SelectionKey.menuAimAssistDebugPaint] == true;
        MenuAimListener.visualizeAim = isMenuAimAssistDebugPaintEnabled;
        return MenuAimScope(enable: isMenuAimAssistEnabled, child: child);
      },
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
