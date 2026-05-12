// lib/models/order_provider.dart

import 'package:flutter/foundation.dart';
import 'order_model.dart';
import 'menu_item.dart';
import '../services/api_order_service.dart';
import '../services/api_admin_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _adminStats;

  // Cached reversed list to avoid re-calculating on every build
  List<Order>? _cachedOrders;

  List<Order> get orders {
    _cachedOrders ??= List.unmodifiable(_orders.reversed.toList());
    return _cachedOrders!;
  }

  bool get isLoading             => _isLoading;
  String? get error              => _error;
  Map<String, dynamic>? get adminStats => _adminStats;
  
  int    get totalOrders         => _orders.length;
  int    get pendingCount        => _orders.where((o) => o.status == OrderStatus.pending).length;
  int    get deliveredCount      => _orders.where((o) => o.status == OrderStatus.delivered).length;

  double get todayRevenue {
    final t = DateTime.now();
    return _orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            o.placedAt.year  == t.year &&
            o.placedAt.month == t.month &&
            o.placedAt.day   == t.day)
        .fold(0.0, (s, o) => s + o.total);
  }

  double get totalRevenue =>
      _orders.where((o) => o.status == OrderStatus.delivered)
             .fold(0.0, (s, o) => s + o.total);

  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList().reversed.toList();

  List<Order> byStatus(OrderStatus s) =>
      _orders.where((o) => o.status == s).toList().reversed.toList();

  // Load orders for current user
  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = ApiOrderService(token);
      _orders = await service.fetchMyOrders();
      _cachedOrders = null; // Invalidate cache
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ADMIN ACTIONS ---

  Future<void> adminFetchAllOrders(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = ApiAdminService(token);
      _orders = await service.fetchAllOrders();
      _cachedOrders = null; // Invalidate cache
      _adminStats = await service.fetchStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String token, String orderId, OrderStatus newStatus) async {
    try {
      final service = ApiAdminService(token);
      final success = await service.updateStatus(orderId, newStatus);
      if (success) {
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx >= 0) {
          _orders[idx].status = newStatus;
          _cachedOrders = null; // Invalidate cache
          notifyListeners();
        }
        // Refresh stats after status change
        _adminStats = await service.fetchStats();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> cancelOrder(String token, String orderId) => updateStatus(token, orderId, OrderStatus.cancelled);

  // --- CUSTOMER ACTIONS ---

  Future<Order?> placeOrder({
    required String token,
    required List<CartItem> cartItems,
    required String paymentMethod,
    required String name,
    required String phone,
    required String address,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    
    try {
      final service = ApiOrderService(token);
      final newOrder = await service.createOrder(
        cartItems: cartItems,
        paymentMethod: paymentMethod,
        name: name,
        phone: phone,
        address: address,
      );
      _orders.add(newOrder);
      _cachedOrders = null; // Invalidate cache
      _isLoading = false;
      notifyListeners();
      return newOrder;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Order? getById(String orderId) {
    try { return _orders.firstWhere((o) => o.id == orderId); }
    catch (_) { return null; }
  }
}
