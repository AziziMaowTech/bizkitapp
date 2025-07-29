import 'package:flutter/material.dart';

class HomeViewMobile extends StatelessWidget {
  const HomeViewMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeMobile = screenWidth > 400;
    final cardWidth = double.infinity;
    final cardHeight = isLargeMobile ? 110.0 : 90.0;
    final iconSize = isLargeMobile ? 38.0 : 32.0;
    final fontSize = isLargeMobile ? 16.0 : 14.0;
    final imageSize = isLargeMobile ? 180.0 : 140.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo/Image
              Image.asset(
                'assets/images/hero-image.webp',
                width: imageSize,
                height: imageSize,
              ),
              const SizedBox(height: 24),
              // Feature cards
              _FeatureCard(
                width: cardWidth,
                height: cardHeight,
                icon: Icons.chat,
                iconSize: iconSize,
                label: 'Bulk upload via Excel',
                fontSize: fontSize,
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                width: cardWidth,
                height: cardHeight,
                icon: Icons.rocket_launch,
                iconSize: iconSize,
                label: 'Create your catalogue',
                fontSize: fontSize,
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                width: cardWidth,
                height: cardHeight,
                icon: Icons.shopping_cart,
                iconSize: iconSize,
                label: 'Start your online business',
                fontSize: fontSize,
              ),
              const SizedBox(height: 14),
              _FeatureCard(
                width: cardWidth,
                height: cardHeight,
                icon: Icons.bar_chart,
                iconSize: iconSize,
                label: 'Grow your business',
                fontSize: fontSize,
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Get started with',
                style: TextStyle(
                  fontSize: isLargeMobile ? 26 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              // Placeholder image
              Image.asset(
                'assets/images/placeholder.png',
                width: imageSize + 40,
                height: imageSize + 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              // Sign-in buttons
              _SignInButtons(isLargeMobile: isLargeMobile),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: const Color.fromARGB(255, 24, 119, 242)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.black, fontSize: fontSize),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButtons extends StatelessWidget {
  final bool isLargeMobile;
  const _SignInButtons({required this.isLargeMobile});

  @override
  Widget build(BuildContext context) {
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: isLargeMobile ? 24 : 16,
      vertical: isLargeMobile ? 16 : 12,
    );
    final buttonFontSize = isLargeMobile ? 16.0 : 14.0;

    return Column(
      children: [
        TextButton(
          onPressed: () async {
            // Add your sign-in dialog logic here
          },
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.blue),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            padding: WidgetStatePropertyAll(buttonPadding),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text('Sign in with Email', style: TextStyle(color: Colors.white, fontSize: buttonFontSize)),
            ],
          ),
        ),
        SizedBox(height: isLargeMobile ? 18 : 12),
        TextButton(
          onPressed: () async {
            // Add your Google sign-in logic here
          },
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.blue),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
              const SizedBox(width: 8),
              Text('Sign in with Google', style: TextStyle(color: Colors.white, fontSize: buttonFontSize)),
            ],
          ),
        ),
      ],
    );
  }
}
