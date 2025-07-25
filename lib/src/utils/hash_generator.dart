import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for generating JazzCash secure hashes
class JazzCashHashGenerator {
  /// Generate secure hash for mobile wallet payment
  static String generateMobileWalletHash(
      Map<String, dynamic> data,
      String integritySalt,
      ) {
    // Create hash string with specific field order for mobile wallet
    final hashFields = [
      data['pp_Amount'].toString(),
      data['pp_BillReference'].toString(),
      data['pp_CNIC'].toString(),
      data['pp_Description'].toString(),
      data['pp_Language'].toString(),
      data['pp_MerchantID'].toString(),
      data['pp_MobileNumber'].toString(),
      data['pp_Password'].toString(),
      data['pp_TxnCurrency'].toString(),
      data['pp_TxnDateTime'].toString(),
      data['pp_TxnExpiryDateTime'].toString(),
      data['pp_TxnRefNo'].toString(),
      data['ppmpf_1'].toString(),
      data['ppmpf_2'].toString(),
      data['ppmpf_3'].toString(),
      data['ppmpf_4'].toString(),
      data['ppmpf_5'].toString(),
    ];

    // Create hash string by prepending integrity salt
    String hashString = integritySalt;
    for (final field in hashFields) {
      if (field.isNotEmpty && field != 'null') {
        hashString += '&$field';
      }
    }

    return generateHMACSHA256(hashString, integritySalt);
  }

  /// Generate secure hash for card payment
  static String generateCardPaymentHash(
      Map<String, dynamic> data,
      String integritySalt,
      ) {
    // For card payments, use specific field order as per documentation
    final hashFields = [
      data['pp_Amount'].toString(),
      data['pp_BankID'].toString(),
      data['pp_BillReference'].toString(),
      data['pp_Description'].toString(),
      data['pp_Language'].toString(),
      data['pp_MerchantID'].toString(),
      data['pp_Password'].toString(),
      data['pp_ProductID'].toString(),
      data['pp_ReturnURL'].toString(),
      data['pp_TxnCurrency'].toString(),
      data['pp_TxnDateTime'].toString(),
      data['pp_TxnExpiryDateTime'].toString(),
      data['pp_TxnRefNo'].toString(),
      data['pp_TxnType'].toString(),
      data['pp_Version'].toString(),
      data['ppmpf_1'].toString(),
      data['ppmpf_2'].toString(),
      data['ppmpf_3'].toString(),
      data['ppmpf_4'].toString(),
      data['ppmpf_5'].toString(),
    ];

    // Create hash string by prepending integrity salt
    String hashString = integritySalt;
    for (final field in hashFields) {
      if (field.isNotEmpty && field != 'null') {
        hashString += '&$field';
      }
    }

    return generateHMACSHA256(hashString, integritySalt);
  }

  static String generateResponseHash(
      Map<String, dynamic> data,
      String integritySalt,
      ) {
    // **CRITICAL: JazzCash response uses SPECIFIC field order**
    final responseFields = [
      'pp_Amount',
      'pp_BillReference',
      'pp_Language',
      'pp_MerchantID',
      'pp_ResponseCode',
      'pp_ResponseMessage',
      'pp_RetreivalReferenceNo', // JazzCash spelling
      'pp_TxnCurrency',
      'pp_TxnDateTime',
      'pp_TxnRefNo',
      'pp_TxnType',
      'pp_Version',
    ];

    // Build the hash string - START with integrity salt
    String hashString = integritySalt;

    // Add field values in specific order
    for (final field in responseFields) {
      if (data.containsKey(field)) {
        final value = data[field]?.toString() ?? '';
        if (value.isNotEmpty && value != 'null') {
          hashString += '&$value';
        }
      }
    }

    print('🔑 Response Hash String: $hashString');

    // Generate HMAC-SHA256 hash
    return generateHMACSHA256(hashString, integritySalt);
  }

