import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AIReportGeneratorScreen extends StatefulWidget {
  const AIReportGeneratorScreen({super.key});

  @override
  State<AIReportGeneratorScreen> createState() =>
      _AIReportGeneratorScreenState();
}

class _AIReportGeneratorScreenState extends State<AIReportGeneratorScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isGenerating = false;
  bool isSaving = false;
  String? errorMessage;

  String selectedTargetId = 'school';
  String selectedTargetName = 'Whole School';
  String selectedTargetType = 'School';
  String selectedReportType = 'Monthly School Report';

  String generatedReport = '';

  List<Map<String, dynamic>> targets = [
    {
      'id': 'school',
      'name': 'Whole School',
      'type': 'School',
      'classId': '',
    },
  ];

  final List<String> reportTypes = [
    'Monthly School Report',
    'Attendance Report',
    'Performance Report',
    'Parent Progress Summary',
    'Fees Report',
    'Assignments Report',
  ];

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> fees = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> submissions = [];
  List<Map<String, dynamic>> announcements = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadData();
    });
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final usersSnapshot = await firestore.collection('users').get();
      final classesSnapshot = await firestore.collection('classes').get();
      final marksSnapshot = await firestore.collection('marks').get();
      final attendanceSnapshot = await firestore.collection('attendance').get();
      final feesSnapshot = await firestore.collection('fees').get();
      final assignmentsSnapshot = await firestore.collection('assignments').get();
      final submissionsSnapshot =
          await firestore.collection('assignment_submissions').get();
      final announcementsSnapshot =
          await firestore.collection('announcements').get();

      users = usersSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? '',
          'role': data['role'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'parentId': data['parentId'] ?? '',
          'parentName': data['parentName'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      classes = classesSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'className': data['className'] ?? '',
          'level': data['level'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();

      marks = marksSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'subjectName': data['subjectName'] ?? '',
          'mark': data['mark'] ?? 0,
          'coefficient': data['coefficient'] ?? 1,
          'comment': data['comment'] ?? '',
        };
      }).toList();

      attendance = attendanceSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'status': data['status'] ?? '',
        };
      }).toList();

      fees = feesSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'title': data['title'] ?? '',
          'amount': data['amount'] ?? 0,
          'status': data['status'] ?? 'Unpaid',
        };
      }).toList();

      assignments = assignmentsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'subjectName': data['subjectName'] ?? '',
          'teacherName': data['teacherName'] ?? '',
        };
      }).toList();

      submissions = submissionsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'assignmentId': data['assignmentId'] ?? '',
          'studentId': data['studentId'] ?? '',
          'studentName': data['studentName'] ?? '',
        };
      }).toList();

      announcements = announcementsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'targetAudience': data['targetAudience'] ?? 'All',
        };
      }).toList();

      buildTargets();

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

  void buildTargets() {
    final loadedTargets = <Map<String, dynamic>>[
      {
        'id': 'school',
        'name': 'Whole School',
        'type': 'School',
        'classId': '',
      },
    ];

    for (final schoolClass in classes) {
      final id = schoolClass['id'] ?? '';
      final name = schoolClass['className'] ?? '';

      if (id.toString().isNotEmpty && name.toString().isNotEmpty) {
        loadedTargets.add({
          'id': id,
          'name': name,
          'type': 'Class',
          'classId': id,
        });
      }
    }

    final students = users.where((user) {
      return user['role'] == 'Student' && user['isActive'] == true;
    }).toList();

    for (final student in students) {
      final id = student['id'] ?? '';
      final name = student['fullName'] ?? '';

      if (id.toString().isNotEmpty && name.toString().isNotEmpty) {
        loadedTargets.add({
          'id': id,
          'name': name,
          'type': 'Student',
          'classId': student['classId'] ?? '',
        });
      }
    }

    targets = loadedTargets;

    if (!targets.any((target) => target['id'] == selectedTargetId)) {
      selectedTargetId = 'school';
      selectedTargetName = 'Whole School';
      selectedTargetType = 'School';
    }
  }

  double parseNumber(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }

  List<Map<String, dynamic>> filteredMarks() {
    if (selectedTargetType == 'School') return marks;

    if (selectedTargetType == 'Class') {
      return marks.where((item) {
        return item['classId'] == selectedTargetId;
      }).toList();
    }

    return marks.where((item) {
      return item['studentId'] == selectedTargetId;
    }).toList();
  }

  List<Map<String, dynamic>> filteredAttendance() {
    if (selectedTargetType == 'School') return attendance;

    if (selectedTargetType == 'Class') {
      return attendance.where((item) {
        return item['classId'] == selectedTargetId;
      }).toList();
    }

    return attendance.where((item) {
      return item['studentId'] == selectedTargetId;
    }).toList();
  }

  List<Map<String, dynamic>> filteredFees() {
    if (selectedTargetType == 'School') return fees;

    if (selectedTargetType == 'Class') {
      return fees.where((item) {
        return item['classId'] == selectedTargetId;
      }).toList();
    }

    return fees.where((item) {
      return item['studentId'] == selectedTargetId;
    }).toList();
  }

  List<Map<String, dynamic>> filteredAssignments() {
    if (selectedTargetType == 'School') return assignments;

    if (selectedTargetType == 'Class') {
      return assignments.where((item) {
        return item['classId'] == selectedTargetId;
      }).toList();
    }

    final student = users.firstWhere(
      (item) => item['id'] == selectedTargetId,
      orElse: () => {},
    );

    final studentClassId = student['classId'] ?? '';

    return assignments.where((item) {
      return item['classId'] == studentClassId;
    }).toList();
  }

  double averageMark(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return 0;

    double total = 0;
    double coefficientTotal = 0;

    for (final mark in list) {
      final value = parseNumber(mark['mark']);
      final coefficient = parseNumber(mark['coefficient']) <= 0
          ? 1
          : parseNumber(mark['coefficient']);

      total += value * coefficient;
      coefficientTotal += coefficient;
    }

    if (coefficientTotal == 0) return 0;

    return total / coefficientTotal;
  }

  String attendanceRate(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return '0%';

    final present = list.where((item) {
      return item['status'] == 'Present' || item['status'] == 'Late';
    }).length;

    return '${((present / list.length) * 100).toStringAsFixed(1)}%';
  }

  String feesSummary(List<Map<String, dynamic>> list) {
    double total = 0;
    double paid = 0;
    double remaining = 0;

    for (final item in list) {
      final amount = parseNumber(item['amount']);
      final status = item['status'].toString().toLowerCase();

      total += amount;

      if (status == 'paid') {
        paid += amount;
      } else {
        remaining += amount;
      }
    }

    return 'Total: ${total.toStringAsFixed(2)} | Paid: ${paid.toStringAsFixed(2)} | Remaining: ${remaining.toStringAsFixed(2)}';
  }

  String generateAttendanceReport() {
    final list = filteredAttendance();
    final present = list.where((item) => item['status'] == 'Present').length;
    final absent = list.where((item) => item['status'] == 'Absent').length;
    final late = list.where((item) => item['status'] == 'Late').length;

    return '''
ATTENDANCE REPORT

Target: $selectedTargetName
Target Type: $selectedTargetType

Total attendance records: ${list.length}
Present: $present
Absent: $absent
Late: $late
Attendance rate: ${attendanceRate(list)}

Observation:
${list.isEmpty ? 'No attendance records are available yet.' : attendanceRate(list).replaceAll('%', '').isNotEmpty && double.tryParse(attendanceRate(list).replaceAll('%', '')) != null && double.parse(attendanceRate(list).replaceAll('%', '')) >= 80 ? 'Attendance is acceptable overall. Continue monitoring late and absent cases.' : 'Attendance needs attention. Follow-up is recommended for repeated absences.'}
''';
  }

  String generatePerformanceReport() {
    final list = filteredMarks();
    final average = averageMark(list);
    final weak = list.where((item) => parseNumber(item['mark']) < 10).toList();
    final strong = list.where((item) => parseNumber(item['mark']) >= 14).toList();

    final buffer = StringBuffer();

    buffer.writeln('PERFORMANCE REPORT');
    buffer.writeln('');
    buffer.writeln('Target: $selectedTargetName');
    buffer.writeln('Target Type: $selectedTargetType');
    buffer.writeln('');
    buffer.writeln('Mark records: ${list.length}');
    buffer.writeln('Average mark: ${average.toStringAsFixed(2)}/20');
    buffer.writeln('Strong records: ${strong.length}');
    buffer.writeln('Weak records: ${weak.length}');
    buffer.writeln('');

    if (weak.isNotEmpty) {
      buffer.writeln('Subjects needing support:');
      for (final item in weak.take(5)) {
        buffer.writeln('- ${item['studentName']} | ${item['subjectName']}: ${parseNumber(item['mark']).toStringAsFixed(1)}/20');
      }
      buffer.writeln('');
    }

    buffer.writeln('Recommendation:');
    if (list.isEmpty) {
      buffer.writeln('No marks are available yet. Teachers should add marks first.');
    } else if (average >= 14) {
      buffer.writeln('Performance is good. Maintain revision consistency and support weaker subjects.');
    } else if (average >= 10) {
      buffer.writeln('Performance is average. More revision and practice exercises are recommended.');
    } else {
      buffer.writeln('Performance needs urgent support. Organize follow-up sessions and inform parents.');
    }

    return buffer.toString();
  }

  String generateFeesReport() {
    final list = filteredFees();

    return '''
FEES REPORT

Target: $selectedTargetName
Target Type: $selectedTargetType

Fee records: ${list.length}
${feesSummary(list)}

Recommendation:
${list.isEmpty ? 'No fee records are available yet.' : 'Follow up with unpaid or pending fee records and update payment status regularly.'}
''';
  }

  String generateAssignmentsReport() {
    final list = filteredAssignments();

    return '''
ASSIGNMENTS REPORT

Target: $selectedTargetName
Target Type: $selectedTargetType

Assignments available: ${list.length}
Total submissions in system: ${submissions.length}

Recommendation:
${list.isEmpty ? 'No assignments are available for this target yet.' : 'Teachers should continue tracking submissions and provide feedback to students.'}
''';
  }

  String generateMonthlyReport() {
    final selectedMarks = filteredMarks();
    final selectedAttendance = filteredAttendance();
    final selectedFees = filteredFees();
    final selectedAssignments = filteredAssignments();

    return '''
MONTHLY SCHOOL REPORT

Target: $selectedTargetName
Target Type: $selectedTargetType

Academic Overview:
- Mark records: ${selectedMarks.length}
- Average mark: ${averageMark(selectedMarks).toStringAsFixed(2)}/20
- Assignments available: ${selectedAssignments.length}

Attendance Overview:
- Attendance records: ${selectedAttendance.length}
- Attendance rate: ${attendanceRate(selectedAttendance)}

Fees Overview:
- Fee records: ${selectedFees.length}
- ${feesSummary(selectedFees)}

School Activity:
- Active students: ${users.where((u) => u['role'] == 'Student' && u['isActive'] == true).length}
- Active teachers: ${users.where((u) => u['role'] == 'Teacher' && u['isActive'] == true).length}
- Classes: ${classes.length}
- Announcements: ${announcements.length}

AI Recommendation:
${selectedMarks.isEmpty && selectedAttendance.isEmpty ? 'There is not enough data yet. Encourage teachers and admins to update attendance, marks, assignments, and fee records.' : 'Continue monitoring attendance, weak subjects, assignment completion, and unpaid fees. The school should use this report for follow-up with teachers and parents.'}
''';
  }

  String generateParentSummary() {
    final selectedMarks = filteredMarks();
    final selectedAttendance = filteredAttendance();
    final selectedFees = filteredFees();
    final selectedAssignments = filteredAssignments();

    return '''
PARENT PROGRESS SUMMARY

Student/Class: $selectedTargetName

Academic:
- Average mark: ${averageMark(selectedMarks).toStringAsFixed(2)}/20
- Assignment records: ${selectedAssignments.length}

Attendance:
- Attendance rate: ${attendanceRate(selectedAttendance)}
- Attendance records: ${selectedAttendance.length}

Fees:
- ${feesSummary(selectedFees)}

Parent Message:
${selectedMarks.isEmpty ? 'Marks are not available yet.' : 'Please encourage consistent revision at home.'}
${selectedAttendance.isEmpty ? 'Attendance data is not available yet.' : 'Please monitor attendance and punctuality.'}
''';
  }

  Future<void> generateReport() async {
    setState(() {
      isGenerating = true;
      generatedReport = '';
    });

    await Future.delayed(const Duration(milliseconds: 350));

    String report;

    if (selectedReportType == 'Attendance Report') {
      report = generateAttendanceReport();
    } else if (selectedReportType == 'Performance Report') {
      report = generatePerformanceReport();
    } else if (selectedReportType == 'Fees Report') {
      report = generateFeesReport();
    } else if (selectedReportType == 'Assignments Report') {
      report = generateAssignmentsReport();
    } else if (selectedReportType == 'Parent Progress Summary') {
      report = generateParentSummary();
    } else {
      report = generateMonthlyReport();
    }

    if (!mounted) return;

    setState(() {
      generatedReport = report;
      isGenerating = false;
    });
  }

  Future<void> approveReport() async {
    if (generatedReport.trim().isEmpty) {
      showSnackBar('Generate a report first.');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await firestore.collection('ai_reports').add({
        'targetId': selectedTargetId,
        'targetName': selectedTargetName,
        'targetType': selectedTargetType,
        'reportType': selectedReportType,
        'content': generatedReport,
        'status': 'Approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Report approved and saved successfully');
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
      child: Row(
        children: [
          Container(
            height: 66,
            width: 66,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Image.asset(
                'assets/icons/ai_report.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.description_outlined,
                    color: AppColors.white,
                    size: 34,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Generate smart reports from real school records.',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.90),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget reportPreview() {
    if (generatedReport.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generated Report Preview',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            generatedReport,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : approveReport,
              icon: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(isSaving ? 'Saving...' : 'Approve & Save Report'),
            ),
          ),
        ],
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
        title: const Text('AI Report Generator'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? errorState()
                : RefreshIndicator(
                    onRefresh: loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerCard(),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            initialValue: selectedTargetId,
                            decoration: const InputDecoration(
                              labelText: 'Select Student, Class, or School',
                              prefixIcon: Icon(Icons.groups_outlined),
                            ),
                            items: targets.map((target) {
                              return DropdownMenuItem<String>(
                                value: target['id'],
                                child: Text(
                                  '${target['type']}: ${target['name']}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final target = targets.firstWhere(
                                (item) => item['id'] == value,
                                orElse: () => targets.first,
                              );

                              setState(() {
                                selectedTargetId = target['id'];
                                selectedTargetName = target['name'];
                                selectedTargetType = target['type'];
                                generatedReport = '';
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: selectedReportType,
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
                                generatedReport = '';
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: isGenerating ? null : generateReport,
                              icon: isGenerating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome_outlined),
                              label: Text(
                                isGenerating
                                    ? 'Generating...'
                                    : 'Generate Report',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          reportPreview(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
