import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    scaleAnimation = Tween<double>(
      begin: 0.86,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutBack,
      ),
    );

    animationController.forward();

    goToNextScreen();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<void> goToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  Widget bubble({
    required double size,
    required double opacity,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget backgroundDesign() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.authGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 45,
            left: 34,
            child: bubble(size: 8, opacity: 0.14),
          ),
          Positioned(
            top: 82,
            right: 46,
            child: bubble(size: 54, opacity: 0.10),
          ),
          Positioned(
            top: 145,
            left: -42,
            child: bubble(size: 175, opacity: 0.08),
          ),
          Positioned(
            top: 235,
            right: -48,
            child: bubble(size: 150, opacity: 0.08),
          ),
          Positioned(
            bottom: 170,
            left: 68,
            child: bubble(size: 58, opacity: 0.10),
          ),
          Positioned(
            bottom: 110,
            right: 62,
            child: bubble(size: 40, opacity: 0.12),
          ),
        ],
      ),
    );
  }

  Widget logoBox() {
    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          height: 108,
          width: 108,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.28),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_outlined,
            size: 60,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget content() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logoBox(),
              const SizedBox(height: 28),
              const Text(
                'Wise School',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'AI-Powered School Management',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 42),
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomText() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 34,
      child: SafeArea(
        top: false,
        child: Text(
          'Smart tools for learning, communication, and progress.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.72),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          backgroundDesign(),
          content(),
          bottomText(),
        ],
      ),
    );
  }
}