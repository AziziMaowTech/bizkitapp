import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// These imports are from your original code, ensure they are correctly mapped
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Crucial for a Column inside SingleChildScrollView
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Crucial for a Row inside a Column that's mainAxisSize.min
                          children: [
                            const Expanded( // This Expanded is now safely within a Column/Row with mainAxisSize.min, which will work.
                              flex: 1,
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
          _SidebarNavItem(icon: Icons.calendar_month, label: 'Calendar', isSelected: true, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CalendarViewDesktop()),
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
          const Spacer(),
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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeView()),
            );
          }),
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

class CalendarCard extends StatefulWidget {
  const CalendarCard({super.key});

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _datesWithMemos = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadDatesWithMemos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDatesWithMemos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('calendar')
          .get();

      setState(() {
        _datesWithMemos = snapshot.docs
            .map((doc) => DateTime.parse(doc.id))
            .toSet();
      });
    }
  }

  // --- FIX: _showSnackBar now correctly checks if widget is mounted ---
  void _showSnackBar(BuildContext context, String message) {
    if (mounted) { // Ensure the widget (CalendarCardState) is still in the tree before using its context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Function to show memo management dialog for a new memo (from calendar date tap)
  void _showMemoManagementDialogForDate(BuildContext context, DateTime date) {
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
          onMemoUpdated: () {
            _loadDatesWithMemos();
          },
          onShowSnackBar: (message) {
            _showSnackBar(context, message);
          },
          initialMemoId: null,      // No initial ID for new memo
          initialMemoText: null,  // No initial text for new memo
        );
      },
    );
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
          initialMemoId: memoId,      // Pass existing memo ID
          initialMemoText: memoText,  // Pass existing memo text
          onMemoUpdated: () {
            _loadDatesWithMemos();
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 4.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      // --- FIX: The CalendarCard itself is now a SingleChildScrollView ---
      // This ensures that the content inside CalendarCard can scroll if it exceeds available height.
      // This is the most common and robust pattern for complex cards within a flexible layout.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.min is often implicit in SingleChildScrollView's child,
          // but explicit can help clarify intention.
          mainAxisSize: MainAxisSize.min, // Added for clarity and robustness within SingleChildScrollView
          children: [
            Text(
              'Calendar & Memos',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16.0),
            TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
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
                _showMemoManagementDialogForDate(context, selectedDay);
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadDatesWithMemos();
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (_datesWithMemos.any((savedDate) => isSameDay(savedDate, date))) {
                    return Positioned(
                      bottom: 1.0,
                      child: Container(
                        width: 5.0,
                        height: 5.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue[300],
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(color: Colors.grey[800]),
                weekendTextStyle: TextStyle(color: Colors.red[700]),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey[600]),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey[600]),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.grey[800]),
                weekendStyle: TextStyle(color: Colors.red[700]),
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              'View all memos (Present & Future)',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8.0),
            // --- FIX: Removed Expanded. ListView.builder must now manage its own scrolling properties. ---
            // It will also correctly shrink-wrap due to its parent Column having mainAxisSize.min
            // and the outer SingleChildScrollView.
            user == null
                ? const Text('Please log in to view memos.', style: TextStyle(color: Colors.grey))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('memos')
                        .where('userId', isEqualTo: user.uid)
                        .where('memoAssociatedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday)) // Filter by memoAssociatedDate
                        .orderBy('memoAssociatedDate', descending: false) // Primary sort by associated date
                        .orderBy('timestamp', descending: false) // Secondary sort by creation/update time
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        print('Firestore Query Error: ${snapshot.error}');
                        return Center(child: Text('Error loading memos. Check console for details.'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No present or future memos found.'));
                      }

                      final memos = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true, // Crucial for ListView within a Column (that is in a SingleChildScrollView)
                        physics: const NeverScrollableScrollPhysics(), // Prevent independent scrolling for this nested list
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
                                        style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
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

class _MemoDialog extends StatefulWidget {
  final DateTime selectedDate;
  final String userId;
  final VoidCallback onMemoUpdated;
  final Function(String message) onShowSnackBar;
  final String? initialMemoId;
  final String? initialMemoText;

  const _MemoDialog({
    required this.selectedDate,
    required this.userId,
    required this.onMemoUpdated,
    required this.onShowSnackBar,
    this.initialMemoId,
    this.initialMemoText,
  });

  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<_MemoDialog> {
  final TextEditingController _memoInputController = TextEditingController();
  String? _currentEditingMemoId;

  @override
  void initState() {
    super.initState();
    if (widget.initialMemoText != null) {
      _memoInputController.text = widget.initialMemoText!;
      _currentEditingMemoId = widget.initialMemoId;
    }
  }

  @override
  void dispose() {
    _memoInputController.dispose();
    super.dispose();
  }

  void _triggerSnackBar(String message) {
    widget.onShowSnackBar(message); // This calls the parent's (CalendarCard's) snackbar function
  }

  Future<void> _addMemo() async {
    if (_memoInputController.text.trim().isEmpty) {
      _triggerSnackBar('Memo cannot be empty.');
      return;
    }

    try {
      final dateDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('calendar')
          .doc(widget.selectedDate.toString().split(' ')[0]);

      await dateDocRef.set({}, SetOptions(merge: true));

      await dateDocRef.collection('memos').add({
        'text': _memoInputController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': widget.userId,
        'memoAssociatedDate': Timestamp.fromDate(widget.selectedDate),
      });
      _memoInputController.clear();
      _triggerSnackBar('Memo added!');
      widget.onMemoUpdated();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _triggerSnackBar('Failed to add memo: $e');
    }
  }

  Future<void> _updateMemo() async {
    if (_currentEditingMemoId == null) return;
    if (_memoInputController.text.trim().isEmpty) {
      _triggerSnackBar('Memo cannot be empty.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('calendar')
          .doc(widget.selectedDate.toString().split(' ')[0])
          .collection('memos')
          .doc(_currentEditingMemoId)
          .update({
        'text': _memoInputController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'memoAssociatedDate': Timestamp.fromDate(widget.selectedDate),
      });
      _memoInputController.clear();
      setState(() {
        _currentEditingMemoId = null;
      });
      _triggerSnackBar('Memo updated!');
      widget.onMemoUpdated();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _triggerSnackBar('Failed to update memo: $e');
    }
  }

  Future<void> _deleteMemo() async {
    if (_currentEditingMemoId == null) return;

    try {
      final dateDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('calendar')
          .doc(widget.selectedDate.toString().split(' ')[0]);

      await dateDocRef.collection('memos').doc(_currentEditingMemoId).delete();

      final remainingMemos = await dateDocRef.collection('memos').get();
      if (remainingMemos.docs.isEmpty) {
        await dateDocRef.delete();
      }

      _triggerSnackBar('Memo deleted!');
      widget.onMemoUpdated();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _triggerSnackBar('Failed to delete memo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _currentEditingMemoId == null
              ? 'Add Memo for ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}'
              : 'Edit Memo for ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _memoInputController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _currentEditingMemoId == null ? 'Enter new memo...' : 'Edit memo...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentEditingMemoId == null ? _addMemo : _updateMemo,
                  child: Text(_currentEditingMemoId == null ? 'Add Memo' : 'Update Memo'),
                ),
                if (_currentEditingMemoId != null)
                  ElevatedButton(
                    onPressed: _deleteMemo,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete Memo'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Other Memos for this Date:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('calendar')
                    .doc(widget.selectedDate.toString().split(' ')[0])
                    .collection('memos')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No other memos for this date.'));
                  }

                  final memos = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: memos.length,
                    itemBuilder: (context, index) {
                      final memoDoc = memos[index];
                      final memoId = memoDoc.id;
                      final memoData = memoDoc.data() as Map<String, dynamic>;
                      final memoText = memoData['text'] ?? 'No text';
                      final memoTimestamp = (memoData['timestamp'] as Timestamp?)?.toDate();

                      if (memoId == _currentEditingMemoId && _currentEditingMemoId != null) {
                         return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(memoText),
                          subtitle: memoTimestamp != null
                              ? Text(DateFormat('HH:mm').format(memoTimestamp))
                              : null,
                          onTap: () {
                             setState(() {
                               _memoInputController.text = memoText;
                               _currentEditingMemoId = memoId;
                             });
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
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}