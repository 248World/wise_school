import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final String role;

  const ProfileScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 65,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Varney D Fahnbulleh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                role,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textGrey,
                ),
              ),

              const SizedBox(height: 30),

              profileItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: 'user@wiseschool.com',
              ),

              profileItem(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: '+212 600 000 000',
              ),

              profileItem(
                icon: Icons.badge_outlined,
                title: 'Role',
                value: role,
              ),

              profileItem(
                icon: Icons.location_city_outlined,
                title: 'School',
                value: 'Wise School',
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}