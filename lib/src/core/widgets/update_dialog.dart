// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final UpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _Phase { info, downloading, installing, done, error }

class _UpdateDialogState extends State<UpdateDialog> {
  _Phase _phase = _Phase.info;
  double _progress = 0;
  String _errorMsg = "";

  Future<void> _startDownload() async {
    setState(() => _phase = _Phase.downloading);

    final path = await widget.updateService.downloadUpdate(
      widget.updateInfo.downloadUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    if (path == null) {
      setState(() {
        _phase = _Phase.error;
        _errorMsg = "Download gagal. Coba lagi.";
      });
      return;
    }

    setState(() => _phase = _Phase.installing);
    final installed = await widget.updateService.installUpdate(path);

    if (mounted) {
      if (installed) {
        setState(() => _phase = _Phase.done);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = "Instalasi gagal. Coba install manual.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildSubtitle(),
            const SizedBox(height: 16),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (_phase) {
      case _Phase.info:
        return const Icon(Icons.system_update, color: AppColors.primaryColor, size: 48);
      case _Phase.downloading:
        return SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: _progress > 0 ? _progress : null,
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        );
      case _Phase.installing:
        return const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case _Phase.done:
        return Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        );
      case _Phase.error:
        return Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 28),
        );
    }
  }

  Widget _buildTitle() {
    final titles = {
      _Phase.info: AppStrings.updateAvailable,
      _Phase.downloading: "Mengunduh Update...",
      _Phase.installing: "Menginstall...",
      _Phase.done: "Selesai!",
      _Phase.error: "Gagal",
    };
    return Text(
      titles[_phase]!,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSubtitle() {
    final info = widget.updateInfo;
    if (_phase == _Phase.downloading) {
      return Text(
        "${(_progress * 100).toInt()}%",
        style: TextStyle(color: AppColors.primaryColor, fontSize: 20, fontWeight: FontWeight.w700),
      );
    }
    if (_phase == _Phase.error) {
      return Text(_errorMsg, textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13));
    }
    if (_phase == _Phase.done) {
      return Text("Installer terbuka. Ikuti instruksi di layar.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13));
    }
    return Text(
      "v${info.currentVersionName} → v${info.versionName}",
      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
    );
  }

  Widget _buildBody() {
    final info = widget.updateInfo;

    switch (_phase) {
      case _Phase.info:
        return Column(
          children: [
            if (info.changelog.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(info.changelog,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppStrings.downloadAndInstall),
              ),
            ),
            if (!info.isForced) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.later, style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ),
            ],
          ],
        );

      case _Phase.downloading:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Jangan tutup dialog ini",
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
            ),
          ],
        );

      case _Phase.installing:
        return Text(
          "Membuka installer...",
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        );

      case _Phase.done:
        return const SizedBox.shrink();

      case _Phase.error:
        return Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _phase = _Phase.info),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Coba Lagi"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Tutup", style: TextStyle(color: Colors.white.withOpacity(0.4))),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
