import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../container_injector.dart';
import '../api/interceptors.dart';
import '../utils/app_constants.dart';
import '../utils/api_config.dart';

const String _contentType = "Content-Type";
const String _applicationJson = "application/json";
const String _apiKey = "d307bdba37mshafbe7cf23257480p1a6509jsn16f897d20823";
const String _apiHost = "social-media-video-downloader.p.rapidapi.com";

class DioHelper {
  final Dio dio;

  DioHelper({required this.dio}) {
    Map<String, dynamic> headers = {
      _contentType: _applicationJson,
      "X-RapidAPI-Key": ApiConfig.rapidApiKey,
      "X-RapidAPI-Host": "social-media-video-downloader.p.rapidapi.com",
    };
    dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      receiveDataWhenStatusError: true,
      headers: headers,
    );
    dio.interceptors.add(sl<LogInterceptor>());
    dio.interceptors.add(sl<AppInterceptors>());
  }

  Future<Response> get({
    required String path,
    Map<String, dynamic>? queryParams,
    String? baseUrl,
    Map<String, dynamic>? customHeaders,
  }) async {
    if (baseUrl != null) {
      final tempDio = Dio();
      tempDio.options = BaseOptions(
        baseUrl: baseUrl,
        receiveDataWhenStatusError: true,
        headers: customHeaders ?? dio.options.headers,
      );
      tempDio.interceptors.add(sl<LogInterceptor>());
      return await tempDio.get(path, queryParameters: queryParams);
    }
    return await dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParams,
    String? baseUrl,
    Map<String, dynamic>? customHeaders,
  }) async {
    if (baseUrl != null) {
      final tempDio = Dio();
      tempDio.options = BaseOptions(
        baseUrl: baseUrl,
        receiveDataWhenStatusError: true,
        headers: customHeaders ?? {_contentType: _applicationJson},
      );
      tempDio.interceptors.add(sl<LogInterceptor>());
      return await tempDio.post(
        path,
        data: data,
        queryParameters: queryParams,
      );
    }

    return await dio.post(
      path,
      data: data,
      queryParameters: queryParams,
    );
  }

  Future<Response> download({
    required String downloadLink,
    required String savePath,
    Map<String, dynamic>? queryParams,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    Dio downloadDio = Dio();

    // Configure timeout and connection settings for better performance
    downloadDio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
    );

    RandomAccessFile? raf;

    try {
      // Download the file with optimized settings
      Response<ResponseBody> response = await downloadDio.get<ResponseBody>(
        downloadLink,
        options: Options(
          headers: {
            "X-RapidAPI-Key": _apiKey,
            "X-RapidAPI-Host": _apiHost,
            "Accept": "*/*",
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Range": "bytes=0-", // Support for resume downloads
          },
          responseType: ResponseType.stream,
        ),
        onReceiveProgress: (received, total) {
          // Throttle progress updates to improve performance
          if (onReceiveProgress != null && total > 0) {
            // Only update progress every 0.5% to prevent UI blocking
            final progress = (received / total * 100);
            if (received == 0 || received == total || (progress % 0.5) < 0.1) {
              onReceiveProgress(received, total);
            }
          }
        },
      );

      // Validate response
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception(
            "Download failed with status code: ${response.statusCode}");
      }

      final file = File(savePath);

      // Create directory if it doesn't exist
      final directory = file.parent;
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      raf = file.openSync(mode: FileMode.write);

      // Write data to the file with improved error handling
      await response.data!.stream.listen(
        (data) {
          try {
            raf!.writeFromSync(data);
          } catch (e) {
            throw Exception("Failed to write data to file: $e");
          }
        },
        onDone: () async {
          try {
            await raf?.close();
          } catch (e) {
            // Log but don't throw, file might already be closed
          }
        },
        onError: (error) async {
          try {
            await raf?.close();
          } catch (e) {
            // Log but don't throw
          }
          throw Exception("Stream error during download: $error");
        },
      ).asFuture();

      // Verify file was created and has content
      if (!file.existsSync()) {
        throw Exception("Download failed: File was not created");
      }

      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        await file.delete();
        throw Exception("Download failed: File is empty");
      }

      return response;
    } catch (e) {
      // Clean up on error
      try {
        await raf?.close();
        final file = File(savePath);
        if (file.existsSync() && file.lengthSync() == 0) {
          await file.delete();
        }
      } catch (cleanupError) {
        // Log cleanup error but don't throw
      }
      rethrow;
    }
  }

  Future<Response> downloadImage({
    required String downloadLink,
    required String savePath,
    Map<String, dynamic>? queryParams,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    Dio imageDio = Dio();

    // Configure timeout and connection settings for image downloads
    imageDio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 20),
      followRedirects: true,
      maxRedirects: 5,
    );

    RandomAccessFile? raf;

    try {
      // Download the image file with optimized settings
      Response<ResponseBody> response = await imageDio.get<ResponseBody>(
        downloadLink,
        options: Options(
          headers: {
            "Accept": "image/*,*/*",
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://xiaohongshu.com/",
            "Cache-Control": "no-cache",
          },
          responseType: ResponseType.stream,
        ),
        onReceiveProgress: (received, total) {
          // Throttle progress updates for images too
          if (onReceiveProgress != null && total > 0) {
            // Only update progress every 1% for images to prevent UI blocking
            final progress = (received / total * 100);
            if (received == 0 || received == total || (progress % 1.0) < 0.1) {
              onReceiveProgress(received, total);
            }
          }
        },
      );

      // Validate response
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception(
            "Image download failed with status code: ${response.statusCode}");
      }

      final file = File(savePath);

      // Create directory if it doesn't exist
      final directory = file.parent;
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      raf = file.openSync(mode: FileMode.write);

      // Write image data to the file with improved error handling
      await response.data!.stream.listen(
        (data) {
          try {
            raf!.writeFromSync(data);
          } catch (e) {
            throw Exception("Failed to write image data to file: $e");
          }
        },
        onDone: () async {
          try {
            await raf?.close();
          } catch (e) {
            // Log but don't throw, file might already be closed
          }
        },
        onError: (error) async {
          try {
            await raf?.close();
          } catch (e) {
            // Log but don't throw
          }
          throw Exception("Stream error during image download: $error");
        },
      ).asFuture();

      // Verify image file was created and has content
      if (!file.existsSync()) {
        throw Exception("Image download failed: File was not created");
      }

      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        await file.delete();
        throw Exception("Image download failed: File is empty");
      }

      // Basic image validation - check for common image headers
      final bytes = file.readAsBytesSync().take(10).toList();
      if (bytes.length >= 4) {
        bool isValidImage = false;

        // Check for JPEG header (FF D8)
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
          isValidImage = true;
        }
        // Check for PNG header (89 50 4E 47)
        if (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47) {
          isValidImage = true;
        }
        // Check for WebP header (52 49 46 46)
        if (bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46) {
          isValidImage = true;
        }

        if (!isValidImage) {
          await file.delete();
          throw Exception("Downloaded file is not a valid image format");
        }
      }

      return response;
    } catch (e) {
      // Clean up on error
      try {
        await raf?.close();
        final file = File(savePath);
        if (file.existsSync() && file.lengthSync() == 0) {
          await file.delete();
        }
      } catch (cleanupError) {
        // Log cleanup error but don't throw
      }
      rethrow;
    }
  }
}
