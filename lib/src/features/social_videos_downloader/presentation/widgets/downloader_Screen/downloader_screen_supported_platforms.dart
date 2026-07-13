// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DownloaderScreenSupportedPlatforms extends StatefulWidget {
  const DownloaderScreenSupportedPlatforms({super.key});

  @override
  State<DownloaderScreenSupportedPlatforms> createState() => _State();
}

class _State extends State<DownloaderScreenSupportedPlatforms> {
  late final ScrollController _ctrl;

  static const _platforms = [
    _P("Facebook", "assets/images/facebook.svg"),
    _P("Instagram", "assets/images/instagram.svg"),
    _P("Threads (Publik)", "assets/images/threads.svg"),
    _P("Twitter/X", "assets/images/twitter.svg"),
    _P("YouTube", "assets/images/youtube.svg"),
    _P("YouTube Music", "assets/images/youtube_music.svg"),
    _P("TikTok", "assets/images/tiktok.svg"),
    _P("Bilibili Global", "assets/images/bilibili.svg"),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScroll());
  }

  void _autoScroll() {
    if (!mounted) return;
    double offset = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 25));
      if (!mounted || !_ctrl.hasClients) return false;
      offset += 0.4;
      if (offset >= _ctrl.position.maxScrollExtent) offset = 0;
      _ctrl.jumpTo(offset);
      return true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [..._platforms, ..._platforms, ..._platforms];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        controller: _ctrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _PlatformChip(p: items[i]),
      ),
    );
  }
}

class _P {
  final String name;
  final String svgPath;
  const _P(this.name, this.svgPath);
}

class _PlatformChip extends StatelessWidget {
  final _P p;
  const _PlatformChip({required this.p});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8EAF0);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
    final iconColor =
        isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.7);
    final textColor =
        isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.7);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            p.svgPath,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Text(
            p.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
