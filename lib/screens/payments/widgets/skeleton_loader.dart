import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final int rows;
  final double rowHeight;
  const SkeletonLoader({super.key, this.rows = 6, this.rowHeight = 56});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.rows, (i) {
            final opacity = 0.04 + ((_controller.value + i * 0.1) % 1.0) * 0.06;
            return Container(
              height: widget.rowHeight,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha((opacity * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        );
      },
    );
  }
}
