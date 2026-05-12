// lib/services/api_menu_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import 'api_config.dart';

class ApiMenuService {
  static final ApiMenuService _instance = ApiMenuService._internal();
  factory ApiMenuService() => _instance;
  ApiMenuService._internal();

  Map<MenuCategory, List<MenuItem>>? _cachedMenu;

  Future<Map<MenuCategory, List<MenuItem>>> fetchMenu({bool forceRefresh = false}) async {
    if (_cachedMenu != null && !forceRefresh) return _cachedMenu!;
    try {
      final url = Uri.parse('${ApiConfig.menu}?limit=150');
      final response = await http.get(url, headers: ApiConfig.headers());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final Map<String, dynamic> menuData = data['menu'];
          Map<MenuCategory, List<MenuItem>> groupedMenu = {};
          
          menuData.forEach((categoryKey, itemsList) {
            // Case-insensitive matching for categories to avoid "Error loading meals"
            MenuCategory category = MenuCategory.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == categoryKey.toLowerCase(),
              orElse: () => MenuCategory.vegPizza,
            );
            groupedMenu[category] = (itemsList as List).map((item) => MenuItem.fromJson(item)).toList();
          });
          
          _cachedMenu = groupedMenu;
          return groupedMenu;
        }
      }
      throw Exception('Failed to load menu: ${response.statusCode}');
    } catch (e) {
      print("Fetch Menu Error: $e");
      rethrow;
    }
  }

  Future<List<MenuItem>> fetchAllItems() async {
    final menu = await fetchMenu();
    return menu.values.expand((x) => x).toList();
  }

  // --- ADMIN METHODS ---

  Future<MenuItem> addItem(String token, Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse(ApiConfig.menu),
      headers: ApiConfig.headers(token),
      body: jsonEncode(itemData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {
      _cachedMenu = null; // Invalidate cache
      return MenuItem.fromJson(data['item']);
    }
    throw Exception(data['message'] ?? 'Failed to add item');
  }

  Future<MenuItem> updateItem(String token, String id, Map<String, dynamic> itemData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.menu}/$id'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(itemData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      _cachedMenu = null;
      return MenuItem.fromJson(data['item']);
    }
    throw Exception(data['message'] ?? 'Failed to update item');
  }

  Future<void> deleteItem(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.menu}/$id'),
      headers: ApiConfig.headers(token),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete item');
    }
    _cachedMenu = null;
  }
}
