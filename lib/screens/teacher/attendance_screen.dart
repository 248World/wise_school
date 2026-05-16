import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

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
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  bool isLoadingStudents = false;
  String? errorMessage;

  String currentUserId = '';
  String currentUserName = '';
  String currentRole = 'Teacher';

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> attendanceRecords = [];

  String selectedClassId = '';
  String selectedClassName = '';

  DateTime selectedDate = DateTime.now();

  final Map<String, String> attendanceStatus = {};
  final Map<String, TextEditingController> noteControllers = {};

  final List<String> statusOptions = [
    'Present',
    'Absent',
    'Late',
  ];

  bool get canMarkAttendance {
    return currentRole == 'Teacher';
  }

  bool get isStudent {
    return currentRole == 'Student';
  }

  bool get isTeacher {
    return currentRole == 'Teacher';
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadInitialData();
    });
  }

  @override
  void dispose() {
    clearControllers();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();

      currentUserId = authProvider.userId ?? '';
      currentUserName = authProvider.fullName ?? widget.role;
      currentRole = widget.role;

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (isStudent) {
        await loadStudentAttendance();
      } else {
        await loadTeacherClasses();
      }

      if (!mounted) return;

      setState(() {
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

  Future<void> loadTeacherClasses() async {
    final classesSnapshot = await firestore.collection('classes').get();

    final loadedClasses = classesSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'className': data['className'] ?? '',
        'level': data['level'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'studentCount': data['studentCount'] ?? 0,
      };
    }).toList();

    classes = loadedClasses.where((schoolClass) {
      final teacherId = (schoolClass['teacherId'] ?? '').toString();
      final teacherName = (schoolClass['teacherName'] ?? '').toString();

      return teacherId == currentUserId || teacherName == currentUserName;
    }).toList();

    classes.sort((a, b) {
      return (a['className'] ?? '').toString().compareTo(
            (b['className'] ?? '').toString(),
          );
    });
  }

  Future<void> loadStudentAttendance() async {
    final userDoc = await firestore.collection('users').doc(currentUserId).get();

    if (userDoc.exists) {
      final userData = userDoc.data();
      selectedClassId = userData?['classId'] ?? '';
      selectedClassName = userData?['className'] ?? '';
    }

    final attendanceSnapshot = await firestore
        .collection('attendance')
        .where('studentId', isEqualTo: currentUserId)
        .get();

    attendanceRecords = attendanceSnapshot.docs.map((doc) {
      return attendanceFromData(doc.id, doc.data());
    }).toList();

    attendanceRecords.sort((a, b) {
      final aDate = a['date'];
      final bDate = b['date'];

      if (aDate is Timestamp && bDate is Timestamp) {
        return bDate.compareTo(aDate);
      }

      return 0;
    });
  }

  Future<void> loadStudentsByClass(String classId) async {
    try {
      setState(() {
        isLoadingStudents = true;
        students = [];
        attendanceRecords = [];
        attendanceStatus.clear();
        clearControllers();
      });

      final studentsSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('classId', isEqualTo: classId)
          .where('isActive', isEqualTo: true)
          .get();

      students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
        };
      }).toList();

      students.sort((a, b) {
        return (a['fullName'] ?? '').toString().compareTo(
              (b['fullName'] ?? '').toString(),
            );
      });

      for (final student in students) {
        final studentId = student['id'] ?? '';

        if (studentId.toString().isNotEmpty) {
          attendanceStatus[studentId] = 'Present';
          noteControllers[studentId] = TextEditingController();
        }
      }

      await loadAttendanceForSelectedDate();

      if (!mounted) return;

      setState(() {
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

  Future<void> loadAttendanceForSelectedDate() async {
    if (selectedClassId.isEmpty) return;

    final snapshot = await firestore
        .collection('attendance')
        .where('classId', isEqualTo: selectedClassId)
        .where('dateKey', isEqualTo: dateKey(selectedDate))
        .get();

    attendanceRecords = snapshot.docs.map((doc) {
      return attendanceFromData(doc.id, doc.data());
    }).toList();

    for (final student in students) {
      final studentId = student['id'] ?? '';

      Map<String, dynamic>? savedRecord;

      try {
        savedRecord = attendanceRecords.firstWhere(
          (record) => record['studentId'] == studentId,
        );
      } catch (_) {
        savedRecord = null;
      }

      attendanceStatus[studentId] = savedRecord?['status'] ?? 'Present';
      noteControllers[studentId]?.text = savedRecord?['note'] ?? '';
    }
  }

  Map<String, dynamic> attendanceFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    return {
      'id': id,
      'studentId': data['studentId'] ?? '',
      'studentName': data['studentName'] ?? '',
      'classId': data['classId'] ?? '',
      'className': data['className'] ?? '',
      'status': data['status'] ?? 'Present',
      'note': data['note'] ?? '',
      'date': data['date'],
      'dateKey': data['dateKey'] ?? '',
      'markedById': data['markedById'] ?? '',
      'markedByName': data['markedByName'] ?? '',
      'markedByRole': data['markedByRole'] ?? '',
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
    };
  }

  void clearControllers() {
    for (final controller in noteControllers.values) {
      controller.dispose();
    }

    noteControllers.clear();
  }

  String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String displayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String displayTimestampDate(dynamic value) {
    if (value is Timestamp) {
      return displayDate(value.toDate());
    }

    return 'No date';
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });

    if (selectedClassId.isNotEmpty) {
      setState(() {
        isLoadingStudents = true;
      });

      await loadAttendanceForSelectedDate();

      if (!mounted) return;

      setState(() {
        isLoadingStudents = false;
      });
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

  int countStatus(String status) {
    if (isStudent) {
      return attendanceRecords.where((record) {
        return record['status'] == status;
      }).length;
    }

    return attendanceStatus.values.where((item) => item == status).length;
  }

  Color attendanceColor(String status) {
    if (status == 'Present') return AppColors.softGreen;
    if (status == 'Late') return Colors.orange;
    if (status == 'Absent') return AppColors.danger;

    return AppColors.primaryBlue;
  }

  IconData statusIcon(String status) {
    if (status == 'Present') return Icons.check_circle_outline;
    if (status == 'Late') return Icons.access_time_outlined;
    if (status == 'Absent') return Icons.cancel_outlined;

    return Icons.fact_check_outlined;
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

      final batch = firestore.batch();
      final currentDateKey = dateKey(selectedDate);

      for (final student in students) {
        final studentId = student['id'] ?? '';

        if (studentId.toString().isEmpty) continue;

        final status = attendanceStatus[studentId] ?? 'Present';
        final note = noteControllers[studentId]?.text.trim() ?? '';

        Map<String, dynamic>? existingRecord;

        try {
          existingRecord = attendanceRecords.firstWhere(
            (record) => record['studentId'] == studentId,
          );
        } catch (_) {
          existingRecord = null;
        }

        final data = {
          'studentId': studentId,
          'studentName': student['fullName'] ?? 'Student',
          'classId': selectedClassId,
          'className': selectedClassName,
          'status': status,
          'note': note,
          'date': Timestamp.fromDate(
            DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            ),
          ),
          'dateKey': currentDateKey,
          'markedById': currentUserId,
          'markedByName': currentUserName,
          'markedByRole': currentRole,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (existingRecord == null) {
          final attendanceRef = firestore.collection('attendance').doc();

          batch.set(attendanceRef, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final attendanceId = existingRecord['id'] ?? '';

          if (attendanceId.toString().isNotEmpty) {
            batch.update(
              firestore.collection('attendance').doc(attendanceId),
              data,
            );
          }
        }
      }

      await batch.commit();

      await loadAttendanceForSelectedDate();

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
    String title = 'Attendance';
    String subtitle = 'View attendance records.';

    if (isTeacher) {
      title = 'Teacher Attendance';
      subtitle = selectedClassName.isEmpty
          ? 'Select one of your assigned classes and mark attendance.'
          : '$selectedClassName • ${displayDate(selectedDate)} • ${students.length} student(s).';
    }

    if (isStudent) {
      title = 'My Attendance';
      subtitle = selectedClassName.isEmpty
          ? 'View your attendance history.'
          : '$selectedClassName • ${attendanceRecords.length} record(s).';
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
                      subtitle,
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

  Widget summaryGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        summaryBox(
          title: 'Present',
          value: countStatus('Present').toString(),
          color: AppColors.softGreen,
          icon: Icons.check_circle_outline,
        ),
        summaryBox(
          title: 'Late',
          value: countStatus('Late').toString(),
          color: Colors.orange,
          icon: Icons.access_time_outlined,
        ),
        summaryBox(
          title: 'Absent',
          value: countStatus('Absent').toString(),
          color: AppColors.danger,
          icon: Icons.cancel_outlined,
        ),
      ],
    );
  }

  Widget summaryBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget classSelector() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedClassId.isEmpty ? null : selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Select Class',
            prefixIcon: Icon(Icons.class_outlined),
          ),
          items: classes.map((schoolClass) {
            return DropdownMenuItem<String>(
              value: schoolClass['id'],
              child: Text(
                schoolClass['className'] ?? 'Unnamed Class',
              ),
            );
          }).toList(),
          onChanged: classes.isEmpty ? null : selectClass,
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: pickDate,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  pngIconBox(
                    imagePath: 'assets/icons/timetable.png',
                    fallbackIcon: Icons.calendar_month_outlined,
                    size: 42,
                    padding: 9,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Date: ${displayDate(selectedDate)}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
      title: 'No assigned classes',
      message:
          'No class is assigned to your teacher account yet. Ask Admin to assign you to a class.',
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

  Widget emptyStudentAttendanceState() {
    return emptyStateBox(
      title: 'No attendance yet',
      message:
          'No attendance record has been saved for your account yet. Once your teacher marks attendance, it will appear here.',
      icon: Icons.fact_check_outlined,
    );
  }

  Widget studentAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Unknown Student';
    final email = student['email'] ?? '';
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          if (email.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    smallStatusChip(
                      text: status,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statusOptions.map((option) {
                    final isSelected = status == option;
                    final optionColor = attendanceColor(option);

                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      selectedColor: optionColor.withValues(alpha: 0.18),
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected ? optionColor : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? optionColor : AppColors.textGrey,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          attendanceStatus[studentId] = option;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteControllers[studentId],
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Optional note',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget attendanceHistoryCard(Map<String, dynamic> record) {
    final status = record['status'] ?? 'Present';
    final note = record['note'] ?? '';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pngIconBox(
                  imagePath: 'assets/icons/attendance.png',
                  fallbackIcon: statusIcon(status),
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
                        displayTimestampDate(record['date']),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          smallStatusChip(
                            text: status,
                            color: color,
                          ),
                          if ((record['className'] ?? '').toString().isNotEmpty)
                            smallStatusChip(
                              text: record['className'],
                              color: AppColors.primaryBlue,
                            ),
                        ],
                      ),
                      if (note.toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Note: $note',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if ((record['markedByName'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Marked by: ${record['markedByName']}',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
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

  Widget mainBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
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
      );
    }

    if (isStudent) {
      return RefreshIndicator(
        onRefresh: loadInitialData,
        child: attendanceRecords.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    headerCard(),
                    const SizedBox(height: 18),
                    summaryGrid(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.42,
                      child: emptyStudentAttendanceState(),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                itemCount: attendanceRecords.length + 2,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return headerCard();
                  }

                  if (index == 1) {
                    return summaryGrid();
                  }

                  return attendanceHistoryCard(attendanceRecords[index - 2]);
                },
              ),
      );
    }

    if (classes.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: headerCard(),
          ),
          Expanded(
            child: emptyClassState(),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              headerCard(),
              const SizedBox(height: 18),
              classSelector(),
              if (selectedClassId.isNotEmpty) ...[
                const SizedBox(height: 18),
                summaryGrid(),
              ],
            ],
          ),
        ),
        if (selectedClassId.isEmpty)
          Expanded(
            child: emptyStateBox(
              title: 'Select a class',
              message: 'Choose a class to load students and mark attendance.',
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
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isStudent ? 'My Attendance' : 'Teacher Attendance';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadInitialData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: mainBody(),
      ),
      bottomNavigationBar: canMarkAttendance && selectedClassId.isNotEmpty
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
