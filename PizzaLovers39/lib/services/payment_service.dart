// lib/services/payment_service.dart

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse)? onExternalWallet;

  PaymentService({
    required this.onSuccess,
    required this.onFailure,
    this.onExternalWallet,
  });

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  void openCheckout({
    required String apiKey,
    required int amount, // in paise
    required String orderId,
    required String name,
    required String description,
    required String contact,
    required String email,
    String  currency = 'INR',
  }) {
    var options = {
      'key': apiKey,
      'amount': amount,
      'name': name,
      'currency': currency,
      'description': description,
      'order_id': orderId, // This must be the razorpay_order_id
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Error: $e");
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
