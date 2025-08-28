import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; // Added this import
import 'package:mt_dashboard/authentication/auth_services.dart';
import 'package:mt_dashboard/authentication/login_view.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupViewDesktop extends StatefulWidget {
  const SignupViewDesktop({super.key});

  @override
  State<SignupViewDesktop> createState() => _SignupViewDesktopState();
}

class _SignupViewDesktopState extends State<SignupViewDesktop> {
  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password requirement tracking from the original signup file
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  String _selectedCountryCode = '+673'; // Default to Brunei's code

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Listener for password field changes to update password requirements
  void _onPasswordChanged() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 9;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  // A helper function to show dialog messages
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
                // Navigate back to login screen on successful registration
                if (title == 'Registration Successful') {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Handle the sign-up process
  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final company = _companyController.text.trim();
    final phone = _selectedCountryCode + _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Basic form validation
    if (name.isEmpty || email.isEmpty || company.isEmpty || _phoneController.text.trim().isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessageDialog('Error', 'Please fill all fields.');
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showMessageDialog('Error', 'Please enter a valid email address.');
      return;
    }

    if (password != confirmPassword) {
      _showMessageDialog('Error', 'Passwords do not match.');
      return;
    }

    // Check all password requirements
    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSymbol) {
      _showMessageDialog('Error', 'Password does not meet all requirements.');
      return;
    }

    String capitalizedName = name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;

      if (user != null) {
        await authService.value.firestore
            .collection('users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'companyName': company,
          'name': capitalizedName,
          'phone': phone,
          'memberId': user.uid,
          'plan': 'Basic Plan',
          'role': 'client',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await authService.value.userData();
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          setState(() => _isLoading = false);
          _showMessageDialog('Registration Successful', 'Your account has been created successfully!');
        }
      } else {
        throw Exception('User was null after Firebase account creation.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showMessageDialog('Sign Up Failed', e.message ?? 'Unknown error');
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showMessageDialog('Sign Up Failed', 'An unexpected error occurred: $e');
    }
  }

  // Handle Google Sign-In
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
          'message': 'User successfully logged in with Google',
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

  // Helper widget to build password requirement rows
  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle,
            color: isMet ? Colors.green : Colors.grey,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF825FDD),
              Color(0xFF8B4F96),
              Color(0xFFEE601C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content row for left and right sections
              Row(
                children: [
                  // Left Section: Logo, Text, Buttons
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            ],
                          ),
                          // const SizedBox(height: 30),
                          // Main tagline text
                          const Text(
                            'A toolbox for entrepreneurial success,\nwith just a click.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Action Buttons
                          Row(
                            children: [
                              // Get started! Sign up button (current page)
                              ElevatedButton(
                                onPressed: () {}, // Already on this page, so no action
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6D4D).withOpacity(0.48),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Get started! Sign up',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_ios, size: 18),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 30),
                              // Already a Member? Log In button
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginView()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6D4D).withOpacity(0.48),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Already a Member? Log In',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                  // Right Section: Signup Form
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(
                        width: 450,
                        height: 750, // Added a fixed height to the card
                        padding: const EdgeInsets.all(40.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Full Name Input Field
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                cursorColor: Colors.white,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
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
                                  hintText: 'Enter your full name',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // Company Name Input Field
                              TextField(
                                controller: _companyController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                cursorColor: Colors.white,
                                decoration: InputDecoration(
                                  labelText: 'Company Name',
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
                                  hintText: 'Enter your company name',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // Email Input Field
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
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
                                  hintText: 'email@example.com',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // Phone Number Input Field with Country Code Picker
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: CountryCodePicker(
                                      onChanged: (CountryCode countryCode) {
                                        setState(() {
                                          _selectedCountryCode = countryCode.dialCode!;
                                        });
                                      },
                                      initialSelection: 'BN',
                                      favorite: const ['+673', 'BN'],
                                      showCountryOnly: false,
                                      showFlagMain: true,
                                      textStyle: const TextStyle(color: Colors.white),
                                      dialogTextStyle: const TextStyle(color: Colors.black),
                                      searchDecoration: const InputDecoration(
                                        hintText: 'Search country',
                                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                                      ),
                                      dialogSize: const Size(400, 500),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                      cursorColor: Colors.white,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number',
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
                                        hintText: 'Enter phone number',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              // Password Input Field
                              TextField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                cursorColor: Colors.white,
                                obscureText: _obscurePassword,
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
                                  hintText: '••••••••••••',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // Confirm Password Input Field
                              TextField(
                                controller: _confirmPasswordController,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                cursorColor: Colors.white,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
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
                                  hintText: '••••••••••••',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Password requirements
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRequirementRow('At least 9 characters', _hasMinLength),
                                  _buildRequirementRow('At least one uppercase letter', _hasUppercase),
                                  _buildRequirementRow('At least one lowercase letter', _hasLowercase),
                                  _buildRequirementRow('At least one number', _hasNumber),
                                  _buildRequirementRow('At least one symbol', _hasSymbol),
                                ],
                              ),
                              const SizedBox(height: 30),
                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6D4D).withOpacity(0.48),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Sign Up',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                  onPressed: _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white70, width: 1.5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.account_circle, // Placeholder for Google icon
                                    size: 24,
                                  ),
                                  label: const Text(
                                    'Google',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Copyright Text at the bottom
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Copyright © 2025 Brniaga by Maow Technological Advancement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
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
