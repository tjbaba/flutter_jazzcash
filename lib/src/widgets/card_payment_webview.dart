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
  State<JazzCashCardPaymentWebView> createState() => _JazzCashCardPaymentWebViewState();
}

class _JazzCashCardPaymentWebViewState extends State<JazzCashCardPaymentWebView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String _pageTitle = 'JazzCash Payment';
  bool _hasProcessedResponse = false; // Prevent duplicate processing

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'PaymentResponse',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final responseData = jsonDecode(message.message) as Map<String, dynamic>;
            _processPaymentResponse(responseData.cast<String, String>());
          } catch (e) {
            widget.onPaymentFailure('Failed to parse payment response');
          }
        },
      )
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });

            // Inject JavaScript to capture POST data when page starts loading
            if (url.contains('jazzcash.com') || url.contains('gateway.mastercard.com')) {
              _injectPostCaptureScript();
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Inject JavaScript to capture forms and POST data
            _injectPostCaptureScript();
            _handlePageFinished(url);
          },
          onWebResourceError: (WebResourceError error) {
            // Ignore Norton security widget and similar third-party resource errors
            if (error.url != null && (error.url!.contains('norton.com') ||
                error.url!.contains('symantec.com') ||
                error.url!.contains('verisign.com') ||
                error.url!.contains('mastercard.com')) ||
                error.description != null && (error.description!.contains('ERR_BLOCKED_BY_ORB') ||
                    error.description!.contains('X-Frame-Options'))) {
              return;
            }

            if (error.url != null && error.url!.contains('jazzcash.com')) {
              widget.onPaymentFailure('Payment page failed to load: ${error.description}');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // **DYNAMIC: Handle return URL based on provided URL**
            if (_isReturnUrl(request.url)) {
              _handleReturnUrl(request.url);
              return NavigationDecision.prevent; // Prevent navigation to non-existent page
            }

            // Log URL components for analysis
            try {
              final uri = Uri.parse(request.url);

              if (uri.queryParameters.isNotEmpty) {
                // Check if query params contain response
                if (uri.queryParameters.containsKey('pp_ResponseCode') ||
                    uri.queryParameters.containsKey('ResponseCode')) {
                  _processPaymentResponse(uri.queryParameters);
                  return NavigationDecision.prevent;
                }
              }
            } catch (e) {
              // Continue navigation on parsing error
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Load the payment form
    _loadPaymentForm();
  }

  /// Check if the URL matches the return URL pattern
  bool _isReturnUrl(String url) {
    try {
      final returnUri = Uri.parse(widget.paymentRequest.returnUrl);
      final currentUri = Uri.parse(url);

      // Match by host and path
      if (returnUri.host == currentUri.host && returnUri.path == currentUri.path) {
        return true;
      }

      // Also check if URL contains the return URL as substring (for flexibility)
      if (url.contains(widget.paymentRequest.returnUrl)) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // New method to inject JavaScript for capturing POST data with dynamic return URL
  void _injectPostCaptureScript() {
    final returnUrl = widget.paymentRequest.returnUrl;

    final script = '''
      (function() {
        var returnUrlPattern = '$returnUrl';

        // Override form submission to capture POST data
        var originalSubmit = HTMLFormElement.prototype.submit;
        HTMLFormElement.prototype.submit = function() {
          // Check if this form is posting to return URL
          if (this.action && this.action.includes(returnUrlPattern)) {
            var formData = {};
            var inputs = this.querySelectorAll('input');

            inputs.forEach(function(input) {
              if (input.name && input.value) {
                formData[input.name] = input.value;
              }
            });

            // Send data to Flutter
            if (window.PaymentResponse) {
              window.PaymentResponse.postMessage(JSON.stringify(formData));
            }

            // Prevent actual form submission
            return false;
          }

          // Allow other forms to submit normally
          return originalSubmit.apply(this, arguments);
        };

        // Also monitor for dynamically created forms
        var observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
              if (node.nodeType === 1 && node.tagName === 'FORM') {
                // Check if this is a return URL form
                if (node.action && node.action.includes(returnUrlPattern)) {
                  // Override its submit
                  var originalSubmit = node.submit;
                  node.submit = function() {
                    var formData = {};
                    var inputs = this.querySelectorAll('input');

                    inputs.forEach(function(input) {
                      if (input.name && input.value) {
                        formData[input.name] = input.value;
                      }
                    });

                    if (window.PaymentResponse) {
                      window.PaymentResponse.postMessage(JSON.stringify(formData));
                    }

                    return false;
                  };

                  // Also add event listener for form submission
                  node.addEventListener('submit', function(e) {
                    e.preventDefault();

                    var formData = {};
                    var inputs = this.querySelectorAll('input');

                    inputs.forEach(function(input) {
                      if (input.name && input.value) {
                        formData[input.name] = input.value;
                      }
                    });

                    if (window.PaymentResponse) {
                      window.PaymentResponse.postMessage(JSON.stringify(formData));
                    }
                  });
                }
              }
            });
          });
        });

        observer.observe(document.body, {
          childList: true,
          subtree: true
        });

        // Check for existing forms on page load
        setTimeout(function() {
          var forms = document.querySelectorAll('form');
          forms.forEach(function(form) {
            if (form.action && form.action.includes(returnUrlPattern)) {
              var formData = {};
              var inputs = form.querySelectorAll('input');

              inputs.forEach(function(input) {
                if (input.name && input.value) {
                  formData[input.name] = input.value;
                }
              });

              if (window.PaymentResponse && Object.keys(formData).length > 0) {
                window.PaymentResponse.postMessage(JSON.stringify(formData));
              }
            }
          });
        }, 1000);
      })();
    ''';

    _webViewController.runJavaScript(script).catchError((error) {
      // Silent error handling
    });
  }

  void _loadPaymentForm() {
    final formData = _generateCardPaymentForm();
    final htmlContent = _generatePaymentFormHTML(formData);
    _webViewController.loadHtmlString(htmlContent);
  }

  Map<String, String> _generateCardPaymentForm() {
    final txnRefNo = widget.paymentRequest.txnRefNo ??
        DateTimeHelper.generateTxnRefNo();
    final txnDateTime = DateTimeHelper.formatDateTime(DateTime.now());
    final txnExpiryDateTime = DateTimeHelper.generateExpiryDateTime();

    // Convert amount to paisas (multiply by 100)
    final amountInPaisas = (widget.paymentRequest.amount * 100).toInt().toString();

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

  String _generatePaymentFormHTML(Map<String, String> formData) {
    final formFields = formData.entries
        .map((entry) => '<input type="hidden" name="${entry.key}" value="${entry.value}">')
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
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #00a651 0%, #004d26 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 400px;
            width: 100%;
        }
        .logo {
            width: 80px;
            height: 80px;
            background: #00a651;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 24px;
            color: white;
            font-weight: bold;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 24px;
        }
        .amount {
            font-size: 28px;
            font-weight: bold;
            color: #00a651;
            margin: 20px 0;
        }
        .description {
            color: #666;
            margin-bottom: 30px;
            line-height: 1.5;
        }
        .btn {
            background: #00a651;
            color: white;
            border: none;
            padding: 16px 32px;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: all 0.3s ease;
        }
        .btn:hover {
            opacity: 0.9;
            transform: translateY(-2px);
        }
        .loading {
            display: none;
            margin-top: 20px;
        }
        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #00a651;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .security-info {
            background: rgba(0, 166, 81, 0.1);
            border: 1px solid rgba(0, 166, 81, 0.2);
            border-radius: 8px;
            padding: 16px;
            margin-top: 20px;
            font-size: 14px;
            color: #00a651;
        }
        .security-icon {
            color: #00a651;
            margin-right: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">JC</div>
        <h1>JazzCash Payment</h1>
        <div class="amount">PKR ${(int.parse(formData['pp_Amount']!) / 100).toStringAsFixed(2)}</div>
        <div class="description">
            ${formData['pp_Description']}<br>
            <small>Transaction Ref: ${formData['pp_TxnRefNo']}</small>
        </div>

        <form id="paymentForm" method="POST" action="${widget.config.cardPaymentUrl}">
            $formFields
            <button type="submit" class="btn" onclick="showLoading()">
                🔒 Pay Securely with Card
            </button>
        </form>

        <div class="loading" id="loading">
            <div class="spinner"></div>
            <p>Redirecting to secure payment page...</p>
        </div>

        <div class="security-info">
            <span class="security-icon">🔒</span>
            Your payment is secured by JazzCash SSL encryption
        </div>
    </div>

    <script>
        function showLoading() {
            document.querySelector('.btn').style.display = 'none';
            document.getElementById('loading').style.display = 'block';
        }
    </script>
</body>
</html>
    ''';
  }

  void _handlePageFinished(String url) {
    // Update page title
    _webViewController.getTitle().then((title) {
      if (title != null && mounted) {
        setState(() {
          _pageTitle = title;
        });
      }
    });

    // Handle return URL if reached via page navigation
    if (_isReturnUrl(url)) {
      _handleReturnUrl(url);
      return;
    }

    // Always try to extract response data from any page
    _extractAllPageData(url);

    // Check for JazzCash response patterns in the URL
    if (url.contains('ResponseCode') || url.contains('pp_ResponseCode')) {
      _extractResponseFromUrl(url);
    }
  }

  void _extractAllPageData(String url) {
    const script = '''
      (function() {
        var allData = {
          url: window.location.href,
          search: window.location.search,
          hash: window.location.hash,
          formData: {},
          pageText: '',
          responseFound: false
        };

        // Get all form inputs
        var inputs = document.querySelectorAll('input');
        inputs.forEach(function(input) {
          if (input.name && input.value) {
            allData.formData[input.name] = input.value;
            if (input.name.includes('ResponseCode') || input.name.includes('pp_')) {
              allData.responseFound = true;
            }
          }
        });

        // Get page text content
        allData.pageText = document.body.innerText || document.body.textContent || '';

        // Check if page text contains response indicators
        if (allData.pageText.includes('ResponseCode') ||
            allData.pageText.includes('pp_ResponseCode') ||
            allData.pageText.includes('Transaction') ||
            allData.pageText.includes('Payment')) {
          allData.responseFound = true;
        }

        // Get all meta tags
        var metas = document.querySelectorAll('meta');
        allData.metaTags = {};
        metas.forEach(function(meta) {
          if (meta.name && meta.content) {
            allData.metaTags[meta.name] = meta.content;
          }
        });

        // Get current page HTML (truncated)
        allData.htmlPreview = document.documentElement.outerHTML.substring(0, 2000);

        return JSON.stringify(allData);
      })();
    ''';

    _webViewController.runJavaScriptReturningResult(script).then((result) {
      if (result != null) {
        try {
          final resultStr = result.toString();
          final cleanResult = resultStr.startsWith('"') && resultStr.endsWith('"')
              ? resultStr.substring(1, resultStr.length - 1)
              : resultStr;
          final decodedResult = cleanResult.replaceAll('\\"', '"');

          final allData = jsonDecode(decodedResult) as Map<String, dynamic>;

          // If we found response data, process it
          final formData = allData['formData'] as Map<String, dynamic>;
          if (formData.isNotEmpty && formData.containsKey('pp_ResponseCode')) {
            _processPaymentResponse(formData.cast<String, String>());
          }

        } catch (e) {
          // Silent error handling
        }
      }
    }).catchError((error) {
      // Silent error handling
    });
  }

  void _handleReturnUrl(String url) {
    // Prevent duplicate processing
    if (_hasProcessedResponse) {
      return;
    }

    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      if (queryParams.isNotEmpty && queryParams.containsKey('pp_ResponseCode')) {
        _processPaymentResponse(queryParams);
      } else {
        // Check if the page title or content indicates success/failure
        final isError404 = url.contains('404') || _pageTitle.contains('404') || _pageTitle.contains('Not Found');

        if (isError404) {
          // Try to get the last successful response from page content
          _extractResponseFromPage();

          // Also wait a bit then try again in case the page is still loading
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!_hasProcessedResponse) {
              _handleMissingResponseParameters();
            }
          });
        } else {
          _handleMissingResponseParameters();
        }
      }
    } catch (e) {
      if (!_hasProcessedResponse) {
        _hasProcessedResponse = true;
        widget.onPaymentFailure('Failed to process payment response');
      }
    }
  }

  void _handleMissingResponseParameters() {
    if (!_hasProcessedResponse) {
      _hasProcessedResponse = true;
      widget.onPaymentCancelled?.call();
      Navigator.pop(context); // Close WebView
    }
  }

  void _extractResponseFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Check query parameters first
      if (uri.queryParameters.isNotEmpty) {
        _processPaymentResponse(uri.queryParameters);
        return;
      }

      _extractResponseFromPage();
    } catch (e) {
      if (!_hasProcessedResponse) {
        _hasProcessedResponse = true;
        widget.onPaymentFailure('Failed to extract payment response');
      }
    }
  }

  void _extractResponseFromPage() {
    const script = '''
      (function() {
        var responseData = {};
        var debugInfo = {
          foundInputs: [],
          pageTextSample: '',
          scriptContents: [],
          allElementsWithPP: []
        };

        // Try to find form inputs with payment response
        var inputs = document.querySelectorAll('input');
        inputs.forEach(function(input) {
          debugInfo.foundInputs.push({
            name: input.name || 'no-name',
            value: input.value || 'no-value',
            type: input.type || 'no-type'
          });

          if (input.name && input.value) {
            responseData[input.name] = input.value;
          }
        });

        // Find all elements that might contain pp_ data
        var allElements = document.querySelectorAll('*');
        allElements.forEach(function(element) {
          if (element.textContent && element.textContent.includes('pp_')) {
            debugInfo.allElementsWithPP.push({
              tagName: element.tagName,
              textContent: element.textContent.substring(0, 200),
              innerHTML: element.innerHTML ? element.innerHTML.substring(0, 200) : ''
            });
          }
        });

        // Try to find response in page text
        var pageText = document.body.innerText || document.body.textContent || '';
        debugInfo.pageTextSample = pageText.substring(0, 1000);

        var responsePattern = /pp_ResponseCode[^\\w]*(\\w+)/i;
        var match = pageText.match(responsePattern);
        if (match) {
          responseData['pp_ResponseCode'] = match[1];
        }

        // Try to find response in script tags
        var scripts = document.querySelectorAll('script');
        scripts.forEach(function(script) {
          var content = script.innerHTML;
          if (content) {
            debugInfo.scriptContents.push(content.substring(0, 300));

            if (content.includes('pp_ResponseCode')) {
              var matches = content.match(/pp_\\w+['"\\s]*[:=]['"\\s]*(\\w+)/g);
              if (matches) {
                matches.forEach(function(match) {
                  var parts = match.split(/[:=]/);
                  if (parts.length === 2) {
                    var key = parts[0].replace(/['"\\s]/g, '');
                    var value = parts[1].replace(/['"\\s]/g, '');
                    responseData[key] = value;
                  }
                });
              }
            }
          }
        });

        return JSON.stringify({
          responseData: responseData,
          debugInfo: debugInfo,
          fullPageHTML: document.documentElement.outerHTML
        });
      })();
    ''';

    _webViewController.runJavaScriptReturningResult(script).then((result) {
      if (result != null) {
        try {
          final resultStr = result.toString();
          final cleanResult = resultStr.startsWith('"') && resultStr.endsWith('"')
              ? resultStr.substring(1, resultStr.length - 1)
              : resultStr;
          final decodedResult = cleanResult.replaceAll('\\"', '"');

          final extractedData = jsonDecode(decodedResult) as Map<String, dynamic>;
          final responseData = extractedData['responseData'] as Map<String, dynamic>;

          if (responseData.isNotEmpty && responseData.containsKey('pp_ResponseCode')) {
            _processPaymentResponse(responseData.cast<String, String>());
          } else {
            if (!_hasProcessedResponse) {
              _hasProcessedResponse = true;
              widget.onPaymentFailure('Payment response not found. Please contact support.');
            }
          }
        } catch (e) {
          if (!_hasProcessedResponse) {
            _hasProcessedResponse = true;
            widget.onPaymentFailure('Failed to parse payment response');
          }
        }
      } else {
        if (!_hasProcessedResponse) {
          _hasProcessedResponse = true;
          widget.onPaymentFailure('Failed to extract payment response');
        }
      }
    }).catchError((error) {
      if (!_hasProcessedResponse) {
        _hasProcessedResponse = true;
        widget.onPaymentFailure('Failed to extract payment response');
      }
    });
  }

  void _processPaymentResponse(Map<String, String> responseData) {
    // Prevent duplicate processing
    if (_hasProcessedResponse) {
      return;
    }
    _hasProcessedResponse = true;

    try {
      // Validate the response hash if possible
      final responseDataMap = Map<String, dynamic>.from(responseData);

      if (responseData.containsKey('pp_SecureHash')) {
        final isValid = JazzCashHashGenerator.validateResponseHash(
          responseDataMap,
          widget.config.integritySalt,
        );

        if (!isValid) {
          widget.onPaymentFailure('Invalid payment response. Transaction may be compromised.');
          return;
        }
      }

      // Create response object
      final response = JazzCashCardPaymentResponse.fromJson(responseDataMap);

      if (response.isSuccessful) {
        widget.onPaymentSuccess(response);
      } else {
        widget.onPaymentFailure(response.responseMessage);
      }
    } catch (e) {
      widget.onPaymentFailure('Failed to process payment response: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: const Color(0xFF00a651),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitConfirmation();
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00a651)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading secure payment page...',
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

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to cancel this payment? Your transaction will not be completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onPaymentCancelled?.call();
              Navigator.pop(context); // Close WebView
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
  }
}