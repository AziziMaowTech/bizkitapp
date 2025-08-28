import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// These imports are from your original code, ensure they are correctly mapped
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
import 'package:mt_dashboard/ui/widgets/custom_app_bar.dart';
// Importing TableCalendar
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For date formatting in UI

void main() {
  runApp(const CalendarViewDesktop());
}

// --- User Dropdown Card Widget from dashboard_view.desktop.dart ---
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

class CalendarViewDesktop extends StatelessWidget {
  const CalendarViewDesktop({super.key});

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
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.blue, width: 1.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
      home: const CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2, // Adjust flex to give more space to the left card
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Align to the left
                                children: [
                                  Text(
                                    'Calendar',
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
                                          userId: FirebaseAuth.instance.currentUser?.uid,
                                          firestore: FirebaseFirestore.instance,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // New card for memos on the left
                            Expanded(
                              flex: 1,
                              child: MemosCard(),
                            ),
                            SizedBox(width: 24.0), // Spacer between the cards
                            // Existing Calendar card on the right
                            Expanded(
                              flex: 2,
                              child: CalendarCard(),
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
        isSelected: true, // This is the selected item
        isExpanded: isExpanded,
        onTap: () {
          // Already on this page
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

// New MemosCard widget
class MemosCard extends StatefulWidget {
  const MemosCard({super.key});

  @override
  State<MemosCard> createState() => _MemosCardState();
}

class _MemosCardState extends State<MemosCard> {
  // --- FIX: _showSnackBar now correctly checks if widget is mounted ---
  void _showSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Function to show memo management dialog for an EXISTING memo (from list tap)
  void _showMemoManagementDialogForExistingMemo(
      BuildContext context, DateTime date, String memoId, String memoText) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(context, 'Please log in to manage memos.');
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _MemoDialog(
          selectedDate: date,
          userId: user.uid,
          initialMemoId: memoId,
          initialMemoText: memoText,
          onMemoUpdated: () {
            // This function is for memos, so it doesn't need to do anything with the calendar
          },
          onShowSnackBar: (message) {
            _showSnackBar(context, message);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final DateTime startOfToday = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Memos',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'View all memos (Present & Future)',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8.0),
            user == null
                ? const Text('Please log in to view memos.', style: TextStyle(color: Colors.grey))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('memos')
                        .where('userId', isEqualTo: user.uid)
                        .where('memoAssociatedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
                        .orderBy('memoAssociatedDate', descending: false)
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        print('Firestore Query Error: ${snapshot.error}');
                        return const Center(child: Text('Error loading memos. Check console for details.'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No present or future memos found.'));
                      }
                      final memos = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: memos.length,
                        itemBuilder: (context, index) {
                          final memoDoc = memos[index];
                          final memoId = memoDoc.id;
                          final memoData = memoDoc.data() as Map<String, dynamic>;
                          final memoText = memoData['text'] ?? 'No text';
                          final memoAssociatedDateTimestamp = memoData['memoAssociatedDate'] as Timestamp?;
                          DateTime? memoDisplayDate;
                          if (memoAssociatedDateTimestamp != null) {
                            memoDisplayDate = memoAssociatedDateTimestamp.toDate();
                          } else {
                            final List<String> pathSegments = memoDoc.reference.path.split('/');
                            if (pathSegments.length >= 4) {
                              try {
                                memoDisplayDate = DateTime.parse(pathSegments[3]);
                              } catch (e) {
                                print('Error parsing date from path segment (fallback): $e');
                                memoDisplayDate = DateTime.now();
                              }
                            } else {
                              print('Path segments not as expected (fallback): ${memoDoc.reference.path}');
                              memoDisplayDate = DateTime.now();
                            }
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: InkWell(
                              onTap: () {
                                if (memoDisplayDate != null) {
                                  _showMemoManagementDialogForExistingMemo(
                                    context,
                                    memoDisplayDate,
                                    memoId,
                                    memoText,
                                  );
                                } else {
                                  _showSnackBar(context, "Could not identify memo date for editing.");
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        memoDisplayDate != null ? DateFormat('dd/MM/yyyy :').format(memoDisplayDate) : 'Unknown Date',
                                        style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        memoText,
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// New CalendarCard widget
class CalendarCard extends StatefulWidget {
  const CalendarCard({super.key});

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<DateTime> _datesWithMemos = {}; // Stores dates with memos
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        _loadDatesWithMemos(); // Load memos when user logs in
      } else {
        setState(() {
          _userId = null;
          _datesWithMemos.clear(); // Clear memos if user logs out
        });
      }
    });
    _selectedDay = _focusedDay;
  }

  // Function to load dates with memos from Firebase
  Future<void> _loadDatesWithMemos() async {
    if (_userId == null) return;
    try {
      // Get all date documents in the 'calendar' collection
      final calendarSnapshot = await _firestore.collection('users').doc(_userId).collection('calendar').get();
      setState(() {
        _datesWithMemos.clear();
        for (var dateDoc in calendarSnapshot.docs) {
          final formattedDate = dateDoc.id; // e.g., '2025-07-24'
          // Check if the 'memos' subcollection under this date document has any documents
          _firestore.collection('users').doc(_userId).collection('calendar').doc(formattedDate).collection('memos').limit(1).get().then((memoSnapshot) {
            if (memoSnapshot.docs.isNotEmpty) {
              try {
                final date = DateTime.parse(formattedDate);
                // Ensure we only add the date once even if multiple memos exist
                if (!_datesWithMemos.contains(date)) {
                  setState(() {
                    _datesWithMemos.add(date);
                  });
                }
              } catch (e) {
                print('Error parsing date from doc ID $formattedDate: $e');
              }
            }
          });
        }
      });
    } catch (e) {
      print('Error loading dates with memos: $e');
    }
  }

  // Function to show memo content in a dialog
  Future<void> _showMemoDialog(BuildContext context, DateTime date) async {
    if (_userId == null) return;

    // Format the date to match your Firestore document ID format (e.g., '2023-10-27')
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      // Access the 'memos' subcollection under the specific date document
      final memosSnapshot = await _firestore.collection('users').doc(_userId).collection('calendar').doc(formattedDate).collection('memos').limit(1).get();

      String memoContent = 'No memo for this date.';
      if (memosSnapshot.docs.isNotEmpty) {
        // Get the data from the first memo document found
        final memoData = memosSnapshot.docs.first.data();
        // Retrieve the 'text' field, as per your specified structure
        memoContent = (memoData['text'] as String?) ?? 'No memo content found.';
      }

      if (!context.mounted) return; // Check if the widget is still mounted before showing dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Memo for $formattedDate'),
            content: SingleChildScrollView(
              child: Text(memoContent),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching memo: $e');
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load memo: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16.0),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showMemoDialog(context, selectedDay);
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return _datesWithMemos.any((date) => isSameDay(date, day)) ? ['memo'] : [];
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                markerSize: 5.0,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New MemoDialog widget
class _MemoDialog extends StatefulWidget {
  final DateTime selectedDate;
  final String userId;
  final String? initialMemoId;
  final String? initialMemoText;
  final VoidCallback onMemoUpdated;
  final Function(String) onShowSnackBar;

  const _MemoDialog({
    super.key,
    required this.selectedDate,
    required this.userId,
    this.initialMemoId,
    this.initialMemoText,
    required this.onMemoUpdated,
    required this.onShowSnackBar,
  });

  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<_MemoDialog> {
  final _memoController = TextEditingController();
  bool _isEditing = false;
  String _dialogTitle = '';
  bool _isSaving = false;
  bool _isLoading = true;
  String _memoId = '';

  @override
  void initState() {
    super.initState();
    _dialogTitle = 'Add Memo';
    if (widget.initialMemoId != null && widget.initialMemoText != null) {
      _memoController.text = widget.initialMemoText!;
      _memoId = widget.initialMemoId!;
      _isEditing = true;
      _dialogTitle = 'Edit Memo';
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    if (_memoController.text.trim().isEmpty) {
      widget.onShowSnackBar('Memo text cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final formattedDate = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';
    final userCalendarCollection = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('calendar');

    try {
      if (_isEditing) {
        // Update existing memo
        final memoRef = userCalendarCollection.doc(formattedDate).collection('memos').doc(_memoId);
        await memoRef.update({
          'text': _memoController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'memoAssociatedDate': Timestamp.fromDate(widget.selectedDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)), // Store date at midnight UTC
        });
        widget.onShowSnackBar('Memo updated successfully!');
      } else {
        // Add new memo
        final memoRef = userCalendarCollection.doc(formattedDate).collection('memos').doc();
        await memoRef.set({
          'text': _memoController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'memoAssociatedDate': Timestamp.fromDate(widget.selectedDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)),
          'userId': widget.userId,
        });
        widget.onShowSnackBar('Memo added successfully!');
      }
      widget.onMemoUpdated();
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Error saving memo: $e');
      widget.onShowSnackBar('Failed to save memo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteMemo() async {
    if (!_isEditing) return; // Can only delete an existing memo

    setState(() {
      _isSaving = true;
    });

    final formattedDate = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';
    final userCalendarCollection = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('calendar');

    try {
      final memoRef = userCalendarCollection.doc(formattedDate).collection('memos').doc(_memoId);
      await memoRef.delete();
      widget.onShowSnackBar('Memo deleted successfully!');

      // Check if the date document is empty and delete it if so
      final memosSnapshot = await userCalendarCollection.doc(formattedDate).collection('memos').get();
      if (memosSnapshot.docs.isEmpty) {
        await userCalendarCollection.doc(formattedDate).delete();
      }

      widget.onMemoUpdated();
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Error deleting memo: $e');
      widget.onShowSnackBar('Failed to delete memo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }
    return AlertDialog(
      title: Text(_dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'Memo',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (_isEditing)
          TextButton(
            onPressed: _isSaving ? null : _deleteMemo,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveMemo,
          child: _isSaving ? const CircularProgressIndicator() : Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}