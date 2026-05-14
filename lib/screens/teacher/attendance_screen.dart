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
        final studentId = student['id'] ?? '';

        if (studentId.toString().isNotEmpty) {
          attendanceStatus[studentId] = 'Present';
        }
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
      showSnackBar('Please select a class');
      return;
    }

    if (students.isEmpty) {
      showSnackBar('No students found for this class');
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

      showSnackBar('Attendance saved successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
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

  Color attendanceColor(String status) {
    if (status == 'Present') return AppColors.softGreen;
    if (status == 'Late') return Colors.orange;
    if (status == 'Absent') return AppColors.danger;

    return AppColors.primaryBlue;
  }

  Widget pngIconBox({
    required String imagePath,
    required IconData fallbackIcon,
    Color color = AppColors.primaryBlue,
    double size = 54,
    double padding = 11,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              fallbackIcon,
              color: color,
              size: size * 0.52,
            );
          },
        ),
      ),
    );
  }

  Widget smallStatusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget headerCard() {
    String title = '${widget.role} Attendance';
    String subtitle = 'Select a class and manage student attendance.';

    if (widget.role == 'Teacher') {
      title = 'Teacher Attendance';
      subtitle = 'Mark attendance for students in your classes.';
    }

    if (widget.role == 'Admin') {
      title = 'Admin Attendance';
      subtitle = 'Review and manage attendance by class.';
    }

    if (widget.role == 'Parent') {
      title = 'Child Attendance';
      subtitle = 'View your child’s attendance records.';
    }

    if (widget.role == 'Student') {
      title = 'My Attendance';
      subtitle = 'View your attendance status.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -28,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            left: -34,
            child: Container(
              height: 115,
              width: 115,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Image.asset(
                    'assets/icons/attendance.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.fact_check_outlined,
                        color: AppColors.white,
                        size: 34,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$subtitle ${students.length} student(s) loaded.',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyStateBox({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/attendance.png',
              fallbackIcon: icon,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyClassState() {
    return emptyStateBox(
      title: 'No classes yet',
      message: 'No classes found yet. Create a class first from Admin Dashboard.',
      icon: Icons.class_outlined,
    );
  }

  Widget emptyStudentState() {
    return emptyStateBox(
      title: 'No students found',
      message:
          'No students found for this class. Assign students to this class from User Management first.',
      icon: Icons.people_outline,
    );
  }

  Widget studentAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Unknown Student';
    final status = attendanceStatus[studentId] ?? 'Present';
    final color = attendanceColor(status);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.border,
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
                  color: color.withValues(alpha: 0.045),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                pngIconBox(
                  imagePath: 'assets/icons/student.png',
                  fallbackIcon: Icons.person_outline,
                  color: color,
                  size: 56,
                  padding: 11,
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
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedClassName.isEmpty
                            ? 'No class'
                            : selectedClassName,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      smallStatusChip(
                        text: status,
                        color: color,
                      ),
                    ],
                  ),
                ),
                if (canMarkAttendance)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: status,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(18),
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
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
                            child: Column(
                              children: [
                                headerCard(),
                                const SizedBox(height: 18),
                                DropdownButtonFormField<String>(
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
                              ],
                            ),
                          ),
                          if (selectedClassId.isEmpty)
                            Expanded(
                              child: emptyStateBox(
                                title: 'Select a class',
                                message:
                                    'Choose a class to load students and mark attendance.',
                                icon: Icons.class_outlined,
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
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  await loadStudentsByClass(selectedClassId);
                                },
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
                            ),
                        ],
                      ),
      ),
      bottomNavigationBar: canMarkAttendance
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                ),
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