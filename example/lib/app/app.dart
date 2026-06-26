import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../floogle_docs/app.dart';
import '../floogle_docs/utilities/colors.dart';
import '../menubar/app.dart';
import '../popup/app.dart';
import '../sequoia/app.dart';
import 'aliased_border.dart';

const _kLightBorderColor = Color.fromARGB(255, 121, 121, 121);
const _kDarkBorderColor = Color.fromARGB(255, 76, 76, 76);

enum Destination {
  popup('Popup', '/', icon: Icon(Symbols.list_alt), selectedIcon: Icon(Symbols.list_alt, fill: 1)),
  menuBar(
    'Menu Bar',
    '/menu-bar',
    icon: Icon(Symbols.list_alt),
    selectedIcon: Icon(Symbols.list_alt, fill: 1),
  ),
  aim('Aim', '/aim', icon: Icon(Symbols.list_alt), selectedIcon: Icon(Symbols.list_alt, fill: 1)),

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
    this.brightness = Brightness.light,
  });

  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final Brightness brightness;

  /// Helper to find a destination based on the current route name.
  static Destination fromRoute(String? route) {
    return Destination.values.firstWhere((d) => d.route == route, orElse: () => Destination.popup);
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final bool _isRTL = false;
  final bool _isDarkMode = false;
  final double _textScaleFactor = 1.0;
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
        initialRoute: Destination.popup.route,
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
                  navigationDrawerTheme: NavigationDrawerThemeData(
                    tileHeight: 36,
                    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    indicatorColor: destination.brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: 14,
                        fontFamily: 'GoogleSans',
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (destination.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                            : (destination.brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.7)),
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 24,
                        color: isSelected
                            ? (destination.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                            : (destination.brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.7)),
                      );
                    }),
                  ),
                );
                return Theme(
                  data: theme,
                  child: _AppRouteWrapper(destination: destination),
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
}

/// A wrapper widget that applies the persistent [AppScaffold] to every route.
class _AppRouteWrapper extends StatelessWidget {
  const _AppRouteWrapper({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (destination) {
      Destination.popup => const PopupApp(),
      Destination.menuBar => const MenuBarApp(),
      Destination.aim => const SizedBox(),
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
                child: AppScaffold(child: child),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

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
                  return Positioned(
                    left: offset,
                    width: size.width - offset,
                    top: 0,
                    bottom: 0,
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
  const _Drawer({required this.onDestinationSelected, required this.selectedIndex});
  final void Function(int) onDestinationSelected;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(64, 12, 16, 0),
                child: Text(
                  'Menu Utilities',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const _DrawerHeader(title: 'EXAMPLES'),
              for (final destination in Destination.values)
                NavigationDrawerDestination(
                  backgroundColor: Colors.transparent,
                  label: Text(destination.label),
                  icon: Padding(padding: const EdgeInsets.only(left: 36), child: destination.icon),
                  selectedIcon: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: destination.selectedIcon,
                  ),
                ),
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}
