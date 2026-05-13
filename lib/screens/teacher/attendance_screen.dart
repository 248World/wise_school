import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  final String role;

  const AttendanceScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String selectedClass = 'Class A';

  final List<String> classes = [
    'Class A',
    'Class B',
    'Class C',
  ];

  final List<Map<String, dynamic>> students = [
    {
      'name': 'Student One',
      'status': true,
    },
    {
      'name': 'Student Two',
      'status': true,
    },
    {
      'name': 'Student Three',
      'status': false,
    },
    {
      'name': 'Student Four',
      'status': true,
    },
  ];

  void saveAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = widget.role == 'Teacher';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTeacher) ...[
                const Text(
                  'Select Class',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.class_outlined),
                    labelText: 'Class',
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
                const SizedBox(height: 24),
              ],

              Text(
                isTeacher ? 'Student Attendance' : 'My Attendance Summary',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 14),

              if (!isTeacher)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        color: AppColors.primaryBlue,
                        size: 36,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Percentage',
                              style: TextStyle(
                                color: AppColors.textGrey,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '89%',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
                        if (isTeacher)
                          Switch(
                            value: student['status'] as bool,
                            activeColor: AppColors.primaryBlue,
                            onChanged: (value) {
                              setState(() {
                                student['status'] = value;
                              });
                            },
                          )
                        else
                          Text(
                            student['status'] == true ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: student['status'] == true
                                  ? AppColors.softGreen
                                  : AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              if (isTeacher) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: saveAttendance,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Attendance'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}