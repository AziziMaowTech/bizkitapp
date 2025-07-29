// lib/authentication/auth_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In package

ValueNotifier<AuthServices> authService = ValueNotifier<AuthServices>(AuthServices());

class AuthServices {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Initialize GoogleSignIn

  // Renamed from signInWithEmail to match usage in login_view.desktop.dart
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  // New method for user registration (signup)
  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
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
  Future<UserCredential> signInWithGoogle() async {
    // Begin interactive sign-in process
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // If the user cancels the sign-in, googleUser will be null
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ABORTED_BY_USER',
        message: 'Google Sign-In aborted by user.',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _auth.signInWithCredential(credential);
  }

  // Add a signOut method
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Sign out from Google as well
    await _auth.signOut();
  }

  // New userData method as provided by the user
  Future<void> userData() async {
    final db = FirebaseFirestore.instance;
    final usersCollection = db.collection('users');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('No current user found. Cannot create/update user data.');
      return;
    }

    final userDocRef = usersCollection.doc(user.uid);
    final userDocSnapshot = await userDocRef.get();

    // If the user document does not exist, create it with initial data.
    if (!userDocSnapshot.exists) {
      final creationTime = user.metadata.creationTime;
      final expiryDate = creationTime != null
          ? Timestamp.fromDate(DateTime(creationTime.year, creationTime.month + 1, creationTime.day))
          : FieldValue.serverTimestamp();

      final userFields = {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(), // Use server timestamp for creation
        'updatedAt': FieldValue.serverTimestamp(),
        'name': user.displayName ?? '', // Populate from Google/Email if available, otherwise empty
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'phone': user.phoneNumber ?? '', // Populate from Phone Auth if available, otherwise empty
        'companyName': '', // Initialize as empty, will be updated by _showDetailsDialog for email signup
        'address': '',
        'facebook': '',
        'instagram': '',
        'twitter': '',
        'whatsapp': '',
        'tiktok': '',
        'linkedin': '',
        'youtube': '',
        'website': '',
        'domain': '',
        'currency': '',
        'verified': false, // Changed to boolean
        'accountExpiryDate': expiryDate,
      };
      await userDocRef.set(userFields, SetOptions(merge: true)); // Use merge to avoid overwriting if partial data exists

      // Also create a default 'catalogue' document for the user
      final userCollection = db.collection(user.uid);
      await userCollection.doc('catalogue').set({
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // If the document exists, ensure essential fields are not null/empty if they should be populated
      // This is for cases where a user might sign in with a different method later (e.g., email then Google)
      final existingData = userDocSnapshot.data() as Map<String, dynamic>;
      final Map<String, dynamic> updates = {};

      if (user.displayName != null && user.displayName!.isNotEmpty && (existingData['name'] == null || existingData['name'].isEmpty)) {
        updates['name'] = user.displayName;
      }
      if (user.email != null && user.email!.isNotEmpty && (existingData['email'] == null || existingData['email'].isEmpty)) {
        updates['email'] = user.email;
      }
      if (user.photoURL != null && user.photoURL!.isNotEmpty && (existingData['photoUrl'] == null || existingData['photoUrl'].isEmpty)) {
        updates['photoUrl'] = user.photoURL;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty && (existingData['phone'] == null || existingData['phone'].isEmpty)) {
        updates['phone'] = user.phoneNumber;
      }

      // Always update 'updatedAt' timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      if (updates.isNotEmpty) {
        await userDocRef.update(updates);
      }
    }
  }

  // You might have other utility methods here, like:
  // Future<void> sendPasswordResetEmail(String email) async {
  //   await _auth.sendPasswordResetEmail(email: email);
  // }

  // Consider adding user data specific methods if they interact directly with Firestore
  // Example:
  // Future<DocumentSnapshot> getUserData(String userId) async {
  //   return await firestore.collection('users').doc(userId).get();
  // }

  // Other utility functions related to user fields
  Widget userFieldText(String fieldName, {String? defaultValue, TextStyle? style, TextAlign? textAlign}) {
    // This part seems unrelated to core AuthServices and might belong elsewhere
    // but keeping it as it was in your provided file.
    // NOTE: This now uses the Firebase Auth user's UID to fetch the document.
    // If you intend to use the `companyName` as the primary document ID
    // for all lookups, you will need to adjust this logic.
    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('users').doc(_auth.currentUser?.uid).get(), // Using user.uid here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final text = data?[fieldName]?.toString() ?? defaultValue ?? 'N/A';
        return Text(
          text,
          style: style,
          textAlign: textAlign ?? TextAlign.left,
        );
      },
    );
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
}
