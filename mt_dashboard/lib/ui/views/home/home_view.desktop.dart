import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/dashboard_view.dart';
import 'package:stacked/stacked.dart';
import 'package:mt_dashboard/authentication/auth_services.dart';

import 'home_viewmodel.dart';

class HomeViewDesktop extends ViewModelWidget<HomeViewModel> {
  const HomeViewDesktop({super.key});

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return Scaffold(
    // Outside Row
    body: Row(
        children: [
          // Left pane
          Expanded(
            flex: 5,
            child: Container(
              color: const Color.fromARGB(255, 24, 119, 242),
                child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // First row with icons and labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Image.asset(
                      'assets/images/hero-image.webp',
                    ),
                    ],
                  ),
                  SizedBox(height: 32),
                  // Second row for image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        width: 160,
                        height: 120,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          ),
                        ],
                        ),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat, size: 40, color: const Color.fromARGB(255, 24, 119, 242)),
                          SizedBox(height: 8),
                          Text(
                          'Bulk upload via Excel',
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          ),
                        ],
                        ),
                      ),
                      ],
                    ),
                    SizedBox(width: 32),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        width: 160,
                        height: 120,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          ),
                        ],
                        ),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, size: 40, color: const Color.fromARGB(255, 24, 119, 242)),
                          SizedBox(height: 8),
                          Text(
                          'Create your catalogue',
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          ),
                        ],
                        ),
                      ),
                      ],
                    ),
                    SizedBox(width: 32),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        width: 160,
                        height: 120,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          ),
                        ],
                        ),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart, size: 40, color: const Color.fromARGB(255, 24, 119, 242)),
                          SizedBox(height: 8),
                          Text(
                          'Start your online business',
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          ),
                        ],
                        ),
                      ),
                      ],
                    ),
                    SizedBox(width: 32),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        width: 160,
                        height: 120,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          ),
                        ],
                        ),
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart , size: 40, color: const Color.fromARGB(255, 24, 119, 242),),
                          SizedBox(height: 8),
                          Text(
                          'Grow your business',
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          ),
                        ],
                        ),
                      ),
                      ],
                    ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          // Vertical divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey[400],
          ),
          // Right pane
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text(
                    'Get started with',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Image.asset(
                      'assets/images/placeholder.png',
                      width: 360,
                      height: 360,
                      fit: BoxFit.contain,
                    ),
                    ),
                    TextButton(
                      onPressed: () async { 
                        try {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              final emailController = TextEditingController();
                              final passwordController = TextEditingController();
                              bool isLoading = false;

                              return StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: Text('Sign in with Email'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.email),
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                      SizedBox(height: 16),
                                      TextField(
                                        controller: passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: Icon(Icons.lock),
                                        ),
                                        obscureText: true,
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              // Handle forgot password
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  final forgotEmailController = TextEditingController();
                                                  return AlertDialog(
                                                    title: Text('Forgot Password'),
                                                    content: TextField(
                                                      controller: forgotEmailController,
                                                      decoration: InputDecoration(
                                                        labelText: 'Enter your email',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          try {
                                                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                                              email: forgotEmailController.text.trim(),
                                                            );
                                                            Navigator.of(context).pop();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Password reset email sent')),
                                                            );
                                                          } catch (e) {
                                                            Navigator.of(context).pop();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Failed to send reset email: $e')),
                                                            );
                                                          }
                                                        },
                                                        child: Text('Send'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: Text('Cancel'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Text('Forgot password?'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // Handle create account
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  final createEmailController = TextEditingController();
                                                  final createPasswordController = TextEditingController();
                                                  return AlertDialog(
                                                    title: Text('Create Account'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller: createEmailController,
                                                          decoration: InputDecoration(
                                                            labelText: 'Email',
                                                          ),
                                                        ),
                                                        SizedBox(height: 16),
                                                        TextField(
                                                          controller: createPasswordController,
                                                          decoration: InputDecoration(
                                                            labelText: 'Password',
                                                          ),
                                                          obscureText: true,
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          try {
                                                            await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                                              email: createEmailController.text.trim(),
                                                              password: createPasswordController.text.trim(),
                                                            );
                                                            // After account creation, add user to Firestore
                                                            await authService.value.userData();
                                                            Navigator.of(context).pop();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Account created! Please sign in.')),
                                                            );
                                                          } catch (e) {
                                                            Navigator.of(context).pop();
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Failed to create account: $e')),
                                                            );
                                                          }
                                                        },
                                                        child: Text('Create'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: Text('Cancel'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Text('Create account'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              setState(() => isLoading = true);
                                              try {
                                                await FirebaseAuth.instance.signInWithEmailAndPassword(
                                                  email: emailController.text.trim(),
                                                  password: passwordController.text.trim(),
                                                );
                                                Navigator.of(context).pop();
                                                if (!context.mounted) return;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => DashboardView()),
                                                );
                                              } catch (e) {
                                                setState(() => isLoading = false);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Sign in failed: $e')),
                                                );
                                              }
                                            },
                                      child: isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text('Sign in'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Sign in failed'),
                              content: Text('Email sign in failed. Please try again.\n$e'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                        } ,
                      style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(Colors.blue),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      ),
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Sign in with Email', style: TextStyle(color: Colors.white)),
                      ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () async { 
                        try {
                          await authService.value.signInWithGoogle();
                          // Navigate to dashboard on success
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DashboardView()),
                          );
                          await authService.value.userData();
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
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                        } ,
                      style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(Colors.blue),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      ),
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                        'assets/images/download (1).png',
                        height: 20,
                        width: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                      ],
                      ),
                    ),
                    // SizedBox(height: 16),
                    // TextButton(
                    //   onPressed: () {},
                    //   style: ButtonStyle(
                    //   backgroundColor: const WidgetStatePropertyAll(Colors.greenAccent),
                    //   shape: WidgetStatePropertyAll(
                    //     RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(12),
                    //     ),
                    //   ),
                    //   padding: WidgetStatePropertyAll(
                    //     EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    //   ),
                    //   ),
                    //   child: Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Image.asset(
                    //     'assets/images/download.png',
                    //     height: 20,
                    //     width: 20,
                    //     ),
                    //     SizedBox(width: 8),
                    //     Text('Sign in with Whatsapp', style: TextStyle(color: Colors.white)),
                    //   ],
                    //   ),
                    // ),
                    // SizedBox(height: 16),
                    // TextButton(
                    //   onPressed: () {},
                    //   style: ButtonStyle(
                    //   backgroundColor: const WidgetStatePropertyAll(Colors.black),
                    //   shape: WidgetStatePropertyAll(
                    //     RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(12),
                    //     ),
                    //   ),
                    //   padding: WidgetStatePropertyAll(
                    //     EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    //   ),
                    //   ),
                    //   child: Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     SvgPicture.asset(
                    //     'assets/images/apple_logo.svg',
                    //     height: 20,
                    //     width: 20,
                    //     ),
                    //     SizedBox(width: 8),
                    //     Text('Sign in with Apple', style: TextStyle(color: Colors.white)),
                    //   ],
                    //   ),
                    // ),
                    // SizedBox(height: 16),
                    // TextButton(
                    //   onPressed: () {
                    //     Navigator.pop(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => DashboardView()),
                    //     );
                    //   },
                    //   style: ButtonStyle(
                    //   backgroundColor: const WidgetStatePropertyAll(Colors.black),
                    //   shape: WidgetStatePropertyAll(
                    //     RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(12),
                    //     ),
                    //   ),
                    //   padding: WidgetStatePropertyAll(
                    //     EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    //   ),
                    //   ),
                    //   child: Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     SvgPicture.asset(
                    //     'assets/images/apple_logo.svg',
                    //     height: 20,
                    //     width: 20,
                    //     ),
                    //     SizedBox(width: 8),
                    //     Text('Continue as guest', style: TextStyle(color: Colors.white)),
                    //   ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
    ));
  }
}

