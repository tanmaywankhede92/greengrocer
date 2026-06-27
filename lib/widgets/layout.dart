import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'header.dart';
import '../config/theme.dart';

class Layout extends StatelessWidget {
  final Widget child;
  const Layout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const Header(),
                Expanded(
                  child: Container(
                    color: AppTheme.surfaceDark,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
