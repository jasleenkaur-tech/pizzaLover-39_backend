// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/auth_provider.dart';
import '../models/order_provider.dart';
import '../models/order_model.dart';
import '../utils/app_theme.dart';
import '../utils/location_service.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notif = true;
  bool _orderUpd = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<OrderProvider>().fetchOrders(auth.token!);
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch activity')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error occurred while launching')));
    }
  }

  Future<void> _detectLocation() async {
    final auth = context.read<AuthProvider>();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Detecting location..."), duration: Duration(seconds: 1)));
    try {
      final addr = await LocationService.getCurrentAddress();
      if (addr != null && mounted) {
        context.read<AuthProvider>().setAddress(addr);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260, pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(
                  colors: [Color(0xFF8B0000), AppTheme.primary, Color(0xFFCC4400)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  Row(children: [
                    GestureDetector(
                      onTap: () => auth.isLoggedIn ? _editProfile(context, auth) : _goLogin(context),
                      child: Stack(children: [
                        Container(width: 80, height: 80,
                            decoration: BoxDecoration(color: Colors.white.withAlpha(51), shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 2.5)),
                            child: Center(child: Text(auth.isLoggedIn && auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : (auth.isLoggedIn ? 'U' : '👤'), style: TextStyle(fontSize: auth.isLoggedIn ? 34 : 38, color: Colors.white, fontWeight: FontWeight.w900)))),
                        Positioned(right: 0, bottom: 0, child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(auth.isLoggedIn ? Icons.edit : Icons.login, size: 16, color: AppTheme.primary))),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(auth.isLoggedIn ? auth.displayName : 'Guest User', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (auth.isLoggedIn) ...[
                        Text(auth.displayEmail, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(auth.displayPhone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                      const SizedBox(height: 10),
                      if (auth.isAdmin) _adminBadge()
                    ])),
                  ]),
                ]),
              )),
            ),
          ),
        ),

        SliverList(delegate: SliverChildListDelegate([
          const SizedBox(height: 12),
          
          if (auth.isAdmin) ...[
            _label('ADMIN MANAGEMENT'),
            _tile(icon: Icons.receipt_long_outlined, bg: Colors.deepPurple, title: 'Orders Management', sub: 'Track, Update & View All Orders', 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard(initialIndex: 1)))),
          ],

          _label('MY ACCOUNT'),
          if (!auth.isLoggedIn)
            _tile(icon: Icons.login_rounded, bg: AppTheme.primary, title: 'Login / Sign Up', sub: 'Access orders, addresses & more', onTap: () => _goLogin(context))
          else ...[
            _tile(icon: Icons.shopping_bag_outlined, bg: Colors.orange, title: 'My Orders', sub: 'View real-time order status', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _OrdersHistory()))),
            _tile(icon: Icons.location_on_outlined, bg: Colors.teal, title: 'Current Address', sub: (auth.currentAddress != null && !auth.currentAddress!.toLowerCase().contains("denied")) ? auth.currentAddress! : 'Tap to detect location', onTap: _detectLocation, trailing: const Icon(Icons.my_location, color: Colors.teal)),
          ],

          _label('SHOP INFORMATION'),
          _shopInfoCard(),

          _label('SETTINGS & SUPPORT'),
          Container(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(children: [
            Expanded(child: _supportBtn('📞', 'Call', Colors.green, () => _launchUrl('tel:9878394950'))),
            const SizedBox(width: 8),
            Expanded(child: _supportBtn('💬', 'Chat', Colors.blue, () => _launchUrl('https://wa.me/919878394950'))),
            const SizedBox(width: 8),
            Expanded(child: _supportBtn('📍', 'Map', Colors.red, () => _launchUrl('https://www.google.com/maps/search/?api=1&query=Pizza+Lovers+39'))),
          ])),

          _sw('Push Notifications', _notif, (v) => setState(() => _notif = v)),
          _sw('Order Updates', _orderUpd, (v) => setState(() => _orderUpd = v)),

          if (auth.isLoggedIn) ...[
            const SizedBox(height: 12),
            _tile(icon: Icons.logout_rounded, bg: Colors.red, title: 'Logout', sub: 'Sign out of your account', onTap: () => auth.logout()),
          ],
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }

  Widget _adminBadge() => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('👑', style: TextStyle(fontSize: 12)), SizedBox(width: 4), Text('ADMIN', style: TextStyle(color: AppTheme.dark, fontSize: 11, fontWeight: FontWeight.w900))]));

  Widget _shopInfoCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pizza Lovers 39', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
      const SizedBox(height: 8),
      const Row(children: [
        Icon(Icons.location_on, size: 16, color: AppTheme.textGrey),
        SizedBox(width: 8),
        Expanded(child: Text('Manakpur, Rajpura, Punjab, India', style: TextStyle(fontSize: 14, color: AppTheme.textDark))),
      ]),
      const SizedBox(height: 6),
      const Row(children: [
        Icon(Icons.access_time, size: 16, color: AppTheme.textGrey),
        SizedBox(width: 8),
        Text('Open: 11:00 AM - 11:00 PM', style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 8),
        const Text('4.8 Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Open Now', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    ]),
  );

  void _goLogin(BuildContext ctx) => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen()));
  Widget _label(String t) => Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 6), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textGrey, letterSpacing: 1.3)));
  
  Widget _tile({required IconData icon, required Color bg, required String title, required String sub, required VoidCallback onTap, Widget? trailing}) => GestureDetector(
    onTap: onTap, 
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), 
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))]), 
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: bg.withAlpha(30), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: bg, size: 21)), 
        const SizedBox(width: 12), 
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)), Text(sub, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)])), 
        trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20)
      ])
    )
  );

  Widget _supportBtn(String e, String l, Color c, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(e, style: const TextStyle(fontSize: 20)), Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c))])));
  
  Widget _sw(String t, bool v, ValueChanged<bool> f) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), 
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), 
    child: ListTile(
      title: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), 
      trailing: Switch(value: v, onChanged: f, activeTrackColor: AppTheme.primary.withAlpha(100), activeThumbColor: AppTheme.primary)
    )
  );

  void _editProfile(BuildContext ctx, AuthProvider auth) {
    final nc = TextEditingController(text: auth.displayName);
    final pc = TextEditingController(text: auth.displayPhone);
    final ec = TextEditingController(text: auth.displayEmail);
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 18),
      TextField(controller: nc, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 12),
      TextField(controller: ec, decoration: InputDecoration(labelText: 'Gmail ID', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 12),
      TextField(controller: pc, decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { auth.updateProfile(name: nc.text, phone: pc.text, email: ec.text); Navigator.pop(ctx); }, child: const Text('Save Changes')))
    ])));
  }
}

class _OrdersHistory extends StatelessWidget {
  const _OrdersHistory();
  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(builder: (context, op, _) {
      if (op.isLoading && op.orders.isEmpty) return Scaffold(appBar: AppBar(title: const Text('My Orders')), body: const Center(child: CircularProgressIndicator()));
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () {
          final auth = context.read<AuthProvider>();
          op.fetchOrders(auth.token!);
        })]),
        body: op.orders.isEmpty 
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(padding: const EdgeInsets.all(12), itemCount: op.orders.length, itemBuilder: (ctx, i) {
              final o = op.orders[i];
              return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                title: Text('Order #${o.shortId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${o.items.length} items • ${o.status.emoji} ${o.status.label}'),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${o.total}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Text(o.status.isActive ? 'Real-time' : '', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ]),
              ));
            }),
      );
    });
  }
}
