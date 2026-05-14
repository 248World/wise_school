import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ChildOverviewScreen extends StatefulWidget {
  const ChildOverviewScreen({super.key});

  @override
  State<ChildOverviewScreen> createState() => _ChildOverviewScreenState();
}

class _ChildOverviewScreenState extends State<ChildOverviewScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  String parentId = '';

  List<Map<String, dynamic>> children = [];
  Map<String, dynamic>? selectedChild;

  int attendanceTotal = 0;
  int attendancePresent = 0;
  int attendanceAbsent = 0;

  int marksTotal = 0;
  double averageMark = 0;

  int assignmentsTotal = 0;
  int assignmentsSubmitted = 0;
  int assignmentsPending = 0;

  int feesTotal = 0;
  int feesPaid = 0;
  int feesUnpaid = 0;
  double totalFeesAmount = 0;
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
      final user = firebaseAuth.currentUser;

      parentId = user?.uid ?? '';

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
    if (selectedChild == null) {
      await loadInitialData();
      return;
    }

    try {
      setState(() {
        isRefreshing = true;
      });

      await loadChildren();

      final selectedChildId = selectedChild?['id'] ?? '';

      if (selectedChildId.toString().isNotEmpty) {
        final matchedChild = children.firstWhere(
          (child) => child['id'] == selectedChildId,
          orElse: () => selectedChild!,
        );

        selectedChild = matchedChild;

        await loadChildOverview(matchedChild);
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
        'profileImageUrl': data['profileImageUrl'] ?? '',
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

    marksTotal = 0;
    averageMark = 0;

    assignmentsTotal = 0;
    assignmentsSubmitted = 0;
    assignmentsPending = 0;

    feesTotal = 0;
    feesPaid = 0;
    feesUnpaid = 0;
    totalFeesAmount = 0;
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

    double total = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final markValue = data['mark'] ??
          data['score'] ??
          data['value'] ??
          data['result'] ??
          data['marks'] ??
          0;

      total += parseDouble(markValue);
    }

    averageMark = total / marksTotal;
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

    assignmentsTotal = assignmentsSnapshot.docs.length;

    final submissionsSnapshot = await firestore
        .collection('assignment_submissions')
        .where('studentId', isEqualTo: studentId)
        .get();

    assignmentsSubmitted = submissionsSnapshot.docs.length;

    if (assignmentsSubmitted > assignmentsTotal) {
      assignmentsSubmitted = assignmentsTotal;
    }

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

      final status = (data['status'] ?? 'Unpaid').toString();
      final amount = parseDouble(data['amount'] ?? 0);

      totalFeesAmount += amount;

      if (status == 'Paid') {
        feesPaid++;
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

    final percent = (attendancePresent / attendanceTotal) * 100;
    return '${percent.toStringAsFixed(0)}%';
  }

  String assignmentProgress() {
    if (assignmentsTotal == 0) {
      return '0%';
    }

    final percent = (assignmentsSubmitted / assignmentsTotal) * 100;
    return '${percent.toStringAsFixed(0)}%';
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
      final percent = (attendancePresent / attendanceTotal) * 100;

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
          'Academic performance is strong with an average of ${averageMark.toStringAsFixed(2)}.',
        );
      } else if (averageMark >= 10) {
        summaryParts.add(
          'Academic performance is acceptable with an average of ${averageMark.toStringAsFixed(2)}, but there is room for improvement.',
        );
      } else {
        summaryParts.add(
          'Academic performance needs support because the average is ${averageMark.toStringAsFixed(2)}.',
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

  Widget childSelector() {
    if (children.length <= 1) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedChild?['id'],
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: children.map((child) {
            return DropdownMenuItem<String>(
              value: child['id'],
              child: Text(child['fullName'] ?? 'Student'),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primaryBlue,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(
                    Icons.child_care_outlined,
                    color: AppColors.white,
                    size: 46,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            child['fullName'] ?? 'Student',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            child['className'].toString().isEmpty
                ? 'No class assigned'
                : child['className'],
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (child['email'].toString().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              child['email'],
              style: const TextStyle(
                color: AppColors.textGrey,
              ),
            ),
          ],
          if (child['phone'].toString().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              child['phone'],
              style: const TextStyle(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 28,
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
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
    );
  }

  Widget statsGrid() {
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
          subtitle: '$attendancePresent present / $attendanceTotal total',
        ),
        statCard(
          title: 'Average Result',
          value: marksTotal == 0 ? '0' : averageMark.toStringAsFixed(2),
          icon: Icons.bar_chart_outlined,
          subtitle: '$marksTotal mark record(s)',
        ),
        statCard(
          title: 'Assignments',
          value: assignmentProgress(),
          icon: Icons.assignment_outlined,
          subtitle: '$assignmentsSubmitted submitted / $assignmentsTotal total',
        ),
        statCard(
          title: 'Fees',
          value: feesUnpaid.toString(),
          icon: Icons.account_balance_wallet_outlined,
          subtitle: 'Unpaid: ${formatDouble(unpaidFeesAmount)}',
        ),
        statCard(
          title: 'Timetable',
          value: timetableTotal.toString(),
          icon: Icons.calendar_month_outlined,
          subtitle: 'Class timetable records',
        ),
        statCard(
          title: 'Absences',
          value: attendanceAbsent.toString(),
          icon: Icons.warning_amber_outlined,
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
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Progress Summary',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiSummary.isEmpty
                ? 'No enough data available yet to generate a useful progress summary.'
                : aiSummary,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.5,
            ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Child Details',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
        padding: const EdgeInsets.all(24),
        child: Text(
          'No child is assigned to your parent account yet. Please contact the school admin.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
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
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
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
    );
  }
}