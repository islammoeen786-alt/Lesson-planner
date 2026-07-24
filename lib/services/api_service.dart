import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;

  static const String _devUrl = 'http://localhost:3000/api';
  static const String _prodUrl = 'https://backend-3f80.onbelmo.uk/api';

  static String get defaultBaseUrl => kReleaseMode ? _prodUrl : _devUrl;

  VoidCallback? onSessionExpired;

  ApiService({String? baseUrl, this.onSessionExpired}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiService.defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('[API] Token error: $e');
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onSessionExpired?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> download(String path, String savePath) =>
      _dio.download(path, savePath);
}
