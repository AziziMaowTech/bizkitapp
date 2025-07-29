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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

// Import the cached_network_image package
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mt_dashboard/ui/widgets/custom_app_bar.dart';
// If you intended to use cached_memory_image for base64/Uint8List, you would keep this too:
// import 'package:cached_memory_image/cached_memory_image.dart';


void main() {
  runApp(const CatalougeViewDesktop());
}

class CatalougeViewDesktop extends StatelessWidget {
  const CatalougeViewDesktop({super.key});

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
                              child: CatalougeCard(
                                title: 'Catalogue',
                                chartColor: Color(0xFF8B5CF6), // Purple
                              ),
                            ),
                            // const Expanded(
                            //    flex: 1,
                            //    child: CatalougeCard(
                            //      title: 'Catalogue',
                            //      chartColor: Color(0xFF8B5CF6), // Purple
                            //    ),
                            // ),

                            // const Expanded(
                            //    flex: 1,
                            //    child: ChartCard(
                            //      title: 'Catalogue',
                            //      chartColor: Color(0xFF8B5CF6), // Purple
                            //    ),
                            // ),

                            Expanded(
                              flex: 1,
                              child: ProductCard(
                                title: 'Products',
                                chartColor: Color.fromARGB(255, 246, 125, 92), // Purple
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
          _SidebarNavItem(icon: Icons.inventory, label: 'Catalouges', isSelected: true, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CatalougeView()),
              );
          }),
          _SidebarNavItem(icon: Icons.local_shipping, label: 'Orders', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => OrdersView()
            ),
            );
          }),
          _SidebarNavItem(icon: Icons.calendar_month, label: 'Calendar', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CalendarView()
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
              MaterialPageRoute(builder: (context) => const HistoryView()),
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
          //    padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //    child: Card(
          //      color: const Color(0xFFEFF6FF), // Light blue background
          //      elevation: 0,
          //      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          //      child: Padding(
          //        padding: const EdgeInsets.all(16.0),
          //        child: Column(
          //          children: [
          //            Image.network(
          //              'https://placehold.co/80x80/E0E7FF/4F46E5?text=App', // Placeholder for mobile app icon
          //              errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, color: Colors.blueAccent, size: 60),
          //            ),
          //            const SizedBox(height: 8.0),
          //            const Text(
          //              'Get mobile app',
          //              style: TextStyle(
          //                fontSize: 16.0,
          //                fontWeight: FontWeight.bold,
          //                color: Color(0xFF1E40AF),
          //              ),
          //              textAlign: TextAlign.center,
          //            ),
          //            const SizedBox(height: 8.0),
          //            Row(
          //              mainAxisAlignment: MainAxisAlignment.center,
          //              children: [
          //                // Placeholder for App Store icon
          //                Image.network(
          //                  'https://placehold.co/24x24/FFFFFF/000000?text=A',
          //                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.apple, size: 24, color: Colors.grey),
          //                  height: 24,
          //                  width: 24,
          //                ),
          //                const SizedBox(width: 8.0),
          //                // Placeholder for Google Play icon
          //                Image.network(
          //                  'https://placehold.co/24x24/FFFFFF/000000?text=G',
          //                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.android, size: 24, color: Colors.grey),
          //                  height: 24,
          //                  width: 24,
          //                ),
          //              ],
          //            ),
          //          ],
          //        ),
          //      ),
          //    ),
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
  final String title;
  final Color chartColor;
  final double height;

  const CatalougeCard({
    required this.title,
    required this.chartColor,
    this.height = 500, // Default height
    // super.key, // Remove unused parameter as it's not passed
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'Please log in to view catalogues.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                // Add Catalouge Button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final TextEditingController controller = TextEditingController();
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Catalogue'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter catalogue name',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                Navigator.pop(context, controller.text.trim());
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && result.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('catalogs')
                          .add({'name': result, 'createdAt': FieldValue.serverTimestamp()});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('Add Catalogue', style: TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(width: 4),
                        Icon(Icons.add, size: 16, color: Colors.grey[700]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Catalogues List from Firestore
            SizedBox(
              height: height,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('catalogs')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading catalogues'));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No catalogues found.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final name = data['name'] ?? 'Unnamed';
                      final docId = docs[index].id;
                      return ListTile(
                        leading: Icon(Icons.folder, color: chartColor),
                        title: Text(name),
                        subtitle: data['createdAt'] != null
                            ? Text(
                                (data['createdAt'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split('.')
                                    .first,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete Catalogue',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Catalogue'),
                                content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              // Delete all products in this catalogue first (if needed)
                              final productsRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('catalogs')
                                  .doc(docId)
                                  .collection('products');
                              final products = await productsRef.get();
                              for (final doc in products.docs) {
                                await doc.reference.delete();
                              }
                              // Delete the catalogue itself
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('catalogs')
                                  .doc(docId)
                                  .delete();
                              // Delete the catalogueId in Storage
                              final storageRef = FirebaseStorage.instance
                                  .ref('product_images/${user.uid}/$docId');
                              await storageRef.listAll().then((list) async {
                                for (final item in list.items) {
                                  await item.delete();
                                }
                              });
                              // Refresh the page
                              Navigator.pushReplacement(
                                  context, MaterialPageRoute(builder: (context) => CatalougeView()));
                            }
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
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final Color chartColor;
  final double height;

  const ProductCard({
    required this.title,
    required this.chartColor,
    this.height = 500, // Default height
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'Please log in to view products.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ),
      );
    }

    // Select catalogue first
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('catalogs')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, catalogSnapshot) {
            if (catalogSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (catalogSnapshot.hasError) {
              return Center(child: Text('Error loading catalogues'));
            }
            final catalogs = catalogSnapshot.data?.docs ?? [];
            if (catalogs.isEmpty) {
              return Center(
                child: Text(
                  'No catalogues found. Please add a catalogue first.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }

            // Use a ValueNotifier to keep track of selected catalogue
            return _ProductCardContent(
              title: title,
              chartColor: chartColor,
              height: height,
              catalogs: catalogs,
              userId: user.uid,
            );
          },
        ),
      ),
    );
  }
}

class _ProductCardContent extends StatefulWidget {
  final String title;
  final Color chartColor;
  final double height;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> catalogs;
  final String userId;

  const _ProductCardContent({
    required this.title,
    required this.chartColor,
    required this.height,
    required this.catalogs,
    required this.userId,
  });

  @override
  State<_ProductCardContent> createState() => _ProductCardContentState();
}

class _ProductCardContentState extends State<_ProductCardContent> {
  String? selectedCatalogId;
  String? selectedCatalogName;

  @override
  void initState() {
    super.initState();
    if (widget.catalogs.isNotEmpty) {
      selectedCatalogId = widget.catalogs.first.id;
      selectedCatalogName = widget.catalogs.first.data()['name'] ?? 'Unnamed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCatalogId,
                      items: widget.catalogs
                          .map((doc) => DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  doc.data()['name'] ?? 'Unnamed',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCatalogId = value;
                          selectedCatalogName = widget.catalogs
                              .firstWhere((doc) => doc.id == value)
                              .data()['name'];
                        });
                      },
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      dropdownColor: Colors.white,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => _AddProductDialog(
                        userId: widget.userId,
                        catalogId: selectedCatalogId,
                      ),
                    );
                    if (result != null && selectedCatalogId != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userId)
                          .collection('catalogs')
                          .doc(selectedCatalogId)
                          .collection('products')
                          .add({
                        ...result,
                        'createdAt': FieldValue.serverTimestamp(),
                        'categoryName': selectedCatalogName ?? '', // Add categoryName here
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('Add Product', style: TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(width: 4),
                        Icon(Icons.add, size: 16, color: Colors.grey[700]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        if (selectedCatalogId == null)
          const Text('Please select a catalogue.'),
        if (selectedCatalogId != null)
          SizedBox(
            height: widget.height,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('catalogs')
                  .doc(selectedCatalogId)
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading products'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found in "$selectedCatalogName".',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final name = data['name'] ?? 'Unnamed';
                    final price = data['price'] ?? '';
                    final colors = data['colors'] ?? [];
                    final description = data['description'] ?? '';
                    final images = data['images'] as List<dynamic>? ?? [];
                    final quantity = data['quantity'] ?? 0;
                    final size = data['size'] ?? '';
                    final docId = docs[index].id;
                    return InkWell(
                      onTap: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => _AddProductDialog(
                            userId: widget.userId,
                            catalogId: selectedCatalogId,
                            initialData: data,
                            initialImages: images,
                            productDocId: docId,
                          ),
                        );
                        if (result != null && selectedCatalogId != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userId)
                              .collection('catalogs')
                              .doc(selectedCatalogId)
                              .collection('products')
                              .doc(docId)
                              .update({
                                ...result,
                                'categoryName': selectedCatalogName ?? '', // Add categoryName on update too
                              });
                        }
                      },
                      child: ListTile(
                        leading: images.isNotEmpty
                            ? _ProductImageCarousel(images: images)
                            : Icon(Icons.shopping_bag, color: widget.chartColor),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (price.toString().isNotEmpty)
                              Text('Price: $price', style: const TextStyle(fontSize: 12)),
                            if (quantity != null)
                              Text('Quantity: $quantity', style: const TextStyle(fontSize: 12)),
                            if (size.toString().isNotEmpty)
                              Text('Size: $size', style: const TextStyle(fontSize: 12)),
                            if (colors is List && colors.isNotEmpty)
                              Row(
                                children: [
                                  const Text('Colors: ', style: TextStyle(fontSize: 12)),
                                  ...colors.map<Widget>((c) {
                                    Color color;
                                    try {
                                      color = Color(int.parse(c, radix: 16));
                                    } catch (_) {
                                      color = Colors.black;
                                    }
                                    return Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            if (description.toString().isNotEmpty)
                              Text('Description: $description', style: const TextStyle(fontSize: 12)),
                            if (data['createdAt'] != null)
                              Text(
                                (data['createdAt'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split('.')
                                    .first,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete Product',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Product'),
                                content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userId)
                                  .collection('catalogs')
                                  .doc(selectedCatalogId)
                                  .collection('products')
                                  .doc(docId)
                                  .delete();

                              final storage = FirebaseStorage.instance;
                              for (final img in data['images']) {
                                final ref = storage.refFromURL(img);
                                await ref.delete();
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  final List<dynamic> images;
  const _ProductImageCarousel({required this.images, super.key});

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  int _currentIndex = 0;

  void _moveLeft() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.images.length) % widget.images.length;
    });
  }

  void _moveRight() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = widget.images[_currentIndex] as String; // Ensure it's a String (URL)
    // Make the carousel bigger: width: 100, height: 100
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage( // Using CachedNetworkImage
              imageUrl: imgUrl, // Pass the image URL here
              // width: 100,
              // height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(), // Placeholder while loading
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                width: 100,
                height: 100,
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: _moveLeft,
                child: Container(
                  width: 28,
                  height: 100,
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: const Icon(Icons.chevron_left, size: 28, color: Colors.black54),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: _moveRight,
                child: Container(
                  width: 28,
                  height: 100,
                  color: Colors.transparent,
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.chevron_right, size: 28, color: Colors.black54),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentIndex ? Colors.white : Colors.black26,
                      border: Border.all(color: Colors.black26, width: 0.5),
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

class _AddProductDialog extends StatefulWidget {
  final String? userId;
  final String? catalogId;
  final Map<String, dynamic>? initialData;
  final List<dynamic>? initialImages;
  final String? productDocId;

  const _AddProductDialog({
    this.userId,
    this.catalogId,
    this.initialData,
    this.initialImages,
    this.productDocId,
    super.key,
  });

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _customColor = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  List<Color> _pickedColors = [];
  final List<XFile> _pickedImages = [];
  final List<PlatformFile> _webPickedImages = [];
  List<String> _existingImageUrls = [];
  bool _uploading = false;

  // Versatile size options
  final List<String> _sizeOptions = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', // Shirt sizes
    '6', '7', '8', '9', '10', '11', '12', // Shoe sizes
    '28', '30', '32', '34', '36', '38', // Pants/waist sizes
    'Custom'
  ];
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _name.text = widget.initialData?['name'] ?? '';
      // Price: always ensure it starts with $
      String priceValue = widget.initialData?['price'] ?? '';
      if (!priceValue.startsWith('\$')) {
        priceValue = '\$${priceValue.replaceAll('\$', '')}';
      }
      _price.text = priceValue;
      _description.text = widget.initialData?['description'] ?? '';
      final colorList = widget.initialData?['colors'] as List<dynamic>? ?? [];
      _pickedColors = colorList
          .map((c) {
            try {
              return Color(int.parse(c, radix: 16));
            } catch (_) {
              return Colors.black;
            }
          })
          .toList();
      _existingImageUrls = (widget.initialImages ?? []).cast<String>();
      final dynamic quantityValue = widget.initialData?['quantity'];
      if (quantityValue is int) {
        _quantityController.text = quantityValue.toString();
      } else if (quantityValue != null) {
        _quantityController.text = quantityValue.toString();
      } else {
        _quantityController.text = '1';
      }
      _selectedSize = widget.initialData?['size']?.toString();
      if (_selectedSize != null && !_sizeOptions.contains(_selectedSize!)) {
        _sizeController.text = _selectedSize!;
        _selectedSize = 'Custom';
      }
    } else {
      _quantityController.text = '1';
      _price.text = '\$';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _customColor.dispose();
    _quantityController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _pickColors() async {
    List<Color> tempColors = List.from(_pickedColors);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick Colors'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: tempColors.isNotEmpty ? tempColors.last : Colors.blue,
              onColorChanged: (color) {
                if (!tempColors.contains(color)) {
                  setState(() {
                    tempColors.add(color);
                  });
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
    setState(() {
      _pickedColors = tempColors;
    });
  }

  void _removeColor(int index) {
    setState(() {
      _pickedColors.removeAt(index);
    });
  }

  void _addCustomColor() {
    final hex = _customColor.text.trim();
    if (hex.isEmpty) return;
    try {
      String hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      final color = Color(int.parse(hexColor, radix: 16));
      if (!_pickedColors.contains(color)) {
        setState(() {
          _pickedColors.add(color);
        });
      }
      _customColor.clear();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid color hex code')),
      );
    }
  }

  Future<void> _pickImages() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _webPickedImages.addAll(result.files);
        });
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(picked);
        });
      }
    }
  }

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else if (kIsWeb) {
        _webPickedImages.removeAt(index);
      } else {
        _pickedImages.removeAt(index);
      }
    });
  }

  Future<List<String>> _uploadImages() async {
    setState(() {
      _uploading = true;
    });
    List<String> urls = [];
    if (kIsWeb) {
      for (final img in _webPickedImages) {
        final ref = FirebaseStorage.instance
            .ref('product_images/${widget.userId ?? 'unknown'}/${widget.catalogId ?? 'unknown'}/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
        final uploadTask = await ref.putData(img.bytes!);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
    } else {
      for (final img in _pickedImages) {
        final file = File(img.path);
        final ref = FirebaseStorage.instance
            .ref('product_images/${widget.userId ?? 'unknown'}/${widget.catalogId ?? 'unknown'}/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
        final uploadTask = await ref.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
    }
    setState(() {
      _uploading = false;
    });
    return urls;
  }

  void _showPreviewDialog() {
    // Gather all product data as it would be saved
    String priceText = _price.text.trim();
    if (!priceText.startsWith('\$')) {
      priceText = '\$$priceText';
    }
    String finalSize = '';
    if (_selectedSize == 'Custom') {
      finalSize = _sizeController.text.trim();
    } else {
      finalSize = _selectedSize ?? '';
    }

    // Gather all images (existing + picked)
    final List<_PreviewImage> allImages = [
      ..._existingImageUrls.map((url) => _PreviewImage.network(url)),
      if (kIsWeb)
        ..._webPickedImages.map((img) => _PreviewImage.memory(img.bytes!)) // Ensure bytes are not null for web
      else
        ..._pickedImages.map((img) => _PreviewImage.file(img.path)),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Make preview card white
        title: const Text('Product Preview'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allImages.isNotEmpty)
                  Center(child: _PreviewImageCarousel(images: allImages)), // Center the carousel
                const SizedBox(height: 16),
                Text('Name: ${_name.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Price: $priceText'),
                const SizedBox(height: 8),
                Text('Quantity: ${_quantityController.text.trim()}'),
                const SizedBox(height: 8),
                Text('Size: $finalSize'),
                const SizedBox(height: 8),
                if (_pickedColors.isNotEmpty)
                  Row(
                    children: [
                      const Text('Colors: '),
                      ..._pickedColors.map((c) => Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          )),
                    ],
                  ),
                const SizedBox(height: 8),
                if (_description.text.trim().isNotEmpty)
                  Text('Description: ${_description.text.trim()}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return AlertDialog(
      title: Text(widget.productDocId != null ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 500, // Make dialog wider for better UX
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
                ),
                const SizedBox(height: 16),
                // Price input with non-removable dollar sign
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    DollarSignTextInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter price';
                    final value = v.trim();
                    if (!value.startsWith('\$')) return 'Price must start with \$';
                    if (value.length < 2) return 'Enter price';
                    final numPart = value.substring(1);
                    if (num.tryParse(numPart) == null) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Quantity input (text field)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter quantity';
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 0) return 'Invalid quantity';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Versatile size selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedSize,
                        hint: const Text('Select size'),
                        items: _sizeOptions
                            .map((size) => DropdownMenuItem(
                                  value: size,
                                  child: Text(size),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSize = value;
                            if (value != 'Custom') {
                              _sizeController.clear();
                            }
                          });
                        },
                      ),
                      if (_selectedSize == 'Custom') ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(
                              labelText: 'Custom size',
                              isDense: true,
                            ),
                            validator: (v) {
                              if (_selectedSize == 'Custom' && (v == null || v.trim().isEmpty)) {
                                return 'Enter custom size';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Colors', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._pickedColors.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final color = entry.value;
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeColor(idx),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            );
                          }),
                          GestureDetector(
                            onTap: _pickColors,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: const Icon(Icons.add, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customColor,
                              decoration: const InputDecoration(
                                labelText: 'Custom Color (hex, e.g. #FF0000)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addCustomColor,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              elevation: 0,
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pictures', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Existing images (for edit)
                          ..._existingImageUrls.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final imgUrl = entry.value;
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage( // Using CachedNetworkImage
                                    imageUrl: imgUrl, // Pass the image URL
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeImage(idx, isExisting: true),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (isWeb)
                            ..._webPickedImages.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final img = entry.value;
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: img.bytes != null
                                        ? Image.memory(
                                              img.bytes!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                        : Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image),
                                            ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeImage(idx),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              );
                            })
                          else
                            ..._pickedImages.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final img = entry.value;
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(img.path),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeImage(idx),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _uploading ? null : _showPreviewDialog,
          child: const Text('Preview'),
        ),
        ElevatedButton(
          onPressed: _uploading
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    List<String> imageUrls = [];
                    if ((kIsWeb && _webPickedImages.isNotEmpty) ||
                        (!kIsWeb && _pickedImages.isNotEmpty)) {
                      imageUrls = await _uploadImages();
                    }
                    // Combine existing and new images for edit, or just new for add
                    final allImages = [
                      ..._existingImageUrls,
                      ...imageUrls,
                    ];
                    String finalSize = '';
                    if (_selectedSize == 'Custom') {
                      finalSize = _sizeController.text.trim();
                    } else {
                      finalSize = _selectedSize ?? '';
                    }
                    // Always save price with dollar sign
                    String priceText = _price.text.trim();
                    if (!priceText.startsWith('\$')) {
                      priceText = '\$$priceText';
                    }
                    if (!mounted) return;
                    Navigator.pop(context, {
                      'name': _name.text.trim(),
                      'price': priceText,
                      'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
                      'size': finalSize,
                      'colors': _pickedColors.map((c) => c.value.toRadixString(16).padLeft(8, '0').toUpperCase()).toList(),
                      'description': _description.text.trim(),
                      'images': allImages,
                      // categoryName will be added in the parent widget when saving
                    });
                  }
                },
          child: Text(widget.productDocId != null ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// Helper class for preview images
class _PreviewImage {
  final String? url;
  final Uint8List? bytes;
  final String? filePath;

  _PreviewImage.network(this.url)
      : bytes = null,
        filePath = null;
  _PreviewImage.memory(this.bytes)
      : url = null,
        filePath = null;
  _PreviewImage.file(this.filePath)
      : url = null,
        bytes = null;
}

class _PreviewImageCarousel extends StatefulWidget {
  final List<_PreviewImage> images;
  const _PreviewImageCarousel({required this.images, super.key});

  @override
  State<_PreviewImageCarousel> createState() => _PreviewImageCarouselState();
}

class _PreviewImageCarouselState extends State<_PreviewImageCarousel> {
  int _currentIndex = 0;

  void _moveLeft() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.images.length) % widget.images.length;
    });
  }

  void _moveRight() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.images[_currentIndex];
    Widget imageWidget;
    if (img.url != null) {
      imageWidget = CachedNetworkImage( // Using CachedNetworkImage for network images
        imageUrl: img.url!,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => Container(
          width: 220,
          height: 220,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 48),
        ),
      );
    } else if (img.bytes != null) {
      // Keep Image.memory for byte-based images
      imageWidget = Image.memory(
        img.bytes!,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
      );
    } else if (img.filePath != null) {
      // Keep Image.file for file-path-based images
      imageWidget = Image.file(
        File(img.filePath!),
        width: 220,
        height: 220,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        width: 220,
        height: 220,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 48),
      );
    }

    // Make the preview carousel bigger: width: 240, height: 240
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
            if (widget.images.length > 1)
              Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: _moveLeft,
                  child: Container(
                    width: 36,
                    height: 220,
                    color: Colors.transparent,
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.chevron_left, size: 36, color: Colors.black54),
                  ),
                ),
              ),
            if (widget.images.length > 1)
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: _moveRight,
                  child: Container(
                    width: 36,
                    height: 220,
                    color: Colors.transparent,
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.chevron_right, size: 36, color: Colors.black54),
                  ),
                ),
              ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (i) => Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentIndex ? Colors.white : Colors.black26,
                        border: Border.all(color: Colors.black26, width: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class DollarSignTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    // Always start with $
    if (!text.startsWith('\$')) {
      text = '\$${text.replaceAll('\$', '')}';
    }
    // Prevent deleting the dollar sign
    if (text == '\$') {
      return TextEditingValue(
        text: '\$',
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    // Keep cursor after the dollar sign if at the start
    int offset = newValue.selection.baseOffset;
    if (offset == 0) offset = 1;
    if (offset > text.length) offset = text.length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}