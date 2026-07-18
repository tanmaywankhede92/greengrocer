import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryRed),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}
