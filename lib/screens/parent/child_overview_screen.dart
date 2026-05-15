import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ChildOverviewScreen extends StatefulWidget {
  const ChildOverviewScreen({super.key});

  @override
  State<ChildOverviewScreen> createState() => _ChildOverviewScreenState();
}

class _ChildOverviewScreenState extends State<ChildOverviewScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  String parentId = '';
  String parentName = '';

  List<Map<String, dynamic>> children = [];
  Map<String, dynamic>? selectedChild;

  int attendanceTotal = 0;
  int attendancePresent = 0;
  int attendanceAbsent = 0;
  int attendanceLate = 0;

  int marksTotal = 0;
  int passedSubjects = 0;
  int weakSubjects = 0;
  double averageMark = 0;

  int assignmentsTotal = 0;
  int assignmentsSubmitted = 0;
  int assignmentsPending = 0;

  int feesTotal = 0;
  int feesPaid = 0;
  int feesUnpaid = 0;
  double totalFeesAmount = 0;
  double paidFeesAmount = 0;
  double unpaidFeesAmount = 0;

  int timetableTotal = 0;

  String aiSummary = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadInitialData();
    });
  }

  Future<void> loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();

      parentId = authProvider.userId ?? '';
      parentName = authProvider.fullName ?? 'Parent';

      if (parentId.isEmpty) {
        throw Exception('Parent account not found. Please login again.');
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await loadChildren();

      if (children.isNotEmpty) {
        selectedChild = children.first;
        await loadChildOverview(selectedChild!);
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

  Future<void> refreshData() async {
    try {
      setState(() {
        isRefreshing = true;
      });

      await loadChildren();

      final selectedChildId = selectedChild?['id'] ?? '';

      if (children.isEmpty) {
        selectedChild = null;
        resetStats();
      } else if (selectedChildId.toString().isNotEmpty) {
        final matchedChild = children.firstWhere(
          (child) => child['id'] == selectedChildId,
          orElse: () => children.first,
        );

        selectedChild = matchedChild;
        await loadChildOverview(matchedChild);
      } else {
        selectedChild = children.first;
        await loadChildOverview(selectedChild!);
      }

      if (!mounted) return;

      setState(() {
        isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isRefreshing = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadChildren() async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .get();

    children = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'profileImage': data['profileImage'] ?? '',
        'profileImageUrl': data['profileImageUrl'] ?? data['profileImage'] ?? '',
        'gender': data['gender'] ?? '',
        'city': data['city'] ?? '',
        'address': data['address'] ?? '',
      };
    }).toList();

    children.sort((a, b) {
      return (a['fullName'] ?? '').toString().compareTo(
            (b['fullName'] ?? '').toString(),
          );
    });
  }

  Future<void> loadChildOverview(Map<String, dynamic> child) async {
    resetStats();

    final childId = child['id'] ?? '';
    final classId = child['classId'] ?? '';

    if (childId.toString().isEmpty) {
      return;
    }

    await loadAttendanceStats(childId);
    await loadMarksStats(childId);
    await loadAssignmentStats(
      studentId: childId,
      classId: classId,
    );
    await loadFeesStats(childId);
    await loadTimetableStats(classId);

    aiSummary = generateAiSummary(child);

    if (!mounted) return;

    setState(() {});
  }

  void resetStats() {
    attendanceTotal = 0;
    attendancePresent = 0;
    attendanceAbsent = 0;
    attendanceLate = 0;

    marksTotal = 0;
    passedSubjects = 0;
    weakSubjects = 0;
    averageMark = 0;

    assignmentsTotal = 0;
    assignmentsSubmitted = 0;
    assignmentsPending = 0;

    feesTotal = 0;
    feesPaid = 0;
    feesUnpaid = 0;
    totalFeesAmount = 0;
    paidFeesAmount = 0;
    unpaidFeesAmount = 0;

    timetableTotal = 0;

    aiSummary = '';
  }

  Future<void> loadAttendanceStats(String childId) async {
    final snapshot = await firestore
        .collection('attendance')
        .where('studentId', isEqualTo: childId)
        .get();

    attendanceTotal = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'present') {
        attendancePresent++;
      } else if (status == 'absent') {
        attendanceAbsent++;
      } else if (status == 'late') {
        attendanceLate++;
      }
    }
  }

  Future<void> loadMarksStats(String childId) async {
    final snapshot = await firestore
        .collection('marks')
        .where('studentId', isEqualTo: childId)
        .get();

    marksTotal = snapshot.docs.length;

    if (marksTotal == 0) {
      averageMark = 0;
      return;
    }

    double weightedTotal = 0;
    double coefficientTotal = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final markValue = data['mark'] ??
          data['score'] ??
          data['value'] ??
          data['result'] ??
          data['marks'] ??
          0;

      final mark = parseDouble(markValue);
      final coefficient = parseDouble(data['coefficient'] ?? 1);
      final safeCoefficient = coefficient <= 0 ? 1 : coefficient;

      weightedTotal += mark * safeCoefficient;
      coefficientTotal += safeCoefficient;

      if (mark >= 10) {
        passedSubjects++;
      } else {
        weakSubjects++;
      }
    }

    averageMark = coefficientTotal == 0 ? 0 : weightedTotal / coefficientTotal;
  }

  Future<void> loadAssignmentStats({
    required String studentId,
    required String classId,
  }) async {
    if (classId.toString().isEmpty) {
      assignmentsTotal = 0;
      assignmentsSubmitted = 0;
      assignmentsPending = 0;
      return;
    }

    final assignmentsSnapshot = await firestore
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .get();

    final assignmentIds = assignmentsSnapshot.docs.map((doc) => doc.id).toSet();

    assignmentsTotal = assignmentIds.length;

    if (assignmentsTotal == 0) {
      assignmentsSubmitted = 0;
      assignmentsPending = 0;
      return;
    }

    final submissionsSnapshot = await firestore
        .collection('assignment_submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    final submittedAssignmentIds = <String>{};

    for (final doc in submissionsSnapshot.docs) {
      final data = doc.data();
      final assignmentId = (data['assignmentId'] ?? '').toString();

      if (assignmentIds.contains(assignmentId)) {
        submittedAssignmentIds.add(assignmentId);
      }
    }

    assignmentsSubmitted = submittedAssignmentIds.length;
    assignmentsPending = assignmentsTotal - assignmentsSubmitted;

    if (assignmentsPending < 0) {
      assignmentsPending = 0;
    }
  }

  Future<void> loadFeesStats(String childId) async {
    final snapshot = await firestore
        .collection('fees')
        .where('studentId', isEqualTo: childId)
        .get();

    feesTotal = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = (data['status'] ?? 'Unpaid').toString().toLowerCase();
      final amount = parseDouble(data['amount'] ?? 0);

      totalFeesAmount += amount;

      if (status == 'paid') {
        feesPaid++;
        paidFeesAmount += amount;
      } else {
        feesUnpaid++;
        unpaidFeesAmount += amount;
      }
    }
  }

  Future<void> loadTimetableStats(String classId) async {
    if (classId.toString().isEmpty) {
      timetableTotal = 0;
      return;
    }

    final snapshot = await firestore
        .collection('timetables')
        .where('classId', isEqualTo: classId)
        .get();

    timetableTotal = snapshot.docs.length;
  }

  double parseDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String attendancePercentage() {
    if (attendanceTotal == 0) {
      return '0%';
    }

    final presentWithLate = attendancePresent + attendanceLate;
    final percent = (presentWithLate / attendanceTotal) * 100;
    return '${percent.toStringAsFixed(0)}%';
  }

  String assignmentProgress() {
    if (assignmentsTotal == 0) {
      return '0%';
    }

    final percent = (assignmentsSubmitted / assignmentsTotal) * 100;
    return '${percent.toStringAsFixed(0)}%';
  }

  String resultStatus() {
    if (marksTotal == 0) return 'No result yet';

    if (averageMark >= 16) return 'Excellent';
    if (averageMark >= 14) return 'Good';
    if (averageMark >= 10) return 'Average';
    return 'Needs Support';
  }

  String generateAiSummary(Map<String, dynamic> child) {
    final childName = child['fullName'] ?? 'This student';
    final className = child['className'] ?? '';

    final summaryParts = <String>[];

    summaryParts.add(
      '$childName ${className.toString().isNotEmpty ? 'in $className ' : ''}has $timetableTotal timetable record(s), $assignmentsTotal assignment(s), $feesTotal fee record(s), and $marksTotal result record(s).',
    );

    if (attendanceTotal == 0) {
      summaryParts.add(
        'Attendance data is not available yet, so the parent should wait for teacher updates.',
      );
    } else {
      final percent = ((attendancePresent + attendanceLate) / attendanceTotal) * 100;

      if (percent >= 80) {
        summaryParts.add(
          'Attendance looks good with ${percent.toStringAsFixed(0)}% presence.',
        );
      } else if (percent >= 50) {
        summaryParts.add(
          'Attendance is average at ${percent.toStringAsFixed(0)}%, so regular follow-up is recommended.',
        );
      } else {
        summaryParts.add(
          'Attendance needs attention because the presence rate is only ${percent.toStringAsFixed(0)}%.',
        );
      }
    }

    if (marksTotal == 0) {
      summaryParts.add(
        'No marks have been added yet, so academic performance cannot be fully evaluated.',
      );
    } else {
      if (averageMark >= 14) {
        summaryParts.add(
          'Academic performance is strong with a weighted average of ${averageMark.toStringAsFixed(2)}/20.',
        );
      } else if (averageMark >= 10) {
        summaryParts.add(
          'Academic performance is acceptable with a weighted average of ${averageMark.toStringAsFixed(2)}/20, but there is room for improvement.',
        );
      } else {
        summaryParts.add(
          'Academic performance needs support because the weighted average is ${averageMark.toStringAsFixed(2)}/20.',
        );
      }
    }

    if (assignmentsTotal > 0) {
      if (assignmentsPending == 0) {
        summaryParts.add(
          'Assignment progress is good because all available assignments are submitted.',
        );
      } else {
        summaryParts.add(
          '$assignmentsPending assignment(s) still need attention.',
        );
      }
    }

    if (feesUnpaid > 0) {
      summaryParts.add(
        'There are $feesUnpaid unpaid or partially paid fee record(s), with ${formatDouble(unpaidFeesAmount)} still requiring follow-up.',
      );
    } else if (feesTotal > 0) {
      summaryParts.add(
        'All available fee records are marked as paid.',
      );
    }

    return summaryParts.join(' ');
  }

  Future<void> selectChild(Map<String, dynamic> child) async {
    setState(() {
      selectedChild = child;
      isRefreshing = true;
    });

    await loadChildOverview(child);

    if (!mounted) return;

    setState(() {
      isRefreshing = false;
    });
  }

  ImageProvider? childImageProvider(Map<String, dynamic> child) {
    final imageUrl = (child['profileImageUrl'] ?? '').toString();

    if (imageUrl.isEmpty) {
      return null;
    }

    return NetworkImage(imageUrl);
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
    final childName = selectedChild?['fullName'] ?? 'Child';
    final className = selectedChild?['className'] ?? '';

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
                    'assets/icons/child_overview.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.child_care_outlined,
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
                      childName.toString().isEmpty ? 'Child Overview' : childName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      className.toString().isEmpty
                          ? 'Follow your child’s attendance, results, assignments, timetable, and fees.'
                          : 'Class: $className • Follow attendance, results, assignments, timetable, and fees.',
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

  Widget smallStatusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  Color percentageColor(double value) {
    if (value >= 80) return AppColors.softGreen;
    if (value >= 50) return Colors.orange;
    return AppColors.danger;
  }

  Color markColor(double value) {
    if (value >= 14) return AppColors.softGreen;
    if (value >= 10) return Colors.orange;
    return AppColors.danger;
  }

  Widget childSelector() {
    if (children.length <= 1) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedChild?['id'],
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: children.map((child) {
            return DropdownMenuItem<String>(
              value: child['id'],
              child: Row(
                children: [
                  const Icon(
                    Icons.child_care_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      child['fullName'] ?? 'Student',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final child = children.firstWhere(
              (item) => item['id'] == value,
              orElse: () => {},
            );

            if (child.isNotEmpty) {
              selectChild(child);
            }
          },
        ),
      ),
    );
  }

  Widget childProfileCard() {
    final child = selectedChild;

    if (child == null) {
      return const SizedBox();
    }

    final imageProvider = childImageProvider(child);

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
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -24,
            child: Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.14),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          'assets/icons/student.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.child_care_outlined,
                              color: AppColors.primaryBlue,
                              size: 46,
                            );
                          },
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                child['fullName'] ?? 'Student',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  smallStatusChip(
                    text: child['className'].toString().isEmpty
                        ? 'No class assigned'
                        : child['className'],
                    color: AppColors.primaryBlue,
                  ),
                  if (child['email'].toString().isNotEmpty)
                    smallStatusChip(
                      text: child['email'],
                      color: AppColors.textGrey,
                    ),
                ],
              ),
              if (child['phone'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  child['phone'],
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required String imagePath,
    required String subtitle,
    Color color = AppColors.primaryBlue,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
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
            top: -28,
            right: -26,
            child: Container(
              height: 78,
              width: 78,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pngIconBox(
                imagePath: imagePath,
                fallbackIcon: icon,
                color: color,
                size: 48,
                padding: 10,
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget statsGrid() {
    final attendanceRate = attendanceTotal == 0
        ? 0.0
        : ((attendancePresent + attendanceLate) / attendanceTotal) * 100;

    final assignmentRate = assignmentsTotal == 0
        ? 0.0
        : (assignmentsSubmitted / assignmentsTotal) * 100;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: [
        statCard(
          title: 'Attendance',
          value: attendancePercentage(),
          icon: Icons.fact_check_outlined,
          imagePath: 'assets/icons/attendance.png',
          color: percentageColor(attendanceRate),
          subtitle:
              '$attendancePresent present, $attendanceLate late / $attendanceTotal total',
        ),
        statCard(
          title: 'Average Result',
          value: marksTotal == 0 ? '0' : averageMark.toStringAsFixed(2),
          icon: Icons.bar_chart_outlined,
          imagePath: 'assets/icons/results.png',
          color: markColor(averageMark),
          subtitle: '$marksTotal mark(s) • $passedSubjects passed',
        ),
        statCard(
          title: 'Assignments',
          value: assignmentProgress(),
          icon: Icons.assignment_outlined,
          imagePath: 'assets/icons/assignments.png',
          color: percentageColor(assignmentRate),
          subtitle: '$assignmentsSubmitted submitted / $assignmentsTotal total',
        ),
        statCard(
          title: 'Fees',
          value: feesUnpaid.toString(),
          icon: Icons.account_balance_wallet_outlined,
          imagePath: 'assets/icons/fees.png',
          color: feesUnpaid == 0 ? AppColors.softGreen : AppColors.danger,
          subtitle: 'Unpaid: ${formatDouble(unpaidFeesAmount)}',
        ),
        statCard(
          title: 'Timetable',
          value: timetableTotal.toString(),
          icon: Icons.calendar_month_outlined,
          imagePath: 'assets/icons/timetable.png',
          subtitle: 'Class timetable records',
        ),
        statCard(
          title: 'Absences',
          value: attendanceAbsent.toString(),
          icon: Icons.warning_amber_outlined,
          imagePath: 'assets/icons/attendance.png',
          color: attendanceAbsent == 0 ? AppColors.softGreen : AppColors.danger,
          subtitle: 'Recorded absences',
        ),
      ],
    );
  }

  Widget aiSummaryCard() {
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
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -24,
            child: Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.045),
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
                    imagePath: 'assets/icons/ai_assistant.png',
                    fallbackIcon: Icons.psychology_outlined,
                    size: 46,
                    padding: 10,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Smart Progress Summary',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                aiSummary.isEmpty
                    ? 'Not enough data available yet to generate a useful progress summary.'
                    : aiSummary,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget detailsCard() {
    final child = selectedChild;

    if (child == null) {
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
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pngIconBox(
                imagePath: 'assets/icons/profile.png',
                fallbackIcon: Icons.account_circle_outlined,
                size: 42,
                padding: 9,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Child Details',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          detailRow(
            icon: Icons.badge_outlined,
            label: 'Name',
            value: child['fullName'] ?? 'Not set',
          ),
          detailRow(
            icon: Icons.class_outlined,
            label: 'Class',
            value: child['className'].toString().isEmpty
                ? 'Not assigned'
                : child['className'],
          ),
          detailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: child['email'].toString().isEmpty
                ? 'Not set'
                : child['email'],
          ),
          detailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: child['phone'].toString().isEmpty
                ? 'Not set'
                : child['phone'],
          ),
          detailRow(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: child['city'].toString().isEmpty ? 'Not set' : child['city'],
          ),
          detailRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: child['address'].toString().isEmpty
                ? 'Not set'
                : child['address'],
          ),
          detailRow(
            icon: Icons.bar_chart_outlined,
            label: 'Progress',
            value: resultStatus(),
          ),
        ],
      ),
    );
  }

  Widget detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/child_overview.png',
              fallbackIcon: Icons.child_care_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No child assigned yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No child is assigned to your parent account yet. Please contact the school admin.',
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

  Widget loadingState() {
    return const Center(
      child: CircularProgressIndicator(),
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
            fontWeight: FontWeight.w600,
          ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Child Overview'),
        actions: [
          IconButton(
            onPressed: isLoading || isRefreshing ? null : refreshData,
            icon: isRefreshing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? loadingState()
            : errorMessage != null
                ? errorState()
                : children.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              headerCard(),
                              const SizedBox(height: 18),
                              childSelector(),
                              if (children.length > 1)
                                const SizedBox(height: 16),
                              childProfileCard(),
                              const SizedBox(height: 18),
                              statsGrid(),
                              const SizedBox(height: 18),
                              aiSummaryCard(),
                              const SizedBox(height: 18),
                              detailsCard(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
