import 'package:flutter/material.dart';

class VideoStatusWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const VideoStatusWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, color: color, size: 16),
      ],
    );
  }
}
