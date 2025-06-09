import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/view_store.dart';
import 'dart:ui';

import 'package:mt_dashboard/ui/views/home/home_view.dart';

class DashboardViewDesktop extends StatefulWidget {
  const DashboardViewDesktop({super.key});

  @override
  State<DashboardViewDesktop> createState() => _DashboardViewDesktopState();
}

class _DashboardViewDesktopState extends State<DashboardViewDesktop>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showHelpCentrePanel = false;
  late AnimationController _panelController;
  late Animation<Offset> _panelOffset;

  final List<Widget> _pages = [
    ViewStore(),
    Catalouge(),
    Orders(),
    ViewStore(),
    // Remove Sync Global Product Data page from here, as it will be a popup
    // Remove Help and Support page from here, as it will be a popup
  ];

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _panelOffset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _onSidebarIndexChanged(int index) {
    if (index == 5) {
      setState(() {
        _showHelpCentrePanel = true;
      });
      _panelController.forward();
    } else if (index == 4) {
      // Sync Global Product Data popup
      showDialog(
        context: context,
        builder: (context) => const _SyncGlobalProductDialog(),
      );
    } else {
      setState(() {
        _selectedIndex = index;
        _showHelpCentrePanel = false;
      });
      _panelController.reverse();
    }
  }

  void _closeHelpCentrePanel() {
    _panelController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showHelpCentrePanel = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove appBar from Scaffold, move it into the Stack so it can be blurred
      body: Stack(
        children: [
          // Main content (including app bar)
          Column(
            children: [
              _DashboardAppBar(),
              Expanded(
                child: Row(
                  children: [
                    _Sidebar(
                      selectedIndex: _selectedIndex,
                      onIndexChanged: _onSidebarIndexChanged,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Blur effect when panel is open
          if (_showHelpCentrePanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeHelpCentrePanel,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          // Slide-in Help Centre Side Panel (covers everything)
          if (_showHelpCentrePanel)
            Positioned.fill(
              child: SlideTransition(
                position: _panelOffset,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HelpCentreSidePanel(onClose: _closeHelpCentrePanel),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.blueGrey,
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Image.asset(
              'assets/images/placeholder.png',
              height: 64,
              width: 64,
            ),
            const SizedBox(width: 12),
            const Text('Dashboard', style: TextStyle(color: Colors.white)),
            const Spacer(),
            TextButton(
                onPressed: () {
                // Set the main content to ViewStore and show overview in ViewStore
                final dashboardState = context.findAncestorStateOfType<_DashboardViewDesktopState>();
                if (dashboardState != null) {
                  // ignore: invalid_use_of_protected_member
                  dashboardState.setState(() {
                  dashboardState._selectedIndex = 0;
                  });
                  // If ViewStore supports showing overview, you can trigger it here.
                  // For example, if ViewStore has a static method or callback, call it.
                  // Otherwise, you may need to use a callback or state management.
                }
                },
              child: const Text('View Store', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('New Updates', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  if (user == null) {
                    return const Text('Guest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));
                  }
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading company...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading company', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));
                    }
                    final companyName = snapshot.data?.data()?['companyName'] as String? ?? 'No Company';
                    return Text(
                      companyName,
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    );
                    },
                  );
                  },
                ),
                FutureBuilder(
                  future: Future.value(FirebaseAuth.instance.currentUser?.email),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading email...', style: TextStyle(color: Colors.white70, fontSize: 12));
                    }
                    if (snapshot.hasError) {
                      return const Text('Error loading email', style: TextStyle(color: Colors.white70, fontSize: 12));
                    }
                    return Text(
                      snapshot.data ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 24),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  // Optionally navigate to login page or show a message
                    Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeView()),
                  ); 
                });
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const _Sidebar({
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _isExpanded = false;

  final List<_SidebarItem> _items = [
    _SidebarItem(icon: Icons.store, label: 'View Store'),
    _SidebarItem(icon: Icons.list_alt, label: 'Catalogues'),
    _SidebarItem(icon: Icons.shopping_cart, label: 'Orders'),
    _SidebarItem(icon: Icons.settings, label: 'Account Settings'),
    _SidebarItem(icon: Icons.sync, label: 'Sync Global Product Data'),
    _SidebarItem(icon: Icons.help, label: 'Help Centre'),
    _SidebarItem(icon: Icons.support_agent, label: 'Help and Support'),
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isExpanded ? 260 : 40,
        color: Colors.grey[200],
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Main navigation items (excluding Help Centre and Help and Support)
            ...List.generate(_items.length - 2, (index) {
              if (index == 4) {
                // Sync Global Product Data as a button (not navigation)
                return _buildSyncGlobalProductButton(index);
              }
              return _buildSidebarButton(index);
            }),
            const Spacer(),
            // Help Centre button (second last)
            _buildSidebarButton(_items.length - 2),
            // Help and Support button (last)
            _buildHelpAndSupportButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarButton(int index) {
    final item = _items[index];
    final isSelected = widget.selectedIndex == index && index != 5;
    final isHelpCentre = index == 5;
    return Material(
      color: (isSelected || (isHelpCentre && widget.selectedIndex == 5)) ? Colors.blue[100] : Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onIndexChanged(index);
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(item.icon, color: (isSelected || (isHelpCentre && widget.selectedIndex == 5)) ? Colors.blue : Colors.black54),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: (isSelected || (isHelpCentre && widget.selectedIndex == 5)) ? Colors.blue : Colors.black87,
                      fontWeight: (isSelected || (isHelpCentre && widget.selectedIndex == 5)) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncGlobalProductButton(int index) {
    final item = _items[index];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onIndexChanged(index);
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.black54),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpAndSupportButton() {
    final item = _items.last;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _HelpAndSupportDialog(),
          );
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.black54),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncGlobalProductDialog extends StatelessWidget {
  const _SyncGlobalProductDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Sync global product data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download Template'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                // Add download template logic here
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart, color: Colors.green),
              label: const Text('Update Products by SKU'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontSize: 16),
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                // Add update products by SKU logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCentreSidePanel extends StatelessWidget {
  final VoidCallback onClose;

  const _HelpCentreSidePanel({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: Container(
        width: 400,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onClose,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Learn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Add your Help Centre content here
            const Text(
              'Welcome to the Help Centre!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Here you can find guides, FAQs, and resources to help you use the dashboard.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.blue),
              title: const Text('Knowledge centre'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // Add navigation or link logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // Add email logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
              title: const Text('Chat'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // Add chat logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Phone'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // Add phone logic here
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpAndSupportDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Help and support',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _HelpLink(
              icon: Icons.menu_book,
              label: 'Knowledge centre',
              onTap: () {
                // Add your navigation or link logic here
                Navigator.of(context).pop();
              },
            ),
            _HelpLink(
              icon: Icons.email,
              label: 'Email',
              onTap: () {
                // Add your email logic here
                Navigator.of(context).pop();
              },
            ),
            _HelpLink(
              icon: Icons.chat,
              label: 'Chat',
              onTap: () {
                // Add your chat logic here
                Navigator.of(context).pop();
              },
            ),
            _HelpLink(
              icon: Icons.phone,
              label: 'Phone',
              onTap: () {
                // Add your phone logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HelpLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});
}