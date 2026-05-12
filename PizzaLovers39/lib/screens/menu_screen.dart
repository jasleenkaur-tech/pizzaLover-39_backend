// lib/screens/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_provider.dart';
import '../models/menu_item.dart';
import '../services/api_menu_service.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final MenuCategory initialCategory;
  const MenuScreen({super.key, this.initialCategory = MenuCategory.vegPizza});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late MenuCategory _selectedCat;
  late Future<Map<MenuCategory, List<MenuItem>>> _menuFuture;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Veg Pizza',  'emoji': '🍕', 'cat': MenuCategory.vegPizza},
    {'label': 'Special',    'emoji': '👑', 'cat': MenuCategory.special},
    {'label': 'Burgers',    'emoji': '🍔', 'cat': MenuCategory.burger},
    {'label': 'Pasta',      'emoji': '🍝', 'cat': MenuCategory.pasta},
    {'label': 'Shakes',     'emoji': '🧋', 'cat': MenuCategory.shakes},
    {'label': 'Wraps',      'emoji': '🌯', 'cat': MenuCategory.wraps},
    {'label': 'Fries',      'emoji': '🍟', 'cat': MenuCategory.fries},
    {'label': 'Sandwich',   'emoji': '🥪', 'cat': MenuCategory.sandwich},
    {'label': 'Tacos',      'emoji': '🌮', 'cat': MenuCategory.tacos},
    {'label': 'Meals',      'emoji': '🎁', 'cat': MenuCategory.meals},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.initialCategory;
    _menuFuture = ApiMenuService().fetchMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          Consumer<CartProvider>(builder: (_, cart, __) => cart.itemCount == 0 
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))))
        ],
      ),
      body: FutureBuilder<Map<MenuCategory, List<MenuItem>>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading menu. Is the backend running?'));
          }
          
          final menuData = snapshot.data!;
          final items = menuData[_selectedCat] ?? [];

          return Column(
            children: [
              _categoryGrid(),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty 
                  ? const Center(child: Text('No items available in this category'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => MenuItemCard(item: items[i]),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryGrid() {
    return Container(
      height: 105,
      color: AppTheme.surface.withOpacity(0.5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final catItem = _categories[i];
          final cat = catItem['cat'] as MenuCategory;
          final isSelected = _selectedCat == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = cat),
            child: Container(
              width: 76,
              margin: const EdgeInsets.only(right: 10),
              child: Column(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.2),
                      width: 1.5
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                  ),
                  child: Center(child: Text(catItem['emoji'] as String, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(height: 6),
                Text(catItem['label'] as String, textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, 
                      color: isSelected ? AppTheme.primary : AppTheme.textDark
                    )),
              ]),
            ),
          );
        },
      ),
    );
  }
}
