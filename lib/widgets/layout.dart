import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'header.dart';
import '../config/theme.dart';
import '../core/constants.dart';

class Layout extends StatelessWidget {
  final Widget child;
  const Layout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppConstants.desktopBreakpoint;

        if (isDesktop) {
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

        return Scaffold(
          drawer: const Drawer(
            child: Sidebar(),
          ),
          body: Builder(
            builder: (ctx) => Column(
              children: [
                Header(
                  onMenuTap: () => Scaffold.of(ctx).openDrawer(),
                ),
                Expanded(
                  child: Container(
                    color: AppTheme.surfaceDark,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
