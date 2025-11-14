import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'miqra_bottom_nav.dart';

class MiqraShellScaffold extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MiqraShellScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MiqraBottomNav(
        currentLocation: currentLocation,
        onTabSelected: (path) {
          if (path == currentLocation) return;
          context.go(path);
        },
      ),
    );
  }
}

