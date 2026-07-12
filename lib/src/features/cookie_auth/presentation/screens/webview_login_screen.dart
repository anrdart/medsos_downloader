// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_constants.dart';
import '../../data/models/platform_login_config.dart';
import '../../data/services/cookie_extraction_service.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';

class WebViewLoginScreen extends StatefulWidget {
  final SocialPlatform platform;
  const WebViewLoginScreen({super.key, required this.platform});

  @override
  State<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends State<WebViewLoginScreen> {
  late final WebViewController _controller;
  late final PlatformLoginConfig _config;
  final CookieExtractionService _extractionService = CookieExtractionService();
  bool _loading = true;
  bool _extracted = false;
  String _statusText = "Menunggu login...";

  @override
  void initState() {
    super.initState();
    _config = PlatformLoginConfig.getConfig(widget.platform)!;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _loading = true);
          _onUrlChanged(url);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _loading = false);
          _tryExtractCookies("pageFinished");
        },
        onUrlChange: (change) {
          if (change.url != null) _onUrlChanged(change.url!);
        },
        onWebResourceError: (error) {
          // Page load failed (timeout etc) - still try to extract cookies
          // because login might have succeeded before the redirect timed out
          _tryExtractCookies("webError: ${error.description}");
        },
      ))
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..loadRequest(Uri.parse(_config.loginUrl));
  }

  void _onUrlChanged(String url) {
    if (_extracted) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final isSuccessPage = _config.successDomains.any(
      (domain) => uri.host == domain || uri.host.endsWith(".$domain"),
    );

    if (isSuccessPage) {
      if (mounted) {
        setState(() => _statusText = "Login terdeteksi, mengambil cookies...");
      }
      // Delay to let cookies propagate, then extract
      Future.delayed(const Duration(seconds: 2), () {
        _tryExtractCookies("successUrl");
      });
    }
  }

  Future<void> _tryExtractCookies(String trigger) async {
    if (_extracted) return;

    try {
      final cookies = await _extractionService.extractCookies(
        _controller,
        widget.platform,
      );

      if (cookies.isEmpty) return;

      if (_extractionService.isLoginSuccessful(cookies, widget.platform)) {
        _extracted = true;
        if (mounted) {
          context.read<AccountBloc>().add(
                CookiesExtracted(platform: widget.platform, cookies: cookies),
              );
          Navigator.of(context).pop(true);
        }
      }
    } catch (_) {
      // JavaScript extraction failed (page not loaded) - ignore, will retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final fgColor = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final mutedColor = isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: fgColor),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          "Login ${_config.name}",
          style: TextStyle(color: fgColor, fontSize: 16),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: cardColor,
            child: Text(
              _statusText,
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
