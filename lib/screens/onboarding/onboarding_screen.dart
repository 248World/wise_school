import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_choice_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  int currentIndex = 0;

  final List<Map<String, dynamic>> slides = [
    {
      'icon': Icons.dashboard_customize_outlined,
      'title': 'Manage School Activities',
      'description':
          'Organize users, classes, subjects, attendance, marks, and school reports in one simple app.',
    },
    {
      'icon': Icons.groups_outlined,
      'title': 'Connect Everyone',
      'description':
          'Bring Admins, Teachers, Students, and Parents together through role-based access.',
    },
    {
      'icon': Icons.smart_toy_outlined,
      'title': 'Use AI for Smarter Work',
      'description':
          'Prepare reports, summarize performance, create announcements, and support learning with AI tools.',
    },
  ];

  void goToAuthChoice() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthChoiceScreen(),
      ),
    );
  }

  void nextPage() {
    if (currentIndex == slides.length - 1) {
      goToAuthChoice();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget buildDot(int index) {
    final bool isActive = currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget buildSlide(Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 130,
            width: 130,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide['icon'] as IconData,
              size: 70,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 35),
          Text(
            slide['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide['description'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: goToAuthChoice,
                child: const Text('Skip'),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return buildSlide(slides[index]);
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                buildDot,
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: nextPage,
                  child: Text(
                    currentIndex == slides.length - 1
                        ? 'Get Started'
                        : 'Continue',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}