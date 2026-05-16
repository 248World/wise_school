import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isLoadingStudents = false;
  bool isSaving = false;
  String? errorMessage;

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
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await loadClasses();

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

  Future<void> loadClasses() async {
    final snapshot = await firestore.collection('classes').get();

    classes = snapshot.docs.map((doc) {
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

    classes.sort((a, b) {
      return (a['className'] ?? '').toString().compareTo(
            (b['className'] ?? '').toString(),
          );
    });
  }

  Future<void> loadStudentsAndAttendance(String classId) async {
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
        isLoadingStudents = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
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
      final data = doc.data();

      return {
        'id': doc.id,
        'studentId': data['studentId'] ?? '',
        'studentName': data['studentName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'status': data['status'] ?? 'Present',
        'note': data['note'] ?? '',
        'date': data['date'],
        'dateKey': data['dateKey'] ?? '',
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
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

    loadStudentsAndAttendance(value);
  }

  int countStatus(String status) {
    return attendanceStatus.values.where((item) => item == status).length;
  }

  Color statusColor(String status) {
    if (status == 'Present') return AppColors.softGreen;
    if (status == 'Late') return Colors.orange;
    return AppColors.danger;
  }

  IconData statusIcon(String status) {
    if (status == 'Present') return Icons.check_circle_outline;
    if (status == 'Late') return Icons.access_time_outlined;
    return Icons.cancel_outlined;
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
          'markedByRole': 'Admin',
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

  Future<void> deleteAttendanceRecord({
    required String studentId,
    required String studentName,
  }) async {
    try {
      Map<String, dynamic>? existingRecord;

      try {
        existingRecord = attendanceRecords.firstWhere(
          (record) => record['studentId'] == studentId,
        );
      } catch (_) {
        existingRecord = null;
      }

      if (existingRecord == null) {
        showSnackBar('No saved attendance record found for $studentName');
        return;
      }

      await firestore.collection('attendance').doc(existingRecord['id']).delete();

      attendanceStatus[studentId] = 'Present';
      noteControllers[studentId]?.clear();

      await loadAttendanceForSelectedDate();

      if (!mounted) return;

      setState(() {});

      showSnackBar('Attendance record deleted for $studentName');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDeleteAttendance({
    required String studentId,
    required String studentName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Attendance'),
          content: Text(
            'Delete the attendance record for $studentName on ${displayDate(selectedDate)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteAttendanceRecord(
        studentId: studentId,
        studentName: studentName,
      );
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

  Widget headerCard() {
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
                    const Text(
                      'Attendance Monitoring',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedClassName.isEmpty
                          ? 'Select a class and monitor student attendance.'
                          : '$selectedClassName • ${displayDate(selectedDate)} • ${students.length} student(s)',
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

  Widget selectorSection() {
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

  Widget studentAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Student';
    final email = student['email'] ?? '';
    final status = attendanceStatus[studentId] ?? 'Present';
    final color = statusColor(status);

    final hasSavedRecord = attendanceRecords.any((record) {
      return record['studentId'] == studentId;
    });

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
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
                      fallbackIcon: Icons.school_outlined,
                      color: color,
                      size: 54,
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
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon(status),
                            color: color,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statusOptions.map((option) {
                    final isSelected = status == option;
                    final optionColor = statusColor(option);

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
                if (hasSavedRecord) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        confirmDeleteAttendance(
                          studentId: studentId,
                          studentName: studentName,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'Delete record',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyClassState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/attendance.png',
              fallbackIcon: Icons.fact_check_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'Select a class',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a class to load students and monitor attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyStudentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/student.png',
              fallbackIcon: Icons.people_outline,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No students found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No active students are assigned to this class yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Monitoring'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (selectedClassId.isEmpty) {
                      await loadInitialData();
                    } else {
                      await loadStudentsAndAttendance(selectedClassId);
                    }
                  },
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? errorState()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            headerCard(),
                            const SizedBox(height: 18),
                            selectorSection(),
                            if (selectedClassId.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              summaryGrid(),
                            ],
                          ],
                        ),
                      ),
                      if (selectedClassId.isEmpty)
                        Expanded(child: emptyClassState())
                      else if (isLoadingStudents)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (students.isEmpty)
                        Expanded(child: emptyStudentsState())
                      else
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await loadStudentsAndAttendance(selectedClassId);
                            },
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 95),
                              itemCount: students.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 12);
                              },
                              itemBuilder: (context, index) {
                                return studentAttendanceCard(students[index]);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
      bottomNavigationBar: selectedClassId.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
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
            ),
    );
  }
}
