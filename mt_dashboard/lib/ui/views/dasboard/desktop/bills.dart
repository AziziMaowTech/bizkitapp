import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/history.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.desktop.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  Future<void> _signOutAndNavigate() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: Colors.blueGrey[900],
            child: Column(
              children: [
          const SizedBox(height: 40),
          const Text(
            'Bizkit POS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _SidebarButton(icon: Icons.restaurant_menu,label: 'Menu',onTap: () { Navigator.push( context, MaterialPageRoute(builder: (context) => const PosViewDesktop()),);},),
                _SidebarButton(icon: Icons.list_alt, label: 'Order List', onTap: () {}),
                _SidebarButton(icon: Icons.history, label: 'History', onTap: () { Navigator.push( context, MaterialPageRoute(builder: (context) => const HistoryPage()),);}),
                Container( decoration: BoxDecoration(color: Colors.blueGrey[700],borderRadius: BorderRadius.circular(8),),child: _SidebarButton(icon: Icons.receipt_long, label: 'Bills', onTap: () { Navigator.push( context, MaterialPageRoute(builder: (context) => const BillPage()),);}),),
          const Divider(color: Colors.white54, height: 32),
          _SidebarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardView()),
              );
            },
          ),
          _SidebarButton(icon: Icons.help_center, label: 'Help Center', onTap: () {}),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              onTap: _signOutAndNavigate,
            ),
          ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.white,
              child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Logs',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final user = snapshot.data;
              if (user == null) {
                return const Center(child: Text('No user logged in.'));
              }
              return StreamBuilder(
                stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('log')
              .orderBy('timestamp', descending: true)
              .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> logSnapshot) {
                  if (logSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
                  }
                  if (!logSnapshot.hasData || logSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No logs found.'));
                  }
                  final logs = logSnapshot.data!.docs;
                  return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final customerName = log['customerName'] ?? '';
                final items = List<Map<String, dynamic>>.from(log['items'] ?? []);
                final message = log['message'] ?? '';
                final payment = log['payment'] ?? '';
                final timestamp = log['timestamp']?.toDate();
                final total = log['total'] ?? 0;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                  customerName.isNotEmpty ? 'Customer: $customerName' : 'User Activity',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                  timestamp != null
                      ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
                      : '',
                  style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                    child: Text('${item['name']} - \$${item['price']}'),
                  )),
                  ],
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Message: $message'),
                  ],
                  if (payment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Payment: $payment'),
                  ],
                  if (total != 0) ...[
                    const SizedBox(height: 8),
                    Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ],
                    ),
                  ),
                );
              },
                  );
                },
              );
            },
                ),
              ),
            ],
          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SidebarButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}
