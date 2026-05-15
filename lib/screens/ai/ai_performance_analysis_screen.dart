import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  String? errorMessage;

  String selectedTargetId = '';
  String selectedTargetName = '';
  String selectedTargetType = 'Student';

  List<Map<String, dynamic>> targets = [];
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> submissions = [];

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
      final assignmentsSnapshot = await firestore.collection('assignments').get();
      final submissionsSnapshot =
          await firestore.collection('assignment_submissions').get();

      users = usersSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? '',
          'role': data['role'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      classes = classesSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'className': data['className'] ?? '',
          'level': data['level'] ?? '',
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

      assignments = assignmentsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'title': data['title'] ?? '',
        };
      }).toList();

      submissions = submissionsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'assignmentId': data['assignmentId'] ?? '',
          'studentId': data['studentId'] ?? '',
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
    final loadedTargets = <Map<String, dynamic>>[];

    for (final student in users.where((user) {
      return user['role'] == 'Student' && user['isActive'] == true;
    })) {
      loadedTargets.add({
        'id': student['id'],
        'name': student['fullName'],
        'type': 'Student',
        'classId': student['classId'] ?? '',
      });
    }

    for (final schoolClass in classes) {
      loadedTargets.add({
        'id': schoolClass['id'],
        'name': schoolClass['className'],
        'type': 'Class',
        'classId': schoolClass['id'],
      });
    }

    targets = loadedTargets;

    if (targets.isNotEmpty && selectedTargetId.isEmpty) {
      selectedTargetId = targets.first['id'];
      selectedTargetName = targets.first['name'];
      selectedTargetType = targets.first['type'];
    }
  }

  double parseNumber(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }

  List<Map<String, dynamic>> selectedMarks() {
    if (selectedTargetType == 'Class') {
      return marks.where((item) => item['classId'] == selectedTargetId).toList();
    }

    return marks.where((item) => item['studentId'] == selectedTargetId).toList();
  }

  List<Map<String, dynamic>> selectedAttendance() {
    if (selectedTargetType == 'Class') {
      return attendance.where((item) {
        return item['classId'] == selectedTargetId;
      }).toList();
    }

    return attendance.where((item) {
      return item['studentId'] == selectedTargetId;
    }).toList();
  }

  List<Map<String, dynamic>> selectedAssignments() {
    if (selectedTargetType == 'Class') {
      return assignments.where((item) {
        return item['classId'] == selectedTargetId;
      }).toList();
    }

    final target = targets.firstWhere(
      (item) => item['id'] == selectedTargetId,
      orElse: () => {},
    );

    final classId = target['classId'] ?? '';

    return assignments.where((item) {
      return item['classId'] == classId;
    }).toList();
  }

  double averageMark() {
    final list = selectedMarks();

    if (list.isEmpty) return 0;

    double total = 0;
    double coefficientTotal = 0;

    for (final item in list) {
      final mark = parseNumber(item['mark']);
      final coefficient = parseNumber(item['coefficient']) <= 0
          ? 1
          : parseNumber(item['coefficient']);

      total += mark * coefficient;
      coefficientTotal += coefficient;
    }

    if (coefficientTotal == 0) return 0;

    return total / coefficientTotal;
  }

  double attendancePercent() {
    final list = selectedAttendance();

    if (list.isEmpty) return 0;

    final present = list.where((item) {
      return item['status'] == 'Present' || item['status'] == 'Late';
    }).length;

    return (present / list.length) * 100;
  }

  int pendingAssignments() {
    final list = selectedAssignments();

    if (selectedTargetType == 'Class') {
      return list.length;
    }

    int pending = 0;

    for (final assignment in list) {
      final assignmentId = assignment['id'] ?? '';

      final submitted = submissions.any((submission) {
        return submission['assignmentId'] == assignmentId &&
            submission['studentId'] == selectedTargetId;
      });

      if (!submitted) {
        pending++;
      }
    }

    return pending;
  }

  String riskLevel() {
    final avg = averageMark();
    final attendance = attendancePercent();
    final pending = pendingAssignments();

    if (avg < 10 || attendance < 65 || pending >= 5) {
      return 'High';
    }

    if (avg < 12 || attendance < 80 || pending >= 2) {
      return 'Medium';
    }

    return 'Low';
  }

  Color riskColor() {
    final risk = riskLevel();

    if (risk == 'High') return AppColors.danger;
    if (risk == 'Medium') return Colors.orange;

    return AppColors.softGreen;
  }

  String aiInsight() {
    final avg = averageMark();
    final att = attendancePercent();
    final pending = pendingAssignments();
    final risk = riskLevel();

    if (selectedMarks().isEmpty && selectedAttendance().isEmpty) {
      return 'There is not enough data yet for $selectedTargetName. Add marks and attendance records first to make the analysis stronger.';
    }

    if (risk == 'High') {
      return '$selectedTargetName needs urgent follow-up. The average mark is ${avg.toStringAsFixed(2)}/20, attendance is ${att.toStringAsFixed(1)}%, and there are $pending pending assignment(s). Admin or teacher should contact the parent and prepare support.';
    }

    if (risk == 'Medium') {
      return '$selectedTargetName is showing moderate risk. Performance or attendance needs monitoring. Encourage revision, assignment completion, and regular attendance.';
    }

    return '$selectedTargetName is performing well overall. Continue monitoring results, attendance, and assignment submissions to maintain progress.';
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
                'assets/icons/ai_performance.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.analytics_outlined,
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
              'Analyze marks, attendance, assignments, and risk level using real data.',
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

  Widget summaryBox({
    required String title,
    required String value,
    required IconData icon,
    required String imagePath,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pngIconBox(
            imagePath: imagePath,
            fallbackIcon: icon,
            color: color,
            size: 48,
            padding: 10,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
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

  Widget insightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pngIconBox(
                imagePath: 'assets/icons/ai_assistant.png',
                fallbackIcon: Icons.smart_toy_outlined,
                size: 46,
                padding: 10,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Insight',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            aiInsight(),
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
              color: riskColor().withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Risk Badge: ${riskLevel()} Attention Needed',
              style: TextStyle(
                color: riskColor(),
                fontWeight: FontWeight.w900,
              ),
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

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No students or classes found yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avg = averageMark();
    final att = attendancePercent();
    final pending = pendingAssignments();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Performance Analysis'),
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
                : targets.isEmpty
                    ? emptyState()
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
                                  labelText: 'Select Student or Class',
                                  prefixIcon:
                                      Icon(Icons.person_search_outlined),
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
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: summaryBox(
                                      title: 'Attendance',
                                      value: '${att.toStringAsFixed(1)}%',
                                      icon: Icons.fact_check_outlined,
                                      imagePath: 'assets/icons/attendance.png',
                                      color: att >= 80
                                          ? AppColors.softGreen
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: summaryBox(
                                      title: 'Average Mark',
                                      value: avg.toStringAsFixed(2),
                                      icon: Icons.bar_chart_outlined,
                                      imagePath: 'assets/icons/results.png',
                                      color: avg >= 14
                                          ? AppColors.softGreen
                                          : avg >= 10
                                              ? Colors.orange
                                              : AppColors.danger,
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
                                      value: '$pending Pending',
                                      icon: Icons.assignment_outlined,
                                      imagePath: 'assets/icons/assignments.png',
                                      color: pending == 0
                                          ? AppColors.softGreen
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: summaryBox(
                                      title: 'Risk Level',
                                      value: riskLevel(),
                                      icon: Icons.warning_amber_outlined,
                                      imagePath:
                                          'assets/icons/ai_performance.png',
                                      color: riskColor(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              insightCard(),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: loadData,
                                  icon: const Icon(Icons.refresh_outlined),
                                  label: const Text('Refresh Analysis'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
