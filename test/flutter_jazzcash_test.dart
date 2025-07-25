import 'package:flutter_jazzcash/flutter_jazzcash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JazzCashService', () {
    late JazzCashService jazzCashService;

    setUp(() {
      jazzCashService = JazzCashService.initialize(
        merchantId: 'TEST_MERCHANT',
        password: 'TEST_PASSWORD',
        integritySalt: 'TEST_SALT',
        isProduction: false,
      );
    });

    test('should initialize with correct configuration', () {
      expect(jazzCashService.merchantId, equals('TEST_MERCHANT'));
      expect(jazzCashService.isProduction, isFalse);
    });

    test('should have correct configuration', () {
      final config = jazzCashService.configuration;
      expect(config.merchantId, equals('TEST_MERCHANT'));
      expect(config.password, equals('TEST_PASSWORD'));
      expect(config.integritySalt, equals('TEST_SALT'));
      expect(config.isProduction, isFalse);
    });

    test('should generate correct URLs for sandbox', () {
      final config = jazzCashService.configuration;
      expect(config.baseUrl, contains('sandbox.jazzcash.com.pk'));
      expect(config.apiBaseUrl, contains('sandbox.jazzcash.com.pk'));
      expect(config.cardPaymentUrl, contains('sandbox.jazzcash.com.pk'));
    });

    test('should generate correct URLs for production', () {
      final prodService = JazzCashService.initialize(
        merchantId: 'PROD_MERCHANT',
        password: 'PROD_PASSWORD',
        integritySalt: 'PROD_SALT',
        isProduction: true,
      );

      final config = prodService.configuration;
      expect(config.baseUrl, contains('payments.jazzcash.com.pk'));
      expect(config.apiBaseUrl, contains('payments.jazzcash.com.pk'));
      expect(config.cardPaymentUrl, contains('payments.jazzcash.com.pk'));
      expect(config.baseUrl, isNot(contains('sandbox')));
    });
  });

  group('JazzCashConfig', () {
    test('should create config with correct values', () {
      const config = JazzCashConfig(
        merchantId: 'TEST123',
        password: 'pass123',
        integritySalt: 'salt123',
        isProduction: true,
      );

      expect(config.merchantId, equals('TEST123'));
      expect(config.password, equals('pass123'));
      expect(config.integritySalt, equals('salt123'));
      expect(config.isProduction, isTrue);
    });

    test('should default to sandbox mode', () {
      const config = JazzCashConfig(
        merchantId: 'TEST123',
        password: 'pass123',
        integritySalt: 'salt123',
      );

      expect(config.isProduction, isFalse);
    });
  });

  group('Payment Models', () {
    test('JazzCashMobileWalletRequest should create correctly', () {
      final request = JazzCashMobileWalletRequest(
        amount: 100.0,
        billReference: 'BILL123',
        cnic: '1234567890123',
        description: 'Test payment',
        mobileNumber: '03001234567',
      );

      expect(request.amount, equals(100.0));
      expect(request.billReference, equals('BILL123'));
      expect(request.cnic, equals('1234567890123'));
      expect(request.description, equals('Test payment'));
      expect(request.mobileNumber, equals('03001234567'));
    });

    test('JazzCashCardPaymentRequest should create correctly', () {
      final request = JazzCashCardPaymentRequest(
        amount: 200.0,
        billReference: 'CARD123',
        description: 'Card payment',
        returnUrl: 'https://example.com/return',
      );

      expect(request.amount, equals(200.0));
      expect(request.billReference, equals('CARD123'));
      expect(request.description, equals('Card payment'));
      expect(request.returnUrl, equals('https://example.com/return'));
    });
  });

  group('Payment Response', () {
    test('should identify successful payment', () {
      final response = JazzCashMobileWalletResponse(
        txnRefNo: 'T123456789',
        responseCode: '000',
        responseMessage: 'Success',
        amount: '10000',
        billReference: 'BILL123',
        txnDateTime: '20241225120000',
        mobileNumber: '03001234567',
        cnic: '1234567890123',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.statusMessage, equals('Payment successful'));
    });

    test('should identify failed payment', () {
      final response = JazzCashMobileWalletResponse(
        txnRefNo: 'T123456789',
        responseCode: '101',
        responseMessage: 'Payment failed',
        amount: '10000',
        billReference: 'BILL123',
        txnDateTime: '20241225120000',
        mobileNumber: '03001234567',
        cnic: '1234567890123',
      );

      expect(response.isSuccessful, isFalse);
      expect(response.statusMessage, equals('Payment failed'));
    });

    test('should handle insufficient balance', () {
      final response = JazzCashMobileWalletResponse(
        txnRefNo: 'T123456789',
        responseCode: '111',
        responseMessage: 'Insufficient balance',
        amount: '10000',
        billReference: 'BILL123',
        txnDateTime: '20241225120000',
        mobileNumber: '03001234567',
        cnic: '1234567890123',
      );

      expect(response.isSuccessful, isFalse);
      expect(response.statusMessage, equals('Insufficient balance'));
    });
  });

  group('DateTimeHelper', () {
    test('should format DateTime correctly for JazzCash', () {
      final dateTime = DateTime(2024, 12, 25, 15, 30, 45);
      final formatted = DateTimeHelper.formatDateTime(dateTime);
      expect(formatted, equals('20241225153045'));
    });

    test('should generate transaction reference number', () {
      final txnRef = DateTimeHelper.generateTxnRefNo();
      expect(txnRef, startsWith('T'));
      expect(txnRef.length,
          equals(18)); // T + 14 digits timestamp + 3 digits random
    });

    test('should generate custom prefix transaction reference', () {
      final txnRef = DateTimeHelper.generateTxnRefNo('PADEL');
      expect(txnRef, startsWith('PADEL'));
    });

    test('should generate expiry date time', () {
      final expiry = DateTimeHelper.generateExpiryDateTime();
      expect(expiry.length, equals(14)); // yyyyMMddHHmmss
    });
  });

  group('JazzCashException', () {
    test('should create exception with message', () {
      final exception = JazzCashException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.code, isNull);
    });

    test('should create exception with message and code', () {
      final exception = JazzCashException('Test error', '001');
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('001'));
    });

    test('should format toString correctly', () {
      final exception = JazzCashException('Test error', '001');
      expect(exception.toString(),
          equals('JazzCashException: Test error (Code: 001)'));
    });
  });
}
