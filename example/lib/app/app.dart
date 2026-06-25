import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../floogle_docs/app.dart';
import '../floogle_docs/utilities/colors.dart';
import '../sequoia/app.dart';
import 'aliased_border.dart';

const _kLightBorderColor = Color.fromARGB(255, 121, 121, 121);
const _kDarkBorderColor = Color.fromARGB(255, 76, 76, 76);

enum Destination {
  simpleMenu(
    'Simple Menu',
    '/',
    icon: Icon(Symbols.list_alt),
    selectedIcon: Icon(Symbols.list_alt, fill: 1),
  ),
  floogleDocs(
    'Floogle Docs',
    '/floogle-docs',
    icon: Icon(Symbols.docs),
    selectedIcon: Icon(Symbols.docs, fill: 1),
  ),
  sequoia(
    'Sequoia',
    '/sequoia',
    icon: Icon(Symbols.temp_preferences_eco),
    selectedIcon: Icon(Symbols.temp_preferences_eco, fill: 1),
    brightness: .dark,
  );

  const Destination(
    this.label,
    this.route, {
    required this.icon,
    required this.selectedIcon,
    this.isDevelopment = false,
    this.brightness = Brightness.light,
  });

  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final bool isDevelopment;
  final Brightness brightness;

  /// Helper to find a destination based on the current route name.
  static Destination fromRoute(String? route) {
    return Destination.values.firstWhere(
      (d) => d.route == route,
      orElse: () => Destination.simpleMenu,
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isRTL = false;
  final bool _isDarkMode = false;
  double _textScaleFactor = 1.0;
  TextDirection get _textDirection => _isRTL ? TextDirection.rtl : TextDirection.ltr;
  Brightness get _brightness => _isDarkMode ? Brightness.dark : Brightness.light;

  @override
  Widget build(BuildContext context) {
    final app = Directionality(
      textDirection: _textDirection,
      child: MaterialApp(
        title: 'Menu Utilities Example',
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const _DisabledPageTransition(),
            },
          ),
        ),
        initialRoute: Destination.simpleMenu.route,
        routes: {
          for (final destination in Destination.values)
            destination.route: (context) => Builder(
              builder: (context) {
                final theme = ThemeData(
                  fontFamily: 'GoogleSans',

                  dividerTheme: DividerThemeData(
                    thickness: 1 / (MediaQuery.maybeDevicePixelRatioOf(context) ?? 1),
                    color: destination.brightness == Brightness.dark
                        ? _kDarkBorderColor
                        : _kLightBorderColor,
                  ),
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                      for (final platform in TargetPlatform.values)
                        platform: const _DisabledPageTransition(),
                    },
                  ),
                  brightness: destination.brightness,
                  colorScheme: destination.brightness == .dark
                      ? ColorScheme.fromSeed(
                          seedColor: const Color.fromARGB(255, 0, 119, 255),
                          brightness: Brightness.dark,
                        )
                      : ColorScheme.fromSeed(
                          seedColor: const Color.fromARGB(255, 66, 133, 244),
                          surfaceContainerLow: FloogleColors.surfaceColor,
                          surfaceContainerHigh: FloogleColors.elevatedSurfaceColor,
                          outlineVariant: FloogleColors.separatorColor,
                          onSurface: FloogleColors.grey,

                          secondaryContainer: FloogleColors.selectedButtonBackground,
                          onSecondaryContainer: FloogleColors.selectedButton,
                        ),
                  splashFactory: InkSparkle.splashFactory,
                  navigationDrawerTheme: const NavigationDrawerThemeData(tileHeight: 36),
                );
                return Theme(
                  data: theme,

                  child: _AppRouteWrapper(destination: destination, settings: _buildSettings()),
                );
              },
            ),
        },
      ),
    );
    return Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_textScaleFactor)),
          child: app,
        );
      },
    );
  }

  Settings _buildSettings() {
    return Settings(
      isRTL: _isRTL,
      setRTL: (value) => setState(() => _isRTL = value),

      textScaleFactor: _textScaleFactor,
      setTextScaleFactor: (value) => setState(() => _textScaleFactor = value),
    );
  }
}

/// A wrapper widget that applies the persistent [AppScaffold] to every route.
class _AppRouteWrapper extends StatelessWidget {
  const _AppRouteWrapper({required this.destination, required this.settings});

  final Destination destination;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (destination) {
      Destination.simpleMenu => const SizedBox.expand(),
      Destination.floogleDocs => const FloogleDocsApp(),
      Destination.sequoia => const SequoiaApp(),
    };

