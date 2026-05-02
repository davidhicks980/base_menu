import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:menu_utilities/menu_utilities.dart';

import '../utilities/colors.dart';
import 'menu_action_label.dart';
import 'menu_panel.dart';

class Submenu extends StatefulWidget {
  const Submenu({
    super.key,
    this.onPressed,
    this.alignment,
    this.menuAlignment,
    this.hoverDelay = Duration.zero,
    this.leading,
    required this.child,
    required this.panel,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final AlignmentGeometry? alignment;
  final AlignmentGeometry? menuAlignment;
  final Widget? leading;
  final Widget child;
  final Widget panel;
  final Duration hoverDelay;
  final bool autofocus;

  @override
  State<Submenu> createState() => _SubmenuState();
}

class _SubmenuState extends State<Submenu> {
  final MenuController controller = MenuController();
  Timer? _openTimer;
  Timer? _closeTimer;
  final ValueNotifier<bool> focusNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _openTimer?.cancel();
    _closeTimer?.cancel();
    focusNotifier.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool value) {
    focusNotifier.value = value;
    if (!value) {
      if (_closeTimer == null) {
        setState(() {
          _closeTimer = Timer(widget.hoverDelay, () {
            if (mounted && controller.isOpen) {
              controller.close();
            }
          });
        });
      }
    } else {
      _closeTimer?.cancel();
      _closeTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoreMenu(
      padding: MenuPanel.defaultPadding,
      controller: controller,
      alignment: widget.alignment,
      menuAlignment: widget.menuAlignment,
      onFocusChange: _handleFocusChange,
      panel: widget.panel,
      child: Builder(
        builder: (context) {
          void handleHover(bool value) {
            if (value) {
              _openTimer ??= Timer(widget.hoverDelay, () {
                if (!context.mounted) {
                  return;
                }

                final controller = MenuController.maybeOf(context);
                if (controller == null || controller.isOpen) {
                  return;
                }

                Actions.maybeInvoke(context, const CoreMenuEnterIntent.setFirstFocus());
              });
            } else {
              _openTimer?.cancel();
              _openTimer = null;
            }
          }

          return Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) {
                  Actions.maybeInvoke(context, const CoreMenuEnterIntent.focusFirst());
                  return null;
                },
              ),
              ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                onInvoke: (intent) {
                  Actions.maybeInvoke(context, const CoreMenuEnterIntent.focusFirst());
                  return null;
                },
              ),
            },
            child: CoreMenuItem(
              autofocus: widget.autofocus,
              requestCloseOnActivate: false,
              onHover: handleHover,
              onPressed: () {
                if (!controller.isOpen) {
                  controller.open();
                }
                widget.onPressed?.call();
              },

              child: ValueListenableBuilder<bool>(
                valueListenable: focusNotifier,
                child: SubmenuActionLabel(
                  leading: widget.leading,
                  axis: Axis.vertical,
                  child: widget.child,
                ),
                builder: (context, hasFocus, child) {
                  return ColoredBox(
                    color: hasFocus ? FloogleColors.menuItemFocusColor : FloogleColors.transparent,
                    child: child,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
