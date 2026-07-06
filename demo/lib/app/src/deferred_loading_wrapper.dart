import 'package:flutter/material.dart';

class DeferredLoadingWrapper extends StatelessWidget {
  const DeferredLoadingWrapper({super.key, required this.loadFuture, required this.builder});
  final Future<dynamic> loadFuture;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
