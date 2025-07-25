/// JazzCash Configuration Model
class JazzCashConfig {
  /// Merchant ID provided by JazzCash
  final String merchantId;

  /// Password provided by JazzCash
  final String password;

  /// Integrity Salt provided by JazzCash
  final String integritySalt;

  /// Whether to use production environment
  final bool isProduction;

  const JazzCashConfig({
    required this.merchantId,
    required this.password,
    required this.integritySalt,
    this.isProduction = false,
  });

  /// Base URL for JazzCash payments
  String get baseUrl => isProduction
      ? 'https://payments.jazzcash.com.pk'
      : 'https://sandbox.jazzcash.com.pk';

  /// API Base URL for mobile wallet payments
  String get apiBaseUrl => isProduction
      ? 'https://payments.jazzcash.com.pk/ApplicationAPI/API'
      : 'https://sandbox.jazzcash.com.pk/ApplicationAPI/API';

  /// Card Payment URL for web view
  String get cardPaymentUrl => isProduction
      ? 'https://payments.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform'
      : 'https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/';

  @override
  String toString() {
    return 'JazzCashConfig(merchantId: $merchantId, isProduction: $isProduction)';
  }
}
