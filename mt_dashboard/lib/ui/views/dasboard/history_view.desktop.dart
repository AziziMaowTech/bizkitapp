import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_view.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:mt_dashboard/ui/widgets/custom_app_bar.dart';

void main() {
  runApp(const HistoryViewDesktop());
}

class HistoryViewDesktop extends StatelessWidget {
  const HistoryViewDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizKit Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // Applying Inter font family
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Light gray background
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none, // No border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.blue, width: 1.0), // Blue border on focus
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // A simple state for sidebar expansion, not fully interactive for this example
  bool _isSidebarExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          MouseRegion(
            onEnter: (event) {
              setState(() {
                _isSidebarExpanded = true;
              });
            },
            onExit: (event) {
              setState(() {
                _isSidebarExpanded = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isSidebarExpanded ? 240 : 70,
              child: Sidebar(
                isExpanded: _isSidebarExpanded,
              ),
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Main Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Charts Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Outpatients vs. Inpatients Trend
                            const Expanded(
                              flex: 1,
                              child: SalesCard(// Purple
                              ),
                            ),
                            const SizedBox(width: 24.0), // Spacing between cards
                            const Expanded(
                              flex: 1,
                              child: ActivityCard( // Purple
                              ),
                            ),
                            
                            // const Expanded(
                            //   flex: 1,
                            //   child: ChartCard(
                            //     title: 'Catalogue',
                            //     chartColor: Color(0xFF8B5CF6), // Purple
                            //   ),
                            // ),
                        
                            
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sidebar Widget (unchanged) ---
class Sidebar extends StatelessWidget {
  final bool isExpanded;

  const Sidebar({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 240 : 70, // Fixed width for the sidebar
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B5CF6), // Lighter purple
            Color(0xFF6F01FD), // Original purple
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24.0), // Top-right curve
          bottomRight: Radius.circular(24.0), // Bottom-right curve
        ),
      ),
      padding: EdgeInsets.zero, // Changed this line to remove padding
      child: Column(
        children: [
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Image.asset(
                'assets/images/placeholder.png',
                height: isExpanded ? 100 : 0, // Smaller when minimized
                width: isExpanded ? 100 : 0, // Smaller when minimized
              ),
            ),
          ),
          const SizedBox(height: 32.0),
          if (isExpanded) // Only show POS button when expanded
            ElevatedButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Text('POS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => PosView()));
              },
            ) else
            const SizedBox(height: 132),
          const SizedBox(height: 24.0),
          _SidebarNavItem(
              icon: Icons.home,
              label: 'Dashboard',
              isExpanded: isExpanded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DashboardView()),
                );
              }),
          _SidebarNavItem(icon: Icons.inventory, label: 'Inventory', isExpanded: isExpanded, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CatalougeView()),
            );
          }),
          _SidebarNavItem(icon: Icons.local_shipping, label: 'Orders', isExpanded: isExpanded, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const OrdersView()),
            );
          }),
          _SidebarNavItem(icon: Icons.calendar_month, label: 'Calendar', isExpanded: isExpanded, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CalendarView()),
            );
          }),
          _SidebarNavItem(icon: Icons.group, label: 'Customers', isExpanded: isExpanded, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MemberView()),
            );
          }),
          _SidebarNavItem(icon: Icons.history, label: 'History',
              isSelected: true, isExpanded: isExpanded, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryView()),
            );
          }),
          const Spacer(),
          // _SidebarNavItem(
          //   icon: Icons.settings,
          //   label: 'Settings',
          //   isExpanded: isExpanded,
          //   onTap: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(builder: (context) => const SettingsView()),
          //     );
          //   },
          // ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.0),
              child: InkWell(
                onTap: () async {},
                borderRadius: BorderRadius.circular(24.0),
                child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 12.0),
                    Text(
                    'Basic Plan',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F01FD),
                    ),
                    ),
                  ],
                  ),
                ),
                ),
              ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 0.0, vertical: 8.0),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.0),
              child: InkWell(
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  final userId = user?.uid;

                  if (userId != null) {
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(userId).collection('activity').add({
                        'type': 'Logout',
                        'message': 'User logged out',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      print('DEBUG: Logout event logged to "activity" collection for user $userId');
                    } catch (e) {
                      print('ERROR: Failed to log logout event for user $userId: $e');
                    }
                  }

                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
                borderRadius: BorderRadius.circular(24.0),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFB8C63),
                        Color(0xFFF74403),
                        Color(0xFFFB8C63),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Container(
                    height: 48,
                    alignment: isExpanded ? Alignment.center : Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24.0 : 0),
                    child: isExpanded
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_outlined, color: Colors.white),
                              SizedBox(width: 12.0),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.logout_outlined, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isPrimary;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isPrimary = false,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    const Color contentBackgroundColor = Color(0xFFF1F5F9);

    Color itemIconColor = isSelected ? const Color(0xFF6F01FD) : Colors.white;

    Color itemTextColor = isSelected ? const Color(0xFF6F01FD) : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected ? contentBackgroundColor : Colors.transparent,
        borderRadius: isSelected
            ? const BorderRadius.horizontal(left: Radius.circular(32.0))
            : const BorderRadius.horizontal(right: Radius.circular(12.0)),
        child: InkWell(
          onTap: onTap,
          borderRadius: isSelected
              ? const BorderRadius.horizontal(left: Radius.circular(32.0))
              : const BorderRadius.horizontal(right: Radius.circular(12.0)),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24.0 : 0.0),
            alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
            decoration: isSelected ? null : null,
            child: isExpanded
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: itemIconColor,
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: itemTextColor,
                        ),
                      ),
                    ],
                  )
                : Icon(icon, color: itemIconColor, size: 24),
          ),
        ),
      ),
    );
  }
}

// --- Placeholder Chart Card ---
class SalesCard extends StatelessWidget {
  const SalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 600, // Increased height for better visibility of scrollable content
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 4.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales History',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 24),
          Expanded( // Wrap the StreamBuilder with Expanded
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
                      // physics: const NeverScrollableScrollPhysics(), // Remove this line
                      shrinkWrap: true, // Keep this
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
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 600, // Increased height for better visibility of scrollable content
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 4.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Activity',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 24),
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
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
    );
  }
}

