import 'package:flutter/widgets.dart';

abstract interface class ExclusiveMenuManager {
  void setActive(MenuController controller);
  void setInactive(MenuController controller);
  void replace(MenuController oldController, MenuController newController);
  static ExclusiveMenuManager of(BuildContext context) {
    final manager = InheritedModel.inheritFrom<_ManagerScope>(
      context,
      aspect: _ManagerAspect.manager,
    );
    assert(manager != null, 'No ExclusiveMenuScope found in context');
    return manager!.manager;
  }

  static MenuController? controllerOf(BuildContext context) {
    final scope = InheritedModel.inheritFrom<_ManagerScope>(
      context,
      aspect: _ManagerAspect.controller,
    );
    assert(scope != null, 'No ExclusiveMenuScope found in context');
    return scope!.controller;
  }
}

enum _ManagerAspect { manager, controller }

class _ManagerScope extends InheritedModel<_ManagerAspect> {
  const _ManagerScope({required super.child, required this.manager, this.controller});
  final ExclusiveMenuManager manager;
  final MenuController? controller;

  @override
  bool updateShouldNotify(_ManagerScope oldWidget) {
    return manager != oldWidget.manager || controller != oldWidget.controller;
  }

  @override
  bool updateShouldNotifyDependent(_ManagerScope oldWidget, Set<_ManagerAspect> dependencies) {
    if (dependencies.contains(_ManagerAspect.manager) && manager != oldWidget.manager) {
      return true;
    }

    if (dependencies.contains(_ManagerAspect.controller) && controller != oldWidget.controller) {
      return true;
    }

    return false;
  }
}

class ExclusiveMenuScope extends StatefulWidget {
  const ExclusiveMenuScope({super.key, required this.child});
  final Widget child;

  @override
  State<ExclusiveMenuScope> createState() => _ExclusiveMenuScopeState();
}

class _ExclusiveMenuScopeState extends State<ExclusiveMenuScope> implements ExclusiveMenuManager {
  MenuController? _activeController;

  @override
  void setActive(MenuController controller) {
    if (_activeController != controller) {
      _activeController?.close();
      setState(() {
        _activeController = controller;
      });
    }
  }

  @override
  void setInactive(MenuController controller) {
    if (_activeController == controller) {
      setState(() {
        _activeController = null;
      });
    }
  }

  @override
  void replace(MenuController oldController, MenuController newController) {
    if (_activeController == oldController) {
      setState(() {
        _activeController = newController;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ManagerScope(manager: this, controller: _activeController, child: widget.child);
  }
}
