import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/services/storage_service.dart';
import '../constants/api_config.dart';

/// Any failed API call. [message] is safe to show to the student.
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message);

  final int status; // 0 = no connection
  final String code;
  final String message;

  bool get isNetwork => status == 0;

  @override
  String toString() => message;
}

/// Small JSON client: adds the Bearer token and, when the access token has
/// expired (401), silently refreshes it once and repeats the request.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  Future<bool>? _refreshing;

  /// Called when the refresh token is no longer valid (go back to Sign in).
  void Function()? onSessionExpired;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
    bool retried = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    final token = TokenStorage.instance.accessToken;
    if (auth && token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 30)),
      );
    } on TimeoutException {
      throw const ApiException(0, 'timeout', 'The server took too long to answer. Please try again.');
    } catch (_) {
      throw const ApiException(0, 'network', 'Cannot reach the server. Check your internet connection.');
    }

    if (response.statusCode == 401 && auth && !retried &&
        TokenStorage.instance.refreshToken != null) {
      if (await _refreshTokens()) {
        return _send(method, path, body: body, query: query, auth: auth, retried: true);
      }
      onSessionExpired?.call();
    }

    final text = utf8.decode(response.bodyBytes); // Khmer text needs UTF-8
    dynamic data;
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 400) {
      final err = (data is Map ? data['error'] : null);
      throw ApiException(
        response.statusCode,
        err is Map ? '${err['code'] ?? 'error'}' : 'error',
        err is Map ? '${err['message'] ?? 'Something went wrong'}' : 'Something went wrong (${response.statusCode})',
      );
    }
    return data;
  }

  /// One refresh at a time, even if several requests fail together.
  Future<bool> _refreshTokens() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refresh = TokenStorage.instance.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await _http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        await TokenStorage.instance.save(
          access: data['accessToken'] as String,
          refresh: data['refreshToken'] as String,
        );
        return true;
      }
      if (res.statusCode == 401) await TokenStorage.instance.clear();
    } catch (_) {
      // Offline: keep the tokens and try again later.
    }
    return false;
  }
}