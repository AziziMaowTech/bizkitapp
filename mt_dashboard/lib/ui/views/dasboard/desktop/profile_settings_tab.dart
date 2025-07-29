// profile_settings_tab.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<ProfileSettingsTab> {
  File? _imageFile; // For non-web platforms
  Uint8List? _imageBytesForWeb; // For temporary display of picked image on web
  String? _imageUrl; // For uploaded image from Firestore
  final TextEditingController _storeUrlController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadUserProfileData();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _storeUrlController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _phoneNumberController.dispose();
    _tiktokController.dispose();
    _twitterController.dispose();
    _whatsappController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _imageUrl = userDoc.data()?['profilePictureUrl'];
        });
      }
    }
  }

  Future<void> _loadUserProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _storeUrlController.text = userDoc.data()?['storeUrl'] ?? '';
            _addressController.text = userDoc.data()?['address'] ?? '';
            _companyNameController.text = userDoc.data()?['companyName'] ?? '';
            _facebookController.text = userDoc.data()?['facebook'] ?? '';
            _instagramController.text = userDoc.data()?['instagram'] ?? '';
            _linkedinController.text = userDoc.data()?['linkedin'] ?? '';
            _phoneNumberController.text = userDoc.data()?['phoneNumber'] ?? '';
            _tiktokController.text = userDoc.data()?['tiktok'] ?? '';
            _twitterController.text = userDoc.data()?['twitter'] ?? '';
            _whatsappController.text = userDoc.data()?['whatsapp'] ?? '';
            _youtubeController.text = userDoc.data()?['youtube'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading user profile data: $e');
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _updateUserProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update your profile.')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'storeUrl': _storeUrlController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
        'address': _addressController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'youtube': _youtubeController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error updating user profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytesForWeb = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytesForWeb = null;
        });
      }
      await _uploadProfilePicture(pickedFile);
    }
  }

  Future<void> _uploadProfilePicture(XFile pickedFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to upload a picture.')),
        );
      }
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final profilePicRef = storageRef.child('profile_pictures/${user.uid}/${pickedFile.name}');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = profilePicRef.putData(await pickedFile.readAsBytes());
      } else {
        uploadTask = profilePicRef.putFile(File(pickedFile.path));
      }

      await uploadTask;
      final downloadUrl = await profilePicRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profilePictureUrl': downloadUrl,
      });

      setState(() {
        _imageUrl = downloadUrl;
        _imageFile = null;
        _imageBytesForWeb = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Settings',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              // Profile Picture Upload Section
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16.0),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                                ? NetworkImage(_imageUrl!) as ImageProvider
                                : (kIsWeb && _imageBytesForWeb != null
                                    ? MemoryImage(_imageBytesForWeb!) as ImageProvider
                                    : (_imageFile != null
                                        ? FileImage(_imageFile!) as ImageProvider
                                        : null)),
                            child: _imageUrl == null && _imageFile == null && _imageBytesForWeb == null
                                ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                                : null,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Upload Profile Picture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    const Text(
                      'Store Information',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (_currentUserId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                      ),
                    TextFormField(
                      controller: _storeUrlController,
                      decoration: InputDecoration(
                        labelText: 'Store URL',
                        hintText: 'yourstorename',
                        prefixText: 'https://www.bizkit.com/',
                      ),
                      keyboardType: TextInputType.url,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Store URL cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24.0),
                    const Text(
                      'Contact Information',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1234567890',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24.0),
                    const Text(
                      'Social Media Links',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp (Link)',
                        hintText: 'e.g., https://wa.me/1234567890',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _facebookController,
                      decoration: const InputDecoration(
                        labelText: 'Facebook (Link)',
                        hintText: 'e.g., https://facebook.com/yourpage',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram (Link)',
                        hintText: 'e.g., https://instagram.com/yourprofile',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(
                        labelText: 'Twitter (Link)',
                        hintText: 'e.g., https://twitter.com/yourhandle',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn (Link)',
                        hintText: 'e.g., https://linkedin.com/in/yourprofile',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tiktokController,
                      decoration: const InputDecoration(
                        labelText: 'TikTok (Link)',
                        hintText: 'e.g., https://tiktok.com/@yourprofile',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _youtubeController,
                      decoration: const InputDecoration(
                        labelText: 'YouTube (Link)',
                        hintText: 'e.g., https://youtube.com/yourchannel',
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _updateUserProfileData,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save Profile Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Export/Import Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Management',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.file_download, size: 16),
                            label: const Text('Export'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.file_upload, size: 16),
                            label: const Text('Import'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}