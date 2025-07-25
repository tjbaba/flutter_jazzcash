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

  /// Generate response hash - UPDATED VERSION
  static String generateResponseHash(
    Map<String, dynamic> data,
    String integritySalt,
  ) {
    // Based on JazzCash official documentation, the response hash should include ALL pp_ fields
    // in alphabetical order, excluding pp_SecureHash itself

    final ppFields = <String, String>{};

    // Extract all pp_ fields (case-insensitive)
    data.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.startsWith('pp_') && lowerKey != 'pp_securehash') {
        ppFields[lowerKey] = value?.toString() ?? '';
      }
    });

    // Sort keys alphabetically
    final sortedKeys = ppFields.keys.toList()..sort();

    // Build hash string
    String hashString = integritySalt;

    for (final key in sortedKeys) {
      final value = ppFields[key] ?? '';
      if (value.isNotEmpty && value != 'null') {
        hashString += '&$value';
      }
    }

    return generateHMACSHA256(hashString, integritySalt);
  }

  /// Alternative response hash method - try exact field order from documentation
  static String generateResponseHashSpecificOrder(
    Map<String, dynamic> data,
    String integritySalt,
  ) {
    // Try the exact order mentioned in JazzCash documentation
    final orderedFields = [
      'pp_Amount',
      'pp_BillReference',
      'pp_Language',
      'pp_MerchantID',
      'pp_ResponseCode',
      'pp_ResponseMessage',
      'pp_RetreivalReferenceNo', // Note: JazzCash uses this spelling
      'pp_TxnCurrency',
      'pp_TxnDateTime',
      'pp_TxnRefNo',
      'pp_TxnType',
      'pp_Version',
    ];

    String hashString = integritySalt;

    for (final field in orderedFields) {
      final value = data[field]?.toString() ?? '';
      if (value.isNotEmpty && value != 'null') {
        hashString += '&$value';
      }
    }

    return generateHMACSHA256(hashString, integritySalt);
  }

  /// Generate response hash including additional fields that might be present
  static String generateResponseHashExtended(
    Map<String, dynamic> data,
    String integritySalt,
  ) {
    // Include additional fields that might be in the response
    final fieldOrder = [
      'pp_Amount',
      'pp_AuthCode', // Additional field
      'pp_BankID',
      'pp_BillReference',
      'pp_Language',
      'pp_MerchantID',
      'pp_ResponseCode',
      'pp_ResponseMessage',
      'pp_RetreivalReferenceNo',
      'pp_SubMerchantID',
      'pp_TxnCurrency',
      'pp_TxnDateTime',
      'pp_TxnRefNo',
      'pp_TxnType',
      'pp_Version',
      // Include ppmpf fields
      'ppmpf_1',
      'ppmpf_2',
      'ppmpf_3',
      'ppmpf_4',
      'ppmpf_5',
    ];

    String hashString = integritySalt;

    for (final field in fieldOrder) {
      if (data.containsKey(field)) {
        final value = data[field]?.toString() ?? '';
        if (value.isNotEmpty && value != 'null') {
          hashString += '&$value';
        }
      }
    }

    return generateHMACSHA256(hashString, integritySalt);
  }

// ADD these enhanced methods to your existing JazzCashHashGenerator class

  static bool validateResponseHash(
    Map<String, dynamic> responseData,
    String integritySalt,
  ) {
    try {
      final receivedHash =
          responseData['pp_SecureHash']?.toString().toUpperCase() ?? '';

      if (receivedHash.isEmpty) {
        print('❌ No secure hash found in response');
        return false;
      }
      final dataForValidation = Map<String, dynamic>.from(responseData);
      dataForValidation.remove('pp_SecureHash');

      // Try multiple validation methods
      final validationMethods = [
        ('Alphabetical All Fields', _validateAlphabeticalAllFields),
        ('Specific Order Standard', _validateSpecificOrderStandard),
        ('Alphabetical PP Only', _validateAlphabeticalPPOnly),
        ('Without Salt Prefix', _validateWithoutSaltPrefix),
        ('Original Flexible Method', _validateOriginalFlexible),
      ];

      print('Received Hash: $receivedHash');

      for (final (methodName, validationMethod) in validationMethods) {
        try {
          final expectedHash =
              validationMethod(dataForValidation, integritySalt).toUpperCase();
          print('$methodName: $expectedHash');

          if (receivedHash == expectedHash) {
            return true;
          }
        } catch (e) {
          print('❌ Error in $methodName: $e');
          continue;
        }
      }
      return false;
    } catch (e) {
      print('❌ Hash validation error: $e');
      return false;
    }
  }

// Method 1: All fields alphabetically (including non-pp fields)
  static String _validateAlphabeticalAllFields(
      Map<String, dynamic> data, String integritySalt) {
    final allFields = <String, String>{};

    data.forEach((key, value) {
      allFields[key.toLowerCase()] = value?.toString() ?? '';
    });

    final sortedKeys = allFields.keys.toList()..sort();
    final values = <String>[];

    for (final key in sortedKeys) {
      final value = allFields[key] ?? '';
      if (value.isNotEmpty && value != 'null') {
        values.add(value);
      }
    }

    final hashString = '$integritySalt&${values.join('&')}';
    return generateHMACSHA256(hashString, integritySalt);
  }

// Method 2: Specific field order from JazzCash documentation
  static String _validateSpecificOrderStandard(
      Map<String, dynamic> data, String integritySalt) {
    final orderedFields = [
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

    final values = <String>[];
    for (final field in orderedFields) {
      if (data.containsKey(field)) {
        final value = data[field]?.toString() ?? '';
        if (value.isNotEmpty && value != 'null') {
          values.add(value);
        }
      }
    }

    final hashString = '$integritySalt&${values.join('&')}';
    return generateHMACSHA256(hashString, integritySalt);
  }

// Method 3: Only pp_ fields alphabetically
  static String _validateAlphabeticalPPOnly(
      Map<String, dynamic> data, String integritySalt) {
    final ppFields = <String, String>{};

    data.forEach((key, value) {
      if (key.toLowerCase().startsWith('pp_')) {
        ppFields[key.toLowerCase()] = value?.toString() ?? '';
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
    return generateHMACSHA256(hashString, integritySalt);
  }

// Method 4: Without salt prefix (just values with salt as HMAC key)
  static String _validateWithoutSaltPrefix(
      Map<String, dynamic> data, String integritySalt) {
    final ppFields = <String, String>{};

    data.forEach((key, value) {
      if (key.toLowerCase().startsWith('pp_')) {
        ppFields[key.toLowerCase()] = value?.toString() ?? '';
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

    final hashString = values.join('&'); // No salt prefix
    return generateHMACSHA256(hashString, integritySalt);
  }

// Method 5: Your original flexible method
  static String _validateOriginalFlexible(
      Map<String, dynamic> data, String integritySalt) {
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

    return generateHMACSHA256(hashString, integritySalt);
  }


  /// Keep the flexible method for backward compatibility
  static String generateResponseHashFlexible(
    Map<String, dynamic> data,
    String integritySalt,
  ) {
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

    return generateHMACSHA256(hashString, integritySalt);
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
