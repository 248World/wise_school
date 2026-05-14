import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  /// Optional PNG icon path.
  /// Example: assets/icons/modules.png
  final String? imagePath;

  /// Fallback icon if PNG is missing.
  final IconData? icon;

  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.imagePath,
    this.icon,
    this.actionText,
    this.onActionTap,
  });

  Widget sectionIcon() {
    if (imagePath == null && icon == null) {
      return const SizedBox();
    }

    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: imagePath != null && imagePath!.trim().isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      icon ?? Icons.apps_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    );
                  },
                ),
              )
            : Icon(
                icon ?? Icons.apps_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasIcon = imagePath != null || icon != null;

    return Row(
      children: [
        if (hasIcon) ...[
          sectionIcon(),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
        ),
        if (actionText != null && actionText!.trim().isNotEmpty)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionText!),
          ),
      ],
    );
  }
}