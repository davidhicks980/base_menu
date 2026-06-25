import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menu_utilities/menu_utilities.dart';

import 'menu_action_label.dart';
import 'menu_divider.dart';
import 'menu_item.dart';
import 'model.dart';
import 'surface.dart';

class _MenuSystemDismissHandler extends InheritedWidget {
  const _MenuSystemDismissHandler({
    required this.state,
    required super.child,
    required this.isInteractive,
  });

  final _SequoiaMenuState state;
  final bool isInteractive;

  static _MenuSystemDismissHandler of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MenuSystemDismissHandler>()!;
  }

  @override
  bool updateShouldNotify(_MenuSystemDismissHandler oldWidget) {
    return state != oldWidget.state || isInteractive != oldWidget.isInteractive;
  }
}

class SequoiaMenu extends StatefulWidget {
  const SequoiaMenu({super.key, required this.items});

  final List<MenuItem> items;

  @override
  State<SequoiaMenu> createState() => _SequoiaMenuState();

  static Widget _buildItem(MenuItem item, bool isTopLevel) {
    if (item case MenuDividerItem()) {
      return const SequoiaMenuDivider();
    }

    if (item.children.isEmpty) {
      return SequoiaMenuItem(shortcut: item.shortcut, child: Text(item.label));
    }

    return _SequoiaModelBarSubmenu(item: item, isTopLevel: isTopLevel);
  }
}

class _SequoiaMenuState extends State<SequoiaMenu> with SingleTickerProviderStateMixin {
  final controller = MenuController();
  bool isAnimating = false;
  bool isInteractive = false;
  final FocusScopeNode focusScopeNode = FocusScopeNode();

  late final AnimationController animation = AnimationController(
    duration: Duration.zero,
    value: 1,
    vsync: this,
  );

  void enableInteractivity() {
    if (!isInteractive) {
      setState(() {
        isInteractive = true;
      });
    }
  }

  void fadeMenuOut() {
    if (isAnimating) {
      return;
    }
    focusScopeNode.requestScopeFocus();
    isAnimating = true;
    animation.duration = const Duration(milliseconds: 125);
    animation.reverse().whenComplete(() {
      controller.close();
      animation.duration = Duration.zero;
      animation.value = 1;
      isAnimating = false;
      setState(() {
        isInteractive = false;
      });
    });
  }

