// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anr_saver/src/core/common_widgets/circular_loader_with_overlay.dart';
import '../../../../config/routes_manager.dart';
import '../bloc/downloader_bloc/downloader_bloc.dart';
import '../widgets/downloader_Screen/downloader_screen_body.dart';
import '../widgets/downloader_Screen/downloader_screen_bottom_app_bar.dart';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({super.key});

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  Future<void> _handleDonation() async {
    try {
      _showDonationDialog();
    } catch (e) {
      // If dialog fails to show, show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to show donation: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDonationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support Developer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Help keep this app free & updated',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Scan QRIS Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Use any Indonesian e-wallet or mobile banking app',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // QRIS Image
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            'assets/donate/donate.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.grey[400], size: 40),
                                    const SizedBox(height: 10),
                                    Text('QRIS image not found',
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Supported apps
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          _buildPaymentChip('GoPay'),
                          _buildPaymentChip('OVO'),
                          _buildPaymentChip('DANA'),
                          _buildPaymentChip('ShopeePay'),
                          _buildPaymentChip('LinkAja'),
                          _buildPaymentChip('Bank Apps'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        '❤️ Thank you for your support! ❤️',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloaderBloc, DownloaderState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Main content
              const DownloaderScreenBody(),
              // Loading overlay
              if (state is DownloaderGetVideoLoading)
                const CircularLoaderWithOverlay(),
            ],
          ),
          bottomNavigationBar: DownloaderBottomAppBar(
            onSharePressed: _handleDonation,
            onDownloadPressed: () {
              Navigator.of(context).pushNamed(Routes.downloads);
            },
          ),
        );
      },
    );
  }
}
