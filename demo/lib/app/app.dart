import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../checkbox_menu_item/checkbox_menu_item_app.dart';
import '../floogle_docs/floogle_docs.dart';
import '../floogle_docs/src/theme/colors.dart';
import '../menu/menu_app.dart';
import '../menubar/menubar_app.dart';
import '../positioning/positioning_app.dart';
import '../sequoia/sequoia_app.dart';
import '../shared/base_menu_app.dart';
import '../shared/browser_context_menu_blocker.dart';
import '../shared/package.dart';
import '../shared/separator.dart';
import '../shared/theme.dart';
import '../submenu/submenu_app.dart';
import 'src/navigation_menu.dart';

enum AppSection {
  api('INTERFACE'),
  examples('EXAMPLES');

  const AppSection(this.label);
  final String label;
}

enum AppDestination {
  menu(
    'BaseMenu',
    '/',
    icon: Icon(Symbols.list_alt),
    selectedIcon: Icon(Symbols.list_alt, fill: 1),
    section: AppSection.api,
  ),
  submenu(
    'BaseSubmenu',
    '/submenu',
    icon: Icon(Symbols.stack),
    selectedIcon: Icon(Symbols.stack, fill: 1),
    section: AppSection.api,
  ),
  menuBar(
    'BaseMenuBar',
    '/menubar',
    icon: Icon(Symbols.view_sidebar),
    selectedIcon: Icon(Symbols.view_sidebar, fill: 1),
    section: AppSection.api,
  ),
  menuItem(
    'BaseMenuItem',
    '/menuitem',
    icon: Icon(Symbols.checklist),
    selectedIcon: Icon(Symbols.checklist, fill: 1),
    section: AppSection.api,
  ),
  positioning(
    'Positioning',
    '/positioning',
    icon: Icon(Symbols.flip),
    selectedIcon: Icon(Symbols.flip, fill: 1),
    section: AppSection.api,
  ),
  floogleDocs(
    'Floogle Docs',
    '/floogledocs',
    icon: Icon(Symbols.docs),
    selectedIcon: Icon(Symbols.docs, fill: 1),
    section: AppSection.examples,
  ),
  sequoia(
    'Sequoia',
    '/sequoia',
    icon: Icon(Symbols.temp_preferences_eco),
    selectedIcon: Icon(Symbols.temp_preferences_eco, fill: 1),
    brightness: .dark,
    section: AppSection.examples,
  );

  const AppDestination(
    this.label,
    this.route, {
    required this.icon,
    required this.selectedIcon,
    required this.section,
    this.brightness = Brightness.light,
  });

  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final Brightness brightness;
  final AppSection section;

  /// Helper to find a destination based on the current route name.
  static AppDestination fromRoute(String? route) {
    return AppDestination.values.firstWhere(
      (d) => d.route == route,
      orElse: () => AppDestination.menu,
    );
  }
}

class AppColorScheme extends InheritedWidget {
  const AppColorScheme({super.key, required super.child, required this.colorScheme});
  final ColorScheme colorScheme;

  static ColorScheme of(BuildContext context) {
    final ColorScheme? result = context
        .dependOnInheritedWidgetOfExactType<AppColorScheme>()
        ?.colorScheme;
    assert(result != null, 'No AppColorScheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppColorScheme oldWidget) {
    return colorScheme != oldWidget.colorScheme;
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
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
    return ContextMenuBlocker(
      child: BaseMenuApp(
        title: 'Base Menu Library',
        initialRoute: AppDestination.menu.route,
        routes: {
          for (final destination in AppDestination.values)
            destination.route: (context) => _AppRouteWrapper(
              destination: destination,
              child: switch (destination) {
                AppDestination.menu => const MenuApp(),
                AppDestination.menuBar => const MenuBarApp(),
                AppDestination.submenu => const SubmenuApp(),
                AppDestination.floogleDocs => const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: FloogleDocsApp(),
                ),
                AppDestination.positioning => const PositioningApp(),
                AppDestination.sequoia => const SequoiaApp(),
                AppDestination.menuItem => const CheckboxMenuItemApp(),
              },
            ),
        },
      ),
    );
  }
}

/// A wrapper widget that applies the persistent [AppScaffold] to every route.
class _AppRouteWrapper extends StatelessWidget {
  const _AppRouteWrapper({required this.child, required this.destination});

