import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalogue_settings_tab.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/coupon_management_tab.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/profile_settings_tab.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_view.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:mt_dashboard/ui/widgets/custom_app_bar.dart';

void main() {
  runApp(const SettingsViewDesktop());
}

class SettingsViewDesktop extends StatelessWidget {
  const SettingsViewDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizKit Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
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
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.blue, width: 1.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// Remove PromoCoupon and CouponManagementCard from here as they are now in coupon_management_tab.dart

// --- UserProfileTab --- (This can also be moved to a separate file if desired, but for now it's not part of the CatalougeCard's tabs)
class UserProfileTab extends StatelessWidget {
  const UserProfileTab({super.key});

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
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.blue[800], size: 20),
              const SizedBox(width: 8.0),
              Text(
                'User Profile',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'View and manage your profile information.',
            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16.0),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get()
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading profile: ${snapshot.error}', style: TextStyle(color: Colors.red[600])),
                );
              }
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return const Center(child: Text('User data not found.'));
              }

              final userData = snapshot.data!.data()!;
              final name = userData['name'] ?? 'N/A';
              final email = FirebaseAuth.instance.currentUser?.email ?? 'N/A';
              final bio = userData['bio'] ?? 'No bio provided.';
              final company = userData['company'] ?? 'N/A';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileDetail('Name', name),
                  _buildProfileDetail('Email', email),
                  _buildProfileDetail('Company', company),
                  _buildProfileDetail('Bio', bio),
                  const SizedBox(height: 24.0),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile functionality coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- TabbedSettingsView --- (This widget seems to be unused in the provided code,
// but if it were used, its children would also be individual tabs)
class TabbedSettingsView extends StatefulWidget {
  const TabbedSettingsView({super.key});

  @override
  State<TabbedSettingsView> createState() => _TabbedSettingsViewState();
}

class _TabbedSettingsViewState extends State<TabbedSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0.5,
      child: Column(
        children: [
          // TabBar (fixed height)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B82F6),
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'User Profile'),
                Tab(text: 'Promotional Coupons'),
              ],
            ),
          ),
          // TabBarView for content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                UserProfileTab(),
                CouponManagementTab(), // Changed from CouponManagementCard
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sidebar Widget (from dashboard_view.desktop.dart) ---
class Sidebar extends StatelessWidget {
  final bool isExpanded;

  const Sidebar({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    // List of navigation items
    final navItems = [
      _SidebarNavItem(
        icon: Icons.home,
        label: 'Dashboard',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DashboardView()),
          );
        },
      ),
      _SidebarNavItem(
        icon: Icons.point_of_sale,
        label: 'POS',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PosView()),
          );
        },
      ),
      _SidebarNavItem(
        icon: Icons.inventory,
        label: 'Inventory',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CatalougeView()),
          );
        },
      ),
      // _SidebarNavItem(
      //   icon: Icons.local_shipping,
      //   label: 'Orders',
      //   isExpanded: isExpanded,
      //   onTap: () {
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (context) => const OrdersView()),
      //     );
      //   },
      // ),
      _SidebarNavItem(
        icon: Icons.calendar_month,
        label: 'Calendar',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CalendarView()),
          );
        },
      ),
      _SidebarNavItem(
        icon: Icons.group,
        label: 'Customers',
        isExpanded: isExpanded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MemberView()),
          );
        },
      ),
      // _SidebarNavItem(
      //   icon: Icons.history,
      //   label: 'History',
      //   isExpanded: isExpanded,
      //   onTap: () {
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (context) => const HistoryView()),
      //     );
      //   },
      // ),
    ];

    return Container(
      width: isExpanded ? 240 : 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6F01FD),
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: 96.0),
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: isExpanded
                  ? Image.asset(
                      'assets/images/placeholder.png',
                      height: 100,
                      width: 100,
                    )
                  : Image.asset(
                      'assets/images/placeholder_small.png',
                      height: 50,
                      width: 50,
                    ),
            ),
          ),
          const SizedBox(height: 24.0),
          // Center navigation items vertically
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: navItems,
              ),
            ),
          ),
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                flex: 1,
                                child: CatalougeCard(),
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
          ),
        ],
      ),
    );
  }
}

// --- Enhanced Catalogue Card with Tabbed Interface ---
class CatalougeCard extends StatefulWidget {
  const CatalougeCard({super.key});

  @override
  State<CatalougeCard> createState() => _CatalougeCardState();
}

class _CatalougeCardState extends State<CatalougeCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8.0,
            spreadRadius: 2.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catalogue Management',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Handle menu actions
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(6.0),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.settings, size: 16),
                  text: 'Settings',
                ),
                Tab(
                  icon: Icon(Icons.discount, size: 16),
                  text: 'Coupons',
                ),
                Tab(
                  icon: Icon(Icons.category, size: 16),
                  text: 'Catalogue Settings',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ProfileSettingsTab(), // Using the new ProfileSettingsTab widget
                CouponManagementTab(), // Using the new CouponManagementTab widget
                CatalogueSettingsTab(), // Using the new CatalogueSettingsTab widget
              ],
            ),
          ),
        ],
      ),
    );
  }
}