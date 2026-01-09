import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import '../utils/either.dart';
import 'network_info.dart';

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });

  final int statusCode;
  final dynamic data;
  final Map<String, String> headers;
}

class ApiClient {
  ApiClient({
    required this.httpClient,
    required this.networkInfo,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client httpClient;
  final NetworkInfo networkInfo;
  final String baseUrl;
  final Duration timeout;

  Future<Either<AppException, ApiResponse>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    return _request(
      () => httpClient.get(
        _buildUri(path, queryParameters),
        headers: headers,
      ),
    );
  }

  Future<Either<AppException, ApiResponse>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    return _request(
      () => httpClient.post(
        _buildUri(path, queryParameters),
        headers: _mergeHeaders(headers, body),
        body: _encodeBody(body),
      ),
    );
  }

  Future<Either<AppException, ApiResponse>> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    return _request(
      () => httpClient.put(
        _buildUri(path, queryParameters),
        headers: _mergeHeaders(headers, body),
        body: _encodeBody(body),
      ),
    );
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final baseUri = Uri.parse(baseUrl);
    return baseUri.replace(
      path: '${baseUri.path}$path',
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _mergeHeaders(
    Map<String, String>? headers,
    Object? body,
  ) {
    final merged = <String, String>{};
    if (headers != null) {
      merged.addAll(headers);
    }
    if (body is Map || body is List) {
      merged.putIfAbsent('Content-Type', () => 'application/json');
    }
    return merged;
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is Map || body is List) {
      return jsonEncode(body);
    }
    return body.toString();
  }

  Future<Either<AppException, ApiResponse>> _request(
    Future<http.Response> Function() request,
  ) async {
    final connected = await networkInfo.isConnected;
    if (!connected) {
      return Left(AppException.network());
    }

    try {
      final response = await request().timeout(timeout);
      return Right(
        ApiResponse(
          statusCode: response.statusCode,
          data: _decodeBody(response),
          headers: response.headers,
        ),
      );
    } on SocketException catch (e) {
      return Left(AppException.network(e.message));
    } on TimeoutException catch (e) {
      return Left(AppException.timeout(e.message));
    } catch (e) {
      return Left(AppException.unexpected(e.toString(), e));
    }
  }

  dynamic _decodeBody(http.Response response) {
    final body = response.body;
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
