import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PayloadTooLargeException implements Exception {
  final String message;
  PayloadTooLargeException(this.message);
  @override
  String toString() => message;
}

class DeviceUnreachableException implements Exception {
  final String message;
  DeviceUnreachableException(this.message);
  @override
  String toString() => message;
}

class GifBuddyClient {
  GifBuddyClient(this.host);

  final String host;

  String get _base => 'http://$host';

  Future<bool> ping() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
        sendTimeout: const Duration(seconds: 2),
        responseType: ResponseType.plain,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        responseHeader: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[gif-buddy:ping] $o'),
      ));
    }
    try {
      final res = await dio.get<String>('$_base/');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[gif-buddy:ping] failed: $e');
      return false;
    } finally {
      dio.close(force: true);
    }
  }

  Future<Uint8List> downloadGif(
    String url, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.bytes,
      ),
    );
    try {
      final res = await dio.get<List<int>>(
        url,
        onReceiveProgress: onProgress,
      );
      return Uint8List.fromList(res.data ?? const []);
    } finally {
      dio.close(force: true);
    }
  }

  Future<int> uploadGif(
    Uint8List bytes, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: false, // binary
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint('[gif-buddy:upload] $o'),
      ));
    }
    debugPrint(
      '[gif-buddy:upload] POST $_base/gif '
      'Content-Type=application/octet-stream Content-Length=${bytes.length}',
    );
    var bodyFullySentLogged = false;
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '$_base/gif',
        data: Stream.fromIterable([bytes]),
        options: Options(
          contentType: 'application/octet-stream',
          headers: {Headers.contentLengthHeader: bytes.length},
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
        ),
        onSendProgress: (sent, total) {
          if (!bodyFullySentLogged && total > 0 && sent >= total) {
            bodyFullySentLogged = true;
            debugPrint(
              '[gif-buddy:upload] body fully sent ($sent/$total bytes), awaiting response…',
            );
          }
          onProgress?.call(sent, total);
        },
      );
      debugPrint('[gif-buddy:upload] status=${res.statusCode} body=${res.data}');
      if (res.statusCode == 200) {
        final size = res.data?['size'];
        return size is int ? size : bytes.length;
      }
      if (res.statusCode == 413) {
        throw PayloadTooLargeException(
          'Device rejected upload: payload too large (${bytes.length} bytes).',
        );
      }
      throw DeviceUnreachableException(
        'Device returned ${res.statusCode}: ${res.data}',
      );
    } on DioException catch (e) {
      debugPrint(
        '[gif-buddy:upload] DioException type=${e.type} '
        'status=${e.response?.statusCode} '
        'message=${e.message} '
        'responseBody=${e.response?.data}',
      );
      if (e.response?.statusCode == 413) {
        throw PayloadTooLargeException(
          'Device rejected upload: payload too large.',
        );
      }
      throw DeviceUnreachableException(
        'Could not reach device at $host: ${e.message ?? e.type.name}',
      );
    } finally {
      dio.close(force: true);
    }
  }
}
