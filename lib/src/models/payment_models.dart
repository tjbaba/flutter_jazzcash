/// Enum for JazzCash payment methods
enum JazzCashPaymentMethod {
  mobileWallet,
  card,
}

/// Mobile Wallet Payment Request Model
class JazzCashMobileWalletRequest {
  final double amount;
  final String billReference;
  final String cnic;
  final String description;
  final String mobileNumber;
  final String? txnRefNo;
  final Map<String, String>? customFields;

  JazzCashMobileWalletRequest({
    required this.amount,
    required this.billReference,
    required this.cnic,
    required this.description,
    required this.mobileNumber,
    this.txnRefNo,
    this.customFields,
  });
}

/// Card Payment Request Model
class JazzCashCardPaymentRequest {
  final double amount;
  final String billReference;
  final String description;
  final String returnUrl;
  final String? txnRefNo;
  final Map<String, String>? customFields;

  JazzCashCardPaymentRequest({
    required this.amount,
    required this.billReference,
    required this.description,
    required this.returnUrl,
    this.txnRefNo,
    this.customFields,
  });
}

/// Base Payment Response Model
abstract class JazzCashPaymentResponse {
  final String txnRefNo;
  final String responseCode;
  final String responseMessage;
  final String amount;
  final String billReference;
  final String? authCode;
  final String? retrievalReferenceNo;
  final String txnDateTime;

  JazzCashPaymentResponse({
    required this.txnRefNo,
    required this.responseCode,
    required this.responseMessage,
    required this.amount,
    required this.billReference,
    this.authCode,
    this.retrievalReferenceNo,
    required this.txnDateTime,
  });

  /// Check if payment was successful
  bool get isSuccessful => responseCode == '000';

  /// Get user-friendly status message
  String get statusMessage {
    switch (responseCode) {
      case '000':
        return 'Payment successful';
      case '001':
        return 'Payment pending';
      case '101':
        return 'Payment failed';
      case '111':
        return 'Insufficient balance';
      case '121':
        return 'Invalid transaction';
      default:
        return responseMessage.isNotEmpty ? responseMessage : 'Unknown error';
    }
  }
}

/// Mobile Wallet Payment Response
class JazzCashMobileWalletResponse extends JazzCashPaymentResponse {
  final String mobileNumber;
  final String cnic;

  JazzCashMobileWalletResponse({
    required super.txnRefNo,
    required super.responseCode,
    required super.responseMessage,
    required super.amount,
    required super.billReference,
    super.authCode,
    super.retrievalReferenceNo,
    required super.txnDateTime,
    required this.mobileNumber,
    required this.cnic,
  });

  factory JazzCashMobileWalletResponse.fromJson(Map<String, dynamic> json) {
    return JazzCashMobileWalletResponse(
      txnRefNo: json['pp_TxnRefNo'] ?? '',
      responseCode: json['pp_ResponseCode'] ?? '',
      responseMessage: json['pp_ResponseMessage'] ?? '',
      amount: json['pp_Amount'] ?? '',
      billReference: json['pp_BillReference'] ?? '',
      authCode: json['pp_AuthCode'],
      retrievalReferenceNo: json['pp_RetreivalReferenceNo'],
      txnDateTime: json['pp_TxnDateTime'] ?? '',
      mobileNumber: json['pp_MobileNumber'] ?? '',
      cnic: json['pp_CNIC'] ?? '',
    );
  }
}

/// Card Payment Response
class JazzCashCardPaymentResponse extends JazzCashPaymentResponse {
  JazzCashCardPaymentResponse({
    required super.txnRefNo,
    required super.responseCode,
    required super.responseMessage,
    required super.amount,
    required super.billReference,
    super.authCode,
    super.retrievalReferenceNo,
    required super.txnDateTime,
  });

  factory JazzCashCardPaymentResponse.fromJson(Map<String, dynamic> json) {
    return JazzCashCardPaymentResponse(
      txnRefNo: json['pp_TxnRefNo'] ?? '',
      responseCode: json['pp_ResponseCode'] ?? '',
      responseMessage: json['pp_ResponseMessage'] ?? '',
      amount: json['pp_Amount'] ?? '',
      billReference: json['pp_BillReference'] ?? '',
      authCode: json['pp_AuthCode'],
      retrievalReferenceNo: json['pp_RetreivalReferenceNo'],
      txnDateTime: json['pp_TxnDateTime'] ?? '',
    );
  }
}

/// Custom Exception for JazzCash errors
class JazzCashException implements Exception {
  final String message;
  final String? code;

  JazzCashException(this.message, [this.code]);

  @override
  String toString() =>
      'JazzCashException: $message${code != null ? ' (Code: $code)' : ''}';
}
