import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ChildOverviewScreen extends StatelessWidget {
  const ChildOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final overviewItems = [
      {
        'title': 'Attendance',
        'value': '91%',
        'icon': Icons.fact_check_outlined,
      },
      {
        'title': 'Average Result',
        'value': '15.2/20',
        'icon': Icons.bar_chart_outlined,
      },
      {
        'title': 'Pending Assignments',
        'value': '03',
        'icon': Icons.assignment_outlined,
      },
      {
        'title': 'Fee Status',
        'value': 'Paid',
        'icon': Icons.payments_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Child Overview'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.child_care_outlined,
                        color: AppColors.primaryBlue,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student One',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Class A • Student ID: WS-2026-001',
                            style: TextStyle(
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Academic Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 14),

              GridView.builder(
                itemCount: overviewItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final item = overviewItems[index];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: AppColors.primaryBlue,
                          size: 30,
                        ),
                        const Spacer(),
                        Text(
                          item['value'] as String,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.primaryBlue,
                      size: 36,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'AI Progress Summary: Your child is performing well, but should improve assignment submission consistency.',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
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