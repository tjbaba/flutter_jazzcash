import 'package:flutter/material.dart';
import 'package:flutter_jazzcash/src/widget/card_payment_webview.dart';
import 'models/jazzcash_config.dart';
import 'models/payment_models.dart';
import 'services/mobile_wallet_service.dart';

/// Main JazzCash Flutter service class
class JazzCashService {
  final JazzCashConfig config;
  late final JazzCashMobileWalletService _mobileWalletService;

  JazzCashService._(this.config) {
    _mobileWalletService = JazzCashMobileWalletService(config);
  }

  /// Initialize JazzCash with configuration
  static JazzCashService initialize({
    required String merchantId,
    required String password,
    required String integritySalt,
    bool isProduction = false,
  }) {
    final config = JazzCashConfig(
      merchantId: merchantId,
      password: password,
      integritySalt: integritySalt,
      isProduction: isProduction,
    );

    return JazzCashService._(config);
  }

  /// Process mobile wallet payment
  ///
  /// This method handles the complete mobile wallet payment flow.
  /// You should call this method when user taps the payment button.
  ///
  /// Example:
  /// ```dart
  /// final response = await jazzCash.processMobileWalletPayment(
  ///   JazzCashMobileWalletRequest(
  ///     amount: 100.0,
  ///     billReference: 'BILL123',
  ///     cnic: '1234567890123',
  ///     description: 'Test payment',
  ///     mobileNumber: '03001234567',
  ///   ),
  /// );
  ///
  /// if (response.isSuccessful) {
  ///   // Payment successful
  ///   print('Payment successful: ${response.txnRefNo}');
  /// } else {
  ///   // Payment failed
  ///   print('Payment failed: ${response.statusMessage}');
  /// }
  /// ```
  Future<JazzCashMobileWalletResponse> processMobileWalletPayment(
    JazzCashMobileWalletRequest request,
  ) async {
    return await _mobileWalletService.processPayment(request);
  }

  /// Open card payment WebView
  ///
  /// This method opens a WebView for card payment processing.
  /// The WebView handles the complete card payment flow including
  /// 3D Secure authentication if required.
  ///
  /// Example:
  /// ```dart
  /// jazzCash.openCardPayment(
  ///   context: context,
  ///   request: JazzCashCardPaymentRequest(
  ///     amount: 100.0,
  ///     billReference: 'BILL123',
  ///     description: 'Test payment',
  ///     returnUrl: 'https://yourapp.com/payment-return',
  ///   ),
  ///   onPaymentSuccess: (response) {
  ///     print('Card payment successful: ${response.txnRefNo}');
  ///   },
  ///   onPaymentFailure: (error) {
  ///     print('Card payment failed: $error');
  ///   },
  ///   onPaymentCancelled: () {
  ///     print('Card payment cancelled');
  ///   },
  /// );
  /// ```
  Future<void> openCardPayment({
    required BuildContext context,
    required JazzCashCardPaymentRequest request,
    required Function(JazzCashCardPaymentResponse) onPaymentSuccess,
    required Function(String) onPaymentFailure,
    VoidCallback? onPaymentCancelled,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JazzCashCardPaymentWebView(
          config: config,
          paymentRequest: request,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentFailure: onPaymentFailure,
          onPaymentCancelled: onPaymentCancelled,
        ),
      ),
    );
  }

  /// Check transaction status
  ///
  /// Use this method to check the status of any transaction
  /// using the transaction reference number.
  ///
  /// Example:
  /// ```dart
  /// final status = await jazzCash.checkTransactionStatus('T20241225123456789');
  /// print('Transaction status: ${status['pp_ResponseCode']}');
  /// ```
  Future<Map<String, dynamic>> checkTransactionStatus(String txnRefNo) async {
    return await _mobileWalletService.checkTransactionStatus(txnRefNo);
  }

  /// Get configuration (for debugging purposes)
  JazzCashConfig get configuration => config;

  /// Check if running in production mode
  bool get isProduction => config.isProduction;

  /// Get merchant ID
  String get merchantId => config.merchantId;
}
