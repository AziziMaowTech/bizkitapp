import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mt_dashboard/authentication/auth_services.dart';
import 'package:currency_picker/currency_picker.dart';

class Overview extends StatelessWidget {
  const Overview({super.key});

  Future<bool> _reauthenticateUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if user signed in with Google
    final isGoogleUser = user.providerData.any((info) => info.providerId == 'google.com');

    if (isGoogleUser) {
      // Simple reCAPTCHA dialog for Google users
      bool verified = false;
      final TextEditingController captchaController = TextEditingController();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Simple math captcha
          final int a = 1 + (DateTime.now().millisecondsSinceEpoch % 9);
          final int b = 1 + ((DateTime.now().millisecondsSinceEpoch ~/ 10) % 9);
          final int answer = a + b;

          return AlertDialog(
            title: const Text('Verify you are human'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('What is $a + $b ?'),
                const SizedBox(height: 12),
                TextField(
                  controller: captchaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (captchaController.text.trim() == answer.toString()) {
                    verified = true;
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification failed. Please try again.')),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      return verified;
    }

    // Default: email/password re-auth
    final TextEditingController emailController =
        TextEditingController(text: user.email ?? '');
    final TextEditingController passwordController = TextEditingController();

    bool success = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Re-authenticate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final cred = EmailAuthProvider.credential(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  await user.reauthenticateWithCredential(cred);
                  success = true;
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-authentication failed. Please try again.')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return success;
  }

  Future<void> _updateUserField(
      BuildContext context, String field, String label, String defaultValue) async {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController _controller = TextEditingController();

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey(field)) {
        _controller.text = doc[field];
      } else {
        _controller.text = defaultValue;
      }
    } else {
      _controller.text = defaultValue;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (user != null) {
                  final reauth = await _reauthenticateUser(context);
                  if (reauth) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({field: _controller.text});
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    _updateUserField(context, 'name', 'Name', 'Name');
  }

  void _showEditCompanynameDialog(BuildContext context) {
    _updateUserField(context, 'companyName', 'Company Name', 'Company Name');
  }

  void _showEditDomain(BuildContext context) {
    _updateUserField(context, 'domain', 'Domain', 'Domain');
  }

  void _showEditAddress(BuildContext context) {
    _updateUserField(context, 'address', 'Address', 'Address');
  }

  void _showEditFacebook(BuildContext context) {
    _updateUserField(context, 'facebook', 'Facebook', 'Facebook');
  }

  void _showEditInstagram(BuildContext context) {
    _updateUserField(context, 'instagram', 'Instagram', 'Instagram');
  }

  void _showEditYoutube(BuildContext context) {
    _updateUserField(context, 'youtube', 'Youtube', 'Youtube');
  }

  void _showEditTwitter(BuildContext context) {
    _updateUserField(context, 'twitter', 'Twitter', 'Twitter');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      FirebaseAuth.instance.currentUser?.photoURL ??
                          'https://www.gravatar.com/avatar/',
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                      backgroundColor: Colors.white,
                      elevation: 2,
                    ),
                    onPressed: () {
                      // TODO: Implement change display image logic
                    },
                    child: const Icon(Icons.camera_alt, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditUsernameDialog(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Name',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.userName(),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditCompanynameDialog(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Company Name',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            authService.value.companyName(),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showCurrencyPicker(
                    context: context,
                    showFlag: true,
                    showCurrencyName: true,
                    showCurrencyCode: true,
                    onSelect: (Currency currency) async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final reauth = await _reauthenticateUser(context);
                        if (reauth) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({'currency': currency.code});
                          (context as Element).markNeedsBuild();
                        }
                      }
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Currency',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  return const Text(
                                    'Currency',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.left,
                                  );
                                }
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get(),
                                  builder: (context, snapshot) {
                                    String currency = 'Currency';
                                    if (snapshot.hasData &&
                                        snapshot.data != null &&
                                        snapshot.data!.data() != null) {
                                      final data = snapshot.data!.data() as Map<String, dynamic>;
                                      if (data.containsKey('currency')) {
                                        currency = data['currency'];
                                      }
                                    }
                                    return Text(
                                      currency,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.left,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditDomain(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Domain',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.domainName(),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Email Cannot Be Changed'),
                      content: const Text('Your email address cannot be changed.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? 'Email',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditAddress(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Address',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.addressName(),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditFacebook(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Facebook Page',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.facebookName()
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditInstagram(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instagram',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.instagramName(),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditYoutube(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Youtube Channel',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.youtubeName()
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditTwitter(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Twitter',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            authService.value.twitterName()
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1),
          ],
        ),
      ),
    );
  }
}
