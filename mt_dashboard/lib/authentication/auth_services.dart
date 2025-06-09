import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthServices> authService = ValueNotifier<AuthServices>(AuthServices());

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Field: accountExpiryDate (1 month after account creation)
  DateTime? get accountExpiryDate {
    final user = _auth.currentUser;
    if (user == null) return null;
    final creationTime = user.metadata.creationTime;
    if (creationTime == null) return null;
    return DateTime(creationTime.year, creationTime.month + 1, creationTime.day);
  }

  // Sign in with Google
  // Note: This requires additional setup with Google Sign-In and Firebase
  Future<UserCredential> signInWithGoogle() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
    googleProvider.setCustomParameters({
      'login_hint': 'user@example.com'
    });

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }

  Future<void> userData() async {
    final db = FirebaseFirestore.instance;
    final users = db.collection('users');
    final user = FirebaseAuth.instance.currentUser;

    // Check if the 'users' collection is empty
    final usersSnapshot = await users.limit(1).get();
    if (usersSnapshot.docs.isEmpty) {
      // Create a dummy document to ensure the collection exists
      // await users.doc('_init').set({'init': true});
      // Optionally, you can delete this dummy doc after creating the first real user
    }

    final userDoc = await users.doc(user?.uid).get();

    if (!userDoc.exists) {
      final creationTime = user?.metadata.creationTime;
      final expiryDate = creationTime != null
          ? Timestamp.fromDate(DateTime(creationTime.year, creationTime.month + 1, creationTime.day))
          : FieldValue.serverTimestamp();

      final userFields = {
        'uid': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'name': user?.displayName ?? '',
        'email': user?.email ?? '',
        'photoUrl': user?.photoURL ?? '',
        // The following fields may not exist on the user object; set as empty string or handle accordingly
        'companyName': 'Company Name',
        'facebook': 'Facebook URL',
        'instagram': 'Instagram URL',
        'twitter': 'Twitter URL',
        'whatsapp': 'Whatsapp URL',
        'tiktok': 'Tiktok URL',
        'linkedin': 'Linkedin URL',
        'phone': user?.phoneNumber ?? 'Phone Number',
        'address': 'Address',
        'youtube': 'Youtube URL',
        'website': 'Website URL',
        'domain': 'Domain URL',
        'currency': 'Currency',
        'verified': 'false',
        'accountExpiryDate': expiryDate,
      };
      await users.doc(user?.uid).set(userFields, SetOptions(merge: true));

      if (user != null) {
        final userCollection = db.collection(user.uid);
        await userCollection.doc('catalogue').set({
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    // If the document exists, do nothing (don't overwrite)
  }
}

Future<Map<String, dynamic>?> getUserData(String uid) async {
  final db = FirebaseFirestore.instance;
  final doc = await db.collection('users').doc(uid).get();
  if (doc.exists) {
    return doc.data();
  } else {
    return null;
  }
}

Future<Map<String, dynamic>?> getCategoryData(String uid, String categoryid) async {
  final db = FirebaseFirestore.instance;
  final doc = await db.collection('users').doc(uid).collection('category').doc(categoryid).get();
  if (doc.exists) {
    return doc.data();
  } else {
    return null;
  }
}

Future<Map<String, dynamic>?> getBrandData(String uid, String categoryid, String brandid) async {
  final db = FirebaseFirestore.instance;
  final doc = await db.collection('users').doc(uid).collection('category').doc(categoryid).collection('brand').doc(brandid).get();
  if (doc.exists) {
    return doc.data();
  } else {
    return null;
  }
}

Widget userFieldText(String field,
  {String? defaultValue, TextStyle? style, TextAlign? textAlign}) {
  return StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser?.uid)
    .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Text(
      'Loading...',
      style: style ?? const TextStyle(color: Colors.blue, fontSize: 12),
      textAlign: textAlign ?? TextAlign.left,
    );
    }
    if (snapshot.hasError ||
      !snapshot.hasData ||
      !(snapshot.data?.exists ?? false)) {
    return Text(
      defaultValue ?? field,
      style: style ?? const TextStyle(color: Colors.blue, fontSize: 12),
      textAlign: textAlign ?? TextAlign.left,
    );
    }
    final data = snapshot.data!.data() as Map<String, dynamic>?;
    return Text(
    data?[field] ?? (defaultValue ?? field),
    style: style ?? const TextStyle(color: Colors.blue, fontSize: 12),
    textAlign: textAlign ?? TextAlign.left,
    );
  },
  );
}

Widget userCategoryText({
  TextStyle? style,
  TextAlign? textAlign,
}) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return const Text('User not logged in');
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('category')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Text(
          'Loading...',
          style: style ?? const TextStyle(color: Colors.blue, fontSize: 12),
          textAlign: textAlign ?? TextAlign.left,
        );
      }

      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Text(
          'No categories',
          style: style ?? const TextStyle(color: Colors.blue, fontSize: 12),
          textAlign: textAlign ?? TextAlign.left,
        );
      }

      final categories = snapshot.data!.docs.map((doc) => doc.id).join(', ');

      return Text(
        categories,
        style: style ?? const TextStyle(color: Colors.blue, fontSize: 12),
        textAlign: textAlign ?? TextAlign.left,
      );
    },
  );
}

Future<List<Map<String, dynamic>>> getAllBrands() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> allBrands = [];

  if (userId == null) return [];

  final categorySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('category')
      .get();

  for (var categoryDoc in categorySnapshot.docs) {
    final brandSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('category')
        .doc(categoryDoc.id)
        .collection('brand')
        .get();

    for (var brandDoc in brandSnapshot.docs) {
      allBrands.add(brandDoc.data());
    }
  }

  return allBrands;
}





// Usage examples:
Widget companyName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('companyName', defaultValue: 'Company Name', style: style, textAlign: textAlign);

Widget domainName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('domain', defaultValue: 'Domain', style: style, textAlign: textAlign);

Widget addressName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('address', defaultValue: 'Address', style: style, textAlign: textAlign);

Widget facebookName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('facebook', defaultValue: 'Facebook', style: style, textAlign: textAlign);

Widget instagramName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('instagram', defaultValue: 'Instagram', style: style, textAlign: textAlign);

Widget youtubeName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('youtube', defaultValue: 'Youtube', style: style, textAlign: textAlign);

Widget twitterName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('twitter', defaultValue: 'Twitter', style: style, textAlign: textAlign);

Widget userName({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('name', defaultValue: 'Name', style: style, textAlign: textAlign);

Widget currency({TextStyle? style, TextAlign? textAlign}) =>
  userFieldText('currency', defaultValue: 'Currency', style: style, textAlign: textAlign);
