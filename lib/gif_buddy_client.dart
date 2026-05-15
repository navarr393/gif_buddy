import 'dart:typed_data';

import 'package:dio/dio.dart';

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
    try {
      final res = await dio.get<String>('$_base/');
      return res.statusCode == 200;
    } catch (_) {
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
        onSendProgress: onProgress,
      );
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
