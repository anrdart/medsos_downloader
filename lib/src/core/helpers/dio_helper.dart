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
    Dio dio = Dio();

    // Download the file
    Response<ResponseBody> response = await dio.get<ResponseBody>(
      downloadLink,
      options: Options(
        headers: {
          "X-RapidAPI-Key": _apiKey,
          "X-RapidAPI-Host": _apiHost,
          "Accept": "*/*",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36",
        },
        responseType: ResponseType.stream,
      ),
      onReceiveProgress: onReceiveProgress,
    );

    final file = File(savePath);
    final raf = file.openSync(mode: FileMode.write);

    // Write data to the file
    await response.data!.stream.listen(
      (data) {
        raf.writeFromSync(data);
      },
      onDone: () async {
        await raf.close();
      },
      onError: (error) {
        raf.close();
      },
    ).asFuture();

    return response;
  }

  Future<Response> downloadImage({
    required String downloadLink,
    required String savePath,
    Map<String, dynamic>? queryParams,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    Dio dio = Dio();

    // Download the image file
    Response<ResponseBody> response = await dio.get<ResponseBody>(
      downloadLink,
      options: Options(
        headers: {
          "Accept": "image/*,*/*",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36",
          "Referer": "https://xiaohongshu.com/",
        },
        responseType: ResponseType.stream,
      ),
      onReceiveProgress: onReceiveProgress,
    );

    final file = File(savePath);
    final raf = file.openSync(mode: FileMode.write);

    // Write image data to the file
    await response.data!.stream.listen(
      (data) {
        raf.writeFromSync(data);
      },
      onDone: () async {
        await raf.close();
      },
      onError: (error) {
        raf.close();
      },
    ).asFuture();

    return response;
  }
}
