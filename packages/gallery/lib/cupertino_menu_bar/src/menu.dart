import 'dart:async';

import 'package:base_menu/base_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dismiss.dart';
import 'menu_action_label.dart';
import 'menu_divider.dart';
import 'menu_item.dart';
import 'model.dart';
import 'theme.dart';

class CupertinoMenuBar extends StatefulWidget {
  const CupertinoMenuBar({super.key, required this.items, this.onOpen});

  final List<MenuItem> items;
  final VoidCallback? onOpen;

  @override
  State<CupertinoMenuBar> createState() => _CupertinoMenuBarState();
}

class _CupertinoMenuBarState extends State<CupertinoMenuBar> {
  final controller = MenuController();
  final FocusScopeNode focusScopeNode = FocusScopeNode();

  @override
  void dispose() {
    focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuDismissCoordinator(
      controller: controller,
      child: Builder(
        builder: (context) {
          return ExcludeFocus(
            excluding: CupertinoMenuDismissHandler.of(context).isAnimatingOut,
            child: TapRegion(
              groupId: controller,
              onTapOutside: (event) {
                CupertinoMenuDismissHandler.of(context).fadeMenuOut();
              },
              child: BaseMenuBar(
                controller: controller,
                focusScopeNode: focusScopeNode,
                child: UnconstrainedBox(
                  alignment: Alignment.topLeft,
                  clipBehavior: .hardEdge,
                  child: BaseMenuPanel(
                    scrollable: false,
                    onPointerExit: (event) {
                      if (focusScopeNode.hasFocus) {
                        focusScopeNode.requestScopeFocus();
                      }
                    },
                    orientation: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final child in widget.items)
                        CupertinoSubmenu.buildItem(
                          child,
                          true,
                          onOpen: widget.onOpen,
                          groupId: controller,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CupertinoSubmenu extends StatefulWidget {
  const CupertinoSubmenu({
    super.key,
    required this.item,
    required this.isTopLevel,
    required this.groupId,
    this.onOpen,
  });

  final MenuItem item;
  final bool isTopLevel;
  final Object groupId;
  final VoidCallback? onOpen;

  static Widget buildItem(
    MenuItem item,
    bool isTopLevel, {
    VoidCallback? onOpen,
    required Object groupId,
  }) {
    if (item case MenuDividerItem()) {
      return const CupertinoMenuDivider();
    }

    if (item.children.isEmpty) {
      return Builder(
        builder: (context) {
          return CupertinoMenuItem(
            shortcut: item.shortcut,
            leading: CupertinoMenuItemTheme.of(context).showIcon ? Icon(item.icon) : null,
            child: Text(item.label),
          );
        },
      );
    }

    return CupertinoSubmenu(item: item, isTopLevel: isTopLevel, groupId: groupId, onOpen: onOpen);
  }

  @override
  State<CupertinoSubmenu> createState() => _CupertinoSubmenuState();
}

class _CupertinoSubmenuState extends State<CupertinoSubmenu> {
  final controller = MenuController();
  final focusNode = FocusNode();
  late MenuDismissCoordinatorState _dismissHandler;
  bool _isClosing = false;
  late final Map<Type, Action<Intent>> actions = {
    DismissIntent: CallbackAction<DismissIntent>(
      onInvoke: (intent) {
        _dismissHandler.fadeMenuOut();
        return null;
      },
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dismissHandler = CupertinoMenuDismissHandler.of(context);
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _handleCloseRequest(VoidCallback hideOverlay) {
    scheduleMicrotask(() {
      if (!_dismissHandler.isAnimatingOut) {
        hideOverlay();
      } else {
        setState(() {
          _isClosing = true;
        });
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.dismissed) {
            _dismissHandler.animation.removeStatusListener(listener);
            hideOverlay();
            if (mounted) {
              setState(() {
                _isClosing = false;
              });
            }
          }
        }

        _dismissHandler.animation.addStatusListener(listener);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoMenuTheme.of(context);
    return ExcludeFocus(
      excluding: _dismissHandler.isAnimatingOut,
      child: IntrinsicWidth(
        child: BaseSubmenu(
          controller: controller,
          // Top level opens down, nested submenus open to the side
          positionDelegate: DefaultMenuPositioningDelegate(
            padding: const EdgeInsets.symmetric(vertical: 4),
            offset: widget.isTopLevel ? const Offset(-4, 0) : const Offset(0, -1.5),
          ),
          onCloseRequest: _handleCloseRequest,
          hoverOpenDelay: widget.isTopLevel ? Duration.zero : const Duration(milliseconds: 250),
          anchorActions: actions,
          focusNode: focusNode,
          requestFocusOnHover: _dismissHandler.isInteractive,
          requestOpenOnPointerEnter: _dismissHandler.isInteractive,
          requestCloseOnPointerExit: _dismissHandler.isInteractive,
          onOpen: widget.onOpen,
          onPressed: () {
            if (controller.isOpen) {
              if (widget.isTopLevel) {
                _dismissHandler.fadeMenuOut();
              }
            } else {
              controller.open();
              focusNode.requestFocus();
              _dismissHandler.enableInteractivity();
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
                    groupId: widget.groupId,
                    onTapOutside: (event) {
                      if (event.buttons == kSecondaryMouseButton) {
                        return;
                      }
                      _dismissHandler.fadeMenuOut();
                    },
                    child: MouseRegion(
                      opaque: true,
                      hitTestBehavior: HitTestBehavior.opaque,
                      child: FadeTransition(
                        opacity: _dismissHandler.animation,
                        child: ColoredBox(
                          color: const Color(0x00000000),
                          child: Padding(
                            padding: widget.isTopLevel
                                ? const EdgeInsets.symmetric(vertical: 8)
                                : EdgeInsets.zero,
                            child: Stack(
                              children: [
                                Positioned.fill(child: theme.surface),
                                BaseMenuPanel(
                                  onPointerExit: (event) {
                                    if (!focusNode.hasFocus) {
                                      focusNode.requestFocus();
                                    }
                                  },
                                  orientation: Axis.vertical,
                                  padding: theme.surfacePadding,
                                  children: [
                                    for (final child in widget.item.children)
                                      CupertinoSubmenu.buildItem(
                                        child,
                                        false,
                                        groupId: widget.groupId,
                                      ),
                                  ],
                                ),
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
                  'System' => CupertinoMenuBarActionLabel(
                    screenRadius: const Radius.circular(12),
                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 5.0),
                    child: _CupertinoTreeIcon(
                      color: const Color(0xFFFFFFFF),
                      size: MediaQuery.textScalerOf(context).scale(16),
                    ),
                  ),
                  'Code' => CupertinoMenuBarActionLabel(
                    child: Text(
                      widget.item.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                        fontVariations: [FontVariation.weight(700)],
                      ),
                    ),
                  ),
                  _ => CupertinoMenuBarActionLabel(child: Text(widget.item.label)),
                }
              : CupertinoSubmenuActionLabel(child: Text(widget.item.label)),
        ),
      ),
    );
  }
}

/// A widget that draws a stylized Cupertino tree icon, intended for use
/// in the main menu bar as a replacement for the system logo.
class _CupertinoTreeIcon extends StatelessWidget {
  const _CupertinoTreeIcon({this.size = 18.0, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CupertinoTreePainter(color: color),
    );
  }
}

class _CupertinoTreePainter extends CustomPainter {
  _CupertinoTreePainter({required this.color});

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
  bool shouldRepaint(covariant _CupertinoTreePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
