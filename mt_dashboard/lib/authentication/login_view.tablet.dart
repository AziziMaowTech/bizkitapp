import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'login_viewmodel.dart';

class LoginViewTablet extends ViewModelWidget<LoginViewModel> {
  const LoginViewTablet({super.key});

  @override
  Widget build(BuildContext context, LoginViewModel viewModel) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeTablet = screenWidth > 1000;
    final cardWidth = isLargeTablet ? 200.0 : 160.0;
    final cardHeight = isLargeTablet ? 140.0 : 120.0;
    final iconSize = isLargeTablet ? 48.0 : 40.0;
    final fontSize = isLargeTablet ? 18.0 : 16.0;
    final imageSize = isLargeTablet ? 420.0 : 320.0;

    return Scaffold(
      body: Row(
        children: [
          // Left pane
          Expanded(
            flex: 5,
            child: Container(
              color: const Color.fromARGB(255, 24, 119, 242),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isLargeTablet ? 48 : 24, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo/Image
                        Image.asset(
                          'assets/images/hero-image.webp',
                          width: isLargeTablet ? 220 : 160,
                          height: isLargeTablet ? 220 : 160,
                        ),
                        SizedBox(height: isLargeTablet ? 48 : 32),
                        // Feature cards in a Wrap for better tablet layout
                        Wrap(
                          spacing: isLargeTablet ? 40 : 24,
                          runSpacing: isLargeTablet ? 32 : 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _FeatureCard(
                              width: cardWidth,
                              height: cardHeight,
                              icon: Icons.chat,
                              iconSize: iconSize,
                              label: 'Bulk upload via Excel',
                              fontSize: fontSize,
                            ),
                            _FeatureCard(
                              width: cardWidth,
                              height: cardHeight,
                              icon: Icons.rocket_launch,
                              iconSize: iconSize,
                              label: 'Create your catalogue',
                              fontSize: fontSize,
                            ),
                            _FeatureCard(
                              width: cardWidth,
                              height: cardHeight,
                              icon: Icons.shopping_cart,
                              iconSize: iconSize,
                              label: 'Start your online business',
                              fontSize: fontSize,
                            ),
                            _FeatureCard(
                              width: cardWidth,
                              height: cardHeight,
                              icon: Icons.bar_chart,
                              iconSize: iconSize,
                              label: 'Grow your business',
                              fontSize: fontSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isLargeTablet ? 48 : 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get started with',
                          style: TextStyle(
                            fontSize: isLargeTablet ? 32 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Image.asset(
                            'assets/images/placeholder.png',
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                        _SignInButtons(isLargeTablet: isLargeTablet),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final double width;
  final double height;
  final IconData icon;
  final double iconSize;
  final String label;
  final double fontSize;

  const _FeatureCard({
    required this.width,
    required this.height,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: const Color.fromARGB(255, 24, 119, 242)),
          SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: Colors.black, fontSize: fontSize),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _SignInButtons extends StatelessWidget {
  final bool isLargeTablet;
  const _SignInButtons({required this.isLargeTablet});

  @override
  Widget build(BuildContext context) {
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: isLargeTablet ? 32 : 24,
      vertical: isLargeTablet ? 20 : 16,
    );
    final buttonFontSize = isLargeTablet ? 18.0 : 16.0;

    return Column(
      children: [
        TextButton(
          onPressed: () async {
            // ... (same as your sign-in dialog logic)
            // You can keep your existing sign-in dialog code here.
          },
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.blue),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            padding: WidgetStatePropertyAll(buttonPadding),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text('Sign in with Email', style: TextStyle(color: Colors.white, fontSize: buttonFontSize)),
            ],
          ),
        ),
        SizedBox(height: isLargeTablet ? 24 : 16),
        TextButton(
          onPressed: () async {
            // ... (same as your Google sign-in logic)
          },
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.blue),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            padding: WidgetStatePropertyAll(buttonPadding),
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
              Text('Sign in with Google', style: TextStyle(color: Colors.white, fontSize: buttonFontSize)),
            ],
          ),
        ),
      ],
    );
  }
}
