import 'package:flutter/material.dart';

class BaseMenuApp extends StatefulWidget {
  const BaseMenuApp(
    this.child, {
    super.key,
    this.textDirection,
    this.alignment = Alignment.topLeft,
    this.backgroundColor = const Color(0xff000000),
  });
  final Widget child;
  final TextDirection? textDirection;
  final AlignmentGeometry alignment;
  final Color backgroundColor;

  @override
  State<BaseMenuApp> createState() => _BaseMenuAppState();
}

class _BaseMenuAppState extends State<BaseMenuApp> {
  TextDirection? _directionality;

  @override
  Widget build(BuildContext context) {
    _directionality = Directionality.maybeOf(context);
    return ColoredBox(
      color: widget.backgroundColor,
      child: FocusScope(
        autofocus: true,
        child: WidgetsApp(
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          color: widget.backgroundColor,
          onGenerateRoute: (RouteSettings settings) {
            return PageRouteBuilder<void>(settings: settings, pageBuilder: _buildPage);
          },
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Directionality(
      textDirection: widget.textDirection ?? _directionality ?? TextDirection.ltr,
      child: widget.child,
    );
  }
}
