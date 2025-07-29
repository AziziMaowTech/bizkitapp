import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class AuthCarousel extends StatefulWidget {
  const AuthCarousel({super.key});

  @override
  State<AuthCarousel> createState() => _AuthCarouselState();
}

class _AuthCarouselState extends State<AuthCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  final List<Map<String, String>> _carouselSlides = [
    {
      'image': 'assets/images/undraw_accept-task.svg',
      'text': 'Manage your task in an easy and more efficient way with BizKit.',
    },
    {
      'image': 'assets/images/undraw_engineering-team.svg',
      'text': 'Stay organized and boost your productivity with smart reminders and lists.',
    },
    {
      'image': 'assets/images/undraw_working-together.svg',
      'text': 'Collaborate seamlessly with your team and achieve your goals together.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int? nextP = _pageController.page?.round();
      if (nextP != null && _currentPage != nextP) {
        setState(() {
          _currentPage = nextP;
        });
      }
    });
    _startCarouselAutoPlay();
  }

  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _carouselSlides.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
          );
        } else {
          _pageController.jumpToPage(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF9333EA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16.0),
          bottomRight: Radius.circular(16.0),
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
                  _startCarouselAutoPlay();
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
                  _startCarouselAutoPlay();
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
                      color: Colors.deepPurple[(_currentPage % 6) * 100 + 400]!, // Dynamic color based on page
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : Image.asset(
                  imagePath, // Assumed to be assets/images, if from network, use Image.network
                  fit: BoxFit.contain,
                  height: 250,
                  width: 300,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[(_currentPage % 6) * 100 + 400]!,
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