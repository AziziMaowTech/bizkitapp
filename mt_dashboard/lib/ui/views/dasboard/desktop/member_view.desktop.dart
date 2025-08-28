import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_view.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';
import 'package:mt_dashboard/ui/widgets/custom_app_bar.dart';
// Required imports for image picking, file picking, Firebase Storage, and platform detection
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const MemberViewDesktop());
}

class MemberViewDesktop extends StatelessWidget {
  const MemberViewDesktop({super.key});

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
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add the missing controller and search query
  final TextEditingController _customerSearchController = TextEditingController();
  String _customerSearchQuery = '';

  // Define the missing method to show member details dialog
  void _showMemberDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          title: Text(
            data['name'] ?? 'Member Details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['email'] != null) Text('Email: ${data['email']}'),
                if (data['phone'] != null) Text('Phone: ${data['phone']}'),
                if (data['address'] != null) Text('Address: ${data['address']}'),
                if (data['city'] != null) Text('City: ${data['city']}'),
                if (data['zip'] != null) Text('Zip: ${data['zip']}'),
                if (data['state'] != null) Text('State: ${data['state']}'),
                if (data['country'] != null) Text('Country: ${data['country']}'),
                if (data['discount'] != null) Text('Discount: ${data['discount']}'),
                if (data['createdAt'] != null && data['createdAt'] is Timestamp)
                  Text('Joined: ${(data['createdAt'] as Timestamp).toDate()}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Added method to show member edit dialog
  void _showMemberEditDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // You can customize this dialog as needed, here is a simple placeholder
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          title: Text(
            'Edit Member',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Member editing functionality is not implemented here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Added method to show member delete dialog
  void _showMemberDeleteDialog(BuildContext context, String docId, String memberName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          title: const Text('Delete Member'),
          content: Text('Are you sure you want to delete "$memberName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('members')
                        .doc(docId)
                        .delete();
                  }
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Member deleted successfully!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting member: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

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
                            Expanded(
                              flex: 2, // Adjust flex to give more space to the left card
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Align to the left
                              children: [
                                Text(
                                'Customer Analytics',
                                style: TextStyle(
                                  fontSize: 60.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                ),
                              ],
                              ),
                            ),
                          const SizedBox(width: 24.0),
                            Expanded(
                            flex: 1, // Adjust flex for the right card
                            child: Column(
                              children: [
                                Row(
                                  // New Row for User Info Card and Buttons
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 16.0),
                                    IconButton(
                                      icon: Icon(Icons.notifications_none, color: Colors.grey[600]),
                                      onPressed: () {},
                                    ),
                                    const SizedBox(width: 16.0),
                                    IconButton(
                                      icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => const SettingsView()),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 24.0),
                                    Expanded(
                                      child: _UserDropdownCard(
                                        userId: _userId,
                                        firestore: _firestore,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          children: [
                          // First Card
                          Expanded(
                            child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                'Total Customers',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Text(
                                      '89',
                                      style: TextStyle(
                                      fontSize: 64.0,
                                      color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 24.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        '2% increase',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Text(
                                        ' since last month.',
                                        style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                              ],
                              ),
                            ),
                            ),
                          ),
                          const SizedBox(width: 32.0),
                          // Second Card
                          Expanded(
                            child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                'Total Members',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Text(
                                      '56',
                                      style: TextStyle(
                                      fontSize: 64.0,
                                      color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 24.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 230, 200, 200),
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        '0.9% decrease',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Text(
                                        ' since last month.',
                                        style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                              ],
                              ),
                            ),
                            ),
                          ),
                          const SizedBox(width: 32.0),
                          // Third Card
                            Expanded(
                            child: Card(
                              child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Text(
                                  'Total Non-Members',
                                  style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Text(
                                      '33',
                                      style: TextStyle(
                                      fontSize: 64.0,
                                      color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 24.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        '1% increase',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Text(
                                        ' since last month.',
                                        style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // First Card
                          Expanded(
                            child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                children: [
                                  Text(
                                  'Your Customers',
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                  width: 250,
                                  child: TextField(
                                    controller: _customerSearchController,
                                    decoration: InputDecoration(
                                    hintText: 'Search customers...',
                                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                                    suffixIcon: _customerSearchQuery.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                          _customerSearchController.clear();
                                          _customerSearchQuery = '';
                                          });
                                        },
                                        )
                                      : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    ),
                                    onChanged: (value) {
                                    setState(() {
                                      _customerSearchQuery = value;
                                    });
                                    },
                                  ),
                                  ),
                                ],
                                ),
                                const SizedBox(height: 16.0),
                                StreamBuilder<QuerySnapshot>(
                                stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
                                  if (user == null) {
                                  return Stream.empty();
                                  }
                                  return FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('members')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots();
                                }),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                    'Error: ${snapshot.error}',
                                    style: TextStyle(color: Colors.red[600]),
                                    ),
                                  );
                                  }
                                  List<QueryDocumentSnapshot> members = snapshot.data?.docs ?? [];
                                  // Apply search filter
                                  if (_customerSearchQuery.isNotEmpty) {
                                  final query = _customerSearchQuery.toLowerCase();
                                  members = members.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final name = (data['name'] ?? '').toString().toLowerCase();
                                    final id = (data['id'] ?? doc.id).toString().toLowerCase();
                                    final phone = (data['phone'] ?? '').toString().toLowerCase();
                                    return name.contains(query) || id.contains(query) || phone.contains(query);
                                  }).toList();
                                  }
                                  if (members.isEmpty) {
                                  return const Text(
                                    'No members found.',
                                    style: TextStyle(color: Colors.grey),
                                  );
                                  }
                                  // Center the table horizontally
                                  return Center(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Name')),
                                      DataColumn(label: Text('Customer ID')),
                                      DataColumn(label: Text('Phone No.')),
                                      DataColumn(label: Text('Membership')),
                                      DataColumn(label: Text('Date Join')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: members.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final name = data['name'] ?? 'No Name';
                                      final customerId = data['id'] ?? doc.id;
                                      final phone = data['phone'] ?? '-';
                                      final membership = (data['discount'] != null && data['discount'] != '0%' && data['discount'] != '0')
                                        ? 'Member'
                                        : 'Non-Member';
                                      final timestamp = data['createdAt'];
                                      String dateJoin = '-';
                                      if (timestamp != null && timestamp is Timestamp) {
                                      final dt = timestamp.toDate();
                                      dateJoin = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                                      }
                                      return DataRow(
                                      cells: [
                                        DataCell(Text(name)),
                                        DataCell(Text(customerId)),
                                        DataCell(Text(phone)),
                                        DataCell(Text(membership)),
                                        DataCell(Text(dateJoin)),
                                        DataCell(
                                        Row(
                                          children: [
                                          Tooltip(
                                            message: 'View Details',
                                            child: IconButton(
                                            icon: const Icon(Icons.info_outline, color: Colors.blue),
                                            onPressed: () {
                                              _showMemberDetailsDialog(context, data);
                                            },
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (value) {
                                            if (value == 'edit') {
                                              _showMemberEditDialog(context, data, doc.id);
                                            } else if (value == 'delete') {
                                              _showMemberDeleteDialog(context, doc.id, data['name'] ?? '');
                                            }
                                            },
                                            itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                            ],
                                          ),
                                          ],
                                        ),
                                        ),
                                      ],
                                      );
                                    }).toList(),
                                    ),
                                  ),
                                  );
                                },
                                )
                              ],
                              ),
                            ),
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  const AddMemberCard(),
                                  const MemberDiscountCard(), // Universal member discount card
                                ],
                              ),
                            ),
                            const SizedBox(width: 24.0), // Spacing between cards
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  const MemberCard(), // Existing member list
                                  const SizedBox(height: 24.0), // Spacing between cards
                                ],
                              ),
                            ),
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
        isSelected: true, // This is the selected item
        isExpanded: isExpanded,
        onTap: () {
          // Already on this page
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

// Updated MemberCard class
class MemberCard extends StatefulWidget {
  const MemberCard({super.key});

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterField = 'name'; // Default filter field
  bool _sortAscending = true; // Default sort order

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

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
            'Members',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16.0),
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search members by name, email, or phone...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16.0),
          // Filter and Sort Options
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterField,
                  decoration: const InputDecoration(
                    labelText: 'Filter by',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'phone', child: Text('Phone')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _filterField = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _sortAscending,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    prefixIcon: Icon(Icons.sort),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Ascending')),
                    DropdownMenuItem(value: false, child: Text('Descending')),
                  ],
                  onChanged: (bool? newValue) {
                    setState(() {
                      _sortAscending = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Re-introduced SizedBox for fixed height
          SizedBox(
            height: 600, // Set a fixed height for the member list
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
                if (user == null) {
                  return Stream.empty(); // No user, no stream
                }
                return FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('members')
                    .snapshots();
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  );
                }

                List<DocumentSnapshot> members = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  members = members.where((memberDoc) {
                    final memberData = memberDoc.data() as Map<String, dynamic>;
                    final name = memberData['name']?.toString().toLowerCase() ?? '';
                    final email = memberData['email']?.toString().toLowerCase() ?? '';
                    final phone = memberData['phone']?.toString().toLowerCase() ?? '';
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) ||
                        email.contains(query) ||
                        phone.contains(query);
                  }).toList();
                }

                // Apply sorting
                members.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aValue = aData[_filterField]?.toString().toLowerCase() ?? '';
                  final bValue = bData[_filterField]?.toString().toLowerCase() ?? '';

                  int comparison = aValue.compareTo(bValue);
                  return _sortAscending ? comparison : -comparison;
                });

                if (members.isEmpty && _searchQuery.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No members found matching your search criteria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                    ),
                  );
                } else if (members.isEmpty) { // Case for no members at all
                  return const Center(
                    child: Text(
                      'No members found.\nAdd members using the form on the left.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }


                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index].data() as Map<String, dynamic>;
                    final memberId = members[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            member['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          member['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member['email'] ?? 'No Email'),
                            Text(member['phone'] ?? 'No Phone'),
                            Text('Discount: ${member['discount'] ?? '0%'}'), // Display discount here
                          ],
                        ),
                        trailing: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey[600],
                        ),
                        onTap: () {
                          // Pass the context of the MemberCard to the dialog function
                          _showMemberDialog(context, member, memberId);
                        },
                      ),
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

  void _showMemberDialog(BuildContext context, Map<String, dynamic> member, String memberId) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(text: member['name']);
    final TextEditingController emailController = TextEditingController(text: member['email']);
    final TextEditingController phoneController = TextEditingController(text: member['phone']);
    final TextEditingController addressController = TextEditingController(text: member['address']);
    final TextEditingController cityController = TextEditingController(text: member['city']);
    final TextEditingController zipController = TextEditingController(text: member['zip']);
    final TextEditingController stateController = TextEditingController(text: member['state']);
    final TextEditingController countryController = TextEditingController(text: member['country']);
    final TextEditingController discountController = TextEditingController(text: member['discount']?.toString().replaceAll('%', '') ?? '0'); // New: Discount field

    // Capture the context that has the Scaffold ancestor
    final BuildContext scaffoldContext = context;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext for Navigator.of(dialogContext).pop()
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.5,
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Member',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a phone number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  controller: addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a city';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  controller: zipController,
                                  decoration: const InputDecoration(
                                    labelText: 'Zip',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a zip code';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: stateController,
                                  decoration: const InputDecoration(
                                    labelText: 'State',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a state';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  controller: countryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Country',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a country';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          // New: Discount Field for editing member
                          TextFormField(
                            controller: discountController,
                            decoration: const InputDecoration(
                              labelText: 'Discount (%)',
                              suffixText: '%',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a discount percentage';
                              }
                              final numValue = double.tryParse(value);
                              if (numValue == null) {
                                return 'Please enter a valid number';
                              }
                              if (numValue < 0 || numValue > 100) {
                                return 'Discount must be between 0 and 100';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Delete Button
                      ElevatedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmation(dialogContext, memberId, member['name'], scaffoldContext); // Pass scaffoldContext
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      // Action Buttons
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12.0),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                try {
                                  await _updateMember(
                                    memberId,
                                    nameController.text,
                                    emailController.text,
                                    phoneController.text,
                                    addressController.text,
                                    cityController.text,
                                    zipController.text,
                                    stateController.text,
                                    countryController.text,
                                    discountController.text, // Pass new discount value
                                  );

                                  if (mounted) { // Check if the dialog is still mounted
                                    Navigator.of(dialogContext).pop(); // Close the edit dialog
                                  }

                                  // Check if the original scaffoldContext is still mounted before showing snackbar
                                  if (scaffoldContext.mounted) {
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Member updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) { // Check if the dialog is still mounted
                                    Navigator.of(dialogContext).pop(); // Close the edit dialog
                                  }

                                  if (scaffoldContext.mounted) {
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating member: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext dialogContext, String memberId, String memberName, BuildContext scaffoldContext) {
    showDialog(
      context: dialogContext, // Use dialogContext for this new dialog
      builder: (BuildContext confirmationDialogContext) {
        return AlertDialog(
          title: const Text('Delete Member'),
          content: Text('Are you sure you want to delete "$memberName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmationDialogContext).pop(), // Close confirmation dialog
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _deleteMember(memberId);

                  if (mounted) { // Check if dialog is still mounted
                    Navigator.of(confirmationDialogContext).pop(); // Close confirmation dialog
                    Navigator.of(dialogContext).pop(); // Close the edit dialog
                  }

                  // Show success message using the stored scaffoldContext
                  if (scaffoldContext.mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text('Member deleted successfully!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) { // Check if dialog is still mounted
                    Navigator.of(confirmationDialogContext).pop(); // Close confirmation dialog
                    Navigator.of(dialogContext).pop(); // Close the edit dialog
                  }

                  // Show error message
                  if (scaffoldContext.mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting member: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateMember(
      String memberId,
      String name,
      String email,
      String phone,
      String address,
      String city,
      String zip,
      String state,
      String country,
      String discount, // New parameter for discount
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('members')
          .doc(memberId)
          .update({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'zip': zip,
        'state': state,
        'country': country,
        'discount': discount.endsWith('%') ? discount : '$discount%', // Ensure percentage symbol is added
      });
    } catch (e) {
      print('Error updating member: $e');
      rethrow; // Re-throw to be caught by the calling function
    }
  }

  Future<void> _deleteMember(String memberId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('members')
          .doc(memberId)
          .delete();
    } catch (e) {
      print('Error deleting member: $e');
      rethrow; // Re-throw to be caught by the calling function
    }
  }
}

class AddMemberCard extends StatefulWidget {
  const AddMemberCard({super.key});

  @override
  State<AddMemberCard> createState() => _AddMemberCardState();
}

class _AddMemberCardState extends State<AddMemberCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    zipController.dispose();
    stateController.dispose();
    countryController.dispose();
    super.dispose();
  }

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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Member',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                // Basic email validation
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                // Basic phone number validation (digits only)
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Please enter a valid phone number (digits only)';
                }
                return null;
              },
            ),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            TextFormField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a city';
                }
                return null;
              },
            ),
            TextFormField(
              controller: zipController,
              decoration: const InputDecoration(
                labelText: 'Zip',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a zip code';
                }
                return null;
              },
            ),
            TextFormField(
              controller: stateController,
              decoration: const InputDecoration(
                labelText: 'State',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a state';
                }
                return null;
              },
            ),
            TextFormField(
              controller: countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a country';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0), // Added spacing before button
            SizedBox(
              width: double.infinity, // Make button full width
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to add members.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    try {
                      // Fetch the current universal discount to apply to the new member
                      String initialDiscount = '0%';
                      final universalDiscountSnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('memberdisc')
                          .limit(1)
                          .get();

                      if (universalDiscountSnapshot.docs.isNotEmpty) {
                        final data = universalDiscountSnapshot.docs.first.data();
                        initialDiscount = data['discount'] as String? ?? '0%';
                      }

                      final memberRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('members')
                          .doc();

                      await memberRef.set({
                        'id': memberRef.id,
                        'name': nameController.text,
                        'email': emailController.text,
                        'phone': phoneController.text,
                        'address': addressController.text,
                        'city': cityController.text,
                        'zip': zipController.text,
                        'state': stateController.text,
                        'country': countryController.text,
                        'discount': initialDiscount, // Apply the current universal discount
                        'createdAt': FieldValue.serverTimestamp(), // Add timestamp
                      });

                      // Clear the form
                      nameController.clear();
                      emailController.clear();
                      phoneController.clear();
                      addressController.clear();
                      cityController.clear();
                      zipController.clear();
                      stateController.clear();
                      countryController.clear();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Member added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding member: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6), // Purple color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Add New Member',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemberDiscountCard extends StatefulWidget {
  const MemberDiscountCard({super.key});

  @override
  State<MemberDiscountCard> createState() => _MemberDiscountCardState();
}

class _MemberDiscountCardState extends State<MemberDiscountCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customDiscountController = TextEditingController();
  String _selectedDiscountOption = '5%';
  bool _isCustom = false;
  bool _isLoading = false;
  bool _isInitialLoadComplete = false; // Add this new flag

  final List<String> _predefinedDiscounts = ['5%', '10%', '15%', '20%', 'Custom'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUniversalDiscountSetting();
  }

  @override
  void dispose() {
    _customDiscountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUniversalDiscountSetting() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User not logged in, cannot load universal discount setting.");
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('memberdisc')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final discountString = data['discount'] as String?;

        if (discountString != null) {
          if (_predefinedDiscounts.contains(discountString)) {
            setState(() {
              _selectedDiscountOption = discountString;
              _isCustom = false;
            });
          } else {
            setState(() {
              _selectedDiscountOption = 'Custom';
              _isCustom = true;
              _customDiscountController.text = discountString.replaceAll('%', '');
            });
          }
        }
      } else {
        // If no universal discount setting exists, default to '5%' as initial selection
        setState(() {
          _selectedDiscountOption = '5%';
          _isCustom = false;
          _customDiscountController.clear();
        });
      }
      // Set flag to true after initial load
      setState(() {
        _isInitialLoadComplete = true;
      });
    } catch (e) {
      print('Error loading current universal discount setting: $e');
      setState(() { // Also ensure flag is set on error to prevent infinite loading state
        _isInitialLoadComplete = true;
      });
    }
  }

  Future<void> _saveUniversalDiscountAndApplyToAllMembers() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save discount settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String discountValueToSave;
      if (_isCustom) {
        discountValueToSave = _customDiscountController.text.trim();
        if (!discountValueToSave.endsWith('%')) {
          discountValueToSave += '%';
        }
      } else {
        discountValueToSave = _selectedDiscountOption;
      }

      final existingDiscDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('memberdisc')
          .get();

      final deleteBatch = FirebaseFirestore.instance.batch();
      for (var doc in existingDiscDocs.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('memberdisc')
          .add({
            'discount': discountValueToSave,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      final allMembersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('members')
          .get();

      final updateMembersBatch = FirebaseFirestore.instance.batch();
      for (var memberDoc in allMembersSnapshot.docs) {
        updateMembersBatch.update(memberDoc.reference, {
          'discount': discountValueToSave,
        });
      }
      await updateMembersBatch.commit();


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member discount updated for all members!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving universal discount and applying to members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Member Discount Settings',
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
              'Set a universal discount for all members. This will update existing members.',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16.0),

            // Current Active Discount Display
            // Removed the problematic WidgetsBinding.instance.addPostFrameCallback
            // This StreamBuilder now only DISPLAYS the current active discount from Firestore
            // It no longer tries to re-set the dropdown's state based on the stream.
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
                if (user == null) {
                  return Stream.empty();
                }
                return FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('memberdisc')
                    .snapshots();
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // While loading, display the currently selected option if available
                  // or an empty container if nothing is loaded yet.
                  return _isInitialLoadComplete
                    ? _buildCurrentDiscountDisplay(_selectedDiscountOption)
                    : Container();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final currentDiscountData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final discountValue = currentDiscountData['discount'] ?? 'N/A';
                  return _buildCurrentDiscountDisplay(discountValue.toString());
                }
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'No universal member discount set.',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16.0),

            // Discount Selection Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDiscountOption, // This is now solely controlled by user interaction
              decoration: const InputDecoration(
                labelText: 'Select Discount',
                prefixIcon: Icon(Icons.percent),
              ),
              items: _predefinedDiscounts.map((String discount) {
                return DropdownMenuItem<String>(
                  value: discount,
                  child: Text(discount),
                );
              }).toList(),
              onChanged: (String? newValue) {
                // This correctly updates the local state for the dropdown
                setState(() {
                  _selectedDiscountOption = newValue!;
                  _isCustom = newValue == 'Custom';
                  if (!_isCustom) {
                    _customDiscountController.clear();
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a discount';
                }
                return null;
              },
            ),

            // Custom Discount Input (shown when Custom is selected)
            if (_isCustom) ...[
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _customDiscountController,
                decoration: const InputDecoration(
                  labelText: 'Custom Discount (%)',
                  prefixIcon: Icon(Icons.edit),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (_isCustom) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a custom discount percentage';
                    }
                    final numValue = double.tryParse(value);
                    if (numValue == null) {
                      return 'Please enter a valid number';
                    }
                    if (numValue < 0 || numValue > 100) {
                      return 'Discount must be between 0 and 100';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 20.0),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveUniversalDiscountAndApplyToAllMembers,
                icon: _isLoading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Apply Discount to All Members'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the current discount display container
  Widget _buildCurrentDiscountDisplay(String discountValue) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green[600],
            size: 18,
          ),
          const SizedBox(width: 8.0),
          Text(
            'Current Universal Discount: ',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            discountValue,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// --- User Dropdown Card Widget ---
class _UserDropdownCard extends StatelessWidget {
  final String? userId;
  final FirebaseFirestore firestore;

  const _UserDropdownCard({
    Key? key,
    required this.userId,
    required this.firestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No user info available.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Error loading user info.'),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final displayName = userData['name'] as String? ?? 'User';
        final email = userData['email'] as String? ?? 'No email';
        // Updated to use 'profilePictureUrl' for the profile image
        final profilePictureUrl = userData['profilePictureUrl'] as String?;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Wrap CircleAvatar with GestureDetector for tap functionality
                GestureDetector(
                  onTap: () async {
                    if (userId != null) {
                      await _changeProfilePicture(context, userId!, firestore);
                    }
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl) : null,
                    child: profilePictureUrl == null ? const Icon(Icons.person, size: 32) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) {
                    if (value == 'Logout') {
                      FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomeView()),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Logout',
                      child: Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to handle changing profile picture
  Future<void> _changeProfilePicture(BuildContext context, String userId, FirebaseFirestore firestore) async {
    final ImagePicker picker = ImagePicker();
    XFile? image;

    if (kIsWeb) {
      // Web specific file picking
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        final fileName = result.files.single.name;
        final fileBytes = result.files.single.bytes!;
        image = XFile.fromData(fileBytes, name: fileName);
      }
    } else {
      // Mobile specific image picking
      image = await picker.pickImage(source: ImageSource.gallery);
    }

    if (image != null) {
      try {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child('$userId/${image.name}');
        UploadTask uploadTask;

        if (kIsWeb) {
          uploadTask = storageRef.putData(await image.readAsBytes());
        } else {
          uploadTask = storageRef.putFile(File(image.path));
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update profilePictureUrl in Firestore
        await firestore.collection('users').doc(userId).update({
          'profilePictureUrl': downloadUrl,
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } on FirebaseException catch (e) {
        print('Error uploading profile picture: ${e.message}');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: ${e.message}')),
        );
      } catch (e) {
        print('Unexpected error: $e');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }
}