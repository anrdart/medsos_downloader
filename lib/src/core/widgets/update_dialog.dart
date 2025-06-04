// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/update_service.dart';

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

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  StreamSubscription<UpdateStatus>? _statusSubscription;
  StreamSubscription<DownloadProgress>? _progressSubscription;
  UpdateStatus _currentStatus = UpdateStatus.available;
  DownloadProgress? _downloadProgress;
  int _selectedTabIndex = 0;

  late AnimationController _progressAnimationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    _currentStatus = UpdateStatus.available;
  }

  void _setupAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    final statusStream = widget.updateService.statusStream;
    if (statusStream != null) {
      _statusSubscription = statusStream.listen((status) {
        if (!mounted) return;

        // Handle different statuses
        if (status == UpdateStatus.downloading) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });
            _pulseController.repeat(reverse: true);
            _fadeController.forward(); // Show progress section
          }
        } else if (status == UpdateStatus.installing) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });
            _pulseController.stop();
            _pulseController.reset();
          }
        } else if (status == UpdateStatus.installed) {
          // Handle installation completion - close dialog immediately
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });

            // Stop all animations immediately
            _pulseController.stop();
            _pulseController.reset();
            _fadeController.reverse();

            // Clear any stale progress data
            _downloadProgress = null;

            // Show success message with more details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Installation initiated! If settings opened, please enable "Install from unknown sources" and try installing again.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                action: SnackBarAction(
                  label: 'Open Settings',
                  textColor: Colors.white,
                  onPressed: () {
                    widget.updateService.openUnknownSourcesSettings();
                  },
                ),
              ),
            );

            // Close dialog immediately without delay
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        } else if (status == UpdateStatus.error) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Update failed. Please try again.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );
          }
        } else if (status == UpdateStatus.cancelled) {
          // Handle cancellation gracefully
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });

            // Stop all animations
            _pulseController.stop();
            _pulseController.reset();
            _fadeController.reverse();

            // Clear progress data
            _downloadProgress = null;

            // Show cancellation message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Download cancelled. You can retry anytime.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
              ),
            );

            // Wait a moment then close dialog
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });
            _pulseController.stop();
            _pulseController.reset();
            if (status != UpdateStatus.installing) {
              _fadeController.reverse(); // Hide progress section
            }
          }
        }
      });
    }

    final downloadStream = widget.updateService.downloadStream;
    if (downloadStream != null) {
      _progressSubscription = downloadStream.listen((progress) {
        if (!mounted) return;

        // Only update progress if we're actually downloading
        if (_currentStatus == UpdateStatus.downloading) {
          setState(() {
            _downloadProgress = progress;
          });
          // Animate progress bar to match actual download progress
          if (mounted) {
            try {
              _progressAnimationController.animateTo(
                progress.progress,
                duration: const Duration(milliseconds: 100),
              );
            } catch (e) {
              // Ignore animation errors during disposal
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions first to stop incoming events
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _progressSubscription?.cancel();
    _progressSubscription = null;

    // Safely dispose animation controllers
    try {
      if (_progressAnimationController.status != AnimationStatus.dismissed &&
          _progressAnimationController.status != AnimationStatus.completed) {
        _progressAnimationController.stop();
      }
      _progressAnimationController.reset();
      _progressAnimationController.dispose();
    } catch (e) {
      // Controller already disposed
    }

    try {
      if (_pulseController.status != AnimationStatus.dismissed &&
          _pulseController.status != AnimationStatus.completed) {
        _pulseController.stop();
      }
      _pulseController.reset();
      _pulseController.dispose();
    } catch (e) {
      // Controller already disposed
    }

    try {
      if (_fadeController.status != AnimationStatus.dismissed &&
          _fadeController.status != AnimationStatus.completed) {
        _fadeController.stop();
      }
      _fadeController.reset();
      _fadeController.dispose();
    } catch (e) {
      // Controller already disposed
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          maxWidth: screenWidth > 600 ? 480 : screenWidth * 0.95,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildVersionInfo(),
            _buildProgressSection(),
            if (_currentStatus != UpdateStatus.downloading &&
                _currentStatus != UpdateStatus.installing)
              _buildTabBar(),
            Flexible(
              child: _buildTabContent(),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(),
            _getStatusColor().withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getStatusSubtitle(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: 20,
            onPressed: () {
              if (_currentStatus != UpdateStatus.downloading &&
                  _currentStatus != UpdateStatus.installing) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildVersionCard(
              'Current',
              widget.updateInfo.currentVersionName,
              Icons.smartphone,
              Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward,
              color: _getStatusColor(),
              size: 20,
            ),
          ),
          Expanded(
            child: _buildVersionCard(
              'New',
              widget.updateInfo.versionName,
              Icons.system_update,
              _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(
      String title, String version, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            version,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_currentStatus != UpdateStatus.downloading &&
        _currentStatus != UpdateStatus.installing) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getStatusColor().withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _currentStatus == UpdateStatus.downloading
                        ? 'Downloading...'
                        : 'Installing...',
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_downloadProgress != null &&
                    _currentStatus == UpdateStatus.downloading)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      '${_downloadProgress!.progressPercentage}%',
                      key: ValueKey(_downloadProgress!.progressPercentage),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _getStatusColor().withOpacity(0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _currentStatus == UpdateStatus.downloading
                          ? (_downloadProgress?.progress ?? 0.0)
                          : null,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      minHeight: 6,
                    ),
                  ),
                );
              },
            ),
            if (_downloadProgress != null &&
                _currentStatus == UpdateStatus.downloading) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _downloadProgress!.formattedProgress,
                      style: TextStyle(
                        color: _getStatusColor().withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${_downloadProgress!.formattedSpeed} • ETA: ${_downloadProgress!.formattedETA}',
                      style: TextStyle(
                        color: _getStatusColor().withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    if (_currentStatus == UpdateStatus.downloading ||
        _currentStatus == UpdateStatus.installing) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          _buildTab('What\'s New', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _getStatusColor() : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_currentStatus == UpdateStatus.downloading ||
        _currentStatus == UpdateStatus.installing) {
      return _buildDownloadingContent();
    }

    return SingleChildScrollView(
      child: _getTabContent(),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildWhatsNewTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildDownloadingContent() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 64,
                    color: _getStatusColor().withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currentStatus == UpdateStatus.downloading
                        ? 'Downloading Update'
                        : 'Installing Update',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentStatus == UpdateStatus.downloading
                        ? 'Please wait while we download the latest version...'
                        : 'Installing update. This may take a few moments...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.updateInfo.updateDescription,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
              'File Size', widget.updateInfo.formattedFileSize, Icons.storage),
          _buildInfoRow('Release Date',
              _formatDate(widget.updateInfo.releaseDate), Icons.calendar_today),
          if (widget.updateInfo.isForced)
            _buildInfoRow('Update Type', 'Required', Icons.priority_high,
                color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildWhatsNewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.updateInfo.featureHighlights.isNotEmpty) ...[
            _buildSectionTitle('✨ New Features', Icons.star),
            ...widget.updateInfo.featureHighlights
                .map((feature) => _buildListItem(feature, Colors.green)),
            const SizedBox(height: 16),
          ],
          if (widget.updateInfo.improvements.isNotEmpty) ...[
            _buildSectionTitle('🚀 Improvements', Icons.trending_up),
            ...widget.updateInfo.improvements
                .map((improvement) => _buildListItem(improvement, Colors.blue)),
            const SizedBox(height: 16),
          ],
          if (widget.updateInfo.bugFixes.isNotEmpty) ...[
            _buildSectionTitle('🐛 Bug Fixes', Icons.bug_report),
            ...widget.updateInfo.bugFixes
                .map((fix) => _buildListItem(fix, Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _getStatusColor()),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? _getStatusColor()),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.updateInfo.isForced &&
              _currentStatus != UpdateStatus.downloading &&
              _currentStatus != UpdateStatus.installing) ...[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.updateService
                          .skipVersion(widget.updateInfo.versionName);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Skip Version',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.updateService.remindLater();
                      Navigator.of(context).pop();

                      // Show confirmation message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.schedule,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child:
                                    Text('Update reminder set for 10 minutes'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Remind Later',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: _buildMainActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    switch (_currentStatus) {
      case UpdateStatus.available:
        return ElevatedButton(
          onPressed: _handleDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 16),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Download & Install',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '(${widget.updateInfo.formattedFileSize})',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      case UpdateStatus.downloading:
        return ElevatedButton(
          onPressed: () {
            widget.updateService.cancelDownload();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 16),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Cancel Download',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case UpdateStatus.installing:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Installing...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleDownload() async {
    if (widget.updateInfo.hasDownloadUrl) {
      try {
        await widget.updateService
            .downloadAndInstall(widget.updateInfo.downloadUrl!);
      } catch (error) {
        // Don't show error snackbar for cancelled downloads
        if (mounted && !error.toString().contains('cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Download failed: $error'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case UpdateStatus.available:
        return const Color(0xFF4CAF50);
      case UpdateStatus.downloading:
        return const Color(0xFF2196F3);
      case UpdateStatus.installing:
        return const Color(0xFFFF9800);
      case UpdateStatus.installed:
        return const Color(0xFF4CAF50);
      case UpdateStatus.cancelled:
        return const Color(0xFFFF9800);
      case UpdateStatus.error:
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case UpdateStatus.available:
        return Icons.system_update;
      case UpdateStatus.downloading:
        return Icons.download;
      case UpdateStatus.installing:
        return Icons.install_mobile;
      case UpdateStatus.installed:
        return Icons.check_circle;
      case UpdateStatus.cancelled:
        return Icons.cancel;
      case UpdateStatus.error:
        return Icons.error;
      default:
        return Icons.system_update;
    }
  }

  String _getStatusTitle() {
    switch (_currentStatus) {
      case UpdateStatus.available:
        return 'Update Available';
      case UpdateStatus.downloading:
        return 'Downloading Update';
      case UpdateStatus.installing:
        return 'Installing Update';
      case UpdateStatus.installed:
        return 'Update Installed';
      case UpdateStatus.cancelled:
        return 'Download Cancelled';
      case UpdateStatus.error:
        return 'Update Failed';
      default:
        return 'Update Available';
    }
  }

  String _getStatusSubtitle() {
    switch (_currentStatus) {
      case UpdateStatus.available:
        return widget.updateInfo.updateTitle;
      case UpdateStatus.downloading:
        return 'Please wait...';
      case UpdateStatus.installing:
        return 'Almost done...';
      case UpdateStatus.installed:
        return 'Restart app to apply changes';
      case UpdateStatus.cancelled:
        return 'You can retry the download';
      case UpdateStatus.error:
        return 'Please try again';
      default:
        return widget.updateInfo.updateTitle;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
