# Flutter JazzCash Package - Complete User Guide

**Developer:** [Talha Javed](https://talha-javed-ch.web.app/) | **GitHub:** [@talhajaved](https://github.com/tjbaba)


## Screenshots

|          Mobile Wallet Payment           |              Card Payment              |           Card Payment           |
|:----------------------------------------:|:--------------------------------------:|:--------------------------------:|
| ![Mobile Wallet](https://raw.githubusercontent.com/tjbaba/flutter_jazzcash/main/screenshots/mobile.jpg) | ![Card Payment](https://raw.githubusercontent.com/tjbaba/flutter_jazzcash/refs/heads/main/screenshots/card1.jpg) | ![Status](https://raw.githubusercontent.com/tjbaba/flutter_jazzcash/refs/heads/main/screenshots/card2.jpg) |


A comprehensive guide for integrating JazzCash payments in your Flutter app using both mobile wallet and card payment methods.

## Table of Contents
1. [Installation](#installation)
2. [Setup & Configuration](#setup--configuration)
3. [Mobile Wallet Payment](#mobile-wallet-payment)
4. [Card Payment](#card-payment)
5. [Transaction Status](#transaction-status)
6. [Error Handling](#error-handling)
7. [Production Setup](#production-setup)
8. [Complete Example](#complete-example)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Installation

### Step 1: Add Dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_jazzcash: ^1.0.0
```

### Step 2: Install Package

```bash
flutter pub get
```

### Step 3: Import Package

```dart
import 'package:flutter_jazzcash/flutter_jazzcash.dart';
```

---

## Setup & Configuration

### Step 1: Get JazzCash Credentials

Contact JazzCash to obtain:
- **Merchant ID** (e.g., MC123456)
- **Password** (provided by JazzCash)
- **Integrity Salt** (for secure hash generation)

### Step 2: Initialize the Service

```dart
class PaymentService {
  late JazzCashService jazzCash;

  void initializeJazzCash() {
    jazzCash = JazzCashService.initialize(
      merchantId: 'YOUR_MERCHANT_ID',      // Replace with your merchant ID
      password: 'YOUR_PASSWORD',           // Replace with your password
      integritySalt: 'YOUR_INTEGRITY_SALT', // Replace with your integrity salt
      isProduction: false,                 // Set to true for production
    );
  }
}
```

⚠️ **Security Note**: Never hardcode production credentials in your app. Use environment variables or secure storage.

---

## Mobile Wallet Payment

Mobile wallet payment allows users to pay directly through their JazzCash mobile app using their mobile number and CNIC.

### Step 1: Create Payment Request

```dart
Future<void> processMobileWalletPayment({
  required double amount,
  required String mobileNumber,
  required String cnic,
  required String description,
}) async {
  try {
    // Create payment request
    final request = JazzCashMobileWalletRequest(
      amount: amount,                           // Amount in PKR (e.g., 100.0)
      billReference: _generateBillReference(),  // Unique bill reference
      cnic: cnic,                              // Customer's CNIC (13 digits)
      description: description,                 // Payment description
      mobileNumber: mobileNumber,              // Customer's mobile number (03XXXXXXXXX)
      customFields: {                          // Optional custom fields
        'ppmpf_1': 'Custom Field 1',
        'ppmpf_2': 'Custom Field 2',
      },
    );

    // Process payment
    final response = await jazzCash.processMobileWalletPayment(request);

    // Handle response
    if (response.isSuccessful) {
      _handlePaymentSuccess(response);
    } else {
      _handlePaymentFailure(response);
    }
  } catch (e) {
    _handlePaymentError(e);
  }
}

String _generateBillReference() {
  // Generate unique bill reference
  return 'BILL${DateTime.now().millisecondsSinceEpoch}';
}
```

### Step 2: Handle Payment Response

```dart
void _handlePaymentSuccess(JazzCashMobileWalletResponse response) {
  print('✅ Payment Successful!');
  print('Transaction Reference: ${response.txnRefNo}');
  print('Auth Code: ${response.authCode}');
  print('Amount: PKR ${double.parse(response.amount) / 100}');
  print('Status: ${response.statusMessage}');
  
  // Update your UI
  showSuccessDialog(
    title: 'Payment Successful',
    message: 'Your payment of PKR ${double.parse(response.amount) / 100} has been processed successfully.',
    transactionRef: response.txnRefNo,
  );
  
  // Save transaction to your backend
  saveTransactionToBackend(response);
}

void _handlePaymentFailure(JazzCashMobileWalletResponse response) {
  print('❌ Payment Failed');
  print('Error: ${response.statusMessage}');
  print('Transaction Reference: ${response.txnRefNo}');
  
  // Show error to user
  showErrorDialog(
    title: 'Payment Failed',
    message: response.statusMessage,
  );
}
```

### Step 3: Input Validation

```dart
bool validateMobileWalletInputs({
  required String amount,
  required String mobileNumber,
  required String cnic,
  required String description,
}) {
  // Validate amount
  final amountValue = double.tryParse(amount);
  if (amountValue == null || amountValue <= 0) {
    showError('Please enter a valid amount');
    return false;
  }
  
  if (amountValue < 10) {
    showError('Minimum amount is PKR 10');
    return false;
  }
  
  if (amountValue > 25000) {
    showError('Maximum amount is PKR 25,000');
    return false;
  }

  // Validate mobile number
  if (!RegExp(r'^03\d{9}$').hasMatch(mobileNumber)) {
    showError('Please enter valid mobile number (03XXXXXXXXX)');
    return false;
  }

  // Validate CNIC
  if (!RegExp(r'^\d{13}$').hasMatch(cnic)) {
    showError('Please enter valid 13-digit CNIC');
    return false;
  }

  // Validate description
  if (description.trim().length < 3) {
    showError('Description must be at least 3 characters');
    return false;
  }

  return true;
}
```

---

## Card Payment

Card payment opens a secure WebView where users can enter their card details and complete payment with 3D Secure authentication.

### Step 1: Create Card Payment Request

```dart
Future<void> processCardPayment({
  required double amount,
  required String description,
  required BuildContext context,
}) async {
  try {
    // Create card payment request
    final request = JazzCashCardPaymentRequest(
      amount: amount,                           // Amount in PKR
      billReference: _generateBillReference(),  // Unique bill reference
      description: description,                 // Payment description
      returnUrl: 'https://yourapp.com/payment-return', // Your return URL
      customFields: {                          // Optional custom fields
        'ppmpf_1': 'Order ID: 12345',
        'ppmpf_2': 'Customer ID: 67890',
      },
    );

    // Open card payment WebView
    await jazzCash.openCardPayment(
      context: context,
      request: request,
      onPaymentSuccess: _handleCardPaymentSuccess,
      onPaymentFailure: _handleCardPaymentFailure,
      onPaymentCancelled: _handleCardPaymentCancellation,
    );
  } catch (e) {
    _handlePaymentError(e);
  }
}
```

### Step 2: Handle Card Payment Callbacks

```dart
void _handleCardPaymentSuccess(JazzCashCardPaymentResponse response) {
  print('✅ Card Payment Successful!');
  print('Transaction Reference: ${response.txnRefNo}');
  print('Auth Code: ${response.authCode}');
  print('Amount: PKR ${double.parse(response.amount) / 100}');
  
  // Close any loading dialogs
  Navigator.of(context).popUntil((route) => route.isFirst);
  
  // Show success message
  showSuccessDialog(
    title: 'Card Payment Successful',
    message: 'Your card payment has been processed successfully.',
    transactionRef: response.txnRefNo,
  );
  
  // Save to backend
  saveTransactionToBackend(response);
}

void _handleCardPaymentFailure(String error) {
  print('❌ Card Payment Failed: $error');
  
  // Show error message
  showErrorDialog(
    title: 'Card Payment Failed',
    message: 'Your card payment could not be processed. Please try again.',
    details: error,
  );
}

void _handleCardPaymentCancellation() {
  print('🚫 Card Payment Cancelled');
  
  // Show cancellation message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Payment was cancelled'),
      backgroundColor: Colors.orange,
    ),
  );
}
```

### Step 3: Card Payment Validation

```dart
bool validateCardInputs({
  required String amount,
  required String description,
}) {
  // Validate amount
  final amountValue = double.tryParse(amount);
  if (amountValue == null || amountValue <= 0) {
    showError('Please enter a valid amount');
    return false;
  }
  
  if (amountValue < 10) {
    showError('Minimum amount is PKR 10');
    return false;
  }

  // Validate description
  if (description.trim().length < 3) {
    showError('Description must be at least 3 characters');
    return false;
  }

  return true;
}
```

---

## Transaction Status

Check the status of any transaction using its reference number.

### Check Transaction Status

```dart
Future<void> checkTransactionStatus(String transactionRef) async {
  try {
    // Show loading indicator
    showLoadingDialog('Checking transaction status...');
    
    // Check status
    final status = await jazzCash.checkTransactionStatus(transactionRef);
    
    // Hide loading
    hideLoadingDialog();
    
    // Parse response
    final responseCode = status['pp_ResponseCode'] ?? '';
    final responseMessage = status['pp_ResponseMessage'] ?? '';
    
    // Handle different status codes
    _handleTransactionStatus(responseCode, responseMessage, transactionRef);
    
  } catch (e) {
    hideLoadingDialog();
    showError('Unable to check transaction status: $e');
  }
}

void _handleTransactionStatus(String code, String message, String txnRef) {
  String statusText;
  Color statusColor;
  IconData statusIcon;
  
  switch (code) {
    case '000':
      statusText = 'Transaction Successful';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      break;
    case '001':
      statusText = 'Transaction Pending';
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      break;
    case '101':
      statusText = 'Transaction Failed';
      statusColor = Colors.red;
      statusIcon = Icons.error;
      break;
    case '111':
      statusText = 'Insufficient Balance';
      statusColor = Colors.red;
      statusIcon = Icons.account_balance_wallet;
      break;
    default:
      statusText = 'Unknown Status';
      statusColor = Colors.grey;
      statusIcon = Icons.help;
  }
  
  // Show status dialog
  showStatusDialog(
    status: statusText,
    color: statusColor,
    icon: statusIcon,
    code: code,
    message: message,
    txnRef: txnRef,
  );
}
```

---

## Error Handling

### Comprehensive Error Handling

```dart
void _handlePaymentError(dynamic error) {
  String errorMessage;
  String? errorCode;
  
  if (error is JazzCashException) {
    errorMessage = error.message;
    errorCode = error.code;
    
    // Handle specific JazzCash errors
    switch (errorCode) {
      case '001':
        errorMessage = 'Transaction is pending. Please wait.';
        break;
      case '101':
        errorMessage = 'Transaction failed. Please try again.';
        break;
      case '111':
        errorMessage = 'Insufficient balance in your account.';
        break;
      case '121':
        errorMessage = 'Invalid transaction. Please check your details.';
        break;
      default:
        errorMessage = error.message;
    }
  } else {
    errorMessage = 'An unexpected error occurred: $error';
  }
  
  // Log error for debugging
  print('Payment Error: $errorMessage (Code: $errorCode)');
  
  // Show user-friendly error
  showErrorDialog(
    title: 'Payment Error',
    message: errorMessage,
    code: errorCode,
  );
}

// Error dialog helper
void showErrorDialog({
  required String title,
  required String message,
  String? code,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (code != null) ...[
            SizedBox(height: 8),
            Text('Error Code: $code', style: TextStyle(color: Colors.grey)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## Production Setup

### Step 1: Update Configuration

```dart
void initializeForProduction() {
  jazzCash = JazzCashService.initialize(
    merchantId: 'YOUR_PRODUCTION_MERCHANT_ID',
    password: 'YOUR_PRODUCTION_PASSWORD',
    integritySalt: 'YOUR_PRODUCTION_INTEGRITY_SALT',
    isProduction: true, // ✅ Set to true for production
  );
}
```

### Step 2: Environment Management

```dart
class AppConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  
  static String get merchantId => isProduction 
      ? 'PROD_MERCHANT_ID' 
      : 'SANDBOX_MERCHANT_ID';
      
  static String get password => isProduction 
      ? 'PROD_PASSWORD' 
      : 'SANDBOX_PASSWORD';
      
  static String get integritySalt => isProduction 
      ? 'PROD_INTEGRITY_SALT' 
      : 'SANDBOX_INTEGRITY_SALT';
}

// Initialize with environment-based config
jazzCash = JazzCashService.initialize(
  merchantId: AppConfig.merchantId,
  password: AppConfig.password,
  integritySalt: AppConfig.integritySalt,
  isProduction: AppConfig.isProduction,
);
```

### Step 3: Build Commands

```bash
# For development (Sandbox)
flutter run

# For production
flutter run --dart-define=PRODUCTION=true
flutter build apk --dart-define=PRODUCTION=true
flutter build ios --dart-define=PRODUCTION=true
```

---

## Complete Example

Here's a complete implementation example:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_jazzcash/flutter_jazzcash.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late JazzCashService jazzCash;
  
  final TextEditingController amountController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize JazzCash
    jazzCash = JazzCashService.initialize(
      merchantId: 'YOUR_MERCHANT_ID',
      password: 'YOUR_PASSWORD',
      integritySalt: 'YOUR_INTEGRITY_SALT',
      isProduction: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('JazzCash Payment')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Amount Field
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (PKR)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            
            // Description Field
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // Mobile Number Field (for mobile wallet)
            TextField(
              controller: mobileController,
              decoration: InputDecoration(
                labelText: 'Mobile Number (for wallet payment)',
                hintText: '03XXXXXXXXX',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            
            // CNIC Field (for mobile wallet)
            TextField(
              controller: cnicController,
              decoration: InputDecoration(
                labelText: 'CNIC (for wallet payment)',
                hintText: '1234567890123',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 32),
            
            // Payment Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _processMobileWalletPayment,
                    icon: Icon(Icons.phone_android),
                    label: Text('Mobile Wallet'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _processCardPayment,
                    icon: Icon(Icons.credit_card),
                    label: Text('Card Payment'),
                  ),
                ),
              ],
            ),
            
            // Loading Indicator
            if (isLoading)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processMobileWalletPayment() async {
    if (!_validateMobileWalletInputs()) return;

    setState(() => isLoading = true);

    try {
      final request = JazzCashMobileWalletRequest(
        amount: double.parse(amountController.text),
        billReference: 'BILL${DateTime.now().millisecondsSinceEpoch}',
        cnic: cnicController.text.trim(),
        description: descriptionController.text.trim(),
        mobileNumber: mobileController.text.trim(),
      );

      final response = await jazzCash.processMobileWalletPayment(request);

      if (response.isSuccessful) {
        _showSuccessDialog('Mobile Wallet Payment Successful', response.txnRefNo);
      } else {
        _showErrorDialog('Payment Failed', response.statusMessage);
      }
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _processCardPayment() async {
    if (!_validateCardInputs()) return;

    final request = JazzCashCardPaymentRequest(
      amount: double.parse(amountController.text),
      billReference: 'CARD${DateTime.now().millisecondsSinceEpoch}',
      description: descriptionController.text.trim(),
      returnUrl: 'https://yourapp.com/payment-return',
    );

    await jazzCash.openCardPayment(
      context: context,
      request: request,
      onPaymentSuccess: (response) {
        _showSuccessDialog('Card Payment Successful', response.txnRefNo);
      },
      onPaymentFailure: (error) {
        _showErrorDialog('Card Payment Failed', error);
      },
      onPaymentCancelled: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment cancelled')),
        );
      },
    );
  }

  bool _validateMobileWalletInputs() {
    if (amountController.text.isEmpty ||
        mobileController.text.isEmpty ||
        cnicController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please fill all fields');
      return false;
    }

    if (!RegExp(r'^03\d{9}$').hasMatch(mobileController.text)) {
      _showErrorDialog('Validation Error', 'Invalid mobile number format');
      return false;
    }

    if (cnicController.text.length != 13) {
      _showErrorDialog('Validation Error', 'CNIC must be 13 digits');
      return false;
    }

    return true;
  }

  bool _validateCardInputs() {
    if (amountController.text.isEmpty || descriptionController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please fill amount and description');
      return false;
    }
    return true;
  }

  void _showSuccessDialog(String title, String txnRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text('Transaction Reference: $txnRef'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    mobileController.dispose();
    cnicController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
```

---

## Best Practices

### 1. Security
- ✅ Never hardcode production credentials
- ✅ Use environment variables for configuration
- ✅ Validate all inputs before processing
- ✅ Always validate payment responses on your backend
- ✅ Use HTTPS for all return URLs

### 2. User Experience
- ✅ Show loading indicators during payment processing
- ✅ Provide clear error messages
- ✅ Allow users to retry failed payments
- ✅ Save payment history for user reference
- ✅ Implement proper navigation handling

### 3. Error Handling
- ✅ Handle network timeouts gracefully
- ✅ Provide fallback options for failed payments
- ✅ Log errors for debugging (without sensitive data)
- ✅ Show user-friendly error messages
- ✅ Implement retry mechanisms

### 4. Testing
- ✅ Test with sandbox credentials thoroughly
- ✅ Test various error scenarios
- ✅ Validate on different devices and network conditions
- ✅ Test payment cancellation flows
- ✅ Verify transaction status checking

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Hash Validation Failed
**Problem**: "Response hash validation failed"
**Solution**:
- Verify integrity salt is correct
- Check field ordering in hash generation
- Ensure all required fields are present

#### 2. WebView Not Loading
**Problem**: Card payment WebView doesn't load
**Solution**:
- Check internet connectivity
- Verify return URL is accessible
- Ensure WebView permissions are granted

#### 3. Payment Timeout
**Problem**: Payment takes too long or times out
**Solution**:
- Increase timeout duration
- Check network stability
- Implement retry mechanism

#### 4. Invalid Credentials
**Problem**: "Invalid merchant credentials"
**Solution**:
- Verify merchant ID, password, and integrity salt
- Check if using correct environment (sandbox vs production)
- Contact JazzCash support if needed

#### 5. Mobile Number Validation
**Problem**: Mobile number not accepted
**Solution**:
- Ensure format is 03XXXXXXXXX (11 digits)
- Remove any spaces or special characters
- Verify number is registered with JazzCash

### Debug Mode

Enable debug logging for troubleshooting:

```dart
void enableDebugMode() {
  // Add debug prints in your payment methods
  print('JazzCash Debug: Processing payment...');
  print('Amount: ${request.amount}');
  print('Bill Reference: ${request.billReference}');
  print('Environment: ${jazzCash.isProduction ? 'Production' : 'Sandbox'}');
}
```

---

## Support

For additional help:

1. **Package Issues**: Create an issue on the GitHub repository
2. **JazzCash Integration**: Contact JazzCash merchant support
3. **Production Setup**: Reach out to JazzCash technical team
4. **Documentation**: Refer to JazzCash official API documentation

---

**🎉 You're now ready to integrate JazzCash payments in your Flutter app!**

This guide covers everything you need to implement both mobile wallet and card payments successfully. Remember to test thoroughly in sandbox mode before going live with production credentials.