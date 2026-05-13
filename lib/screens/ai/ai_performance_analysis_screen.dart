import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AIPerformanceAnalysisScreen extends StatefulWidget {
  const AIPerformanceAnalysisScreen({super.key});

  @override
  State<AIPerformanceAnalysisScreen> createState() =>
      _AIPerformanceAnalysisScreenState();
}

class _AIPerformanceAnalysisScreenState
    extends State<AIPerformanceAnalysisScreen> {
  String selectedTarget = 'Student One';

  final List<String> targets = [
    'Student One',
    'Student Two',
    'Class A',
    'Class B',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Performance Analysis'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analyze Student Performance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'AI will help summarize attendance, marks, progress, and risk level.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: selectedTarget,
                decoration: const InputDecoration(
                  labelText: 'Select Student or Class',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
                items: targets.map((target) {
                  return DropdownMenuItem<String>(
                    value: target,
                    child: Text(target),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTarget = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: summaryBox(
                      title: 'Attendance',
                      value: '89%',
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: summaryBox(
                      title: 'Average Mark',
                      value: '14.5',
                      icon: Icons.bar_chart_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: summaryBox(
                      title: 'Assignments',
                      value: '03 Pending',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: summaryBox(
                      title: 'Risk Level',
                      value: 'Medium',
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'AI Insight',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      '$selectedTarget has a good academic level, but attendance and assignment consistency should be monitored. The system can later use real marks and attendance data to generate better predictions.',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Risk Badge: Medium Attention Needed',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI analysis refreshed'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Refresh Analysis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
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
            icon,
            color: AppColors.primaryBlue,
            size: 30,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}