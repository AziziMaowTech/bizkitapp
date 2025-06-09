import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/overview.dart';
import 'package:mt_dashboard/ui/views/home/home_view.dart';

// Import your page widgets here
import 'pl.dart';

class ViewStore extends StatefulWidget {
  const ViewStore({super.key});

  @override
  State<ViewStore> createState() => _ViewStoreState();
}

class _ViewStoreState extends State<ViewStore> {
  final List<String> _titles = [
    'Basic',
    'Content and layout',
    'Settings',
    'Marketing',
    'More',
    'Account',
  ];

  // Button names, icons, and subtexts for each section
  final List<List<Map<String, dynamic>>> _buttonData = [
    [
      {'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Guest', 'icon': Icons.dashboard, 'subtext': '${FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Phone Number'}\n${FirebaseAuth.instance.currentUser?.email ?? 'Email'}'},
      {'name': 'Domain', 'icon': Icons.public, 'subtext': 'Connect and manage your domain'},
      {'name': 'Payment gateway settings', 'icon': Icons.attach_money, 'subtext': 'Manage payment options'},
      {'name': 'Shipping cost settings', 'icon': Icons.store, 'subtext': 'Collect shipping costs from customers'},
    ],
    [
      {'name': 'Custom themes', 'icon': Icons.brush, 'subtext': 'Create custom themes for your catalogues'},
      {'name': 'Product grid tile', 'icon': Icons.dashboard, 'subtext': 'Create custom product grid tiles for your website'},
      {'name': 'Product list tile', 'icon': Icons.list, 'subtext': 'Create custom product lists tile for your website'},
      {'name': 'Catalogue grid tile', 'icon': Icons.card_giftcard, 'subtext': 'Create custom catalogue grid tile for your website'},
      {'name': 'Pages', 'icon': Icons.slideshow, 'subtext': 'Add pages like privacy policy, terms and conditions,refund and exchange policy, etc.'},
      {'name': 'Custom front page', 'icon': Icons.arrow_forward_ios, 'subtext': 'Design your front page'},
      {'name': 'Custom website footer', 'icon': Icons.view_list, 'subtext': 'Design your website footer'},
      {'name': 'Custom website fonts', 'icon': Icons.view_headline, 'subtext': 'Set custom fonts for your website'},
      {'name': 'Menu builder', 'icon': Icons.info_outline, 'subtext': 'Design your website menu'},
      {'name': 'Product options', 'icon': Icons.info_outline, 'subtext': 'Add and manage variants for your products'},
      {'name': 'Metal rates', 'icon': Icons.list, 'subtext': 'Add and manage metal rates'},
      {'name': 'Custom fields', 'icon': Icons.grid_view, 'subtext': 'Add and manage custom fields for your products'},
      {'name': 'Webhooks', 'icon': Icons.grid_on, 'subtext': 'Manage your webhooks settings'},
      {'name': 'Jewellery price display', 'icon': Icons.visibility, 'subtext': 'Manage jewellery price display settings'},
    ],
    [
      {'name': 'Taxes', 'icon': Icons.settings, 'subtext': 'Apply or add taxes for your products'},
      {'name': 'Inventory settings', 'icon': Icons.local_shipping, 'subtext': 'Manage your inventory settings at a global level'},
      {'name': 'Language settings', 'icon': Icons.location_on, 'subtext': 'Use BizKitin your language'},
      {'name': 'Catalogue settings', 'icon': Icons.local_shipping, 'subtext': 'Manage your catalogue settings'},
      {'name': 'Checkout settings', 'icon': Icons.local_shipping, 'subtext': 'Manage your checkout settings'},
      {'name': 'Product type settings', 'icon': Icons.location_city, 'subtext': 'Select your company wide product type'},
      {'name': 'Developer API', 'icon': Icons.attach_money, 'subtext': 'Integrate BizKit with 3rd party software using our public API'},
      {'name': 'Privacy settings', 'icon': Icons.payment, 'subtext': 'Manage your privacy settings'},
    ],
    [
      {'name': 'Coupons', 'icon': Icons.campaign, 'subtext': 'Create coupons for your customers'},
      {'name': 'Reports', 'icon': Icons.email, 'subtext': 'Access your sales reports and metrics'},
      {'name': 'Facebook pixel', 'icon': Icons.email, 'subtext': 'Connect your Facebook pixel to retarget and run Facebook ads for tracking'},
      {'name': 'Google analytics', 'icon': Icons.analytics, 'subtext': 'Connect Google Analytics to track people who visit your catalouge'},
      {'name': 'Google search console', 'icon': Icons.tag, 'subtext': 'Google search setting'},
    ],
    [
      {'name': 'Become a BizKit partner', 'icon': Icons.help_outline, 'subtext': 'Sell BizKit in your local region and earn 15% commission'},
      {'name': 'Refer BizKit to a friend', 'icon': Icons.info, 'subtext': 'Get rewards for each friend who joins'},
      {'name': 'New Updates', 'icon': Icons.contact_mail, 'subtext': 'Learn about our latest updates and new feature launches'},
      {'name': 'About us', 'icon': Icons.support, 'subtext': 'More information about BizKit app'},
      {'name': 'Help us translate', 'icon': Icons.feedback, 'subtext': 'Help us translate BizKit app in your native language'},
    ],
    [
      {'name': 'Logout', 'icon': Icons.logout, 'subtext': 'Logout from your account'},
      {'name': 'Delete account', 'icon': Icons.delete, 'subtext': 'Delete your account permanently'},
    ],
  ];

