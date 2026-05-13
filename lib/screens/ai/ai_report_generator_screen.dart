import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AIReportGeneratorScreen extends StatefulWidget {
  const AIReportGeneratorScreen({super.key});

  @override
  State<AIReportGeneratorScreen> createState() =>
      _AIReportGeneratorScreenState();
}

class _AIReportGeneratorScreenState extends State<AIReportGeneratorScreen> {
  String selectedTarget = 'Class A';
  String selectedReportType = 'Monthly School Report';

  final List<String> targets = [
    'Class A',
    'Class B',
    'Student One',
    'Student Two',
  ];

  final List<String> reportTypes = [
    'Monthly School Report',
    'Attendance Report',
    'Performance Report',
    'Parent Progress Summary',
  ];

  bool showPreview = false;

  void generateReport() {
    setState(() {
      showPreview = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI report generated as preview'),
      ),
    );
  }

  void approveReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report approved successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Report Generator'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate Smart Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Use AI to prepare school, class, attendance, or student performance reports.',
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
                  prefixIcon: Icon(Icons.groups_outlined),
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

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: selectedReportType,
                decoration: const InputDecoration(
                  labelText: 'Select Report Type',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                items: reportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReportType = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: generateReport,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Generate Report'),
                ),
              ),

              const SizedBox(height: 24),

              if (showPreview)
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
                      const Text(
                        'AI Generated Report Preview',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Target: $selectedTarget',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Report Type: $selectedReportType',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'This is a placeholder AI report. The final version will analyze attendance, marks, assignments, and school records to generate a professional summary.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: approveReport,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve Report'),
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