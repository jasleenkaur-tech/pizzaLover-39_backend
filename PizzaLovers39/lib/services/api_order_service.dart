// lib/services/api_order_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/menu_item.dart';
import 'api_config.dart';

class ApiOrderService {
  final String token;

  ApiOrderService(this.token);

  Future<Order> createOrder({
    required List<CartItem> cartItems,
    required String paymentMethod,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createOrder),
        headers: ApiConfig.headers(token),
        body: jsonEncode({
          'items': cartItems.map((c) => c.toJson()).toList(),
          'paymentMethod': paymentMethod,
          'customerDetails': {
            'name': name,
            'phone': phone,
            'address': address,
          }
        }),
      );

      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return Order.fromJson(data['order']);
      }
      throw Exception(data['message'] ?? 'Failed to place order');
    } catch (e) {
      print('Create Order Error: $e');
      rethrow;
    }
  }

  Future<List<Order>> fetchMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myOrders),
        headers: ApiConfig.headers(token),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return (data['orders'] as List)
            .map((o) => Order.fromJson(o))
            .toList();
      }
      throw Exception(data['message'] ?? 'Failed to load orders');
    } catch (e) {
      print('Fetch Orders Error: $e');
      rethrow;
    }
  }
}
