import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController messageController = TextEditingController();

  bool isLoading = false;

  final List<Map<String, dynamic>> messages = [
    {
      'text':
          'Hello! I am your Wise School AI assistant. I can summarize attendance, fees, assignments, users, announcements, and generate school reports from your database.',
      'isUser': false,
    },
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<int> countCollection(String collection) async {
    final snapshot = await firestore.collection(collection).get();
    return snapshot.docs.length;
  }

  Future<int> countUsersByRole(String role) async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }

  Future<String> generateDashboardSummary() async {
    final students = await countUsersByRole('Student');
    final parents = await countUsersByRole('Parent');
    final teachers = await countUsersByRole('Teacher');
    final admins = await countUsersByRole('Admin');

    final classes = await countCollection('classes');
    final subjects = await countCollection('subjects');
    final assignments = await countCollection('assignments');
    final attendance = await countCollection('attendance');
    final marks = await countCollection('marks');
    final fees = await countCollection('fees');
    final announcements = await countCollection('announcements');

    return '''
Wise School Summary:

Users:
- Students: $students
- Parents: $parents
- Teachers: $teachers
- Admins: $admins

Academic:
- Classes: $classes
- Subjects: $subjects
- Assignments: $assignments
- Attendance records: $attendance
- Mark records: $marks

Administration:
- Fee records: $fees
- Announcements: $announcements

AI Note:
The school system is active. You can monitor students, parents, teachers, assignments, attendance, marks, fees, and announcements directly from the admin dashboard.
''';
  }

  Future<String> generateAttendanceSummary() async {
    final snapshot = await firestore.collection('attendance').get();

    int total = snapshot.docs.length;
    int present = 0;
    int absent = 0;
    int late = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'present') {
        present++;
      } else if (status == 'absent') {
        absent++;
      } else if (status == 'late') {
        late++;
      }
    }

    if (total == 0) {
      return 'No attendance records found yet. Teachers need to start marking attendance before I can generate a useful attendance summary.';
    }

    final presentRate = ((present / total) * 100).toStringAsFixed(1);
    final absentRate = ((absent / total) * 100).toStringAsFixed(1);

    return '''
Attendance Summary:

Total attendance records: $total
Present: $present
Absent: $absent
Late: $late

Presence rate: $presentRate%
Absence rate: $absentRate%

AI Note:
${double.parse(presentRate) >= 80 ? 'Attendance looks good overall.' : 'Attendance needs attention. The school should follow up with students who have repeated absences.'}
''';
  }

  Future<String> generateFeesSummary() async {
    final snapshot = await firestore.collection('fees').get();

    int totalRecords = snapshot.docs.length;
    int paid = 0;
    int unpaid = 0;
    int pending = 0;
    double totalAmount = 0;
    double paidAmount = 0;
    double unpaidAmount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = (data['status'] ?? '').toString().toLowerCase();
      final amountRaw = data['amount'] ?? 0;
      final amount = double.tryParse(amountRaw.toString()) ?? 0;

      totalAmount += amount;

      if (status == 'paid') {
        paid++;
        paidAmount += amount;
      } else if (status == 'pending') {
        pending++;
        unpaidAmount += amount;
      } else {
        unpaid++;
        unpaidAmount += amount;
      }
    }

    if (totalRecords == 0) {
      return 'No fee records found yet. The admin should add school fee records first.';
    }

    return '''
Fees Summary:

Total fee records: $totalRecords
Paid records: $paid
Pending records: $pending
Unpaid records: $unpaid

Total expected amount: ${totalAmount.toStringAsFixed(2)}
Paid amount: ${paidAmount.toStringAsFixed(2)}
Remaining / pending amount: ${unpaidAmount.toStringAsFixed(2)}

AI Note:
${unpaidAmount > 0 ? 'There are still fee records that need follow-up.' : 'All available fee records appear to be completed.'}
''';
  }

  Future<String> generateAssignmentSummary() async {
    final assignmentsSnapshot = await firestore.collection('assignments').get();
    final submissionsSnapshot =
        await firestore.collection('assignment_submissions').get();

    final assignments = assignmentsSnapshot.docs.length;
    final submissions = submissionsSnapshot.docs.length;

    if (assignments == 0) {
      return 'No assignments found yet. Teachers need to create assignments first.';
    }

    return '''
Assignments Summary:

Total assignments: $assignments
Student submissions: $submissions

AI Note:
${submissions == 0 ? 'Students have not submitted assignments yet, or the submission records are not available.' : 'Assignment submission activity has started. Admins and teachers can monitor student progress from the assignments module.'}
''';
  }

  Future<String> generateAnnouncementsSummary() async {
    final snapshot = await firestore.collection('announcements').get();

    int total = snapshot.docs.length;
    int all = 0;
    int students = 0;
    int parents = 0;
    int teachers = 0;
    int admins = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final target = data['targetAudience'] ?? 'All';

      if (target == 'All') all++;
      if (target == 'Students') students++;
      if (target == 'Parents') parents++;
      if (target == 'Teachers') teachers++;
      if (target == 'Admins') admins++;
    }

    if (total == 0) {
      return 'No announcements found yet. Admin can create announcements for students, parents, teachers, or everyone.';
    }

    return '''
Announcements Summary:

Total announcements: $total

Target audience:
- All: $all
- Students: $students
- Parents: $parents
- Teachers: $teachers
- Admins: $admins

AI Note:
Announcements are being used. Make sure important school updates are targeted to the correct audience.
''';
  }

  Future<String> generateMarksSummary() async {
    final snapshot = await firestore.collection('marks').get();

    if (snapshot.docs.isEmpty) {
      return 'No marks found yet. Teachers need to add marks before I can analyze academic performance.';
    }

    double total = 0;
    int count = 0;
    int weak = 0;
    int good = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final mark = double.tryParse((data['mark'] ?? 0).toString()) ?? 0;

      total += mark;
      count++;

      if (mark < 10) {
        weak++;
      }

      if (mark >= 14) {
        good++;
      }
    }

    final average = count == 0 ? 0 : total / count;

    return '''
Marks Summary:

Total mark records: $count
Average mark: ${average.toStringAsFixed(2)}/20
Good records: $good
Weak records: $weak

AI Note:
${average >= 14 ? 'Academic performance looks good overall.' : average >= 10 ? 'Academic performance is average and needs continued revision support.' : 'Academic performance needs attention. Teachers should support weak students and contact parents where necessary.'}
''';
  }

  Future<String> generateMonthlyReport() async {
    final dashboard = await generateDashboardSummary();
    final attendance = await generateAttendanceSummary();
    final marks = await generateMarksSummary();
    final fees = await generateFeesSummary();
    final assignments = await generateAssignmentSummary();
    final announcements = await generateAnnouncementsSummary();

    return '''
MONTHLY SCHOOL REPORT

$dashboard

$attendance

$marks

$fees

$assignments

$announcements

Final AI Recommendation:
The admin should keep monitoring attendance, academic performance, unpaid fees, assignment submissions, and announcements. The more teachers and parents use the platform, the more accurate the report becomes.
''';
  }

  Future<String> answerQuestion(String question) async {
    final lower = question.toLowerCase();

    if (lower.contains('monthly') || lower.contains('report')) {
      return generateMonthlyReport();
    }

    if (lower.contains('attendance') || lower.contains('absence')) {
      return generateAttendanceSummary();
    }

    if (lower.contains('mark') ||
        lower.contains('result') ||
        lower.contains('performance')) {
      return generateMarksSummary();
    }

    if (lower.contains('fee') ||
        lower.contains('payment') ||
        lower.contains('paid')) {
      return generateFeesSummary();
    }

    if (lower.contains('assignment') ||
        lower.contains('homework') ||
        lower.contains('task')) {
      return generateAssignmentSummary();
    }

    if (lower.contains('announcement') || lower.contains('notice')) {
      return generateAnnouncementsSummary();
    }

    if (lower.contains('student') ||
        lower.contains('teacher') ||
        lower.contains('parent') ||
        lower.contains('user') ||
        lower.contains('class') ||
        lower.contains('subject')) {
      return generateDashboardSummary();
    }

    return '''
I can help with school data from your database.

Try asking:
- Generate monthly report
- Summarize attendance
- Summarize marks
- Summarize fees
- Summarize assignments
- Summarize announcements
- How many students, parents, and teachers do we have?
''';
  }

  Future<void> sendMessage(String text) async {
    final message = text.trim();

    if (message.isEmpty) return;

    setState(() {
      messages.add({
        'text': message,
        'isUser': true,
      });
      isLoading = true;
    });

    messageController.clear();

    try {
      final response = await answerQuestion(message);

      if (!mounted) return;

      setState(() {
        messages.add({
          'text': response,
          'isUser': false,
        });
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'text': error.toString().replaceAll('Exception: ', ''),
          'isUser': false,
        });
        isLoading = false;
      });
    }
  }

  Widget pngIconBox({
    required String imagePath,
    required IconData fallbackIcon,
    Color color = AppColors.primaryBlue,
    double size = 44,
    double padding = 9,
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

  Widget quickAction({
    required String text,
    required IconData icon,
    required String imagePath,
  }) {
    return ActionChip(
      avatar: Image.asset(
        imagePath,
        height: 18,
        width: 18,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            icon,
            size: 18,
            color: AppColors.primaryBlue,
          );
        },
      ),
      backgroundColor: AppColors.white,
      side: const BorderSide(color: AppColors.border),
      label: Text(text),
      onPressed: isLoading
          ? null
          : () {
              sendMessage(text);
            },
    );
  }

  Widget messageBubble(Map<String, dynamic> item) {
    final isUser = item['isUser'] == true;
    final text = item['text'] ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: isUser ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: isUser ? AppColors.white : AppColors.textDark,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ask the AI assistant...',
                  prefixIcon: Icon(Icons.smart_toy_outlined),
                ),
                onSubmitted: sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 50,
              width: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        sendMessage(messageController.text);
                      },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/icons/ai_assistant.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.white,
                    size: 30,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Ask questions about users, attendance, marks, fees, assignments, announcements, and reports.',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.90),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget quickActionsBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          quickAction(
            text: 'Generate monthly report',
            icon: Icons.description_outlined,
            imagePath: 'assets/icons/ai_report.png',
          ),
          const SizedBox(width: 8),
          quickAction(
            text: 'Summarize attendance',
            icon: Icons.fact_check_outlined,
            imagePath: 'assets/icons/attendance.png',
          ),
          const SizedBox(width: 8),
          quickAction(
            text: 'Summarize marks',
            icon: Icons.bar_chart_outlined,
            imagePath: 'assets/icons/results.png',
          ),
          const SizedBox(width: 8),
          quickAction(
            text: 'Summarize fees',
            icon: Icons.account_balance_wallet_outlined,
            imagePath: 'assets/icons/fees.png',
          ),
          const SizedBox(width: 8),
          quickAction(
            text: 'Summarize assignments',
            icon: Icons.assignment_outlined,
            imagePath: 'assets/icons/assignments.png',
          ),
          const SizedBox(width: 8),
          quickAction(
            text: 'Summarize announcements',
            icon: Icons.campaign_outlined,
            imagePath: 'assets/icons/announcements.png',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            headerCard(),
            quickActionsBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return messageBubble(messages[index]);
                },
              ),
            ),
            inputBar(),
          ],
        ),
      ),
    );
  }
}
