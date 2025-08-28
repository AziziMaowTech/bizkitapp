import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Corrected import
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; // Corrected import
// import 'package:flutter_svg/flutter_svg.dart'; // Not used in the new design, can be removed if not needed elsewhere
import 'package:mt_dashboard/authentication/auth_services.dart'; // Corrected import
import 'package:mt_dashboard/authentication/signup_view.dart'; // Corrected import
// import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart'; // Not directly used in login, but might be for navigation after login
// import 'package:mt_dashboard/ui/widgets/auth_carousel.dart'; // This widget is removed in the new design

// Import Google Sign-In package - already present
import 'package:google_sign_in/google_sign_in.dart';


class LoginViewDesktop extends StatefulWidget {
  const LoginViewDesktop({super.key});

  @override
  State<LoginViewDesktop> createState() => _LoginViewDesktopState();
}

class _LoginViewDesktopState extends State<LoginViewDesktop> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true; // Added for password visibility toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessageDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessageDialog('Login Error', 'Please enter both email and password.');
      return;
    }
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userId = userCredential.user?.uid;
      if (userId != null) {
        final logRef = authService.value.firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .doc();
        await logRef.set({
          'useractivity': 'login_email',
          'email': userCredential.user?.email,
          'type': 'Login',
          'message': 'User successfully logged in',
          'timestamp': FieldValue.serverTimestamp()
        });
        await authService.value.userData();
      }
      // StreamBuilder in HomeViewDesktop will handle navigation
    } on FirebaseAuthException catch (e) {
      _showMessageDialog('Login Failed', e.message ?? 'Unknown error');
    } catch (e) {
      _showMessageDialog('Login Failed', 'An unexpected error occurred.');
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ForgotPasswordDialog(
          onEmailSubmitted: (email) async {
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              if (!mounted) return;
              _showMessageDialog('Password Reset', 'Password reset link sent to: $email');
            } on FirebaseAuthException catch (e) {
              if (!mounted) return;
              _showMessageDialog('Password Reset Failed', 'Error: ${e.message}');
            }
          },
        );
      },
    );
  }

  void _handleSignInWithPhone() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PhoneSignInDialog(
          onCodeSent: (phoneNumber) {
            _showMessageDialog('Phone Verification', 'OTP sent to $phoneNumber. Please enter the code.');
          },
          onSignInSuccess: (phoneNumber) async {
            await authService.value.userData();
            if (!mounted) return;
            _showMessageDialog('Phone Sign In', 'Successfully signed in with $phoneNumber!');
            // Navigation to Dashboard will be handled by the StreamBuilder in home_view.desktop.dart
          },
          onSignInFailed: (error) {
            _showMessageDialog('Phone Sign In Failed', 'Error: $error');
          },
        );
      },
    );
  }

  // New method to handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    try {
      final userCredential = await authService.value.signInWithGoogle();
      final userId = userCredential.user?.uid;
      if (userId != null) {
        final logRef = authService.value.firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .doc();
        await logRef.set({
          'useractivity': 'login_google',
          'email': userCredential.user?.email,
          'type': 'Login',
          'message': 'User successfully logged in with Google', // Updated message
          'timestamp': FieldValue.serverTimestamp()
        });
        await authService.value.userData();
        if (!mounted) return;
        _showMessageDialog('Google Sign In', 'Successfully signed in with Google!');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessageDialog('Google Sign In Failed', e.message ?? 'An unknown Firebase error occurred.');
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog('Google Sign In Failed', 'An unexpected error occurred: $e');
    }
  }

  // Placeholder for Apple Sign-In (if mt_dashboard/authentication/auth_services.dart supports it)
  // This function is no longer used for the 'Continue with phone' button but is kept for reference.
  Future<void> _handleAppleSignIn() async {
    // You would typically call authService.value.signInWithApple() here
    _handleSignInWithPhone(); // Re-using phone sign-in as a placeholder for Apple, adapt as needed
  }


  @override
  Widget build(BuildContext context) {
    // We are implementing a desktop-first design based on the image,
    // so `isLargeScreen` logic from the original file is less critical for this specific design but kept for reference.
    // The design itself looks like a fixed large desktop view.
    // final bool isLargeScreen = MediaQuery.of(context).size.width > 768; // Removed as it simplifies the layout to always be desktop-like

    return Scaffold(
      // Remove backgroundColor from Scaffold and apply gradient to a Container in the body
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Updated colors as per user request
            colors: [
              Color(0xFF825FDD), // Purple
              Color(0xFF8B4F96), // Grey Neon Pink
              Color(0xFFEE601C), // Orange
            ],
            stops: [0.0, 0.5, 1.0], // Adjust stops if needed for gradient distribution
          ),
        ),
        child: SafeArea(
          // Use Stack to place the copyright at the very bottom, over the main Row content
          child: Stack(
            children: [
              // Main content row for left and right sections
              Row(
                children: [
                  // Left Section: Logo, Text, Buttons
                  Expanded(
                    flex: 1, // Takes equal space
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
                        crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start (left)
                        children: [
                          // Brniaga Logo and Text
                            Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 25),
                              Image.asset(
                              'assets/images/Placeholder_small.png',
                              height: 150,
                              width: 150,
                              ),
                              SizedBox(width: 25),
                              Image.asset(
                              'assets/images/Placeholder_text.png',
                              height: 300,
                              width: 300,
                              ),
                              // const SizedBox(width: 10),
                              // const Text(
                              // 'Brniaga',
                              // style: TextStyle(
                              //   color: Colors.white,
                              //   fontSize: 60,
                              //   fontWeight: FontWeight.bold,
                              // ),
                              // ),
                            ],
                            ),
                          // Main tagline text
                          const Text(
                            'A toolbox for entrepreneurial success,\nwith just a click.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48, // Large and bold for impact
                              fontWeight: FontWeight.bold, // Made bold as requested
                              height: 1.2, // Adjust line height for better readability
                            ),
                          ),
                          const SizedBox(height: 60), // More space before buttons
                          // Action Buttons
                          Row(
                            children: [
                              // Get started! Sign up button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignupView()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6D4D).withOpacity(0.48), // Orange with 48% transparency
                                  foregroundColor: Colors.white, // White font color
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // Slightly rounded corners
                                  ),
                                  elevation: 5, // Subtle shadow
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min, // To keep button content compact
                                  children: [
                                    Text(
                                      'Get started! Sign up', // Text includes "Get started!" which needs to be bold.
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Made bold as requested
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios, size: 18), // Forward arrow icon
                                  ],
                                ),
                              ),
                              const SizedBox(width: 30), // Space between buttons
                              // Already a Member? Log In button (replaces old "Sign in with Phone" or similar left-aligned buttons)
                              TextButton(
                                onPressed: () {
                                  // No specific action here as the main login is on the right,
                                  // but it could scroll to the login form or highlight it.
                                  // For now, it could be a redundant "Log In" if the user is already on the login page.
                                  // Or navigate to the same current view, ensuring the right side is visible.
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6D4D).withOpacity(0.48), // Orange with 48% transparency
                                  foregroundColor: Colors.white, // White font color
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  shape: RoundedRectangleBorder( // Apply shape for background
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Already a Member? Log In', // Text includes "Already a Member?" which needs to be bold.
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Made bold as requested
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Section: Login Form
                  Expanded(
                    flex: 1, // Takes equal space
                    child: Center(
                      child: Container(
                        width: 450, // Fixed width for the login card as seen in the design
                        padding: const EdgeInsets.all(40.0), // Padding inside the card
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), // Translucent white for the frosted glass effect
                          borderRadius: BorderRadius.circular(25), // More rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15), // Subtle shadow for depth
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10), // Shadow offset
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Column shrinks to fit children vertically
                          crossAxisAlignment: CrossAxisAlignment.center, // Center contents horizontally within the card
                          children: [
                            const Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 40), // Space after title
                            // Email Input Field
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              cursorColor: Colors.white,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'E-mail',
                                labelStyle: const TextStyle(color: Colors.white70), // Lighter label text
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1), // Slightly transparent background for input
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none, // No visible border line
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white70, width: 1.5), // Subtle focus border
                                ),
                                hintText: 'email@example.com', // Hint text from image
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                            const SizedBox(height: 25), // Space between fields
                            // Password Input Field
                            TextField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              cursorColor: Colors.white,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white70, width: 1.5),
                                ),
                                hintText: '••••••••••••', // Hint text from image
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Forgot Password?
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword, // Linked to existing function
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Log In Button
                            SizedBox(
                              width: double.infinity, // Button takes full width of the card
                              child: ElevatedButton(
                                onPressed: _handleSignIn, // Linked to existing function
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6D4D).withOpacity(0.48), // Orange with 48% transparency
                                  foregroundColor: Colors.white, // White font color
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Made bold as requested
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Or Continue With separator
                            const Text(
                              'Or Continue With',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 30),
                            // Continue with Google Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _handleGoogleSignIn, // Linked to existing function
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white70, width: 1.5), // White border
                                  foregroundColor: Colors.white, // White text and icon
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Image.network(
                                  'https://img.icons8.com/color/48/000000/google-logo.png', // Google logo from original code
                                  height: 24.0,
                                  width: 24.0,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata, size: 24.0, color: Colors.white), // Fallback icon
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Continue with Phone Button (replaces Apple button)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _handleSignInWithPhone, // Linked to existing phone handler
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white70, width: 1.5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.phone_android, size: 24), // Changed to phone icon
                                label: const Text(
                                  'Continue with phone', // Changed button text
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Copyright Footer (positioned at the bottom using Align)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 25.0), // Padding from the bottom edge
                  child: Text(
                    'Copyright © 2025 Brniaga by Maow Technological Advancement',
                    style: TextStyle(color: Colors.white, fontSize: 14), // Made white with no transparency
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

// Re-using existing dialogs, ensuring they are correctly imported and accessible.
// These dialogs (_ForgotPasswordDialog, _PhoneSignInDialog) must be defined
// in the same file or properly imported if they are in separate files.
// Assuming they are in the same file as per the provided `login_view.desktop.dart`.

class _ForgotPasswordDialog extends StatefulWidget {
  final ValueChanged<String> onEmailSubmitted;

  const _ForgotPasswordDialog({
    required this.onEmailSubmitted,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('Validation Error', 'Please enter your email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    widget.onEmailSubmitted(email);

    if (mounted) {
      // Navigator.of(context).pop(); // Let the calling function handle pop if needed
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 10.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Icon(
                Icons.lock_reset,
                size: 60.0,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827), // Consider making this white or a theme color for consistency if dialogs are themed
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              const Text(
                'Enter your email address below to receive a password reset link.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF4B5563), // Consider making this white or a theme color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'email@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // Default blue, consider matching new design accents
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Send Reset Link'),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).primaryColor), // Default blue
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneSignInDialog extends StatefulWidget {
  final ValueChanged<String> onCodeSent;
  final ValueChanged<String> onSignInSuccess;
  final ValueChanged<String> onSignInFailed;

  const _PhoneSignInDialog({
    required this.onCodeSent,
    required this.onSignInSuccess,
    required this.onSignInFailed,
  });

  @override
  State<_PhoneSignInDialog> createState() => _PhoneSignInDialogState();
}

class _PhoneSignInDialogState extends State<_PhoneSignInDialog> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _verificationId;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 10.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Icon(
                Icons.phone_android,
                size: 60.0,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Sign in with Phone',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827), // Consider matching new design accents
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to your phone number.'
                    : 'Enter your phone number to sign in or create an account.',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF4B5563), // Consider matching new design accents
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              if (!_codeSent)
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1234567890',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                )
              else
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code (OTP)',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.dialpad),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_codeSent) {
                          final otp = _otpController.text.trim();
                          if (otp.isEmpty || _verificationId == null) {
                            _showErrorDialog('Validation Error', 'Please enter the OTP.');
                            return;
                          }
                          setState(() => _isLoading = true);
                          try {
                            PhoneAuthCredential credential = PhoneAuthProvider.credential(
                              verificationId: _verificationId!,
                              smsCode: otp,
                            );
                            await FirebaseAuth.instance.signInWithCredential(credential);
                            if (mounted) {
                               widget.onSignInSuccess(_phoneNumberController.text.trim());
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => _isLoading = false);
                            widget.onSignInFailed(e.message ?? 'OTP verification failed.');
                          } finally {
                             if (mounted) {
                               Navigator.of(context).pop(); // Pop the dialog on success or failure
                             }
                          }
                        } else {
                          final phoneNumber = _phoneNumberController.text.trim();
                          if (phoneNumber.isEmpty) {
                            _showErrorDialog('Validation Error', 'Please enter your phone number.');
                            return;
                          }
                          setState(() => _isLoading = true);
                          await FirebaseAuth.instance.verifyPhoneNumber(
                            phoneNumber: phoneNumber,
                            timeout: const Duration(seconds: 60),
                            verificationCompleted: (PhoneAuthCredential credential) async {
                              try {
                                await FirebaseAuth.instance.signInWithCredential(credential);
                                if (mounted) {
                                  widget.onSignInSuccess(phoneNumber);
                                }
                              } on FirebaseAuthException catch (e) {
                                debugPrint('Verification completed with error: ${e.message}');
                              } finally {
                                 if (mounted) {
                                   Navigator.of(context).pop(); // Pop the dialog on completion
                                 }
                              }
                            },
                            verificationFailed: (FirebaseAuthException e) {
                              setState(() => _isLoading = false);
                              widget.onSignInFailed(e.message ?? 'Phone verification failed.');
                            },
                            codeSent: (String verificationId, int? resendToken) {
                              setState(() {
                                _isLoading = false;
                                _codeSent = true;
                                _verificationId = verificationId;
                              });
                              widget.onCodeSent(phoneNumber);
                            },
                            codeAutoRetrievalTimeout: (String verificationId) {
                              setState(() {
                                _verificationId = verificationId;
                              });
                            },
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // Default blue
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_codeSent ? 'Verify Code' : 'Send Code'),
              ),
              const SizedBox(height: 16.0),
              if (_codeSent)
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _codeSent = false;
                            _isLoading = false;
                            _otpController.clear();
                            _verificationId = null;
                          });
                        },
                  child: Text(
                    'Edit Phone Number',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              else
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}