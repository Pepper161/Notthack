import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// In-memory session for the Flutter client.
///
/// Holds the bearer token returned by the backend, plus the user profile
/// (role, email, displayName, and the role-specific binding — studentId for
/// students, merchantId for merchants, actorId for issuer/auditor).
///
/// All other services read the token from here via [authHeaders]. The
/// session is NOT persisted to disk, so a cold start of the app lands the
/// user back on the login screen — which is the correct behavior for a
/// demo with shared devices.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;

  String? get role => _user?['role'] as String?;
  String? get email => _user?['email'] as String?;
  String? get displayName => _user?['displayName'] as String?;
  String? get studentId => _user?['studentId'] as String?;
  String? get merchantId => _user?['merchantId'] as String?;

  /// Returns `null` on success; an error message on failure.
  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );
      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || body['ok'] != true) {
        return (body['error'] as String?) ?? 'Login failed (${res.statusCode})';
      }
      _token = body['token'] as String?;
      _user = (body['user'] as Map?)?.cast<String, dynamic>();
      if (_token == null || _user == null) {
        _token = null;
        _user = null;
        return 'Login response was malformed';
      }
      return null;
    } catch (e) {
      return 'Could not reach server: $e';
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${ApiService.baseUrl}/auth/logout'),
          headers: authHeaders(),
        );
      } catch (_) {
        // Swallow — we still want to clear local state.
      }
    }
    _token = null;
    _user = null;
  }

  /// Headers for authenticated GET requests.
  Map<String, String> authHeaders() {
    return {
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Headers for authenticated JSON POST/PUT requests.
  Map<String, String> jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
