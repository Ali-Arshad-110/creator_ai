import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Gets the current Supabase session token automatically.
  String? get _authToken => Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(AppConfig.receiveTimeout);
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.receiveTimeout);
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }

  Future<void> delete(String path) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${AppConfig.apiBaseUrl}$path'),
            headers: _headers,
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwError(response);
      }
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final int code = response.statusCode;
    final String body = response.body;

    if (code >= 200 && code < 300) {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    _throwError(response);
    return {}; // unreachable
  }

  Never _throwError(http.Response response) {
    try {
      final errorJson = jsonDecode(response.body);
      final detail = errorJson['detail'] ?? 'An unknown error occurred.';
      throw Exception(detail);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Server returned status code ${response.statusCode}');
    }
  }
}
