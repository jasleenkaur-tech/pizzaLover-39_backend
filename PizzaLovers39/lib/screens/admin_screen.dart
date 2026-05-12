// lib/screens/admin_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/order_provider.dart';
import '../models/auth_provider.dart';
import '../models/menu_item.dart';
import '../models/admin_provider.dart';
import '../services/api_menu_service.dart';
import '../utils/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  final int initialIndex;
  const AdminDashboard({super.key, this.initialIndex = 0});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Timer? _refreshTimer;
  
  @override
  void initState() { 
    super.initState(); 
    _tab = TabController(length: 5, vsync: this, initialIndex: widget.initialIndex); 
    _refreshData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.read<OrderProvider>().adminFetchAllOrders(auth.token ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('👨‍🍳 Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing admin data...'), duration: Duration(seconds: 1)));
              _refreshData();
            }
          )
        ],
        bottom: TabBar(controller: _tab, isScrollable: true, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: AppTheme.accent,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Stats'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Orders'),
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
              Tab(icon: Icon(Icons.local_offer), text: 'Coupons'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ]),
      ),
      body: TabBarView(controller: _tab, children: [
        const _OverviewTab(),
        const _OrdersTab(),
        const _MenuManagementTab(),
        const _CouponsTab(),
        const _RestaurantSettingsTab(),
      ]),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(builder: (ctx, op, _) {
      final stats = op.adminStats ?? {};
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Business Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
          children: [
            _StatCard('Revenue', '₹${stats['totalRevenue'] ?? 0}', Icons.payments, Colors.green),
            _StatCard('Orders', '${stats['totalOrders'] ?? 0}', Icons.shopping_bag, Colors.blue),
            _StatCard('Pending', '${op.pendingCount}', Icons.timer, Colors.orange),
            _StatCard('Users', '${stats['totalUsers'] ?? 0}', Icons.people, Colors.purple),
          ]),
      ]);
    });
  }
}

class _MenuManagementTab extends StatefulWidget {
  const _MenuManagementTab();
  @override
  State<_MenuManagementTab> createState() => _MenuManagementTabState();
}

class _MenuManagementTabState extends State<_MenuManagementTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuItem>>(
      future: ApiMenuService().fetchAllItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No items found"));
        final items = snapshot.data!;
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showItemDialog(context),
          ),
          body: ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (ctx, i) {
              final item = items[i];
              return Card(
                child: ListTile(
                  leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${item.getPrice()} • ${item.category.toString().split('.').last}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showItemDialog(context, item: item)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(item.id)),
                  ]),
                ),
              );
            },
          ),
        );
      }
    );
  }

  void _showItemDialog(BuildContext ctx, {MenuItem? item}) {
    final nameCtrl = TextEditingController(text: item?.name ?? "");
    final priceCtrl = TextEditingController(text: item?.prices?['regular']?.toString() ?? item?.price?.toString() ?? "");
    final descCtrl = TextEditingController(text: item?.description ?? "");
    final emojiCtrl = TextEditingController(text: item?.emoji ?? "🍕");
    MenuCategory selectedCat = item?.category ?? MenuCategory.vegPizza;

    showDialog(context: ctx, builder: (dCtx) => StatefulBuilder(builder: (sCtx, ss) => AlertDialog(
      title: Text(item == null ? 'Add New Item' : 'Edit Item'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
        TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji')),
        DropdownButton<MenuCategory>(
          value: selectedCat, isExpanded: true,
          items: MenuCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.toString().split('.').last))).toList(),
          onChanged: (v) { if (v != null) ss(() => selectedCat = v); }
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
          final auth = context.read<AuthProvider>();
          final data = {
            'name': nameCtrl.text,
            'description': descCtrl.text,
            'prices': {'regular': double.parse(priceCtrl.text)},
            'category': selectedCat.toString().split('.').last,
            'emoji': emojiCtrl.text,
          };
          try {
            if (item == null) await ApiMenuService().addItem(auth.token!, data);
            else await ApiMenuService().updateItem(auth.token!, item.id, data);
            if (mounted) { Navigator.pop(dCtx); setState(() {}); }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }, child: Text(item == null ? 'Add' : 'Update'))
      ],
    )));
  }

  void _confirmDelete(String id) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Item?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final auth = context.read<AuthProvider>();
          try {
            await ApiMenuService().deleteItem(auth.token!, id);
            if (mounted) { Navigator.pop(context); setState(() {}); }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
      ],
    ));
  }
}

class _CouponsTab extends StatelessWidget {
  const _CouponsTab();
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _addCoupon(context),
      ),
      body: admin.coupons.isEmpty 
        ? const Center(child: Text("No coupons active"))
        : ListView.builder(itemCount: admin.coupons.length, padding: const EdgeInsets.all(12), itemBuilder: (ctx, i) {
            final c = admin.coupons[i];
            return Card(child: ListTile(
              leading: const Icon(Icons.local_offer, color: Colors.orange),
              title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${c.discount}${c.isPercentage ? "%" : "₹"} OFF • Exp: ${c.expiry.day}/${c.expiry.month}'),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => admin.deleteCoupon(c.code)),
            ));
          }),
    );
  }
  void _addCoupon(BuildContext ctx) {
    final codeCtrl = TextEditingController();
    final discCtrl = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Create Coupon'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code')),
        TextField(controller: discCtrl, decoration: const InputDecoration(labelText: 'Discount'), keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          if (codeCtrl.text.isEmpty || discCtrl.text.isEmpty) return;
          ctx.read<AdminProvider>().addCoupon(Coupon(code: codeCtrl.text.toUpperCase(), discount: double.parse(discCtrl.text), isPercentage: true, expiry: DateTime.now().add(const Duration(days: 30))));
          Navigator.pop(ctx);
        }, child: const Text('Save'))
      ],
    ));
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(builder: (ctx, op, _) {
      if (op.isLoading) return const Center(child: CircularProgressIndicator());
      if (op.orders.isEmpty) return const Center(child: Text("No orders found"));
      return ListView.builder(itemCount: op.orders.length, padding: const EdgeInsets.all(12), itemBuilder: (ctx, i) {
        final o = op.orders[i];
        return Card(child: ListTile(
          title: Text('Order #${o.shortId}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Status: ${o.status.label} • ₹${o.total}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showStatusPicker(ctx, o),
        ));
      });
    });
  }

  void _showStatusPicker(BuildContext ctx, Order o) {
    showModalBottomSheet(context: ctx, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ...OrderStatus.values.map((s) => ListTile(title: Text(s.label), leading: Text(s.emoji), onTap: () {
        final auth = ctx.read<AuthProvider>();
        ctx.read<OrderProvider>().updateStatus(auth.token!, o.id, s);
        Navigator.pop(ctx);
      })),
    ]));
  }
}

class _RestaurantSettingsTab extends StatelessWidget {
  const _RestaurantSettingsTab();
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final nameCtrl = TextEditingController(text: admin.restaurantName);
    final descCtrl = TextEditingController(text: admin.description);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Restaurant Identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: () {
        admin.updateRestaurantDetails(name: nameCtrl.text, desc: descCtrl.text);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurant updated!")));
      }, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)), child: const Text('SAVE SETTINGS')),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String l, v; final IconData i; final Color c;
  const _StatCard(this.l, this.v, this.i, this.c);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 20), const Spacer(), Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c)), Text(l, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11))]));
}
