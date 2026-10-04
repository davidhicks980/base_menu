import 'package:flutter/material.dart';

class BaseMenuApp extends StatefulWidget {
  const BaseMenuApp({
    super.key,
    this.textDirection,
    this.alignment = Alignment.topLeft,
    this.backgroundColor = const Color(0xff000000),
    required this.title,
    required this.initialRoute,
    required this.routes,
    this.textStyle,
  });

  final TextDirection? textDirection;
  final AlignmentGeometry alignment;
  final Color backgroundColor;
  final String title;
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;
  final TextStyle? textStyle;

  @override
  State<BaseMenuApp> createState() => _BaseMenuAppState();
}

class _BaseMenuAppState extends State<BaseMenuApp> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: FocusScope(
          autofocus: true,
          child: WidgetsApp(
            pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
                PageRouteBuilder<T>(
                  settings: settings,
                  pageBuilder:
                      (
                        BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation,
                      ) => builder(context),
                ),
            title: widget.title,
            routes: widget.routes,
            initialRoute: widget.initialRoute,
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            textStyle: widget.textStyle,
            color: widget.backgroundColor,
          ),
        ),
      ),
    );
  }
}
