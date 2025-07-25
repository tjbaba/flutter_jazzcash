import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for generating JazzCash secure hashes
class JazzCashHashGenerator {
  /// Generate secure hash for mobile wallet payment
  static String generateMobileWalletHash(
    Map<String, dynamic> data,
    String integritySalt,
  ) {
    // Get all PP fields and sort them alphabetically
    final ppFields = <String, String>{};

    data.forEach((key, value) {
      if (key.toLowerCase().startsWith('pp_') ||
          key.toLowerCase().startsWith('ppmpf_')) {
        ppFields[key.toLowerCase()] = value.toString();
      }
    });

    // Sort keys alphabetically
    final sortedKeys = ppFields.keys.toList()..sort();

    // Create concatenated string with non-empty values only
    final values = <String>[];
    for (final key in sortedKeys) {
      final value = ppFields[key] ?? '';
      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    // Prepend integrity salt and join with &
    final hashString = '$integritySalt&${values.join('&')}';

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
      if (field.isNotEmpty) {
        hashString += '&$field';
      }
    }

    return generateHMACSHA256(hashString, integritySalt);
  }

  /// Generate secure hash for response validation
  static String generateResponseHash(
    Map<String, dynamic> data,
    String integritySalt,
  ) {
    // For response validation, use all PP fields in alphabetical order
    final ppFields = <String, String>{};

    data.forEach((key, value) {
      if (key.toLowerCase().startsWith('pp_')) {
        ppFields[key.toLowerCase()] = value.toString();
      }
    });

    // Sort keys alphabetically
    final sortedKeys = ppFields.keys.toList()..sort();

    // Create concatenated string
    final values = sortedKeys.map((key) => ppFields[key] ?? '').toList();
    final hashString = '$integritySalt&${values.join('&')}';

    return generateHMACSHA256(hashString, integritySalt);
  }

  /// Validate response hash
  static bool validateResponseHash(
    Map<String, dynamic> responseData,
    String integritySalt,
  ) {
    try {
      // Extract secure hash from response
      final receivedHash =
          responseData['pp_SecureHash']?.toString().toUpperCase() ?? '';

      // Remove secure hash from data for validation
      final dataForValidation = Map<String, dynamic>.from(responseData);
      dataForValidation.remove('pp_SecureHash');

      // Generate expected hash
      final expectedHash =
          generateResponseHash(dataForValidation, integritySalt);

      return receivedHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Generate HMAC-SHA256 hash
  static String generateHMACSHA256(String hashString, String integritySalt) {
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
    final random =
        (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return '${prefix ?? 'T'}$timestamp$random';
  }

  /// Generate expiry date time (current + specified duration)
  static String generateExpiryDateTime([Duration? duration]) {
    final expiry = DateTime.now().add(duration ?? const Duration(days: 1));
    return formatDateTime(expiry);
  }
}
