import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerLine(width: 0.6, height: 18),
                const SizedBox(height: 12),
                _shimmerLine(width: 0.9, height: 14),
                const SizedBox(height: 8),
                _shimmerLine(width: 0.5, height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [
            AppColors.borderLight.withValues(alpha: 0.3),
            AppColors.borderLight.withValues(alpha: 0.6),
            AppColors.borderLight.withValues(alpha: 0.3),
          ],
        ).createShader(bounds),
        child: Container(
          width: MediaQuery.of(context).size.width * width,
          height: height,
          color: AppColors.borderLight.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
