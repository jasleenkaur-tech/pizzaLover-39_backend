import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/cart_provider.dart';
import '../models/menu_item.dart';
import '../models/order_provider.dart';
import '../models/order_model.dart';
import '../models/ui_provider.dart';
import '../models/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import '../services/api_config.dart';
import '../utils/location_service.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final List<CartItem> cartItems;
  const PaymentScreen({super.key, required this.total, required this.cartItems});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0; // 0 = Razorpay, 1 = COD
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _loading = false;
  Order? _currentOrder; 

  late PaymentService _razorpayService;

  static const _methods = [
    (Icons.qr_code, "razorpay", "Online Payment", "UPI, Card, NetBanking"),
    (Icons.money, "cashOnDelivery", "Cash on Delivery", "Pay when delivered"),
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.displayName;
    _phoneCtrl.text = auth.displayPhone;
    if (auth.currentAddress != null && !auth.currentAddress!.toLowerCase().contains("denied")) {
      _addrCtrl.text = auth.currentAddress!;
    }

    _razorpayService = PaymentService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
    );
    _razorpayService.init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_currentOrder != null) {
      _verifyPaymentOnBackend(response);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Cancelled: ${response.message}"), backgroundColor: Colors.orange),
    );
  }

  Future<void> _detectLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Detecting location..."), duration: Duration(seconds: 1)));
    try {
      final addr = await LocationService.getCurrentAddress();
      if (addr != null) {
        setState(() {
          _addrCtrl.text = addr;
        });
        if (mounted) {
          context.read<AuthProvider>().setAddress(addr);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location detected!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _pay() async {
    if (_addrCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter delivery address")));
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
       _handleUnauthorized();
       return;
    }

    setState(() => _loading = true);

    final orderProvider = context.read<OrderProvider>();
    final int selectedIndex = _method.clamp(0, _methods.length - 1);
    final String paymentKey = _methods[selectedIndex].$2;

    final order = await orderProvider.placeOrder(
      token: auth.token ?? '',
      cartItems: widget.cartItems,
      paymentMethod: paymentKey,
      name: _nameCtrl.text.trim().isEmpty ? 'Customer' : _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
    );

    if (!mounted) return;

    if (order == null) {
      setState(() => _loading = false);
      if (orderProvider.error?.contains("401") ?? false) {
        _handleUnauthorized();
      } else {
        _showErrorDialog("Order Failed", orderProvider.error ?? "Failed to save order to database.");
      }
      return;
    }

    _currentOrder = order;

    if (paymentKey == 'razorpay') {
      _startRazorpayPayment(order.id);
    } else {
      _onOrderComplete();
    }
  }

  Future<void> _startRazorpayPayment(String dbOrderId) async {
    try {
      final auth = context.read<AuthProvider>();
      final url = Uri.parse("${ApiConfig.baseUrl}/payments/create-order");
      final response = await http.post(
        url,
        headers: ApiConfig.headers(auth.token),
        body: jsonEncode({"orderId": dbOrderId}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String? rzpId = data['orderId'] ?? data['razorpayOrderId'] ?? data['id'];
        if (rzpId != null) {
          _razorpayService.openCheckout(
            apiKey: data['key'] ?? 'rzp_test_SldPrBPmCC7KeR', 
            amount: (data['amount'] as num).toInt(),
            orderId: rzpId,
            name: 'Pizza Lovers 39',
            description: 'Order Payment',
            contact: _phoneCtrl.text,
            email: auth.displayEmail,
            currency: data['currency'] ?? 'INR',
          );
        } else {
          throw Exception("Razorpay Order ID missing.");
        }
      } else {
        throw Exception("Server Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog("Razorpay Failed", e.toString());
    }
  }

  Future<void> _verifyPaymentOnBackend(PaymentSuccessResponse response) async {
    try {
      final auth = context.read<AuthProvider>();
      final url = Uri.parse("${ApiConfig.baseUrl}/payments/verify");
      final res = await http.post(
        url,
        headers: ApiConfig.headers(auth.token),
        body: jsonEncode({
          "razorpay_order_id": response.orderId,
          "razorpay_payment_id": response.paymentId,
          "razorpay_signature": response.signature,
          "orderId": _currentOrder!.id,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        _onOrderComplete();
      } else {
        throw Exception("Verification failed");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog("Verification Error", e.toString());
    }
  }

  void _onOrderComplete() {
    context.read<CartProvider>().clearCart();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PaymentSuccessScreen(order: _currentOrder!)),
    );
  }

  void _handleUnauthorized() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session expired. Login again.")));
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int safeIndex = _method.clamp(0, _methods.length - 1);
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AmountCard(total: widget.total, count: widget.cartItems.length),
            const SizedBox(height: 20),
            const Text("Delivery Details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _tf(_nameCtrl, "Your Name", Icons.person_outline, TextInputType.name),
            const SizedBox(height: 10),
            _tf(_phoneCtrl, "Phone Number", Icons.phone_outlined, TextInputType.phone),
            const SizedBox(height: 10),
            _tf(
              _addrCtrl, "Delivery Address", Icons.location_on_outlined, TextInputType.streetAddress, lines: 2,
              suffixIcon: IconButton(icon: const Icon(Icons.my_location, color: AppTheme.primary), onPressed: _detectLocation, tooltip: "Detect current location")
            ),
            const SizedBox(height: 20),
            const Text("Select Payment Method", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ...List.generate(_methods.length, (i) => _MethodTile(
              icon: _methods[i].$1, title: _methods[i].$3, sub: _methods[i].$4, selected: safeIndex == i,
              onTap: () => setState(() => _method = i),
            )),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _pay,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_methods[safeIndex].$2 == "razorpay" ? "Proceed to Pay" : "Place Order", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon, TextInputType type, {int lines = 1, Widget? suffixIcon}) {
    return TextFormField(
      controller: c, keyboardType: type, maxLines: lines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: suffixIcon, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double total; final int count;
  const _AmountCard({required this.total, required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFFCC4400)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Order Total", style: TextStyle(color: Colors.white70, fontSize: 13)), const SizedBox(height: 4), Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text("$count item${count > 1 ? "s" : ""} in your order", style: const TextStyle(color: Colors.white70, fontSize: 12))]),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon; final String title, sub; final bool selected; final VoidCallback onTap;
  const _MethodTile({required this.icon, required this.title, required this.sub, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: selected ? AppTheme.primary.withOpacity(0.06) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade200, width: selected ? 2 : 1)), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: selected ? AppTheme.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: selected ? Colors.white : AppTheme.textGrey, size: 22)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: selected ? AppTheme.primary : AppTheme.textDark)), Text(sub, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12))])), Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? AppTheme.primary : AppTheme.textGrey, size: 22)])));
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final Order order;
  const PaymentSuccessScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.home_outlined, color: AppTheme.textDark), onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)), title: const Text("Order Confirmed", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700))),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, color: Colors.green, size: 100), const SizedBox(height: 24), const Text("Order Placed Successfully!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text("Order ID: #${order.shortId}"), const SizedBox(height: 40), ElevatedButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text("Back to Menu"))])),
    );
  }
}
