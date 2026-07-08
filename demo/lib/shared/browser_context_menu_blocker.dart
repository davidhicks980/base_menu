import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class _ContextMenuBlockerScope extends InheritedWidget {
  const _ContextMenuBlockerScope({
    required this.isEnabled,
    required super.child,
    required this.state,
  });
  final bool isEnabled;
  final _ContextMenuBlockerState state;

  @override
  bool updateShouldNotify(_ContextMenuBlockerScope oldWidget) {
    return isEnabled != oldWidget.isEnabled || state != oldWidget.state;
  }
}

class ContextMenuBlocker extends StatefulWidget {
  const ContextMenuBlocker({super.key, required this.child});
  final Widget child;

  static bool isEnabledOf(BuildContext context) {
    if (!kIsWeb) {
      return false;
    }

    final _ContextMenuBlockerScope? scope = context
        .dependOnInheritedWidgetOfExactType<_ContextMenuBlockerScope>();
    assert(scope != null, 'ContextMenuBlocker must be an ancestor of the context.');
    return scope?.isEnabled ?? false;
  }

  @override
  State<ContextMenuBlocker> createState() => _ContextMenuBlockerState();
}

class _ContextMenuBlockerState extends State<ContextMenuBlocker> {
  Future<void> _lock = SynchronousFuture<void>(null);
  int mouseCount = 0;
  bool? _willEnable;
  final Set<Object> _entered = {};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _updateBlockingDemand(enable: false);
    _entered.clear();
    super.dispose();
  }

  void addMouse(Object identifier) {
    if (_entered.contains(identifier)) {
      return;
    }
    _entered.add(identifier);
    _update();
  }

  void removeMouse(Object identifier) {
    if (!_entered.contains(identifier)) {
      return;
    }
    _entered.remove(identifier);
    _update();
  }

  /// Safely manages this instance's contribution to the global blocker count
  Future<void> _updateBlockingDemand({required bool enable}) async {
    if (_willEnable == enable) {
      return;
    }

    _willEnable = enable;
    if (enable) {
      await enableContextMenu();
    } else {
      await disableContextMenu();
    }
  }

  Future<void> _update() async {
    // Block only if the mouse is inside AND the shift key is NOT held down
    final enable = _entered.isEmpty || HardwareKeyboard.instance.isShiftPressed;
    await _updateBlockingDemand(enable: enable);
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> disableContextMenu() {
    if (!kIsWeb) {
      return Future.value();
    }

    return _lock = _lock.then((_) async {
      await BrowserContextMenu.disableContextMenu();
    });
  }

  Future<void> enableContextMenu() {
    if (!kIsWeb) {
      return Future.value();
    }

    return _lock = _lock.then((_) async {
      await BrowserContextMenu.enableContextMenu();
    });
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight) {
      _update();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.child;
    }

    return _ContextMenuBlockerScope(
      state: this,
      isEnabled: BrowserContextMenu.enabled,
      child: widget.child,
    );
  }
}

class ContextMenuBlockerRegion extends StatefulWidget {
  const ContextMenuBlockerRegion({super.key, required this.child});
  final Widget child;

  @override
  State<ContextMenuBlockerRegion> createState() => _ContextMenuBlockerRegionState();
}

class _ContextMenuBlockerRegionState extends State<ContextMenuBlockerRegion> {
  final identifier = Object();
  _ContextMenuBlockerState? _state;
  bool isOver = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.dependOnInheritedWidgetOfExactType<_ContextMenuBlockerScope>()!.state;
    if (_state != state) {
      _state?.removeMouse(identifier);
      _state = state;
      if (isOver) {
        _state?.addMouse(identifier);
      }
    }
  }

  @override
  void dispose() {
    _state?.removeMouse(identifier);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: MouseRegion(
            opaque: false,
            hitTestBehavior: .translucent,
            onEnter: (_) {
              if (!isOver) {
                isOver = true;
                _state?.addMouse(identifier);
              }
            },

            onExit: (_) {
              isOver = false;
              _state?.removeMouse(identifier);
            },
            child: const ColoredBox(color: Color(0x00000000)),
          ),
        ),
      ],
    );
  }
}
