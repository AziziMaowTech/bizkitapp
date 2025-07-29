import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer for auto-play
import 'package:flutter/gestures.dart'; // Required for TapGestureRecognizer
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mt_dashboard/authentication/auth_services.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart'; // For SVG image support

// Keeping main function for direct execution, but commenting it out
// as the user's project likely has its own main.dart.
void main() {
  runApp(const HomeViewDesktop());
}

class HomeViewDesktop extends StatelessWidget {
  // Renamed from TaskyLoginApp
  const HomeViewDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizKit Login', // Changed from Tasky Login
      theme: ThemeData(
        // Define a custom font for Inter if available, otherwise use default
        // To use 'Inter', you'd typically add it to your pubspec.yaml file
        // and include the font files in your project.
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Global theme for Card and Button styles
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0, // Matching the shadow in the image
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
            elevation: 4.0, // Shadow for buttons
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
            side: const BorderSide(color: Color(0xFFD1D5DB)), // Gray-300 from Tailwind
            textStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563), // Gray-700 from Tailwind
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)), // Gray-300
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
                color: Color(0xFF3B82F6), width: 2.0), // Blue-500
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          labelStyle: const TextStyle(color: Color(0xFF4B5563)), // Gray-700
          hintStyle: const TextStyle(color: Color(0xFF6B7280)), // Gray-500
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // If user is logged in, show Dashboard, otherwise show LoginPage
          if (snapshot.hasData) {
            return DashboardView();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  // Text controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Timer? _carouselTimer; // Timer for automatic carousel advance

  // Define carousel slides data
  final List<Map<String, String>> _carouselSlides = [
    {
      'image': 'assets/images/undraw_accept-task.svg',
      'text':
          'Manage your task in an easy and more efficient way with BizKit.', // Changed from Tasky
    },
    {
      'image': 'assets/images/undraw_engineering-team.svg',
      'text':
          'Stay organized and boost your productivity with smart reminders and lists.',
    },
    {
      'image': 'assets/images/undraw_working-together.svg',
      'text': 'Collaborate seamlessly with your team and achieve your goals together.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to update current page indicator for carousel
    _pageController.addListener(() {
      int? nextP = _pageController.page?.round();
      if (nextP != null && _currentPage != nextP) {
        setState(() {
          _currentPage = nextP;
        });
      }
    });

    // Start auto-play for the carousel
    _startCarouselAutoPlay();
  }

  // Method to start or restart the carousel auto-play timer
  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel(); // Cancel any existing timer
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _carouselSlides.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
          );
        } else {
          // Loop back to the first slide
          _pageController.jumpToPage(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _carouselTimer?.cancel(); // Important: cancel timer to prevent memory leaks
    super.dispose();
  }

  // Function to show a custom AlertDialog message
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

  // Placeholder for login logic
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
      // Log user activity in Firestore
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
        // Ensure user data is created/checked in Firestore
        await authService.value.userData();
      }
      // Removed direct navigation here, relying on StreamBuilder for existing users.
    } on FirebaseAuthException catch (e) {
      _showMessageDialog('Login Failed', e.message ?? 'Unknown error');
    } catch (e) {
      _showMessageDialog('Login Failed', 'An unexpected error occurred.');
    }
  }

  // Placeholder for signup logic
  void _handleSignUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Sign Up'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          if (email.isEmpty || password.isEmpty) {
                            _showMessageDialog('Error', 'Please enter email and password.');
                            return;
                          }
                          setState(() => isLoading = true);
                          try {
                            if (!mounted) return;
                            final bool detailsSaved =
                                await _showDetailsDialog(email, password);

                            if (detailsSaved) {
                              // Details were saved and user created successfully
                              if (!mounted) return;
                              Navigator.of(context).pop(); // Pop the signup dialog
                              // The success message is already shown in _showDetailsDialog
                              // No navigation to dashboard - let StreamBuilder handle it
                            } else {
                              // Details were not saved (e.g., dialog dismissed or error)
                              if (!mounted) return;
                              Navigator.of(context).pop(); // Pop the signup dialog
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => isLoading = false);
                            _showMessageDialog('Sign Up Failed', e.message ?? 'Unknown error');
                          } catch (e) {
                            setState(() => isLoading = false);
                            _showMessageDialog('Sign Up Failed', 'An unexpected error occurred: $e');
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Proceed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showDetailsDialog(String email, String password) async {
    Completer<bool> completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final companyController = TextEditingController();
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        bool isLoading = false;

        final List<String> _countryCodes = [
          '+673',
          '+1',
          '+44',
          '+91',
          '+61',
          '+81',
          '+49',
          '+86',
          '+33',
          '+971'
        ];
        String _selectedCountryCode = _countryCodes[0];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Your Details'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _selectedCountryCode,
                          items: _countryCodes
                              .map((code) => DropdownMenuItem(
                                    value: code,
                                    child: Text(code),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCountryCode = value!;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop(); // Pop the details dialog
                          completer.complete(false); // Indicate details not saved
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final company = companyController.text.trim();
                          final name = nameController.text.trim();
                          final phone = _selectedCountryCode + phoneController.text.trim();
                          if (company.isEmpty ||
                              name.isEmpty ||
                              phoneController.text.trim().isEmpty) {
                            _showMessageDialog('Error', 'Please fill all details.');
                            return;
                          }
                          setState(() => isLoading = true);
                          try {
                            // Create Firebase user account here
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
                                'name': name,
                                'phone': phone,
                                'createdAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              // Ensure user data is fully initialized/merged after custom fields are set
                              await authService.value.userData();

                              // Reset loading state and pop the dialog
                              if (mounted) {
                                setState(() => isLoading = false);
                                Navigator.of(context).pop(); // Pop the details dialog
                                _showMessageDialog('Registration Successful',
                                    'Your account has been created successfully!');
                              }
                              completer.complete(true); // Then complete the completer
                            } else {
                              // User was null after creation, which shouldn't happen but good to handle
                              throw Exception(
                                  'User was null after Firebase account creation.');
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => isLoading = false);
                            _showMessageDialog(
                                'Sign Up Failed', e.message ?? 'Unknown error');
                            completer.complete(false); // Indicate failure
                          } catch (e) {
                            setState(() => isLoading = false);
                            _showMessageDialog('Error', 'Failed to save details: $e');
                            completer.complete(false); // Indicate failure
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    return completer.future; // Return the future
  }

  // Integrated Forgot Password logic to show a custom dialog
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

  // New: Handle Sign in with Phone
  void _handleSignInWithPhone() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PhoneSignInDialog(
          onCodeSent: (phoneNumber) {
            _showMessageDialog('Phone Verification', 'OTP sent to $phoneNumber. Please enter the code.');
          },
          onSignInSuccess: (phoneNumber) async {
            // Ensure user data is created/checked in Firestore after successful phone sign-in
            await authService.value.userData();
            if (!mounted) return;
            _showMessageDialog('Phone Sign In', 'Successfully signed in with $phoneNumber!');
            // You might navigate after successful sign-in here.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardView()),
            );
          },
          onSignInFailed: (error) {
            _showMessageDialog('Phone Sign In Failed', 'Error: $error');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are on a large screen based on width
    final bool isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light gray background matching the image
      body: Center(
        child: Card(
          color: Colors.white,
          // The Card widget already has global theme styling for shape and elevation
          margin: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0), // Adjust margin for responsiveness
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 960), // Max width similar to Tailwind's max-w-4xl (1024px)
            child: Flex(
              direction: isLargeScreen ? Axis.horizontal : Axis.vertical, // Row on large, Column on small
              children: [
                // Left Section - Login Form
                Expanded(
                  flex: isLargeScreen ? 1 : 0, // Flex only if large screen, allows form to take half width
                  child: Container(
                    // Removed padding from here, added padding to the Column instead
                    decoration: BoxDecoration(
                      color: Colors.white, // Explicitly set background color to white
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16.0),
                        bottomLeft:
                            isLargeScreen ? const Radius.circular(16.0) : Radius.zero,
                        topRight:
                            isLargeScreen ? Radius.zero : const Radius.circular(16.0),
                        // Bottom right is handled by the parent Card widget's border radius
                      ),
                    ),
                    child: SingleChildScrollView(
                      // Made this panel scrollable
                      padding: const EdgeInsets.all(48.0), // p-12 equivalent
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.start, // Align content to the start
                        mainAxisSize:
                            MainAxisSize.min, // Allow column to take minimum space required
                        children: [
                          Column(
                            // Group top elements
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize:
                                MainAxisSize.min, // Ensure this column takes minimum space required
                            children: [
                              // BizKit Logo
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/placeholder.png',
                                    height: 100.0,
                                    width: 100.0,
                                  ),
                                  // SizedBox(width: 8.0),
                                  // Text(
                                  //   'BizKit', // Changed from Tasky
                                  //   style: TextStyle(
                                  //     fontSize: 24.0,
                                  //     fontWeight: FontWeight.bold,
                                  //     color: Color(0xFF1F2937), // Gray-800 color
                                  //   ),
                                  // ),
                                ],
                              ),
                              // const SizedBox(height: 40.0), // mb-10 equivalent

                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 30.0, // text-3xl
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827), // Gray-900 color
                                ),
                              ),
                              const SizedBox(height: 8.0), // mb-2
                              const Text(
                                'Please enter login details below',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Color(0xFF4B5563), // Gray-600 color
                                ),
                              ),
                            ],
                          ),

                          // Login Form fields and buttons
                          const SizedBox(height: 32.0), // Spacing before email
                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter the email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16.0), // Spacing
                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true, // Hides input for passwords
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter the Password',
                            ),
                          ),
                          const SizedBox(height: 12.0), // Spacing
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: RichText(
                              text: TextSpan(
                                text: 'Forgot password?',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB), // Blue-600 color
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _handleForgotPassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0), // Spacing
                          // Sign in Button
                          ElevatedButton(
                            onPressed: _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF2563EB), // Blue-600 color
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(
                                  50), // w-full and py-3 equivalent
                            ),
                            child: const Text('Sign in'),
                          ),
                          const SizedBox(height: 32.0), // Spacing

                          // Or continue divider
                          Row(
                            children: const [
                              Expanded(
                                  child: Divider(
                                      color: Color(0xFFD1D5DB))), // Gray-300 color
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Or continue',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Color(0xFF6B7280), // Gray-500 color
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Color(0xFFD1D5DB))), // Gray-300 color
                            ],
                          ),
                          const SizedBox(height: 32.0), // Spacing

                          // Log in with Google Button
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                final userCredential =
                                    await authService.value.signInWithGoogle();
                                // Log user activity in Firestore
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
                                    'message': 'User successfully logged in',
                                    'timestamp': FieldValue.serverTimestamp()
                                  });
                                  // Ensure user data is created/checked in Firestore
                                  await authService.value.userData();
                                }
                                // Removed direct navigation here, relying on StreamBuilder for existing users.
                              } catch (e) {
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Sign in failed'),
                                    content: Text('Google sign in failed. Please try again.\n$e'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor:
                                  const Color(0xFF4B5563), // Text gray-700 color
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Placeholder for Google icon. In a real app, use asset or a package like font_awesome_flutter
                                Image.network(
                                  'https://img.icons8.com/color/48/000000/google-logo.png', // Example Google icon URL
                                  height: 24.0,
                                  width: 24.0,
                                  // Fallback for when image fails to load
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata,
                                          size: 24.0, color: Colors.blue),
                                ),
                                const SizedBox(width: 8.0),
                                const Text('Log in with Google'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0), // Spacing before phone sign-in
                          // New: Sign in with Phone Button
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
                          const SizedBox(height: 24.0), // Spacing before "Don't have an account?"
                          // Don't have an account? Sign Up
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: const TextStyle(
                                  color: Color(0xFF4B5563), // Gray-600 color
                                  fontSize: 16.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB), // Blue-600 color
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    // Using TapGestureRecognizer for individual text span tap detection
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _handleSignUp,
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

                // Right Section - Carousel (PageView)
                Expanded(
                  flex: isLargeScreen ? 1 : 0, // Flex only if large screen, allows carousel to take half width
                  child: Container(
                    padding: const EdgeInsets.all(48.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1), // Indigo-500 from Tailwind
                          Color(0xFF9333EA), // Purple-600 from Tailwind
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: const Radius.circular(16.0),
                        bottomRight: const Radius.circular(16.0),
                        bottomLeft:
                            isLargeScreen ? Radius.zero : const Radius.circular(16.0),
                        // Top left is handled by the parent Card widget or left panel's border radius
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _carouselSlides.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                                _startCarouselAutoPlay(); // Restart timer on manual swipe
                              });
                            },
                            itemBuilder: (context, index) {
                              final slide = _carouselSlides[index];
                              return _buildCarouselSlide(
                                imagePath: slide['image']!,
                                text: slide['text']!,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Carousel Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_carouselSlides.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                                _startCarouselAutoPlay(); // Restart timer on dot tap
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeInOut,
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withAlpha((0.5 * 255).toInt()),
                                ),
                              ),
                            );
                          }),
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
    );
  }

  Widget _buildCarouselSlide({required String imagePath, required String text}) {
    final bool isSvg = imagePath.toLowerCase().endsWith('.svg');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: isSvg
              ? SvgPicture.asset(
                  imagePath,
                  height: 250,
                  width: 300,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => Container(
                    height: 250,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[400],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : Image.network(
                  imagePath,
                  fit: BoxFit.contain,
                  height: 250,
                  width: 300,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[400],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Center(
                      child: Text(
                        'Illustration Error',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24.0),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// --- NEW WIDGET: Forgot Password Dialog ---
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

    // Call the callback to send password reset email
    widget.onEmailSubmitted(email);

    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
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
        constraints: const BoxConstraints(maxWidth: 400), // Max width for the dialog
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
              // Icon/Image Section (using a simple icon as placeholder for custom image)
              Icon(
                Icons.lock_reset, // Or Icons.mail_outline
                size: 60.0,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24.0),
              // Title
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827), // Gray-900
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              // Description
              const Text(
                'Enter your email address below to receive a password reset link.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF4B5563), // Gray-600
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              // Email Input
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
              // Send Reset Link Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // Blue-600
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50), // Full width
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
              // Cancel Button
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

// --- NEW WIDGET: Phone Sign-In Dialog ---
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
  String? _verificationId; // Stores the verification ID sent by Firebase
  bool _codeSent = false; // Tracks if OTP has been sent

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

  // --- NEW WIDGET: Phone Sign-In Dialog ---
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
                          // Verify OTP
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
                              // The onSignInSuccess callback now handles navigation
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => _isLoading = false);
                            widget.onSignInFailed(e.message ?? 'OTP verification failed.');
                          }
                        } else {
                          // Send code
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