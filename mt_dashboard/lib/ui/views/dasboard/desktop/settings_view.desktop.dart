import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
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

// --- Sidebar Widget ---
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
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
          const SizedBox(height: 24.0),
          _SidebarNavItem(icon: Icons.dashboard, label: 'Overview', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => DashboardView()),
            );
          }),
          _SidebarNavItem(icon: Icons.inventory, label: 'Catalouges', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CatalougeView()),
            );
          }),
          _SidebarNavItem(icon: Icons.local_shipping, label: 'Orders', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => OrdersView()),
            );
          }),
          _SidebarNavItem(icon: Icons.calendar_month, label: 'Calendar', onTap: () {}),
          _SidebarNavItem(icon: Icons.group, label: 'Members', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MemberView()),
            );
          }),
          _SidebarNavItem(icon: Icons.history, label: 'History', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryView()),
            );
          }),
          const Spacer(),
          _SidebarNavItem(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SettingsView()),
              );
            },
          ),
          _SidebarNavItem(icon: Icons.logout_outlined, label: 'Logout', onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeView()),
            );
          },)
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
    Color itemBackgroundColor = isSelected ? const Color(0xFFDBEAFE) : Colors.transparent;

    Color itemIconColor = isPrimary
        ? Colors.white
        : isSelected
        ? const Color(0xFF3B82F6)
        : Colors.grey[600]!;

    Color itemTextColor = isPrimary
        ? Colors.white
        : isSelected
        ? const Color(0xFF3B82F6)
        : Colors.grey[800]!;


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
            border: Border(left: BorderSide(color: Color(0xFF3B82F6), width: 3.0)),
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
              if (isPrimary) const Spacer(),
            ],
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
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: _isSidebarExpanded ? 240 : 70,
            child: const Sidebar(),
          ),
          Expanded(
            child: Column(
              children: [
                const CustomAppBar(),
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