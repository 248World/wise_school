import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ModuleCard extends StatelessWidget {
  final String title;

  /// Fallback icon if PNG is missing.
  final IconData icon;

  /// Required PNG path.
  /// Example: assets/icons/attendance.png
  final String imagePath;

  final VoidCallback? onTap;

  /// Optional badge text like notification count.
  final String? badgeText;

  const ModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.imagePath,
    this.onTap,
    this.badgeText,
  });

  Widget moduleIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon,
                    color: AppColors.primaryBlue,
                    size: 32,
                  );
                },
              ),
            ),
          ),
        ),
        if (badgeText != null && badgeText!.trim().isNotEmpty)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 22,
                minWidth: 22,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
              child: Text(
                badgeText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.softBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -26,
                right: -24,
                child: Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.045),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    moduleIcon(),
                    const SizedBox(height: 13),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textLight,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}