import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/jazzcash_config.dart';
import '../models/payment_models.dart';
import '../utils/hash_generator.dart';

/// WebView widget for JazzCash card payments
class JazzCashCardPaymentWebView extends StatefulWidget {
  final JazzCashConfig config;
  final JazzCashCardPaymentRequest paymentRequest;
  final Function(JazzCashCardPaymentResponse) onPaymentSuccess;
  final Function(String) onPaymentFailure;
  final VoidCallback? onPaymentCancelled;

  const JazzCashCardPaymentWebView({
    super.key,
    required this.config,
    required this.paymentRequest,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.onPaymentCancelled,
  });

  @override
  State<JazzCashCardPaymentWebView> createState() =>
      _JazzCashCardPaymentWebViewState();
}

class _JazzCashCardPaymentWebViewState
    extends State<JazzCashCardPaymentWebView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            _handlePageFinished(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleNavigationRequest(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _handleWebResourceError(error);
          },
        ),
      );

    _loadPaymentForm();
  }

  void _loadPaymentForm() {
    final formData = _generateFormData();
    final htmlContent = _generateHtmlForm(formData);

    controller.loadHtmlString(htmlContent);
  }

  Map<String, String> _generateFormData() {
    final txnRefNo =
        widget.paymentRequest.txnRefNo ?? DateTimeHelper.generateTxnRefNo();
    final txnDateTime = DateTimeHelper.formatDateTime(DateTime.now());
    final txnExpiryDateTime = DateTimeHelper.generateExpiryDateTime();

    // Convert amount to paisas (multiply by 100)
    final amountInPaisas =
        (widget.paymentRequest.amount * 100).toInt().toString();

    final Map<String, dynamic> data = {
      'pp_Version': '1.1',
      'pp_TxnType': 'MPAY',
      'pp_Language': 'EN',
      'pp_MerchantID': widget.config.merchantId,
      'pp_SubMerchantID': '',
      'pp_Password': widget.config.password,
      'pp_TxnRefNo': txnRefNo,
      'pp_Amount': amountInPaisas,
      'pp_TxnCurrency': 'PKR',
      'pp_TxnDateTime': txnDateTime,
      'pp_BillReference': widget.paymentRequest.billReference,
      'pp_Description': widget.paymentRequest.description,
      'pp_TxnExpiryDateTime': txnExpiryDateTime,
      'pp_ReturnURL': widget.paymentRequest.returnUrl,
      'pp_BankID': '',
      'pp_ProductID': '',
      'ppmpf_1': widget.paymentRequest.customFields?['ppmpf_1'] ?? '',
      'ppmpf_2': widget.paymentRequest.customFields?['ppmpf_2'] ?? '',
      'ppmpf_3': widget.paymentRequest.customFields?['ppmpf_3'] ?? '',
      'ppmpf_4': widget.paymentRequest.customFields?['ppmpf_4'] ?? '',
      'ppmpf_5': widget.paymentRequest.customFields?['ppmpf_5'] ?? '',
    };

    // Generate secure hash for card payment
    data['pp_SecureHash'] = JazzCashHashGenerator.generateCardPaymentHash(
      data,
      widget.config.integritySalt,
    );

    // Convert all values to strings for form submission
    final Map<String, String> stringFormData = {};
    data.forEach((key, value) {
      stringFormData[key] = value.toString();
    });

    return stringFormData;
  }

  String _generateHtmlForm(Map<String, String> formData) {
    final formFields = formData.entries
        .map((entry) =>
            '<input type="hidden" name="${entry.key}" value="${entry.value}">')
        .join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JazzCash Payment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .loading-container {
            text-align: center;
        }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #00a651;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .message {
            color: #333;
            font-size: 16px;
            margin-bottom: 20px;
        }
        .logo {
            width: 150px;
            height: auto;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="loading-container">
        <div class="spinner"></div>
        <div class="message">Redirecting to JazzCash Payment Gateway...</div>
        <div class="message" style="font-size: 14px; color: #666;">
            Please wait while we securely process your payment.
        </div>
    </div>
    
    <form id="paymentForm" method="POST" action="${widget.config.cardPaymentUrl}">
        $formFields
    </form>
    
    <script>
        // Auto-submit the form after a short delay
        setTimeout(function() {
            document.getElementById('paymentForm').submit();
        }, 2000);
    </script>
</body>
</html>
    ''';
  }

  void _handlePageFinished(String url) {
    // Check if we're on the return URL
    if (url.contains(widget.paymentRequest.returnUrl) ||
        url.contains('payment-return') ||
        url.contains('return')) {
      _extractPaymentResponse(url);
    }
  }

  void _handleNavigationRequest(String url) {
    // Handle any specific URL patterns if needed
    if (url.contains('cancel') || url.contains('abort')) {
      widget.onPaymentCancelled?.call();
    }
  }

  void _handleWebResourceError(WebResourceError error) {
    if (mounted) {
      widget.onPaymentFailure('Web resource error: ${error.description}');
    }
  }

  void _extractPaymentResponse(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      if (queryParams.isNotEmpty) {
        // Validate response hash
        if (!JazzCashHashGenerator.validateResponseHash(
          queryParams,
          widget.config.integritySalt,
        )) {
          widget.onPaymentFailure('Response validation failed');
          return;
        }

        final response = JazzCashCardPaymentResponse.fromJson(queryParams);

        if (response.isSuccessful) {
          widget.onPaymentSuccess(response);
        } else {
          widget.onPaymentFailure(response.statusMessage);
        }
      } else {
        // Try to extract from URL fragment or body
        _extractFromPageContent();
      }
    } catch (e) {
      widget.onPaymentFailure('Failed to process payment response: $e');
    }
  }

  void _extractFromPageContent() {
    controller.runJavaScriptReturningResult('''
      // Try to extract payment response from page content
      var responseData = {};
      var inputs = document.querySelectorAll('input[name^="pp_"]');
      inputs.forEach(function(input) {
        responseData[input.name] = input.value;
      });
      
      // Also try to get data from any JavaScript variables
      if (typeof paymentResponse !== 'undefined') {
        responseData = paymentResponse;
      }
      
      JSON.stringify(responseData);
    ''').then((result) {
      try {
        // Handle the result properly - it might be wrapped in quotes
        String jsonString = result.toString();

        // Remove surrounding quotes if present
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          jsonString = jsonString.substring(1, jsonString.length - 1);
          // Unescape any escaped quotes
          jsonString = jsonString.replaceAll('\\"', '"');
        }

        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        if (data.isNotEmpty) {
          final response = JazzCashCardPaymentResponse.fromJson(data);
          if (response.isSuccessful) {
            widget.onPaymentSuccess(response);
          } else {
            widget.onPaymentFailure(response.statusMessage);
          }
        } else {
          widget.onPaymentFailure('No payment data found on page');
        }
      } catch (e) {
        widget.onPaymentFailure('Unable to extract payment response: $e');
      }
    }).catchError((error) {
      widget.onPaymentFailure('JavaScript execution failed: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JazzCash Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onPaymentCancelled?.call();
          },
        ),
        backgroundColor: const Color(0xFF00a651),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00a651)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading Payment Gateway...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
