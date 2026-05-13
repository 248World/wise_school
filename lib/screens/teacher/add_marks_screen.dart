import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AddMarksScreen extends StatefulWidget {
  const AddMarksScreen({super.key});

  @override
  State<AddMarksScreen> createState() => _AddMarksScreenState();
}

class _AddMarksScreenState extends State<AddMarksScreen> {
  String selectedClass = 'Class A';
  String selectedSubject = 'Mathematics';

  final List<String> classes = [
    'Class A',
    'Class B',
    'Class C',
  ];

  final List<String> subjects = [
    'Mathematics',
    'Science',
    'English',
    'Computer Science',
  ];

  final List<Map<String, dynamic>> students = [
    {
      'name': 'Student One',
      'mark': TextEditingController(),
    },
    {
      'name': 'Student Two',
      'mark': TextEditingController(),
    },
    {
      'name': 'Student Three',
      'mark': TextEditingController(),
    },
    {
      'name': 'Student Four',
      'mark': TextEditingController(),
    },
  ];

  @override
  void dispose() {
    for (final student in students) {
      final controller = student['mark'] as TextEditingController;
      controller.dispose();
    }
    super.dispose();
  }

  void saveMarks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marks saved successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Marks'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Class and Subject',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: classes.map((className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value!;
                  });
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: subjects.map((subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubject = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Student Marks',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 14),

              ListView.separated(
                itemCount: students.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = students[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primaryBlue.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primaryBlue,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Text(
                            student['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller:
                                student['mark'] as TextEditingController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0/20',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: saveMarks,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Marks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}