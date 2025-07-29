// signup_view.desktop.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:mt_dashboard/authentication/auth_services.dart';
import 'package:mt_dashboard/ui/widgets/auth_carousel.dart';
import 'package:country_code_picker/country_code_picker.dart'; // Import the package

// If you are using go_router directly here for navigation back to login/dashboard
// import 'package:go_router/go_router.dart'; // Uncomment if you decide to use GoRouter directly here

class SignupViewDesktop extends StatefulWidget {
  const SignupViewDesktop({super.key});

  @override
  State<SignupViewDesktop> createState() => _SignupViewDesktopState();
}

class _SignupViewDesktopState extends State<SignupViewDesktop> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // For password visibility
  bool _obscureConfirmPassword = true; // For confirm password visibility

  // Password requirement tracking
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  String _selectedCountryCode = '+673'; // Default to Brunei's code, will be updated by CountryCodePicker

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final company = _companyController.text.trim();
    final name = _nameController.text.trim();
    final phone = _selectedCountryCode + _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || company.isEmpty || name.isEmpty || _phoneController.text.trim().isEmpty) {
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
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
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
                                'Create Your Account',
                                style: TextStyle(
                                  fontSize: 30.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Join BizKit and manage your tasks efficiently',
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
                              hintText: 'Enter your email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0), // Space for checklist
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
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company Name',
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              CountryCodePicker(
                                onChanged: (CountryCode countryCode) {
                                  setState(() {
                                    _selectedCountryCode = countryCode.dialCode ?? '+673';
                                  });
                                },
                                initialSelection: 'BN',
                                favorite: const ['+673', 'US'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24.0),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Sign Up'),
                          ),
                          const SizedBox(height: 24.0),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Already have an account? ",
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 16.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pop(context);
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