import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String role;

  const AttendanceScreen({
    super.key,
    this.role = 'Teacher',
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  bool isSaving = false;
  bool isLoadingStudents = false;
  String? errorMessage;

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];

  String selectedClassId = '';
  String selectedClassName = '';

  final Map<String, String> attendanceStatus = {};

  bool get canMarkAttendance {
    return widget.role == 'Teacher' || widget.role == 'Admin';
  }

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedClasses = await databaseService.getClasses();

      if (!mounted) return;

      setState(() {
        classes = loadedClasses;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> loadStudentsByClass(String classId) async {
    try {
      setState(() {
        isLoadingStudents = true;
        students = [];
        attendanceStatus.clear();
      });

      final loadedStudents = await databaseService.getStudentsByClass(
        classId: classId,
      );

      for (final student in loadedStudents) {
        attendanceStatus[student['id']] = 'Present';
      }

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        isLoadingStudents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoadingStudents = false;
      });
    }
  }

  Future<void> saveAttendance() async {
    if (selectedClassId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
        ),
      );
      return;
    }

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found for this class'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final attendanceData = students.map((student) {
        final studentId = student['id'] ?? '';

        return {
          'studentId': studentId,
          'studentName': student['fullName'] ?? 'Unknown Student',
          'status': attendanceStatus[studentId] ?? 'Present',
        };
      }).toList();

      await databaseService.saveAttendance(
        classId: selectedClassId,
        className: selectedClassName,
        markedBy: widget.role,
        attendanceData: attendanceData,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void selectClass(String? value) {
    if (value == null) return;

    final selectedClass = classes.firstWhere(
      (schoolClass) => schoolClass['id'] == value,
      orElse: () => {},
    );

    setState(() {
      selectedClassId = value;
      selectedClassName = selectedClass['className'] ?? '';
    });

    loadStudentsByClass(value);
  }

  Widget emptyClassState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No classes found yet. Create a class first from Admin Dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget emptyStudentState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No students found for this class. Assign students to this class from User Management first.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget studentAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Unknown Student';
    final status = attendanceStatus[studentId] ?? 'Present';

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
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedClassName.isEmpty ? 'No class' : selectedClassName,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (canMarkAttendance)
            DropdownButton<String>(
              value: status,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: 'Present',
                  child: Text('Present'),
                ),
                DropdownMenuItem(
                  value: 'Absent',
                  child: Text('Absent'),
                ),
                DropdownMenuItem(
                  value: 'Late',
                  child: Text('Late'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  attendanceStatus[studentId] = value;
                });
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.role} Attendance';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadClasses,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : classes.isEmpty
                    ? emptyClassState()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedClassId.isEmpty
                                  ? null
                                  : selectedClassId,
                              decoration: const InputDecoration(
                                labelText: 'Select Class',
                                prefixIcon: Icon(Icons.class_outlined),
                              ),
                              items: classes.map((schoolClass) {
                                return DropdownMenuItem<String>(
                                  value: schoolClass['id'],
                                  child: Text(
                                    schoolClass['className'] ??
                                        'Unnamed Class',
                                  ),
                                );
                              }).toList(),
                              onChanged: selectClass,
                            ),
                          ),
                          if (selectedClassId.isEmpty)
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Select a class to load students.',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            )
                          else if (isLoadingStudents)
                            const Expanded(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (students.isEmpty)
                            Expanded(
                              child: emptyStudentState(),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 0, 18, 90),
                                itemCount: students.length,
                                separatorBuilder: (context, index) {
                                  return const SizedBox(height: 12);
                                },
                                itemBuilder: (context, index) {
                                  return studentAttendanceCard(
                                    students[index],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
      ),
      bottomNavigationBar: canMarkAttendance
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                color: AppColors.white,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveAttendance,
                    icon: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Attendance',
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}