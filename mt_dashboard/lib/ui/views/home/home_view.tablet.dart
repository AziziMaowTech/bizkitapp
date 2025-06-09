import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeViewTablet extends ViewModelWidget<HomeViewModel> {
  const HomeViewTablet({super.key});

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
              color: Colors.green,
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
                      height: 240,
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
                            Icon(Icons.settings, size: 40, color: Colors.green),
                            SizedBox(height: 8),
                            Text(
                              'Grow your business',
                              style: TextStyle(color: Colors.black),
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
                            Icon(Icons.settings, size: 40, color: Colors.green),
                            SizedBox(height: 8),
                            Text(
                              'Grow your business',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                    ],
                  ),
                  SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
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
                            Icon(Icons.settings, size: 40, color: Colors.green),
                            SizedBox(height: 8),
                            Text(
                              'Grow your business',
                              style: TextStyle(color: Colors.black),
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
                            Icon(Icons.settings, size: 40, color: Colors.green),
                            SizedBox(height: 8),
                            Text(
                              'Grow your business',
                              style: TextStyle(color: Colors.black),
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
                      'assets/images/mtcircle.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    ),
                    TextButton(
                      onPressed: () {},
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
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(Colors.greenAccent),
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
                        'assets/images/download.png',
                        height: 20,
                        width: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Sign in with Whatsapp', style: TextStyle(color: Colors.white)),
                      ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      style: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(Colors.black),
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
                        SvgPicture.asset(
                        'assets/images/apple_logo.svg',
                        height: 20,
                        width: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Sign in with Apple', style: TextStyle(color: Colors.white)),
                      ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
    ));
  }
}