  static bool validateResponseHash(
      Map<String, dynamic> responseData,
      String integritySalt,
      ) {
    try {
      final receivedHash = responseData['pp_SecureHash']?.toString().toUpperCase() ?? '';

      if (receivedHash.isEmpty) {
        print('❌ No secure hash found in response');
        return false;
      }

      final dataForValidation = Map<String, dynamic>.from(responseData);
      dataForValidation.remove('pp_SecureHash');

      // **Method 1: Use the corrected response hash**
      final expectedHash1 = generateResponseHash(dataForValidation, integritySalt).toUpperCase();

      // **Method 2: Use your original alphabetical method**
      final expectedHash2 = _generateResponseHashAlphabetical(dataForValidation, integritySalt).toUpperCase();

      // **Method 3: Try without empty fields**
      final expectedHash3 = generateResponseHashFlexible(dataForValidation, integritySalt).toUpperCase();

      print('🔒 Hash Validation Multi-Method:');
      print('Received Hash: $receivedHash');
      print('Method 1 (Ordered): $expectedHash1');
      print('Method 2 (Alphabetical): $expectedHash2');
      print('Method 3 (Flexible): $expectedHash3');

      // Return true if any method matches
      if (receivedHash == expectedHash1) {
        print('✅ Hash validated using Method 1 (Ordered)');
        return true;
      } else if (receivedHash == expectedHash2) {
        print('✅ Hash validated using Method 2 (Alphabetical)');
        return true;
      } else if (receivedHash == expectedHash3) {
        print('✅ Hash validated using Method 3 (Flexible)');
        return true;
      }

      print('❌ Hash validation failed with all methods');
      return false;

    } catch (e) {
      print('❌ Hash validation error: $e');
      return false;
    }
  }

  /// Alternative method: Try multiple approaches for response validation
  static String generateResponseHashFlexible(
      Map<String, dynamic> data,
      String integritySalt,
      ) {
    // Method similar to your card payment hash but for response fields
    final responseFields = [
      'pp_Amount',
      'pp_BillReference',
      'pp_Language',
      'pp_MerchantID',
      'pp_ResponseCode',
      'pp_ResponseMessage',
      'pp_RetreivalReferenceNo',
      'pp_TxnCurrency',
      'pp_TxnDateTime',
      'pp_TxnRefNo',
      'pp_TxnType',
      'pp_Version',
    ];

    String hashString = integritySalt;
    for (final field in responseFields) {
      final value = data[field]?.toString() ?? '';
      if (value.isNotEmpty && value != 'null') {
        hashString += '&$value';
      }
    }

    print('🔑 Flexible Response Hash String: $hashString');
    return generateHMACSHA256(hashString, integritySalt);
  }

  // Your original alphabetical method for comparison
  static String _generateResponseHashAlphabetical(
      Map<String, dynamic> data,
      String integritySalt,
      ) {
    final ppFields = <String, String>{};

    data.forEach((key, value) {
      if (key.toLowerCase().startsWith('pp_')) {
        ppFields[key.toLowerCase()] = value.toString();
      }
    });

    final sortedKeys = ppFields.keys.toList()..sort();
    final values = <String>[];

    for (final key in sortedKeys) {
      final value = ppFields[key] ?? '';
      if (value.isNotEmpty && value != 'null') {
        values.add(value);
      }
    }

    final hashString = '$integritySalt&${values.join('&')}';
    print('🔑 Alphabetical Hash String: $hashString');

    return generateHMACSHA256(hashString, integritySalt);
  }


  /// Generate HMAC-SHA256 hash (made public)
  static String generateHMACSHA256(String hashString, String integritySalt) {
    print('🔑 Hash String: $hashString'); // Debug print

    final key = utf8.encode(integritySalt);
    final bytes = utf8.encode(hashString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    return digest.toString().toUpperCase();
  }

}

/// Utility class for date time formatting
class DateTimeHelper {
  /// Format DateTime to JazzCash format (yyyyMMddHHmmss)
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Generate transaction reference number
  static String generateTxnRefNo([String? prefix]) {
    final now = DateTime.now();
    final timestamp = formatDateTime(now);
    final random = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return '${prefix ?? 'T'}$timestamp$random';
  }

  /// Generate expiry date time (current + specified duration)
  static String generateExpiryDateTime([Duration? duration]) {
    final expiry = DateTime.now().add(duration ?? const Duration(days: 1));
    return formatDateTime(expiry);
  }
}