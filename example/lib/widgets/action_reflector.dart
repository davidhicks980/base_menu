import 'dart:async';

import 'package:flutter/widgets.dart';

class ActionReflector extends StatefulWidget {
  const ActionReflector({super.key, required this.child});
  final Widget child;

  @override
  State<ActionReflector> createState() => _ActionReflectorState();
}

class _ActionReflectorState extends State<ActionReflector> {
  final List<String> _notifications = [];
  GlobalKey<SliverAnimatedListState>? listKey = GlobalKey<SliverAnimatedListState>();
  int index = 0;

  void _notify(BuildContext context, String label) {
    if (_notifications.length == 10) {
      final removedLabel = _notifications.removeAt(0);
      listKey?.currentState?.removeItem(
        0,
        (context, animation) => _Notification(label: removedLabel, animation: animation),
      );
      index--;
    }

    _notifications.add(label);
    listKey?.currentState?.insertItem(index);
    index++;

    Timer(const Duration(seconds: 2), () {
      if (_notifications.contains(label)) {
        _notifications.remove(label);
        listKey?.currentState?.removeItem(
          0,
          (context, animation) => _Notification(label: label, animation: animation),
        );
        index--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {ShowSnackbarTextIntent: _LocalShowSnackbarAction()},
      child: Stack(
        children: [
          widget.child,
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: [
                  SliverAnimatedList(
                    key: listKey,
                    itemBuilder: (context, index, animation) {
                      return _Notification(label: _notifications[index], animation: animation);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notification extends StatelessWidget {
  const _Notification({required this.label, required this.animation});

  final String label;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1f1f1f),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: Align(
            heightFactor: animation.value,
            widthFactor: animation.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ShowSnackbarTextIntent extends Intent {
  const ShowSnackbarTextIntent(this.message);
  final String message;
}

class _LocalShowSnackbarAction extends ContextAction<ShowSnackbarTextIntent> {
  @override
  Object? invoke(ShowSnackbarTextIntent intent, [BuildContext? context]) {
    context?.findAncestorStateOfType<_ActionReflectorState>()?._notify(context, intent.message);
    return null;
  }
}

class ShowSnackbarAction extends ContextAction<Intent> {
  ShowSnackbarAction(this.message);
  final String message;
  @override
  Object? invoke(Intent intent, [BuildContext? context]) {
    context?.findAncestorStateOfType<_ActionReflectorState>()?._notify(context, message);
    return null;
  }
}

class ReflectAction extends ContextAction<Intent> {
  @override
  Object? invoke(Intent intent, [BuildContext? context]) {
    context?.findAncestorStateOfType<_ActionReflectorState>()?._notify(context, 'Intent invoked');
    return null;
  }
}
