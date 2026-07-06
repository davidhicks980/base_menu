// ignore_for_file: unused_element_parameter

import 'package:base_menu/base_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../shared/package.dart';
import 'src/model/enum.dart';
import 'src/theme/colors.dart';
import 'src/widgets/action_reflector.dart';
import 'src/widgets/app_state_manager.dart';
import 'src/widgets/editor.dart';
import 'src/widgets/floogle_docs_logo.dart';
import 'src/widgets/menus/document_menu_bar.dart';
import 'src/widgets/title_field.dart';
import 'src/widgets/title_icon.dart';
import 'src/widgets/toolbar.dart';
import 'src/widgets/tooltip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const _App(FloogleDocsApp()));
}

class FloogleDocsApp extends StatefulWidget {
  const FloogleDocsApp({super.key});
  @override
  State<FloogleDocsApp> createState() => _FloogleDocsAppState();
}

class _FloogleDocsAppState extends State<FloogleDocsApp> {
  late final SemanticsHandle _semanticsHandle;

  @override
  void initState() {
    super.initState();
    _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void dispose() {
    _semanticsHandle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const DefaultTextStyle(
      style: TextStyle(
        fontFamily: 'RobotoFlex',
        fontFamilyFallback: ['InterVariable'],
        package: kPackage,
        color: FloogleColors.grey,
        fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.w400,
      ),
      child: ActionReflector(child: AppStateManager(child: _Body())),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
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
    final child = MenuTooltipScope(
      child: IconTheme(
        data: const IconThemeData(
          size: 18,
          color: FloogleColors.grey,
          // Fonts look slightly anemic on web, so compensate with a heavier weight.
          weight: kIsWeb ? 550 : 400,
        ),
        child: TapRegionSurface(
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
                            AnimatedPositionedDirectional(
                              top: _isHeaderExpanded ? 16 : 16 - 40,
                              start: 17,
                              duration: const Duration(milliseconds: 100),
                              child: const FloogleDocsLogoButton(),
                            ),
                            AnimatedPositionedDirectional(
                              top: _isHeaderExpanded ? 7 : 7 - 40,
                              start: 55,
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
                                    tooltip: TextSpan(text: 'Document status: Saved to Drive'),
                                    child: _CloudIcon(),
                                  ),
                                ],
                              ),
                            ),

                            const PositionedDirectional(
                              top: 34,
                              start: 54,
                              end: 0,
                              child: DocumentMenuBar(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 2, top: 2),
                  child: Toolbar(),
                ),

                const Expanded(child: EditorView()),
              ],
            ),
          ),
        ),
      ),
    );

    return Builder(
      builder: (context) {
        final documentState = AppStateManager.documentStateOf(context);
        final isMenuAimAssistEnabled = documentState[SelectionKey.menuAimAssist] == true;
        final isMenuAimAssistDebugPaintEnabled =
            documentState[SelectionKey.menuAimAssistDebugPaint] == true;
        MenuAimInterceptor.visualizeAim = isMenuAimAssistDebugPaintEnabled;
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

class _App extends StatefulWidget {
  const _App(
    this.child, {
    super.key,
    this.textDirection,
    this.alignment = Alignment.center,
    this.actions,
    this.shortcuts,
    this.backgroundColor = const Color(0xff000000),
  });
  final Widget child;
  final TextDirection? textDirection;
  final AlignmentGeometry alignment;
  final Map<Type, Action<Intent>>? actions;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Color backgroundColor;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  TextDirection? _directionality;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _directionality = Directionality.maybeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: FocusScope(
        autofocus: true,
        child: WidgetsApp(
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          actions: widget.actions ?? WidgetsApp.defaultActions,
          shortcuts: widget.shortcuts ?? WidgetsApp.defaultShortcuts,
          color: widget.backgroundColor,
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(settings: settings, pageBuilder: _buildPage);
          },
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Directionality(
      textDirection: widget.textDirection ?? _directionality ?? TextDirection.ltr,
      child: Align(alignment: widget.alignment, child: widget.child),
    );
  }
}
