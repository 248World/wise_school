import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fees = [
      {
        'title': 'School Fees',
        'amount': '2500 MAD',
        'status': 'Paid',
        'dueDate': 'Paid on Apr 12, 2026',
      },
      {
        'title': 'Transport Fees',
        'amount': '600 MAD',
        'status': 'Pending',
        'dueDate': 'Due May 10, 2026',
      },
      {
        'title': 'Exam Fees',
        'amount': '300 MAD',
        'status': 'Pending',
        'dueDate': 'Due May 20, 2026',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fees'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: fees.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = fees[index];
            final bool isPaid = item['status'] == 'Paid';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          item['amount'] as String,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          item['dueDate'] as String,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.softGreen.withValues(alpha: 0.14)
                          : AppColors.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: TextStyle(
                        color: isPaid ? AppColors.softGreen : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}