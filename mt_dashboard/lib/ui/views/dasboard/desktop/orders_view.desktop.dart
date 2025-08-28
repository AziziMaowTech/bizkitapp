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
          _SidebarNavItem(icon: Icons.local_shipping, label: 'Orders',
              isSelected: true, isExpanded: isExpanded, onTap: () {
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
          _SidebarNavItem(icon: Icons.history, label: 'History', isExpanded: isExpanded, onTap: () {
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
class CatalougeCard extends StatelessWidget {
  const CatalougeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
