import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/bills.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';
import 'package:async/async.dart'; // Import for StreamZip

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Future<void> _signOutAndNavigate() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeView()),
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
                _SidebarButton(
                  icon: Icons.restaurant_menu,
                  label: 'Menu',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PosViewDesktop()),
                    );
                  },
                ),
                _SidebarButton(icon: Icons.list_alt, label: 'Order List', onTap: () {
                  // Assuming you have an OrdersList or similar view
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersListView()));
                  // For now, no navigation is added if you don't have this view
                }),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _SidebarButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () {
                      // Already on History Page, could refresh or do nothing
                      // Or navigate to itself to clear routes if needed, but not common.
                    },
                  ),
                ),
                _SidebarButton(
                  icon: Icons.receipt_long,
                  label: 'Bills',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BillPage()),
                    );
                  },
                ),
                _SidebarButton(
                    icon: Icons.calendar_month,
                    label: 'Calendar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CalendarPage()),
                      );
                    }),
                const Divider(color: Colors.white54, height: 32),
                _SidebarButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsView()),
                    );
                  },
                ),
                _SidebarButton(icon: Icons.help_center, label: 'Help Center', onTap: () {
                  // Implement help center navigation or dialog
                }),
                const Spacer(),
                const _LogoutSidebarButton(),
              ],
            ),
          ),

          // Main Content Area (Two Columns)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Activity Logs',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align tops of columns
                      children: [
                        // Left Column: Customer Transaction Logs (Scrollable Card)
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Customer Transactions',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: SingleChildScrollView( // Make content of this card scrollable
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
                                          return StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .collection('log') // Sales logs
                                                .orderBy('timestamp', descending: true)
                                                .snapshots(),
                                            builder: (context, salesSnapshot) {
                                              if (salesSnapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: CircularProgressIndicator());
                                              }
                                              if (!salesSnapshot.hasData || salesSnapshot.data!.docs.isEmpty) {
                                                return const Center(child: Text('No customer transactions found.'));
                                              }

                                              final salesLogs = salesSnapshot.data!.docs;

                                              return ListView.builder(
                                                physics: const NeverScrollableScrollPhysics(), // Handled by SingleChildScrollView
                                                shrinkWrap: true, // Take only as much space as needed
                                                itemCount: salesLogs.length,
                                                itemBuilder: (context, index) {
                                                  final log = salesLogs[index];
                                                  final logData = log.data() as Map<String, dynamic>;

                                                  // Only display 'Sale' type logs here (or logs without a 'type' field which are assumed sales)
                                                  final logType = logData['type'] ?? 'Sale';
                                                  if (logType != 'Sale') {
                                                    return const SizedBox.shrink(); // Hide non-sale logs
                                                  }

                                                  final customerName = logData['customerName'] ?? 'N/A';
                                                  final List<Map<String, dynamic>> items = 
                                                      (logData['items'] as List<dynamic>?)
                                                          ?.map((item) => Map<String, dynamic>.from(item))
                                                          .toList() ?? [];
                                                  final String message = logData['message'] ?? 'N/A';
                                                  final String payment = logData['payment'] ?? 'N/A';
                                                  final Timestamp? timestamp = logData['timestamp'] as Timestamp?;
                                                  final double originalTotal = (logData['originalTotal'] as num?)?.toDouble() ?? 0.0;
                                                  final double finalTotal = (logData['finalTotal'] as num?)?.toDouble() ?? 0.0;
                                                  final List<Map<String, dynamic>> appliedDiscounts = 
                                                      (logData['appliedDiscounts'] as List<dynamic>?)
                                                          ?.map((discount) => Map<String, dynamic>.from(discount))
                                                          .toList() ?? [];
                                                  final double totalDiscountAmount = (logData['totalDiscountAmount'] as num?)?.toDouble() ?? 0.0;
                                                  
                                                  return Card(
                                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Adjust margin for inner cards
                                                    elevation: 1,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                customerName.isNotEmpty ? 'Customer: $customerName' : 'Walk-in Customer',
                                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                                                              ),
                                                              Text(
                                                                timestamp != null
                                                                    ? '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}-${timestamp.toDate().day.toString().padLeft(2, '0')} ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                                                    : 'N/A',
                                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                              ),
                                                            ],
                                                          ),
                                                          const Divider(height: 15, thickness: 0.5),

                                                          if (items.isNotEmpty) ...[
                                                            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                            const SizedBox(height: 2),
                                                            ...items.map((item) {
                                                              final int itemQuantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                                                              return Padding(
                                                                padding: const EdgeInsets.only(left: 6.0, top: 1.0),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Text('${item['name']} ${itemQuantity > 1 ? 'x$itemQuantity' : ''}', style: const TextStyle(fontSize: 13)),
                                                                    Text('\$${(item['itemTotal'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 13)),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                            const SizedBox(height: 6),
                                                          ],
                                                          
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                                                              Text('\$${originalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                                                            ],
                                                          ),
                                                          
                                                          if (appliedDiscounts.isNotEmpty) ...[
                                                            const SizedBox(height: 4),
                                                            ...appliedDiscounts.map((discount) {
                                                              final discType = discount['type'] ?? 'Discount';
                                                              final discPercentage = (discount['percentage'] as num?)?.toDouble() ?? 0.0;
                                                              final discAmount = originalTotal * (discPercentage / 100);
                                                              return Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text('$discType (${discPercentage.toStringAsFixed(0)}%):',
                                                                      style: const TextStyle(fontSize: 14, color: Colors.green)),
                                                                  Text(
                                                                      '-\$${discAmount.toStringAsFixed(2)}',
                                                                      style: const TextStyle(fontSize: 14, color: Colors.green)),
                                                                ],
                                                              );
                                                            }).toList(),
                                                            const SizedBox(height: 4),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                const Text('Total Discount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                                                Text(
                                                                    '-\$${totalDiscountAmount.toStringAsFixed(2)}',
                                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                                              ],
                                                            ),
                                                          ],

                                                          const SizedBox(height: 8),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text('Final Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                              Text('\$${finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                          
                                                          if (payment.isNotEmpty) ...[
                                                            const SizedBox(height: 8),
                                                            Text('Payment Method: $payment', style: const TextStyle(fontSize: 13)),
                                                          ],
                                                          if (message.isNotEmpty && message != 'N/A') ...[
                                                            const SizedBox(height: 8),
                                                            Text('Message: $message', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24), // Spacing between columns
                        // Right Column: User Activity Logs (Scrollable Card)
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'User Activity',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: SingleChildScrollView( // Make content of this card scrollable
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
                                          if (user == null) {
                                            return Stream.empty();
                                          }
                                          return FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .collection('activity') // User activity logs (login/logout)
                                              .orderBy('timestamp', descending: true)
                                              .snapshots();
                                        }),
                                        builder: (context, activitySnapshot) {
                                          if (activitySnapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          if (!activitySnapshot.hasData || activitySnapshot.data!.docs.isEmpty) {
                                            return const Center(child: Text('No user activity found.'));
                                          }

                                          final activityLogs = activitySnapshot.data!.docs;

                                          return ListView.builder(
                                            physics: const NeverScrollableScrollPhysics(), // Handled by SingleChildScrollView
                                            shrinkWrap: true, // Take only as much space as needed
                                            itemCount: activityLogs.length,
                                            itemBuilder: (context, index) {
                                              final doc = activityLogs[index];
                                              final logData = doc.data() as Map<String, dynamic>;

                                              final String message = logData['message'] ?? 'N/A';
                                              final Timestamp? timestamp = logData['timestamp'] as Timestamp?;
                                              final String logType = logData['type'] ?? 'Unknown Activity';
                                              final IconData icon = logType == 'Login' ? Icons.login : Icons.logout;
                                              final Color color = logType == 'Login' ? Colors.blue[700]! : Colors.red[700]!;


                                              return Card(
                                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Adjust margin for inner cards
                                                elevation: 1,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                color: logType == 'Login' ? Colors.blue[50] : Colors.red[50],
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Icon(icon, color: color, size: 20),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          message,
                                                          style: TextStyle(fontSize: 15, color: color),
                                                        ),
                                                      ),
                                                      Text(
                                                        timestamp != null
                                                            ? '${timestamp.toDate().year}-${timestamp.toDate().month.toString().padLeft(2, '0')}-${timestamp.toDate().day.toString().padLeft(2, '0')} ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                                            : 'N/A',
                                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

// _LogoutSidebarButton widget
class _LogoutSidebarButton extends StatelessWidget {
  const _LogoutSidebarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        onTap: () async {
          final user = FirebaseAuth.instance.currentUser;
          final userId = user?.uid;

          if (userId != null) {
            try {
              // Log the logout event to the 'activity' collection as requested
              await FirebaseFirestore.instance.collection('users').doc(userId).collection('activity').add({
                'type': 'Logout', // Explicitly set type for easy filtering in HistoryPage
                'message': 'User logged out',
                'timestamp': FieldValue.serverTimestamp(),
              });
              print('DEBUG: Logout event logged to "activity" collection for user $userId');
            } catch (e) {
              print('ERROR: Failed to log logout event for user $userId: $e');
              // Continue with sign out even if logging fails
            }
          }

          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
        },
      ),
    );
  }
}