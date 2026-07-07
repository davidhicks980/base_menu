import 'package:base_menu/base_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../checkbox_menu_item/checkbox_menu_item_app.dart';
import '../floogle_docs/floogle_docs.dart';
import '../floogle_docs/src/theme/colors.dart';
import '../menu/menu_app.dart';
import '../menubar/menubar_app.dart';
import '../positioning/positioning_app.dart';
import '../sequoia/sequoia_app.dart';
import '../shared/base_menu_app.dart';
import '../shared/package.dart';
import '../shared/theme.dart';
import '../submenu/submenu_app.dart';

enum Destination {
  menu(
    'BaseMenu',
    '/',
    icon: Icon(Symbols.list_alt),
    selectedIcon: Icon(Symbols.list_alt, fill: 1),
  ),
  submenu(
    'BaseSubmenu',
    '/submenu',
    icon: Icon(Symbols.stack),
    selectedIcon: Icon(Symbols.stack, fill: 1),
  ),
  menuBar(
    'BaseMenuBar',
    '/menu-bar',
    icon: Icon(Symbols.view_sidebar),
    selectedIcon: Icon(Symbols.view_sidebar, fill: 1),
  ),
  menuItem(
    'BaseMenuItem',
    '/menu-item',
    icon: Icon(Symbols.checklist),
    selectedIcon: Icon(Symbols.checklist, fill: 1),
  ),
  positioning(
    'Positioning',
    '/positioning',
    icon: Icon(Symbols.flip),
    selectedIcon: Icon(Symbols.flip, fill: 1),
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
    this.brightness = Brightness.light,
  });

  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final Brightness brightness;

  /// Helper to find a destination based on the current route name.
  static Destination fromRoute(String? route) {
    return Destination.values.firstWhere((d) => d.route == route, orElse: () => Destination.menu);
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
    return BaseMenuApp(
      title: 'Base Menu Library',
      initialRoute: Destination.menu.route,
      routes: {
        for (final destination in Destination.values)
          destination.route: (context) => _AppRouteWrapper(
            brightness: destination.brightness,
            child: switch (destination) {
              Destination.menu => const MenuApp(),
              Destination.menuBar => const MenuBarApp(),
              Destination.submenu => const SubmenuApp(),
              Destination.floogleDocs => const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: FloogleDocsApp(),
              ),
              Destination.positioning => const PositioningApp(),
              Destination.sequoia => const SequoiaApp(),
              Destination.menuItem => const CheckboxMenuItemApp(),
            },
          ),
      },
    );
  }
}

/// A wrapper widget that applies the persistent [AppScaffold] to every route.
class _AppRouteWrapper extends StatelessWidget {
  const _AppRouteWrapper({required this.brightness, required this.child});

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = brightness == Brightness.light ? AppTheme.light : AppTheme.dark;
    return AppColorScheme(
      colorScheme: brightness == Brightness.dark
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
      child: DefaultTextStyle(
        style: TextStyle(fontFamily: 'GoogleSans', package: kPackage, color: theme.shade),
        child: Builder(
          builder: (context) {
            return ColoredBox(
              color: AppColorScheme.of(context).surfaceContainerLow,
              child: Semantics(
                label: 'Base Menu Library',
                child: Title(
                  title: 'Base Menu Library',
                  color: theme.shade,
                  child: AppScaffold(child: child),
                ),
              ),
            );
          },
        ),
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
    return ColoredBox(
      color: AppColorScheme.of(context).surfaceContainerLow,
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
                    left: offset,
                    width: size.width - offset,
                    curve: Curves.easeOutQuint,
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
                left: showNavigationDrawer ? 0 : -200,
                width: 250,
                top: 0,
                bottom: 0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuint,
                child: RepaintBoundary(
                  child: FocusTraversalGroup(
                    child: Stack(
                      children: [
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
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
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
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          child: Separator.vertical(
                            color: AppColorScheme.of(context).outlineVariant,
                            thickness: 2,
                          ),
                        ),
                      ],
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

class _Sidenav extends StatelessWidget {
  const _Sidenav();

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: DefaultTextStyle.merge(
        child: CustomDrawer(
          onDestinationSelected: (int selectedIndex) {
            if (selectedIndex != -1) {
              Navigator.pushReplacementNamed(context, Destination.values[selectedIndex].route);
            }
          },
          selectedIndex: Destination.values.indexOf(
            Destination.fromRoute(ModalRoute.of(context)!.settings.name),
          ),
          header: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Base Menu',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontSize: 24,
                    color: AppColorScheme.of(context).onSurface,
                  ),
                ),
              ),
            ],
          ),
          label: 'Main',
          children: <Widget>[
            const _DrawerHeader(title: 'EXAMPLES'),
            for (final destination in Destination.values)
              AppDestination(child: DestinationLabel(destination: destination)),
          ],
        ),
      ),
    );
  }
}

