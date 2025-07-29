import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_view.dart'; // Keep this import if CalendarView is still used elsewhere
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/publiccatalouge_view.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mt_dashboard/ui/widgets/custom_app_bar.dart';
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar

void main() {
  runApp(const DashboardViewDesktop());
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

class DashboardViewDesktop extends StatelessWidget {
  const DashboardViewDesktop({super.key});

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

/// Enum to define the time period for sales analysis.
enum SalesTimePeriod { daily, weekly, monthly }

/// Extension to capitalize the first letter of a string.
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  // A simple state for sidebar expansion, not fully interactive for this example
  bool _isSidebarExpanded = false; // Start minimized

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userId;
  String _userName = 'User'; // Added for storing the user's name
  SalesTimePeriod _selectedPeriod = SalesTimePeriod.daily;

  // Calendar related variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<DateTime> _datesWithMemos = {}; // Stores dates with memos

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        _loadUserName(); // Load user's name when user logs in
        _loadDatesWithMemos(); // Load memos when user logs in
      } else {
        setState(() {
          _userId = null;
          _userName = 'User'; // Reset name if user logs out
          _datesWithMemos.clear(); // Clear memos if user logs out
        });
      }
    });
    _selectedDay = _focusedDay;
  }

  // Function to load the user's name from Firebase
  Future<void> _loadUserName() async {
    if (_userId == null) return;
    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        setState(() {
          _userName = (userDoc.data()?['name'] as String?) ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
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

  /// Groups sales data by the selected time period.
  /// Returns a Map where keys are the specific day/week/month numbers
  /// and values are the total sales for that period.
  Map<int, double> _groupSalesData(List<QueryDocumentSnapshot> docs, SalesTimePeriod period) {
    Map<int, double> groupedData = {};
    final now = DateTime.now();

    if (period == SalesTimePeriod.daily) {
      // Last 7 days, including today
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        groupedData[date.day] = 0.0;
      }
      for (var doc in docs) {
        final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
        final finalTotal = (doc['finalTotal'] as num?)?.toDouble() ?? 0.0;
        if (timestamp != null && timestamp.isAfter(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)))) {
          groupedData.update(timestamp.day, (value) => value + finalTotal, ifAbsent: () => finalTotal);
        }
      }
    } else if (period == SalesTimePeriod.weekly) {
      // Last 12 weeks, including current week.
      for (int i = 0; i < 12; i++) {
        groupedData[i] = 0.0;
      }

      final startOfCurrentWeek = now.subtract(Duration(days: now.weekday - 1));

      for (var doc in docs) {
        final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
        final finalTotal = (doc['finalTotal'] as num?)?.toDouble() ?? 0.0;

        if (timestamp != null) {
          final startOfWeekTimestamp = timestamp.subtract(Duration(days: timestamp.weekday - 1));
          final differenceInDays = startOfCurrentWeek.difference(startOfWeekTimestamp).inDays;
          final weekIndex = (differenceInDays / 7).floor();

          if (weekIndex >= 0 && weekIndex < 12) {
            groupedData.update(11 - weekIndex, (value) => value + finalTotal, ifAbsent: () => finalTotal);
          }
        }
      }
    } else if (period == SalesTimePeriod.monthly) {
      // Last 12 months, including current month.
      for (int i = 0; i < 12; i++) {
        final month = (now.month - i - 1 + 12) % 12 + 1;
        groupedData[month] = 0.0;
      }

      final twelveMonthsAgo = DateTime(now.year - (now.month == 1 ? 1 : 0), now.month == 1 ? 12 : now.month - 1);

      for (var doc in docs) {
        final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
        final finalTotal = (doc['finalTotal'] as num?)?.toDouble() ?? 0.0;
        if (timestamp != null &&
            (timestamp.isAfter(twelveMonthsAgo) || (timestamp.year == twelveMonthsAgo.year && timestamp.month == twelveMonthsAgo.month))) {
          groupedData.update(timestamp.month, (value) => value + finalTotal, ifAbsent: () => finalTotal);
        }
      }
    }
    return groupedData;
  }

  Widget _buildSalesChartCard() {
    return Card(
      color: Colors.grey[100], // Set the card color to grey
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Trend (${_selectedPeriod.name.capitalize()})',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                ToggleButtons(
                  isSelected: SalesTimePeriod.values.map((period) => period == _selectedPeriod).toList(),
                  onPressed: (int index) {
                    setState(() {
                      _selectedPeriod = SalesTimePeriod.values[index];
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  color: Colors.grey[700],
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Daily'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Weekly'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Monthly'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15.0),
            Container(
              height: 300, // Fixed height for the chart
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_userId)
                    .collection('log')
                    .orderBy('timestamp', descending: true) // Order by timestamp for consistent grouping
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading sales data: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No sales data available.'));
                  }

                  final groupedSales = _groupSalesData(snapshot.data!.docs, _selectedPeriod);

                  final List<FlSpot> spots = groupedSales.entries
                      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                      .toList()
                    ..sort((a, b) => a.x.compareTo(a.x));

                  if (spots.isEmpty) {
                    return const Center(child: Text('No data to display for this period.'));
                  }

                  double minY = 0;
                  double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.2;
                  if (maxY == 0) maxY = 10;

                  double minX = spots.first.x;
                  double maxX = spots.last.x; // Corrected: Added 'double' keyword

                  return SalesChart(
                    spots: spots,
                    minY: minY,
                    maxY: maxY,
                    minX: minX,
                    maxX: maxX,
                    selectedPeriod: _selectedPeriod,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15.0),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_userId)
                  .collection('activity')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent activity.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final activity = snapshot.data!.docs[index];
                    final message = activity['message'] as String? ?? 'N/A';
                    final timestamp = (activity['timestamp'] as Timestamp?)?.toDate();
                    final formattedTime = timestamp != null
                        ? '${timestamp.toLocal().hour}:${timestamp.toLocal().minute.toString().padLeft(2, '0')} ${timestamp.toLocal().day}/${timestamp.toLocal().month}/${timestamp.toLocal().year}'
                        : 'N/A';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[500], size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$message at $formattedTime',
                              style: TextStyle(fontSize: 15.0, color: Colors.grey[700]),
                            ),
                          ),
                        ],
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
            child: GestureDetector(
              onTap: () {
                if (_isSidebarExpanded) {
                  setState(() {
                    _isSidebarExpanded = false;
                  });
                }
              },
              child: Column(
                children: [
                  // Main Dashboard Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        // Changed to Row for side-by-side layout
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2, // Adjust flex to give more space to the left card
                            child: Column(
                              children: [
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Search anything...',
                                            prefixIcon: const Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                          ),
                                        ),
                                        const SizedBox(height: 15.0),
                                        Text(
                                          'Hello, $_userName!', // Display user's name
                                          style: TextStyle(
                                            fontSize: 50.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Text(
                                          'Here’s an overview analysis of your business.',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 15.0),
                                        AnalyticsOverview(userId: _userId),
                                        const SizedBox(height: 20.0),
                                        if (_userId != null) _buildSalesChartCard(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24.0), // Spacing between the two main columns
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
                                const SizedBox(height: 20.0), // Spacing below the new card
                                // Start of the new Calendar Card with memo integration
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Calendar',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 15.0),
                                        if (_userId != null) // Only show calendar if user is logged in
                                          TableCalendar(
                                            firstDay: DateTime.utc(2000, 1, 1),
                                            lastDay: DateTime.utc(2050, 12, 31),
                                            focusedDay: _focusedDay,
                                            calendarFormat: _calendarFormat,
                                            selectedDayPredicate: (day) {
                                              return isSameDay(_selectedDay, day);
                                            },
                                            onDaySelected: (selectedDay, focusedDay) {
                                              setState(() {
                                                _selectedDay = selectedDay;
                                                _focusedDay = focusedDay; // update `_focusedDay` here as well
                                              });
                                              // Check if there's a memo for the selected day and show it
                                              if (_datesWithMemos.any((memoDate) => isSameDay(memoDate, selectedDay))) {
                                                _showMemoDialog(context, selectedDay);
                                              }
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
                                              _loadDatesWithMemos(); // Reload memos for the new month
                                            },
                                            headerStyle: const HeaderStyle(
                                              formatButtonVisible: false, // Hide format button
                                              titleCentered: true,
                                            ),
                                            calendarStyle: CalendarStyle(
                                              todayDecoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              selectedDecoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              // markerDecoration is not needed here as we use defaultBuilder
                                              // markerDecoration: const BoxDecoration(
                                              //   color: Colors.red,
                                              //   shape: BoxShape.circle,
                                              // ),
                                            ),
                                            calendarBuilders: CalendarBuilders(
                                              // Custom builder for day content to place marker on top of number
                                              defaultBuilder: (context, day, focusedDay) {
                                                final isMemoDay = _datesWithMemos.any((memoDate) => isSameDay(memoDate, day));
                                                final isSelected = isSameDay(_selectedDay, day);
                                                final isToday = isSameDay(DateTime.now(), day);

                                                return Container(
                                                  margin: const EdgeInsets.all(6.0), // Adjust margin for visual appeal
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isMemoDay
                                                        ? Colors.red // Red background for memo dates
                                                        : isSelected
                                                            ? Theme.of(context).primaryColor
                                                            : isToday
                                                                ? Theme.of(context).primaryColor.withOpacity(0.5)
                                                                : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    '${day.day}',
                                                    style: TextStyle(
                                                      color: isMemoDay || isSelected ? Colors.white : Colors.black, // White text for memo/selected dates
                                                    ),
                                                  ),
                                                );
                                              },
                                              markerBuilder: (context, date, events) {
                                                return null; // Return null to disable default markers, as we handle it in defaultBuilder
                                              },
                                            ),
                                          ),
                                        const SizedBox(height: 20.0), // Spacing between Calendar and Recent Activity
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20.0), // Spacing below the new card
                                // End of the new Calendar Card
                                if (_userId != null) _buildRecentActivityCard(),
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
              isSelected: true,
              isExpanded: isExpanded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DashboardView()),
                );
              }),
          _SidebarNavItem(icon: Icons.inventory, label: 'Catalouges', isExpanded: isExpanded, onTap: () {
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
          _SidebarNavItem(icon: Icons.group, label: 'Members', isExpanded: isExpanded, onTap: () {
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
          _SidebarNavItem(
            icon: Icons.settings,
            label: 'Settings',
            isExpanded: isExpanded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
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

// --- Analytics Overview Widget (Modified to only show metric cards) ---
class AnalyticsOverview extends StatefulWidget {
  final String? userId;
  const AnalyticsOverview({super.key, required this.userId});

  @override
  State<AnalyticsOverview> createState() => _AnalyticsOverviewState();
}

class _AnalyticsOverviewState extends State<AnalyticsOverview> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return const Center(child: Text('Please log in to see analytics.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Row for Total Sales and Total Orders
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Sales',
                icon: Icons.attach_money,
                iconColor: Colors.green,
                stream: _firestore.collection('users').doc(widget.userId).collection('log').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  double totalSales = 0.0;
                  for (var doc in snapshot.data!.docs) {
                    totalSales += (doc['finalTotal'] as num?)?.toDouble() ?? 0.0;
                  }
                  return Text(
                    '\$${totalSales.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  );
                },
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDAB9), Colors.white], // Pastel Orange to white
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 20.0),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Orders',
                icon: Icons.shopping_cart,
                iconColor: Colors.orange,
                stream: _firestore.collection('users').doc(widget.userId).collection('log').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return Text(
                    snapshot.data!.docs.length.toString(),
                    style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  );
                },
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6E6FA), Colors.white], // Pastel Purple to white
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0), // Spacing between the two rows of metric cards
        // Second Row for Total Members and Active Coupons
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Members',
                icon: Icons.group,
                iconColor: Colors.blue,
                stream: _firestore.collection('users').doc(widget.userId).collection('members').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return Text(
                    snapshot.data!.docs.length.toString(),
                    style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  );
                },
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6E6FA), Colors.white], // Pastel Purple to white
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 20.0),
            Expanded(
              child: _buildMetricCard(
                title: 'Active Coupons',
                icon: Icons.local_offer,
                iconColor: Colors.purple,
                stream: _firestore.collection('users').doc(widget.userId).collection('promo_coupons').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  int activeCoupons = 0;
                  final now = Timestamp.now();
                  for (var doc in snapshot.data!.docs) {
                    final isActive = doc['isActive'] as bool? ?? false;
                    final expiryDate = doc['expiryDate'] as Timestamp?;
                    if (isActive && (expiryDate == null || expiryDate.toDate().isAfter(now.toDate()))) {
                      activeCoupons++;
                    }
                  }
                  return Text(
                    activeCoupons.toString(),
                    style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  );
                },
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6E6FA), Colors.white], // Pastel Purple to white
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Stream<QuerySnapshot> stream,
    required Widget Function(BuildContext, AsyncSnapshot<QuerySnapshot>) builder,
    required LinearGradient gradient, // Added gradient parameter
  }) {
    return Card(
      child: Container(
        // Wrap with Container to apply gradient
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0), // Match Card's border radius
          gradient: gradient,
        ),
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
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Icon(icon, color: iconColor, size: 30.0),
                ],
              ),
              const SizedBox(height: 10.0),
              StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: builder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final double minX;
  final double maxX;
  final SalesTimePeriod selectedPeriod;

  const SalesChart({
    super.key,
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                String text;
                int xValueInt = value.toInt();

                switch (selectedPeriod) {
                  case SalesTimePeriod.daily:
                    text = '$xValueInt';
                    break;
                  case SalesTimePeriod.weekly:
                    text = 'Wk ${xValueInt + 1}';
                    break;
                  case SalesTimePeriod.monthly:
                    text = _getMonthAbbreviation(xValueInt);
                    break;
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8.0,
                  child: Text(text, style: const TextStyle(color: Color(0xff68737d), fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}', style: const TextStyle(color: Color(0xff67727d), fontSize: 10));
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a month abbreviation for a given month number (1-12).
  String _getMonthAbbreviation(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }
}