// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/services/pip_service.dart';

class ViewVideoScreen extends StatefulWidget {
  final String videoPath;
  const ViewVideoScreen({super.key, required this.videoPath});

  @override
  State<ViewVideoScreen> createState() => _ViewVideoScreenState();
}

class _ViewVideoScreenState extends State<ViewVideoScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isInitialized = false;
  bool _isPipMode = false;
  late StreamSubscription<bool> _pipModeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePipService();
    _initializeVideoPlayer();
  }

  void _initializePipService() {
    // Initialize PIP service
    PipService.instance.initialize();

    // Listen to PIP mode changes
    _pipModeSubscription = PipService.instance.pipModeStream.listen((isPip) {
      if (mounted) {
        setState(() {
          _isPipMode = isPip;
        });

        if (_isPipMode) {
          _optimizeForPipMode();
        } else {
          _optimizeForNormalMode();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle PIP mode detection
    if (state == AppLifecycleState.paused) {
      // App might be in PIP mode or user pressed home
      _checkPipMode();
    } else if (state == AppLifecycleState.resumed) {
      // App returned from PIP mode
      if (_isPipMode) {
        setState(() {
          _isPipMode = false;
        });
        _optimizeForNormalMode();
      }
    }
  }

  void _checkPipMode() {
    // Check if the app is in PIP mode by examining screen dimensions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        final isPip = PipService.instance
            .isPipModeByDimensions(screenSize.width, screenSize.height);

        if (isPip != _isPipMode) {
          setState(() {
            _isPipMode = isPip;
          });

          if (_isPipMode) {
            _optimizeForPipMode();
          } else {
            _optimizeForNormalMode();
          }
        }
      }
    });
  }

  void _optimizeForPipMode() {
    // Optimize video player for PIP mode
    if (_chewieController.isFullScreen) {
      _chewieController.exitFullScreen();
    }

    // Hide system UI for better PIP experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // Update PIP parameters with video info
    if (_videoPlayerController.value.isInitialized) {
      final aspectRatio = PipService.instance.getOptimalAspectRatio(
        _videoPlayerController.value.size.width,
        _videoPlayerController.value.size.height,
      );

      PipService.instance.updatePipParams(
        aspectRatio: aspectRatio,
        title: 'ANR Saver',
        subtitle: 'Playing Video',
      );
    }
  }

  void _optimizeForNormalMode() {
    // Restore system UI when not in PIP mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);
  }

  Future<void> _enterPipMode() async {
    if (_videoPlayerController.value.isInitialized) {
      final aspectRatio = PipService.instance.getOptimalAspectRatio(
        _videoPlayerController.value.size.width,
        _videoPlayerController.value.size.height,
      );

      final success = await PipService.instance.enterPipMode(
        aspectRatio: aspectRatio,
        title: 'ANR Saver',
        subtitle: 'Video Player',
      );

      if (success) {
        setState(() {
          _isPipMode = true;
        });
        _optimizeForPipMode();
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController =
          VideoPlayerController.file(File(widget.videoPath));
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryColor,
          handleColor: AppColors.primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: AppColors.primaryColor.withOpacity(0.3),
        ),
        placeholder: Container(
          color: AppColors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error playing video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isPipMode ? 12 : 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: _isPipMode ? 10 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipModeSubscription.cancel();
    _videoPlayerController.dispose();
    _chewieController.dispose();
    _optimizeForNormalMode(); // Restore system UI when leaving video screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = PipService.instance
        .isPipModeByDimensions(screenSize.width, screenSize.height);

    // Update PIP mode state based on screen size
    if (isSmallScreen != _isPipMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isPipMode = isSmallScreen;
          });
        }
      });
    }

    return PopScope(
      canPop: !_isPipMode,
      onPopInvoked: (didPop) async {
        if (_isPipMode) {
          await PipService.instance.exitPipMode();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: _buildVideoPlayer(context),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPipSize = PipService.instance
            .isPipModeByDimensions(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: Chewie(
                  controller: _chewieController,
                ),
              ),
            ),

            // Close button and PIP button - only show when not in PIP mode
            if (!isPipSize) ...[
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: _buildCloseButton(),
              ),
              // PIP mode button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: _buildPipButton(),
              ),
            ],

            // PIP controls overlay
            if (isPipSize) _buildPipControls(),
          ],
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPipButton() {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enterPipMode,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.picture_in_picture_alt,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPipControls() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          // Toggle play/pause on tap in PIP mode
          if (_videoPlayerController.value.isPlaying) {
            _videoPlayerController.pause();
          } else {
            _videoPlayerController.play();
          }
        },
        onDoubleTap: () {
          // Double tap to exit PIP mode
          PipService.instance.exitPipMode();
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity: _videoPlayerController.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _videoPlayerController.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
