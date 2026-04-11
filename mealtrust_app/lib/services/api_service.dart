import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voucher.dart';
import 'auth_service.dart';

class ApiService {
  static const String _overrideBaseUrl =
      String.fromEnvironment('MEALTRUST_API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:3000/api';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000/api',
      TargetPlatform.iOS => 'http://localhost:3000/api',
      _ => 'http://localhost:3000/api',
    };
  }

  static Map<String, String> get _authHeaders =>
      AuthService.instance.authHeaders();
  static Map<String, String> get _jsonHeaders =>
      AuthService.instance.jsonHeaders();

  // ─── Issuer ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> issueVoucher(String studentId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/issuer/issue'),
      headers: _jsonHeaders,
      body: jsonEncode({'studentId': studentId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> revokeVoucher(
      String voucherId, String reasonCode) async {
    final res = await http.post(
      Uri.parse('$baseUrl/issuer/revoke'),
      headers: _jsonHeaders,
      body: jsonEncode({'voucherId': voucherId, 'reasonCode': reasonCode}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> logOverride(
      String voucherId, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/issuer/override'),
      headers: _jsonHeaders,
      body: jsonEncode({'voucherId': voucherId, 'overrideReason': reason}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Merchant ──────────────────────────────────────────────────────────────

  static Future<VerifyResult> verifyVoucher(String voucherId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/verify'),
      headers: _jsonHeaders,
      body: jsonEncode({'voucherId': voucherId}),
    );
    return VerifyResult.fromJson(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> redeemVoucher(String voucherId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/redeem'),
      headers: _jsonHeaders,
      body: jsonEncode({'voucherId': voucherId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Student ───────────────────────────────────────────────────────────────

  static Future<Voucher?> getMyVoucher() async {
    final res = await http.get(
      Uri.parse('$baseUrl/student/me/voucher'),
      headers: _authHeaders,
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode >= 400) return null;
    return Voucher.fromJson(jsonDecode(res.body));
  }

  // ─── Auditor ───────────────────────────────────────────────────────────────

  static Future<List<AuditEvent>> getAuditHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auditor/history'),
      headers: _authHeaders,
    );
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List<dynamic> events = data['events'] ?? [];
    return events.map((e) => AuditEvent.fromJson(e)).toList();
  }

  // ─── System ────────────────────────────────────────────────────────────────

  static Future<List<Voucher>> getVouchers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/bootstrap'),
      headers: _authHeaders,
    );
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List<dynamic> vouchers = data['vouchers'] ?? [];
    return vouchers.map((e) => Voucher.fromJson(e)).toList();
  }

  static Future<void> resetSeed() async {
    await http.post(
      Uri.parse('$baseUrl/reset'),
      headers: _authHeaders,
    );
  }

  // ─── Solana ────────────────────────────────────────────────────────────────

  static Future<SolanaStatus> getSolanaStatus() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/solana/status'),
        headers: _authHeaders,
      );
      return SolanaStatus.fromJson(jsonDecode(res.body));
    } catch (_) {
      return SolanaStatus(enabled: false);
    }
  }
}

class SolanaStatus {
  final bool enabled;
  final String? wallet;
  final double? balance;
  final String? cluster;
  final String? rpcUrl;

  SolanaStatus({
    required this.enabled,
    this.wallet,
    this.balance,
    this.cluster,
    this.rpcUrl,
  });

  factory SolanaStatus.fromJson(Map<String, dynamic> json) => SolanaStatus(
        enabled: json['enabled'] ?? false,
        wallet: json['wallet'],
        balance: (json['balance'] as num?)?.toDouble(),
        cluster: json['cluster'],
        rpcUrl: json['rpcUrl'],
      );
}
