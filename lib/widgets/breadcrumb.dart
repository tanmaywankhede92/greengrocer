import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class Crumb {
  final String label;
  final String? route;
  const Crumb(this.label, {this.route});
}

class Breadcrumb extends StatelessWidget {
  final List<Crumb> crumbs;
  const Breadcrumb({super.key, required this.crumbs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 4),
      child: Row(
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0) const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary),
            ),
            if (crumbs[i].route != null)
              GestureDetector(
                onTap: () => context.go(crumbs[i].route!),
                child: Text(crumbs[i].label, style: const TextStyle(color: AppTheme.primaryGreenLight, fontSize: 13)),
              )
            else
              Text(crumbs[i].label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
