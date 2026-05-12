// lib/models/admin_provider.dart

import 'package:flutter/foundation.dart';

class Coupon {
  final String code;
  final double discount;
  final bool isPercentage;
  final DateTime expiry;

  Coupon({required this.code, required this.discount, required this.isPercentage, required this.expiry});
}

class AdminProvider extends ChangeNotifier {
  // Restaurant Details
  String _restaurantName = "Pizza Lovers 39";
  String _description = "Authentic Hand-Crafted Pizzas & More";
  String _openingTime = "11:00 AM";
  String _closingTime = "11:00 PM";
  String _imageUrl = "";

  String get restaurantName => _restaurantName;
  String get description => _description;
  String get openingTime => _openingTime;
  String get closingTime => _closingTime;
  String get imageUrl => _imageUrl;

  // Coupons
  final List<Coupon> _coupons = [
    Coupon(code: "PIZZA39", discount: 10, isPercentage: true, expiry: DateTime.now().add(const Duration(days: 30))),
  ];
  List<Coupon> get coupons => _coupons;

  void updateRestaurantDetails({String? name, String? desc, String? open, String? close, String? image}) {
    if (name != null) _restaurantName = name;
    if (desc != null) _description = desc;
    if (open != null) _openingTime = open;
    if (close != null) _closingTime = close;
    if (image != null) _imageUrl = image;
    notifyListeners();
    // In a real app, you would call an API here: PATCH /api/admin/restaurant
  }

  void addCoupon(Coupon coupon) {
    _coupons.add(coupon);
    notifyListeners();
  }

  void deleteCoupon(String code) {
    _coupons.removeWhere((c) => c.code == code);
    notifyListeners();
  }
}
