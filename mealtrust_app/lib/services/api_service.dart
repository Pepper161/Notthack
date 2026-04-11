import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voucher.dart';

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

  // ─── Issuer ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> issueVoucher(String studentId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/issuer/issue'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'studentId': studentId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> revokeVoucher(
      String voucherId, String reasonCode) async {
    final res = await http.post(
      Uri.parse('$baseUrl/issuer/revoke'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voucherId': voucherId, 'reasonCode': reasonCode}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> logOverride(
      String voucherId, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/issuer/override'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voucherId': voucherId, 'overrideReason': reason}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Merchant ──────────────────────────────────────────────────────────────

  static Future<VerifyResult> verifyVoucher(
      String voucherId, String merchantId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voucherId': voucherId, 'merchantId': merchantId}),
    );
    return VerifyResult.fromJson(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> redeemVoucher(
      String voucherId, String merchantId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/redeem'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voucherId': voucherId, 'merchantId': merchantId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Student ───────────────────────────────────────────────────────────────

  static Future<Voucher?> getStudentVoucher(String studentId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/student/$studentId/voucher'));
    if (res.statusCode == 404) return null;
    return Voucher.fromJson(jsonDecode(res.body));
  }

  // ─── Auditor ───────────────────────────────────────────────────────────────

  static Future<List<AuditEvent>> getAuditHistory() async {
    final res = await http.get(Uri.parse('$baseUrl/auditor/history'));
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List<dynamic> events = data['events'] ?? [];
    return events.map((e) => AuditEvent.fromJson(e)).toList();
  }

  // ─── System ────────────────────────────────────────────────────────────────

  static Future<List<Voucher>> getVouchers() async {
    final res = await http.get(Uri.parse('$baseUrl/bootstrap'));
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List<dynamic> vouchers = data['vouchers'] ?? [];
    return vouchers.map((e) => Voucher.fromJson(e)).toList();
  }

  static Future<void> resetSeed() async {
    await http.post(Uri.parse('$baseUrl/reset'));
  }

  // ─── Solana ────────────────────────────────────────────────────────────────

  static Future<SolanaStatus> getSolanaStatus() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/solana/status'));
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
