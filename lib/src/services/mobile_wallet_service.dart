import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jazzcash_config.dart';
import '../models/payment_models.dart';
import '../utils/hash_generator.dart';

/// Service for handling JazzCash Mobile Wallet payments
class JazzCashMobileWalletService {
  final JazzCashConfig config;

  JazzCashMobileWalletService(this.config);

  /// Process mobile wallet payment
  Future<JazzCashMobileWalletResponse> processPayment(
    JazzCashMobileWalletRequest request,
  ) async {
    try {
      final requestData = _buildRequestData(request);
      final response = await _makeApiCall(requestData);

      return JazzCashMobileWalletResponse.fromJson(response);
    } catch (e) {
      throw JazzCashException('Mobile wallet payment failed: $e');
    }
  }

  /// Build request data for mobile wallet payment
  Map<String, dynamic> _buildRequestData(JazzCashMobileWalletRequest request) {
    final txnRefNo = request.txnRefNo ?? DateTimeHelper.generateTxnRefNo();
    final txnDateTime = DateTimeHelper.formatDateTime(DateTime.now());
    final txnExpiryDateTime = DateTimeHelper.generateExpiryDateTime();

    // Convert amount to paisas (multiply by 100)
    final amountInPaisas = (request.amount * 100).toInt().toString();

    final Map<String, dynamic> data = {
      'pp_Amount': amountInPaisas,
      'pp_BillReference': request.billReference,
      'pp_CNIC': request.cnic,
      'pp_Description': request.description,
      'pp_Language': 'EN',
      'pp_MerchantID': config.merchantId,
      'pp_MobileNumber': request.mobileNumber,
      'pp_Password': config.password,
      'pp_TxnCurrency': 'PKR',
      'pp_TxnDateTime': txnDateTime,
      'pp_TxnExpiryDateTime': txnExpiryDateTime,
      'pp_TxnRefNo': txnRefNo,
      'ppmpf_1': request.customFields?['ppmpf_1'] ?? '',
      'ppmpf_2': request.customFields?['ppmpf_2'] ?? '',
      'ppmpf_3': request.customFields?['ppmpf_3'] ?? '',
      'ppmpf_4': request.customFields?['ppmpf_4'] ?? '',
      'ppmpf_5': request.customFields?['ppmpf_5'] ?? '',
    };

    // Generate secure hash - FIXED: Pass data map, not hashString
    data['pp_SecureHash'] = JazzCashHashGenerator.generateMobileWalletHash(
      data, // ✅ Pass the data map
      config.integritySalt,
    );

    return data;
  }

  /// Make API call to JazzCash
  Future<Map<String, dynamic>> _makeApiCall(Map<String, dynamic> data) async {
    final url = '${config.apiBaseUrl}/2.0/Purchase/DoMWalletTransaction';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode(data);

    final response = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Validate response hash
      if (!JazzCashHashGenerator.validateResponseHash(
        responseData,
        config.integritySalt,
      )) {
        throw JazzCashException('Response hash validation failed');
      }

      return responseData;
    } else {
      throw JazzCashException(
        'API call failed with status: ${response.statusCode}',
        response.statusCode.toString(),
      );
    }
  }

  /// Check transaction status
  Future<Map<String, dynamic>> checkTransactionStatus(String txnRefNo) async {
    try {
      final requestData = _buildStatusInquiryData(txnRefNo);
      final url = '${config.apiBaseUrl}/PaymentInquiry/Inquire';

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode(requestData);

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw JazzCashException(
          'Status inquiry failed with status: ${response.statusCode}',
          response.statusCode.toString(),
        );
      }
    } catch (e) {
      throw JazzCashException('Status inquiry error: $e');
    }
  }

  /// Build status inquiry request data
  Map<String, dynamic> _buildStatusInquiryData(String txnRefNo) {
    final Map<String, dynamic> data = {
      'pp_TxnRefNo': txnRefNo,
      'pp_MerchantID': config.merchantId,
      'pp_Password': config.password,
    };

    // Generate hash for status inquiry - using public method
    final fields = [
      data['pp_MerchantID'].toString(),
      data['pp_Password'].toString(),
      data['pp_TxnRefNo'].toString(),
    ];

    final hashString = '${config.integritySalt}&${fields.join('&')}';
    data['pp_SecureHash'] = JazzCashHashGenerator.generateHMACSHA256(
      hashString,
      config.integritySalt,
    );

    return data;
  }
}
