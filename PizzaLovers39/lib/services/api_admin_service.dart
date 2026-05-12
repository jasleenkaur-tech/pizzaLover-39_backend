// lib/services/api_admin_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import 'api_config.dart';

class ApiAdminService {
  final String token;
  ApiAdminService(this.token);

  // Fetch all orders for admin
  Future<List<Order>> fetchAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminOrders),
        headers: ApiConfig.headers(token),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return (data['orders'] as List)
            .map((o) => Order.fromJson(o))
            .toList();
      }
      throw Exception(data['message'] ?? 'Failed to load admin orders');
    } catch (e) {
      print('Admin Orders Error: $e');
      rethrow;
    }
  }

  // Update order status
  Future<bool> updateStatus(String orderId, OrderStatus status) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.updateStatus(orderId)),
        headers: ApiConfig.headers(token),
        body: jsonEncode({
          'status': status.toString().split('.').last,
          'note': 'Updated via Admin App'
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('Update Status Error: $e');
      return false;
    }
  }

  // Get Dashboard Stats
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminStats),
        headers: ApiConfig.headers(token),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['stats'];
      }
      throw Exception('Failed to load stats');
    } catch (e) {
      print('Stats Error: $e');
      rethrow;
    }
  }
}
