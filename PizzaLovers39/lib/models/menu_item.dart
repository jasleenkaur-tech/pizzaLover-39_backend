// lib/models/menu_item.dart

enum MenuCategory {
  vegPizza,
  burger,
  pasta,
  shakes,
  wraps,
  fries,
  sandwich,
  tacos,
  snacks,
  garlic,
  meals,
  special,
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final Map<String, double>? prices;
  final double? price;
  final MenuCategory category;
  final String? subCategory;
  final bool isVeg;
  final bool isBestseller;
  final String emoji;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    this.description = '',
    this.prices,
    this.price,
    required this.category,
    this.subCategory,
    this.isVeg = true,
    this.isBestseller = false,
    this.emoji = '🍕',
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Map string category from API to Enum
    MenuCategory cat = MenuCategory.values.firstWhere(
      (e) => e.toString().split('.').last == json['category'],
      orElse: () => MenuCategory.vegPizza,
    );

    // Handle prices map (convert numeric values to double)
    Map<String, double>? pricesMap;
    if (json['prices'] != null) {
      pricesMap = (json['prices'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      prices: pricesMap,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      category: cat,
      subCategory: json['subCategory'],
      isVeg: json['isVeg'] ?? true,
      isBestseller: json['isBestseller'] ?? false,
      emoji: json['emoji'] ?? '🍕',
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  double getPrice([String size = 'regular']) {
    if (prices != null) return prices![size] ?? 0;
    return price ?? 0;
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String selectedSize;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedSize = 'regular',
  });

  double get totalPrice => menuItem.getPrice(selectedSize) * quantity;
  
  Map<String, dynamic> toJson() => {
    'menuItemId': menuItem.id,
    'size': selectedSize,
    'quantity': quantity,
  };
}
