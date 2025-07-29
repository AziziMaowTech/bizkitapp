// lib/ui/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/publiccatalouge_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.dart'; // Ensure this path is correct if SettingsView is needed

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PublicCatalougeView(storename: '',)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6), // A light grey to match the theme
                  foregroundColor: Colors.white, // Dark text
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Catalogues'),
              ),
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
              StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  if (user == null) {
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueGrey[100],
                          child: const Text(
                            '??',
                            style: TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Guest',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    );
                  }
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey[100],
                              child: const Text(
                                '..',
                                style: TextStyle(color: Color(0xFF4B5563)),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Text(
                               'Loading...',
                               style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        );
                      }
                      final data = snapshot.data?.data();
                      final name = data?['name'] as String? ?? 'No Name';
                      final profilePictureUrl = data?['profilePictureUrl'] as String?;
                      
                      String initials = '';
                      if (name.trim().isNotEmpty) {
                        final parts = name.trim().split(' ');
                        if (parts.length == 1) {
                          initials = parts[0].substring(0, 1).toUpperCase();
                        } else {
                          initials = parts[0].substring(0, 1).toUpperCase() +
                              parts.last.substring(0, 1).toUpperCase();
                        }
                      }
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey[100],
                            backgroundImage: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                                ? NetworkImage(profilePictureUrl) as ImageProvider
                                : null, // Fallback to child if no image
                            child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                                ? Text(
                                    initials.isNotEmpty ? initials : '??',
                                    style: const TextStyle(color: Color(0xFF4B5563)),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}