const WidgetStateProperty<Color> lightBackgroundColor = WidgetStateProperty.fromMap({
  WidgetState.pressed: Color(0x0E000000),
  WidgetState.selected: Color(0x14000000),
  WidgetState.focused: Color(0x0A000000),
  WidgetState.hovered: Color(0x0A000000),
  WidgetState.any: kTransparentLight,
});

const WidgetStateProperty<Color> darkBackgroundColor = WidgetStateProperty.fromMap({
  WidgetState.pressed: Color(0x1EFFFFFF),
  WidgetState.selected: Color(0x14FFFFFF),
  WidgetState.focused: Color(0x0AFFFFFF),
  WidgetState.hovered: Color(0x0AFFFFFF),
  WidgetState.any: kTransparent,
});

class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BaseControl(
      onPressed: onPressed,
      child: Builder(
        builder: (context) {
          return Container(
            alignment: Alignment.center,
            width: 56,
            height: 56,
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
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColorScheme.of(context).onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
          fontSize: 11.0,
          letterSpacing: 0.5,
          height: 1.4,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
  }
}

class DestinationLabel extends StatelessWidget {
  const DestinationLabel({super.key, required this.destination});
  final Destination destination;

  static const WidgetStateProperty<TextStyle> textStyle = WidgetStateProperty.fromMap({
    WidgetState.selected: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    WidgetState.focused: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    WidgetState.any: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
  });

  @override
  Widget build(BuildContext context) {
    final states = AppDestination.statesOf(context);
    final isSelected = states.contains(WidgetState.selected);
    final brightness = AppColorScheme.of(context).brightness;
    final Color color = switch (brightness) {
      Brightness.dark => isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
      Brightness.light => isSelected ? Colors.black : Colors.black.withValues(alpha: 0.7),
    };

    return RepaintBoundary(
      child: AnimatedDecoration(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuint,
        decoration: BoxDecoration(
          color: switch (brightness) {
            Brightness.dark => darkBackgroundColor.resolve(states),
            Brightness.light => lightBackgroundColor.resolve(states),
          },
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          border: states.contains(WidgetState.focused) || states.contains(WidgetState.pressed)
              ? Border.all(strokeAlign: BorderSide.strokeAlignOutside, width: 2, color: kSeedColor)
              : Border.all(
                  strokeAlign: BorderSide.strokeAlignOutside,
                  width: 6,
                  color: brightness == Brightness.dark ? kTransparent : kTransparentLight,
                ),
        ),
        child: Container(
          height: 40,
          width: 225,
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Row(
            mainAxisAlignment: .start,
            children: [
              IconTheme.merge(
                data: IconThemeData(size: 24, color: color),
                child: Builder(
                  builder: (context) {
                    final states = AppDestination.statesOf(context);
                    return states.contains(WidgetState.selected)
                        ? destination.selectedIcon
                        : destination.icon;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Text(
                  destination.label,
                  style: textStyle.resolve(states).copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({
    super.key,
    required this.label,
    required this.children,
    required this.selectedIndex,
    this.header,
    this.footer,
    this.onDestinationSelected,
  });

  final String label;
  final List<Widget> children;
  final int selectedIndex;
  final void Function(int)? onDestinationSelected;
  final Widget? header;
  final Widget? footer;

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant CustomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    var index = 0;
    final List<Widget> children = widget.children.map((child) {
      if (child case AppDestination()) {
        final currentIndex = index;
        index++;
        return _DestinationData(
          key: ValueKey(currentIndex),
          index: currentIndex,
          isSelected: currentIndex == _selectedIndex,
          destinationCount: widget.children.length,
          onSelect: () {
            setState(() {
              _selectedIndex = currentIndex;
            });
            if (widget.onDestinationSelected != null) {
              widget.onDestinationSelected!(currentIndex);
            }
          },
          child: child,
        );
      }

      return child;
    }).toList();
    return Semantics(
      role: SemanticsRole.navigation,
      explicitChildNodes: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          ?widget.header,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(crossAxisAlignment: .start, children: children),
            ),
          ),
          ?widget.footer,
        ],
      ),
    );
  }
}

class AppDestination extends StatelessWidget {
  /// Builds a destination (icon + label) to use in a Material 3 [NavigationDrawer].
  const AppDestination({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// Indicates that this destination is selectable.
  ///
  /// Defaults to true.
  final bool enabled;

  static Set<WidgetState> statesOf(BuildContext context) {
    return {
      ...BaseControl.statesOf(context),
      if (_DestinationData.of(context).isSelected) WidgetState.selected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final _DestinationData info = _DestinationData.of(context);
    return _DestinationSemantics(
      child: BaseControl(
        autofocus: info.isSelected,
        onPressed: enabled ? info.onSelect : null,
        mouseCursor: WidgetStateMouseCursor.adaptiveClickable,
        child: child,
      ),
    );
  }
}

class _DestinationSemantics extends StatelessWidget {
  /// Adds the appropriate semantics for navigation drawer destinations to the
  /// [child].
  const _DestinationSemantics({required this.child});

  /// The widget that should receive the destination semantics.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final _DestinationData destinationInfo = _DestinationData.of(context);
    // The AnimationStatusBuilder will make sure that the semantics update to
    // "selected" when the animation status changes.
    return MergeSemantics(
      child: Semantics(
        selected: destinationInfo.isSelected,
        container: true,
        button: true,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            child,
            Semantics(
              label: localizations.tabLabel(
                tabIndex: destinationInfo.index + 1,
                tabCount: destinationInfo.destinationCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationData extends InheritedWidget {
  const _DestinationData({
    required super.key,
    required this.index,
    required this.isSelected,
    required this.destinationCount,
    required this.onSelect,
    required super.child,
  });

  final int index;
  final bool isSelected;
  final int destinationCount;
  final VoidCallback onSelect;
  static _DestinationData of(BuildContext context) {
    final _DestinationData? result = context.dependOnInheritedWidgetOfExactType<_DestinationData>();
    assert(
      result != null,
      'Navigation destinations need a _NavigationDrawerDestinationInfo parent, '
      'which is usually provided by NavigationDrawer.',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(_DestinationData oldWidget) {
    return index != oldWidget.index ||
        destinationCount != oldWidget.destinationCount ||
        isSelected != oldWidget.isSelected ||
        onSelect != oldWidget.onSelect;
  }
}

class AnimatedDecoration extends ImplicitlyAnimatedWidget {
  const AnimatedDecoration({
    super.key,
    required this.decoration,
    required super.duration,
    super.curve = Curves.linear,
    this.position = DecorationPosition.background,
    required this.child,
  });

  final Decoration decoration;
  final DecorationPosition position;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedDecoration> createState() => _AnimatedDecorationState();
}

class _AnimatedDecorationState extends AnimatedWidgetBaseState<AnimatedDecoration> {
  DecorationTween? _decoration;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _decoration =
        visitor(
              _decoration,
              widget.decoration,
              (dynamic value) => DecorationTween(begin: value as Decoration),
            )
            as DecorationTween?;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoration!.evaluate(animation),
      position: widget.position,
      child: widget.child,
    );
  }
}
