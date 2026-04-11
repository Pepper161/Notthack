class Voucher {
  final String id;
  final String studentId;
  final String state; // active | redeemed | revoked
  final String issuedAt;
  final String? redeemedAt;
  final String? revokedAt;
  final String? merchantId;

  Voucher({
    required this.id,
    required this.studentId,
    required this.state,
    required this.issuedAt,
    this.redeemedAt,
    this.revokedAt,
    this.merchantId,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: json['voucherId'] ?? json['id'] ?? '',
        studentId: json['studentId'] ?? '',
        state: json['state'] ?? 'active',
        issuedAt: json['issuedAt'] ?? '',
        redeemedAt: json['redeemedAt'],
        revokedAt: json['revokedAt'],
        merchantId: json['merchantId'],
      );

  bool get isActive => state == 'active';
  bool get isRedeemed => state == 'redeemed';
  bool get isRevoked => state == 'revoked';
}

class AuditEvent {
  final String type;
  final String voucherId;
  final String timestamp;
  final String? merchantId;
  final String? reason;
  final String? studentId;
  final String? txSignature;
  final String? explorerUrl;
  final String? cluster;

  AuditEvent({
    required this.type,
    required this.voucherId,
    required this.timestamp,
    this.merchantId,
    this.reason,
    this.studentId,
    this.txSignature,
    this.explorerUrl,
    this.cluster,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
        type: json['type'] ?? '',
        voucherId: json['voucherId'] ?? '',
        timestamp: json['timestamp'] ?? '',
        merchantId: json['merchantId'],
        reason: json['reasonCode'] ?? json['reason'],
        studentId: json['studentId'],
        txSignature: json['txSignature'],
        explorerUrl: json['explorerUrl'],
        cluster: json['cluster'],
      );

  bool get isOnChain => txSignature != null && txSignature!.isNotEmpty;

  String get label {
    switch (type) {
      case 'voucher_issued':
        return 'Issued';
      case 'voucher_redeemed':
        return 'Redeemed';
      case 'voucher_revoked':
        return 'Revoked';
      case 'voucher_redemption_blocked':
        return 'Blocked';
      case 'override_logged':
        return 'Override';
      default:
        return type;
    }
  }
}

class VerifyResult {
  final bool valid;
  final String status; // valid | revoked | already_redeemed | unknown_voucher | merchant_not_approved
  final String message;
  final Voucher? voucher;

  VerifyResult({
    required this.valid,
    required this.status,
    required this.message,
    this.voucher,
  });

  factory VerifyResult.fromJson(Map<String, dynamic> json) => VerifyResult(
        valid: json['status'] == 'valid',
        status: json['status'] ?? 'unknown',
        message: json['message'] ?? '',
        voucher: json['voucher'] != null ? Voucher.fromJson(json['voucher']) : null,
      );
}