  @override
  void dispose() {
    focusScopeNode.dispose();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MenuSystemDismissHandler(
      isInteractive: isInteractive,
      state: this,
      child: TapRegion(
        groupId: 'menu_system',
        onTapOutside: (event) {
          fadeMenuOut();
        },
        child: MouseRegion(
          onExit: (event) {
            if (!controller.isOpen) {
              focusScopeNode.requestScopeFocus();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BaseMenuBar(
              controller: controller,
              focusScopeNode: focusScopeNode,
              child: BaseMenuPanel(
                orientation: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: widget.items.map((item) => SequoiaMenu._buildItem(item, true)).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SequoiaModelBarSubmenu extends StatefulWidget {
  const _SequoiaModelBarSubmenu({required this.item, required this.isTopLevel});

  final MenuItem item;
  final bool isTopLevel;

  @override
  State<_SequoiaModelBarSubmenu> createState() => _SequoiaModelBarSubmenuState();
}

class _SequoiaModelBarSubmenuState extends State<_SequoiaModelBarSubmenu>
    with SingleTickerProviderStateMixin {
  final controller = MenuController();
  final focusNode = FocusNode();
  late _SequoiaMenuState _menuState;
  bool _isClosing = false;
  late final Map<Type, Action<Intent>> actions = {
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (intent) {
        _menuState.fadeMenuOut();
        return null;
      },
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuState = _MenuSystemDismissHandler.of(context).state;
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _handleCloseRequest(VoidCallback hideOverlay) {
    scheduleMicrotask(() {
      if (!_menuState.isAnimating) {
        hideOverlay();
      } else {
        setState(() {
          _isClosing = true;
        });
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.dismissed) {
            _menuState.animation.removeStatusListener(listener);
            hideOverlay();
            if (mounted) {
              setState(() {
                _isClosing = false;
              });
            }
          }
        }

        _menuState.animation.addStatusListener(listener);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: BaseSubmenu(
        controller: controller,
        // Top level opens down, nested submenus open to the side
        positionDelegate: DefaultBaseMenuPositioningDelegate(
          padding: const EdgeInsets.symmetric(vertical: 4),
          offset: widget.isTopLevel ? const Offset(-4, 0) : const Offset(0, -1.5),
        ),
        onCloseRequest: _handleCloseRequest,
        hoverOpenDelay: widget.isTopLevel ? Duration.zero : const Duration(milliseconds: 250),
        anchorActions: actions,
        focusNode: focusNode,
        requestFocusOnHover: _menuState.isInteractive,
        onPressed: () {
          if (controller.isOpen) {
            if (widget.isTopLevel) {
              _menuState.fadeMenuOut();
              focusNode.unfocus();
            }
          } else {
            controller.open();
            focusNode.requestFocus();
            _menuState.enableInteractivity();
          }
        },
        menu: Actions(
          actions: actions,
          child: ExcludeSemantics(
            excluding: _isClosing,
            child: ExcludeFocus(
              excluding: _isClosing,
              child: IgnorePointer(
                ignoring: _isClosing,
                child: TapRegion(
                  groupId: 'menu_system',
                  onTapOutside: (event) {
                    _menuState.fadeMenuOut();
                  },
                  child: FadeTransition(
                    opacity: _menuState.animation,
                    child: ColoredBox(
                      color: const Color(0x00000000),
                      child: Padding(
                        padding: widget.isTopLevel
                            ? const EdgeInsets.symmetric(vertical: 8)
                            : EdgeInsets.zero,
                        child: SequoiaMenuSurface(
                          child: BaseMenuPanel(
                            onEnter: (event) {
                              if (!focusNode.hasFocus) {
                                focusNode.requestFocus();
                              }
                            },
                            orientation: Axis.vertical,
                            padding: const EdgeInsets.all(4),
                            children: [
                              for (final child in widget.item.children)
                                SequoiaMenu._buildItem(child, false),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: widget.isTopLevel
            ? switch (widget.item.label) {
                'System' => SequoiaMenuBarActionLabel(
                  radius: const BorderRadiusGeometry.directional(
                    topStart: Radius.circular(12),
                    bottomStart: Radius.circular(5),
                    bottomEnd: Radius.circular(5),
                    topEnd: Radius.circular(5),
                  ),
                  padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 5.0),
                  child: SequoiaTreeIcon(
                    color: const Color(0xFFFFFFFF),
                    size: MediaQuery.textScalerOf(context).scale(16),
                  ),
                ),
                'Code' => SequoiaMenuBarActionLabel(
                  child: Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                      fontVariations: [FontVariation.weight(700)],
                    ),
                  ),
                ),
                _ => SequoiaMenuBarActionLabel(child: Text(widget.item.label)),
              }
            : SequoiaSubmenuActionLabel(child: Text(widget.item.label)),
      ),
    );
  }
}

/// A widget that draws a stylized Sequoia tree icon, intended for use
/// in the main menu bar as a replacement for the system logo.
class SequoiaTreeIcon extends StatelessWidget {
  const SequoiaTreeIcon({super.key, this.size = 18.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SequoiaTreePainter(
        color: IconTheme.of(context).color ?? color ?? const Color(0xFFFFFFFF),
      ),
    );
  }
}

class _SequoiaTreePainter extends CustomPainter {
  _SequoiaTreePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    final path = Path();

    // Start at bottom of the trunk (thicker base)
    path.moveTo(w * 0.38, h * 0.95);
    path.lineTo(w * 0.62, h * 0.95);
    // Taper slightly up to the first tier
    path.lineTo(w * 0.58, h * 0.80);

    // Bottom branch tier (widest and lowest)
    path.lineTo(w * 0.92, h * 0.80);
    // The control points are adjusted to make the bottom of the tier "fuller"
    path.quadraticBezierTo(w * 0.70, h * 0.72, w * 0.56, h * 0.62);

    // Middle branch tier
    path.lineTo(w * 0.85, h * 0.62);
    path.quadraticBezierTo(w * 0.65, h * 0.52, w * 0.54, h * 0.36);

    // Top branch tier and apex
    path.lineTo(w * 0.74, h * 0.36);
    path.quadraticBezierTo(w * 0.50, h * 0.25, w * 0.50, h * 0.05);

    // Left side - mirroring the right for symmetry
    path.quadraticBezierTo(w * 0.50, h * 0.25, w * 0.26, h * 0.36);
    path.lineTo(w * 0.46, h * 0.36);

    path.quadraticBezierTo(w * 0.35, h * 0.52, w * 0.15, h * 0.62);
    path.lineTo(w * 0.44, h * 0.62);

    path.quadraticBezierTo(w * 0.30, h * 0.72, w * 0.08, h * 0.80);
    path.lineTo(w * 0.42, h * 0.80);

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SequoiaTreePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
