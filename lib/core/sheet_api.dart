import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Thrown when the server rejects the token — caller should lock the app.
class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

/// Port of legacy/app.js:28-47 — Google Apps Script Web App client.
class SheetApi {
  SheetApi({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // Same endpoint as the legacy web app.
  static const _webappUrl =
      'https://script.google.com/macros/s/AKfycbwIFRJnRQPKI1d2bvtHm3nrWN0Dhw7sC331eTrQo5HvROiCLuxS7QPQvXAdZwj7mMstBw/exec';
  static const _tokenKey = 'mp_session';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<String?> get token => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  /// Returns true on success and stores the issued token.
  Future<bool> checkPin(String pin) async {
    final res = await _client.get(Uri.parse(
        '$_webappUrl?action=checkpin&pin=${Uri.encodeComponent(pin)}'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] == true && data['token'] is String) {
      await _storage.write(key: _tokenKey, value: data['token'] as String);
      return true;
    }
    return false;
  }

  /// GET a sheet's full contents. Returns null on network/parse failure.
  /// Throws [UnauthorizedException] when the token is rejected.
  Future<List<List<String>>?> readSheet(String sheetName) async {
    try {
      final tok = await token ?? '';
      final res = await _client.get(Uri.parse(
          '$_webappUrl?sheet=${Uri.encodeComponent(sheetName)}&token=${Uri.encodeComponent(tok)}'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['ok'] == false && data['error'] == 'unauthorized') {
        throw const UnauthorizedException();
      }
      final values = (data['values'] as List?) ?? const [];
      return values
          .map<List<String>>((row) =>
              (row as List).map((c) => c?.toString() ?? '').toList())
          .toList();
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// POST full sheet contents (overwrite). Content-Type text/plain avoids the
  /// CORS preflight (kept from the web client, harmless on mobile).
  Future<void> writeSheet(String sheetName, List<List<Object?>> rows) async {
    final res = await _client.post(
      Uri.parse(_webappUrl),
      headers: {'Content-Type': 'text/plain'},
      body: jsonEncode({'sheet': sheetName, 'rows': rows, 'token': await token}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['ok'] == false && data['error'] == 'unauthorized') {
      throw const UnauthorizedException();
    }
    if (data['ok'] != true) throw Exception('write failed');
  }
}
