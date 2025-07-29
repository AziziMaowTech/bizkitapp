import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mt_dashboard/authentication/auth_services.dart';
import 'package:mt_dashboard/authentication/signup_view.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:mt_dashboard/ui/widgets/auth_carousel.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In package

class LoginViewDesktop extends StatefulWidget {
  const LoginViewDesktop({super.key});

  @override
  State<LoginViewDesktop> createState() => _LoginViewDesktopState();
}

class _LoginViewDesktopState extends State<LoginViewDesktop> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: Card(
          color: Colors.white,
          margin: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Flex(
              direction: isLargeScreen ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  flex: isLargeScreen ? 1 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16.0),
                        bottomLeft: isLargeScreen ? const Radius.circular(16.0) : Radius.zero,
                        topRight: isLargeScreen ? Radius.zero : const Radius.circular(16.0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/placeholder.png',
                                    height: 100.0,
                                    width: 100.0,
                                  ),
                                ],
                              ),
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 30.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Please enter login details below',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32.0),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter the email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter the Password',
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: RichText(
                              text: TextSpan(
                                text: 'Forgot password?',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _handleForgotPassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          ElevatedButton(
                            onPressed: _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('Sign in'),
                          ),
                          const SizedBox(height: 32.0),
                          Row(
                            children: const [
                              Expanded(
                                  child: Divider(color: Color(0xFFD1D5DB))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Or continue',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: Color(0xFFD1D5DB))),
                            ],
                          ),
                          const SizedBox(height: 32.0),
                          OutlinedButton(
                            onPressed: _handleGoogleSignIn, // Call the new handler
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: const Color(0xFF4B5563),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://img.icons8.com/color/48/000000/google-logo.png',
                                  height: 24.0,
                                  width: 24.0,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata,
                                          size: 24.0, color: Colors.blue),
                                ),
                                const SizedBox(width: 8.0),
                                const Text('Log in with Google'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          OutlinedButton(
                            onPressed: _handleSignInWithPhone,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: const Color(0xFF4B5563),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.phone,
                                    size: 24.0, color: Color(0xFF2563EB)),
                                SizedBox(width: 8.0),
                                Text('Sign in with Phone'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 16.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const SignupView()),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isLargeScreen) const Expanded(child: AuthCarousel()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      Navigator.of(context).pop();
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
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              const Text(
                'Enter your email address below to receive a password reset link.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF4B5563),
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
                  backgroundColor: const Color(0xFF2563EB),
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
                  color: Color(0xFF111827),
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
                  color: Color(0xFF4B5563),
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
                  backgroundColor: const Color(0xFF2563EB),
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
