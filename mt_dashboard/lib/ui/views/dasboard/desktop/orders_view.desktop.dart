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
  runApp(const OrdersViewDesktop());
}

class OrdersViewDesktop extends StatelessWidget {
  const OrdersViewDesktop({super.key});

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
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none, // No border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
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
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: _isSidebarExpanded ? 240 : 70, // Adjust width based on expansion state
            child: const Sidebar(),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                const CustomAppBar(),
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
                              child: CatalougeCard(// Purple
                              ),
                            ),
                            // const Expanded(
                            //   flex: 1,
                            //   child: CatalougeCard(
                            //     title: 'Catalogue',
                            //     chartColor: Color(0xFF8B5CF6), // Purple
                            //   ),
                            // ),
                            
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

// --- Sidebar Widget ---
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, // Fixed width for the sidebar
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Image.asset(
              'assets/images/placeholder.png',
              height: 100,
              width: 100,
              // errorBuilder: (context, error, stackTrace) => const Icon(Icons.medical_services, color: Color(0xFF1E40AF), size: 32),
              ),
            ),
            ),
            const SizedBox(height: 32.0),
            ElevatedButton.icon(
            icon: const Icon(Icons.point_of_sale),
            label: const Text('POS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PosView()));
            },
          ),
          // const SizedBox(height: 32.0),
          // Navigation Items
          // _SidebarNavItem(icon: Icons.app_registration, label: 'Add Product', onTap: () {}),
          const SizedBox(height: 24.0),
          _SidebarNavItem(icon: Icons.dashboard, label: 'Overview', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => DashboardView()),
              );
          }), // Spacer before other nav items
          _SidebarNavItem(icon: Icons.inventory, label: 'Catalouges', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CatalougeView()),
              );
          }),
          _SidebarNavItem(icon: Icons.local_shipping, label: 'Orders', isSelected: true, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => OrdersView()
            ),
            );
          }),
          _SidebarNavItem(icon: Icons.calendar_month, label: 'Calendar', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CalendarView()
            ),
            );
          }),
          _SidebarNavItem(icon: Icons.group, label: 'Members', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MemberView()),
              );
          }),
          _SidebarNavItem(icon: Icons.history, label: 'History', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryView() // Placeholder for History view
            ),
            );
          }),
          const Spacer(), // Pushes "Get mobile app" to bottom
            _SidebarNavItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => SettingsView()),
              );
            },
            ),
            _SidebarNavItem(icon: Icons.logout_outlined, label: 'Logout', onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  // Optionally, show a snackbar or navigate to login/home page
                   Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },)
          // const SizedBox(height: 24.0),
          // Get mobile app card
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //   child: Card(
          //     color: const Color(0xFFEFF6FF), // Light blue background
          //     elevation: 0,
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          //     child: Padding(
          //       padding: const EdgeInsets.all(16.0),
          //       child: Column(
          //         children: [
          //           Image.network(
          //             'https://placehold.co/80x80/E0E7FF/4F46E5?text=App', // Placeholder for mobile app icon
          //             errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, color: Colors.blueAccent, size: 60),
          //           ),
          //           const SizedBox(height: 8.0),
          //           const Text(
          //             'Get mobile app',
          //             style: TextStyle(
          //               fontSize: 16.0,
          //               fontWeight: FontWeight.bold,
          //               color: Color(0xFF1E40AF),
          //             ),
          //             textAlign: TextAlign.center,
          //           ),
          //           const SizedBox(height: 8.0),
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               // Placeholder for App Store icon
          //               Image.network(
          //                 'https://placehold.co/24x24/FFFFFF/000000?text=A',
          //                 errorBuilder: (context, error, stackTrace) => const Icon(Icons.apple, size: 24, color: Colors.grey),
          //                 height: 24,
          //                 width: 24,
          //               ),
          //               const SizedBox(width: 8.0),
          //               // Placeholder for Google Play icon
          //               Image.network(
          //                 'https://placehold.co/24x24/FFFFFF/000000?text=G',
          //                 errorBuilder: (context, error, stackTrace) => const Icon(Icons.android, size: 24, color: Colors.grey),
          //                 height: 24,
          //                 width: 24,
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
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
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color itemBackgroundColor = isSelected ? const Color(0xFFDBEAFE) : Colors.transparent; // Blue-100 for selected

    Color itemIconColor = isPrimary
        ? Colors.white // Primary button icon color
        : isSelected
            ? const Color(0xFF3B82F6) // Blue-500 for selected icon
            : Colors.grey[600]!; // Default grey icon color

    Color itemTextColor = isPrimary
        ? Colors.white // Primary button text color
        : isSelected
            ? const Color(0xFF3B82F6) // Blue-500 for selected text
            : Colors.grey[800]!; // Default grey text color


    return Material(
      color: itemBackgroundColor,
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12.0)),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          alignment: Alignment.centerLeft,
          decoration: isSelected
              ? const BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFF3B82F6), width: 3.0)), // Blue-500
                )
              : null,
          child: Row(
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
              if (isPrimary) const Spacer(), // Pushes icon to right (for Register patient)
            ],
          ),
        ),
      ),
    );
  }
}

// --- Placeholder Chart Card ---
class CatalougeCard extends StatelessWidget {
  const CatalougeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
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
          Text(
            'Catalogue',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8.0),
          // Placeholder chart goes here
        ],
      ),
    );
  }
}