  // Each section has its own list of page widgets from pl.dart
  final List<List<Widget>> _sectionPages = [
    [Overview(), Placeholder1(), Placeholder1(), Placeholder1()],
    [Placeholder1(), Placeholder1(), Placeholder1()],
    [Placeholder1(), Placeholder1(), Placeholder1()],
    [Placeholder1(), Placeholder1(), Placeholder1()],
    [Placeholder1(), Placeholder1(), Placeholder1()],
    [const SizedBox.shrink(), const SizedBox.shrink()],
  ];

  int _selectedSection = 0;
  int _selectedButton = 0;

  final ScrollController _scrollController = ScrollController();

  // Helper to calculate the offset for a section
  double _calculateSectionOffset(int sectionIndex) {
    double offset = 0;
    for (int i = 0; i < sectionIndex; i++) {
      // Header + buttons + divider
      offset += 48 + (_buttonData[i].length * 64.0) + 1;
    }
    return offset;
  }

  // Helper to calculate the offset for a button in a section
  double _calculateButtonOffset(int sectionIndex, int buttonIndex) {
    double offset = _calculateSectionOffset(sectionIndex);
    offset += 48; // header
    offset += buttonIndex * 64.0;
    return offset;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int sectionIndex) {
    final offset = _calculateSectionOffset(sectionIndex);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToButton(int sectionIndex, int buttonIndex) {
    final offset = _calculateButtonOffset(sectionIndex, buttonIndex);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleSignoutButtonTap(int btnIdx) async {
    if (btnIdx == 0) {
      // Logout
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } else if (btnIdx == 1) {
      // Delete account logic here
      // TODO: Implement delete account
    }
  }

  Future<void> _handleAccountButtonTap(int sectionIndex, int buttonIndex) async {
    final TextEditingController _captchaController = TextEditingController();
    // Generate a simple 4-digit captcha
    final String captcha = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to permanently delete your account? This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Enter captcha: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(captcha, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _captchaController,
                decoration: const InputDecoration(
                  labelText: 'Captcha',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_captchaController.text.trim() == captcha) {
                  try {
                    // Delete user document from Firestore before deleting the account
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Import this at the top: import 'package:cloud_firestore/cloud_firestore.dart';
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                      await user.delete();
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    Navigator.of(context).pop(false);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Captcha incorrect.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main Sidebar
        Container(
          width: 240,
          color: Colors.grey[200],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                child: Text(
                  'Configure',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...List.generate(_titles.length, (index) {
                return Container(
                  color: _selectedSection == index
                      ? Colors.grey[400]
                      : Colors.transparent,
                  child: ListTile(
                    title: Text(_titles[index]),
                    selected: _selectedSection == index,
                    selectedTileColor: Colors.white,
                    onTap: () {
                      setState(() {
                        _selectedSection = index;
                        _selectedButton = 0; // Reset button selection
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToSection(index);
                      });
                    },
                  ),
                );
              }),
              const Spacer(),
            ],
          ),
        ),
        // Second Navigation Bar (Buttons with icons and subtext)
        Container(
          width: 280,
          color: Colors.grey[100],
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _titles.length,
            itemBuilder: (context, sectionIndex) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header (not clickable, never highlighted)
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    alignment: Alignment.center,
                    height: 48,
                    child: Text(
                      _titles[sectionIndex],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Column(
                    children: List.generate(
                      _buttonData[sectionIndex].length,
                      (btnIdx) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isAccountSection = sectionIndex == _titles.length - 1;
                            return Material(
                              color: (_selectedSection == sectionIndex && _selectedButton == btnIdx)
                                  ? Colors.blue[100]
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () async {
                                  setState(() {
                                  _selectedSection = sectionIndex;
                                  _selectedButton = btnIdx;
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollToButton(sectionIndex, btnIdx);
                                  });
                                  if (isAccountSection) {
                                  if (btnIdx == 0) {
                                    _handleSignoutButtonTap(btnIdx);
                                  } else if (btnIdx == 1) {
                                    _handleAccountButtonTap(sectionIndex, btnIdx);
                                  }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _buttonData[sectionIndex][btnIdx]['icon'],
                                        color: (_selectedSection == sectionIndex && _selectedButton == btnIdx)
                                            ? Colors.blue[900]
                                            : Colors.black54,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _buttonData[sectionIndex][btnIdx]['name'],
                                              style: TextStyle(
                                                color: (_selectedSection == sectionIndex && _selectedButton == btnIdx)
                                                    ? Colors.blue[900]
                                                    : Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _buttonData[sectionIndex][btnIdx]['subtext'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.left,
                                              maxLines: null,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          ),
        ),
        // Content
        Expanded(
          child: _sectionPages[_selectedSection][_selectedButton],
        ),
      ],
    );
  }
}