  final AppDestination destination;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppColorScheme(
      colorScheme: destination.brightness == Brightness.dark
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
              primaryContainer: FloogleColors.selectedButtonBackground,
              onPrimaryContainer: FloogleColors.selectedButton,
            ),
      child: Builder(
        builder: (context) {
          return DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'InterVariable',
              package: kPackage,
              color: AppColorScheme.of(context).onSurface,
            ),
            child: ColoredBox(
              color: AppColorScheme.of(context).surfaceContainerLow,
              child: Title(
                title: 'Base Menu Library - ${destination.label}',
                color: AppColorScheme.of(context).onSurface,
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

  void toggleDrawer() {
    setState(() {
      showNavigationDrawer = !showNavigationDrawer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(child: widget.child);
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: ColoredBox(
        color: AppColorScheme.of(context).surfaceContainerLow,
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedPositioned(
                left: showNavigationDrawer ? 0 : -198,
                width: 250,
                top: 0,
                bottom: 0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuint,
                child: ColoredBox(
                  color: AppColorScheme.of(context).brightness == Brightness.light
                      ? const Color.fromARGB(4, 28, 27, 31)
                      : kTransparent,
                  child: Row(
                    children: [
                      Flexible(
                        child: CustomScrollView(
                          slivers: [
                            PinnedHeaderSliver(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                          child: Text(
                                            'Base Menu',
                                            style: TextStyle(
                                              fontVariations: const [FontVariation.weight(800)],
                                              letterSpacing: -0.5,
                                              fontSize: 24,
                                              fontFamily: 'InterVariable',
                                              package: kPackage,
                                              color: AppColorScheme.of(context).onSurface,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.only(end: 1),
                                          child: MenuButton(
                                            isOpen: showNavigationDrawer,
                                            onPressed: toggleDrawer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SliverToBoxAdapter(
                              child: ExcludeFocus(
                                excluding: !showNavigationDrawer,
                                child: ExcludeSemantics(
                                  excluding: !showNavigationDrawer,
                                  child: IgnorePointer(
                                    ignoring: !showNavigationDrawer,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuint,
                                      opacity: showNavigationDrawer ? 1 : 0,
                                      child: const _Sidenav(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Separator.vertical(
                        color: AppColorScheme.of(context).outlineVariant,
                        thickness: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final size = MediaQuery.sizeOf(context);
                  final offset = showNavigationDrawer ? 250.0 : 52.0;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    left: offset,
                    width: size.width - offset,
                    curve: Curves.easeOutQuint,
                    top: 0,
                    bottom: 0,
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(size: Size(size.width - offset, size.height)),
                      child: ColoredBox(
                        color: AppColorScheme.of(context).surfaceContainerLow,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidenav extends StatelessWidget {
  const _Sidenav();

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: NavigationMenu<AppDestination>(
        onDestinationSelected: (AppDestination selected) {
          Navigator.pushReplacementNamed(context, selected.route);
        },
        selected: AppDestination.fromRoute(ModalRoute.of(context)!.settings.name),
        label: 'Main',
        children: [
          NavigationMenuGroup(
            header: _DrawerHeader(title: AppSection.api.label),
            groupLabel: AppSection.api.label,
            children: [
              for (final destination in AppDestination.values.where(
                (d) => d.section == AppSection.api,
              ))
                NavigationMenuDestination(
                  identifier: destination,
                  child: _DestinationLabel(destination: destination),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: NavigationMenuGroup(
              header: _DrawerHeader(title: AppSection.examples.label),
              groupLabel: AppSection.examples.label,
              children: [
                for (final destination in AppDestination.values.where(
                  (d) => d.section == AppSection.examples,
                ))
                  NavigationMenuDestination(
                    identifier: destination,
                    child: _DestinationLabel(destination: destination),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const WidgetStateProperty<Color> lightBackgroundColor = WidgetStateProperty.fromMap({
  WidgetState.pressed: Color.fromARGB(20, 0, 0, 0),
  WidgetState.hovered: Color.fromARGB(15, 0, 0, 0),
  WidgetState.any: kTransparentLight,
});

const WidgetStateProperty<Color> darkBackgroundColor = WidgetStateProperty.fromMap({
  WidgetState.pressed: Color.fromARGB(30, 255, 255, 255),
  WidgetState.hovered: Color.fromARGB(15, 255, 255, 255),
  WidgetState.any: kTransparent,
});

class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  static const WidgetStateProperty<Color> lightBackgroundColor = WidgetStateProperty.fromMap({
    WidgetState.pressed: Color.fromARGB(30, 0, 0, 0),
    WidgetState.focused: Color.fromARGB(15, 0, 0, 0),
    WidgetState.hovered: Color.fromARGB(10, 0, 0, 0),
    WidgetState.any: kTransparentLight,
  });

  static const WidgetStateProperty<Color> darkBackgroundColor = WidgetStateProperty.fromMap({
    WidgetState.pressed: Color.fromARGB(30, 255, 255, 255),
    WidgetState.focused: Color.fromARGB(15, 255, 255, 255),
    WidgetState.hovered: Color.fromARGB(10, 255, 255, 255),
    WidgetState.any: kTransparent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      expanded: isOpen,
      label: isOpen ? 'Collapse navigation menu' : 'Expand navigation menu',
      onExpand: isOpen ? null : onPressed,
      onCollapse: isOpen ? onPressed : null,
      child: BaseControl(
        onPressed: onPressed,
        child: Builder(
          builder: (context) {
            return Container(
              alignment: Alignment.center,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColorScheme.of(context).brightness == .light
                    ? lightBackgroundColor.resolve(BaseControl.statesOf(context))
                    : darkBackgroundColor.resolve(BaseControl.statesOf(context)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOpen ? Symbols.menu_open_rounded : Symbols.menu_rounded,
                size: 24,
                color: AppColorScheme.of(context).onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColorScheme.of(context).onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          fontFamily: 'InterVariable',
          package: kPackage,
          letterSpacing: 0.5,
          height: 1.4,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
  }
}

class _DestinationLabel extends StatelessWidget {
  const _DestinationLabel({required this.destination});
  final AppDestination destination;

  static const WidgetStateProperty<TextStyle> textStyle = WidgetStateProperty.fromMap({
    WidgetState.selected: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      letterSpacing: -0.1,
      fontFamily: 'InterVariable',
      package: kPackage,
    ),
    WidgetState.any: TextStyle(
      fontVariations: [FontVariation.weight(550)],
      fontSize: 14,
      fontFamily: 'InterVariable',
      package: kPackage,
    ),
  });

  static const WidgetStateProperty<Color> lightBackgroundColor = WidgetStateProperty.fromMap({
    WidgetState.pressed: Color.fromARGB(20, 0, 0, 0),
    WidgetState.hovered: Color.fromARGB(15, 0, 0, 0),
    WidgetState.any: kTransparentLight,
  });

  static const WidgetStateProperty<Color> darkBackgroundColor = WidgetStateProperty.fromMap({
    WidgetState.pressed: Color.fromARGB(30, 255, 255, 255),
    WidgetState.hovered: Color.fromARGB(15, 255, 255, 255),
    WidgetState.any: kTransparent,
  });

  @override
  Widget build(BuildContext context) {
    final states = NavigationMenuDestination.statesOf(context);
    final isSelected = states.contains(WidgetState.selected);
    final isFocused = states.contains(WidgetState.focused);
    final brightness = AppColorScheme.of(context).brightness;
    final ColorScheme colorScheme = AppColorScheme.of(context);

    final Color itemColor = isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    final Color backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : switch (brightness) {
            Brightness.dark => darkBackgroundColor.resolve(states),
            Brightness.light => lightBackgroundColor.resolve(states),
          };

    return RepaintBoundary(
      child: Container(
        height: 40,
        width: 232,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: isFocused ? colorScheme.primary : kTransparentLight, width: 2),
        ),

        child: Row(
          mainAxisAlignment: .start,
          children: [
            IconTheme.merge(
              data: IconThemeData(size: 24, color: itemColor),
              child: Builder(
                builder: (context) {
                  final states = NavigationMenuDestination.statesOf(context);
                  return states.contains(WidgetState.selected)
                      ? destination.selectedIcon
                      : destination.icon;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: Text(
                destination.label,
                style: textStyle.resolve(states).copyWith(color: itemColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