    return Theme(
      data: Theme.of(context).copyWith(brightness: destination.brightness),
      child: Builder(
        builder: (context) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Semantics(
              label: 'Menu Utilities Example',
              child: Title(
                title: 'Menu Utilities Example',
                color: Colors.black,
                child: AppScaffold(settings: settings, child: child),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.child, required this.settings});

  final Widget child;
  final Widget settings;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> with SingleTickerProviderStateMixin {
  bool showNavigationDrawer = true;
  bool disposeNavigationDrawer = false;

  int get _selectedIndex =>
      Destination.values.indexOf(Destination.fromRoute(ModalRoute.of(context)!.settings.name));

  void handleScreenChanged(int selectedScreen) {
    Navigator.pushReplacementNamed(context, Destination.values[selectedScreen].route);
  }

  void toggleDrawer() {
    setState(() {
      showNavigationDrawer = !showNavigationDrawer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(child: widget.child);
    return ColoredBox(
      color: ColorScheme.of(context).surfaceContainerLow,
      child: SafeArea(
        child: Center(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Builder(
                builder: (context) {
                  final size = MediaQuery.sizeOf(context);
                  final offset = showNavigationDrawer ? 250.0 : 50.0;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    left: offset + 4,
                    width: size.width - offset,
                    top: 0,
                    bottom: 0,
                    curve: Curves.easeOutQuint,
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(size: Size(size.width - offset, size.height)),
                      child: child,
                    ),
                  );
                },
              ),
              AnimatedPositioned(
                left: showNavigationDrawer ? -50 : -250,
                width: 300,
                top: 0,
                bottom: 0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuint,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: AliasedBorder(
                      right: BorderSide(color: ColorScheme.of(context).outlineVariant),
                    ),
                  ),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: AlignmentDirectional.topStart,
                      fit: OverflowBoxFit.deferToChild,
                      maxWidth: 300,
                      minWidth: 0,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutQuint,
                              opacity: showNavigationDrawer ? 1 : 0,
                              child: FocusTraversalGroup(
                                descendantsAreTraversable: showNavigationDrawer,
                                descendantsAreFocusable: showNavigationDrawer,
                                child: _Drawer(
                                  onDestinationSelected: handleScreenChanged,
                                  selectedIndex: _selectedIndex,
                                  settings: widget.settings,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            height: 50,
                            width: 50,
                            right: 0,
                            child: Center(
                              child: MenuButton(
                                isOpen: showNavigationDrawer,
                                onPressed: toggleDrawer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({required this.onDestinationSelected, required this.selectedIndex, this.settings});
  final void Function(int) onDestinationSelected;
  final int selectedIndex;
  final Widget? settings;

  @override
  Widget build(BuildContext context) {
    final dividerTheme = DividerTheme.of(context);
    return MediaQuery.withNoTextScaling(
      child: DefaultTextStyle.merge(
        child: ColoredBox(
          color: ColorScheme.of(context).surfaceContainerLow,
          child: NavigationDrawer(
            onDestinationSelected: onDestinationSelected,
            selectedIndex: selectedIndex,
            backgroundColor: Colors.transparent,

            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(64, 16, 16, 10),
                child: Text(
                  'Menu Utilities',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(64, 16, 16, 10),
                child: Text('Documentation', style: TextTheme.of(context).titleMedium),
              ),
              for (final destination in Destination.values.where(
                (destination) => !destination.isDevelopment,
              ))
                NavigationDrawerDestination(
                  backgroundColor: Colors.transparent,
                  label: Text(destination.label),
                  icon: Padding(padding: const EdgeInsets.only(left: 36), child: destination.icon),
                  selectedIcon: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: destination.selectedIcon,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(64, 16, 16, 10),
                child: Text('Development', style: TextTheme.of(context).titleMedium),
              ),
              for (final destination in Destination.values.where(
                (destination) => destination.isDevelopment,
              ))
                NavigationDrawerDestination(
                  backgroundColor: Colors.transparent,
                  label: Text(destination.label, style: TextTheme.of(context).bodyMedium),
                  icon: Padding(padding: const EdgeInsets.only(left: 36), child: destination.icon),
                  selectedIcon: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: destination.selectedIcon,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(70, 16, 28, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: AliasedBorder(
                      bottom: BorderSide(color: ColorScheme.of(context).outlineVariant),
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(68, 16, 28, 10), child: settings),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.isOpen, required this.onPressed});

  final bool isOpen;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        iconSize: 24,
        constraints: BoxConstraints.tight(const Size(56, 56)),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        splashColor: Colors.transparent,
        color: Colors.transparent,
        icon: Icon(
          isOpen ? Symbols.menu_open_rounded : Symbols.menu_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DisabledPageTransition extends PageTransitionsBuilder {
  /// Constructs a page transition animation that matches the iOS transition.
  const _DisabledPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class Settings extends StatelessWidget {
  const Settings({
    super.key,
    required this.isRTL,
    required this.setRTL,
    required this.textScaleFactor,
    required this.setTextScaleFactor,
  });
  final bool isRTL;
  final ValueSetter<bool> setRTL;

  final double textScaleFactor;
  final ValueSetter<double> setTextScaleFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: FontWeight.w500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setRTL(!isRTL);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Right-to-left'),
                  Switch(value: isRTL, onChanged: setRTL),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text('Text scale')),
                Flexible(
                  child: Slider(value: textScaleFactor, onChanged: setTextScaleFactor, max: 3),
                ),
              ],
            ),
            Text(
              'Text scale: ${textScaleFactor.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(letterSpacing: -0.21, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
