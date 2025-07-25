import 'package:flutter/material.dart';
import 'package:flutter_jazzcash/flutter_jazzcash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JazzCash Flutter Package Example',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const PaymentScreen(),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late JazzCashService jazzCash;

  final TextEditingController mobileController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize JazzCash with sandbox credentials
    jazzCash = JazzCashService.initialize(
      merchantId: 'MC202938', // Replace with your sandbox merchant ID
      password: 'z5udd1u03y', // Replace with your sandbox password
      integritySalt: 'se3vaxe1g8', // Replace with your sandbox integrity salt
      isProduction: false, // Set to true for production
    );

    // Pre-fill with test data for easy testing
    mobileController.text = '03001234567';
    cnicController.text = '123456';
    amountController.text = '100';
    descriptionController.text = 'Test Payment';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JazzCash Flutter Package'),
        backgroundColor: const Color(0xFF00a651),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (PKR)',
                        prefixText: 'PKR ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mobile Wallet Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Wallet Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Required for mobile wallet payments only',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '03XXXXXXXXX',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cnicController,
                      decoration: const InputDecoration(
                        labelText: 'CNIC',
                        hintText: 'last 6',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Methods Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Methods',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                isLoading ? null : _processMobileWalletPayment,
                            icon: const Icon(Icons.phone_android),
                            label: const Text('Mobile Wallet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00a651),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _processCardPayment,
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Card Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loading Indicator
            if (isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Processing payment...'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Package Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Package Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Mode: ${jazzCash.isProduction ? 'Production' : 'Sandbox'}'),
                    Text('Merchant ID: ${jazzCash.merchantId}'),
                    const Text('Type: Flutter Package'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processMobileWalletPayment() async {
    if (!mounted) return;
    if (!_validateMobileWalletInputs()) return;

    setState(() {
      isLoading = true;
    });

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
        _showSuccessDialog(
          'Mobile Wallet Payment Successful',
          'Transaction Reference: ${response.txnRefNo}\n'
              'Auth Code: ${response.authCode ?? 'N/A'}\n'
              'Amount: PKR ${double.parse(response.amount) / 100}',
          response.txnRefNo,
        );
      } else {
        _showErrorDialog('Payment Failed', response.statusMessage);
      }
    } on JazzCashException catch (e) {
      _showErrorDialog('JazzCash Error', e.message);
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _processCardPayment() async {
    if (!mounted) return;
    if (!_validateCardInputs()) return;

    final request = JazzCashCardPaymentRequest(
      amount: double.parse(amountController.text),
      billReference: 'CARD${DateTime.now().millisecondsSinceEpoch}',
      description: descriptionController.text.trim(),
      returnUrl: 'https://padellite.com/payment-return',
    );

    await jazzCash.openCardPayment(
      context: context,
      request: request,
      onPaymentSuccess: (response) {
        _showSuccessDialog(
          'Card Payment Successful',
          'Transaction Reference: ${response.txnRefNo}\n'
              'Auth Code: ${response.authCode ?? 'N/A'}\n'
              'Amount: PKR ${double.parse(response.amount) / 100}',
          response.txnRefNo,
        );
      },
      onPaymentFailure: (error) {
        _showErrorDialog('Card Payment Failed', error);
      },
      onPaymentCancelled: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled by user'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }

  bool _validateMobileWalletInputs() {
    if (amountController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter amount');
      return false;
    }

    if (double.tryParse(amountController.text) == null ||
        double.parse(amountController.text) <= 0) {
      _showErrorDialog('Validation Error', 'Please enter a valid amount');
      return false;
    }

    if (mobileController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter mobile number');
      return false;
    }

    if (!RegExp(r'^03\d{9}$').hasMatch(mobileController.text)) {
      _showErrorDialog('Validation Error',
          'Please enter a valid mobile number (03XXXXXXXXX)');
      return false;
    }

    if (cnicController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter CNIC');
      return false;
    }

    if (cnicController.text.length != 6) {
      _showErrorDialog('Validation Error', 'Enter last 6 digit from cnic');
      return false;
    }

    if (descriptionController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter description');
      return false;
    }

    return true;
  }

  bool _validateCardInputs() {
    if (amountController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter amount');
      return false;
    }

    if (double.tryParse(amountController.text) == null ||
        double.parse(amountController.text) <= 0) {
      _showErrorDialog('Validation Error', 'Please enter a valid amount');
      return false;
    }

    if (descriptionController.text.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter description');
      return false;
    }

    return true;
  }

  void _showSuccessDialog(String title, String message, String txnRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'Status can be checked using transaction reference',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _checkTransactionStatus(txnRef),
            child: const Text('Check Status'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkTransactionStatus(String txnRef) async {
    if (!mounted) return;
    Navigator.pop(context); // Close the success dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking transaction status...'),
          ],
        ),
      ),
    );

    try {
      final status = await jazzCash.checkTransactionStatus(txnRef);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final responseCode = status['pp_ResponseCode'] ?? '';
      final responseMessage = status['pp_ResponseMessage'] ?? '';

      String statusText;
      Color statusColor;

      if (responseCode == '000') {
        statusText = 'Transaction Successful';
        statusColor = Colors.green;
      } else if (responseCode == '001') {
        statusText = 'Transaction Pending';
        statusColor = Colors.orange;
      } else {
        statusText = 'Transaction Failed';
        statusColor = Colors.red;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transaction Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Transaction Reference: $txnRef'),
              Text('Response Code: $responseCode'),
              Text('Response Message: $responseMessage'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(
          'Status Check Failed', 'Unable to check transaction status: $e');
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    cnicController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
