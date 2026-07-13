// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Lightweight shimmer skeleton (no external package). Wrap a placeholder
/// layout to show an animated loading state while data is being fetched.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_c.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0x22FFFFFF),
                Color(0x66FFFFFF),
                Color(0x22FFFFFF),
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A single grey block used as a skeleton placeholder.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton that mimics the download bottom sheet (thumbnail + title +
/// quality options) shown while fetching video info.
class DownloadSheetSkeleton extends StatelessWidget {
  const DownloadSheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Shimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Center(
              child: SkeletonBox(width: 40, height: 4, radius: 2),
            ),
            SizedBox(height: 16),
            SkeletonBox(height: 160, radius: 12), // thumbnail
            SizedBox(height: 14),
            SkeletonBox(width: 220, height: 16), // title
            SizedBox(height: 8),
            SkeletonBox(width: 140, height: 12), // subtitle
            SizedBox(height: 18),
            Row(children: [
              Expanded(child: SkeletonBox(height: 40, radius: 20)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 40, radius: 20)),
            ]),
            SizedBox(height: 12),
            SkeletonBox(height: 48, radius: 24), // download button
          ],
        ),
      ),
    );
  }
}
