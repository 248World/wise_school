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
          'Hello! I am your Wise School AI assistant. I can help you summarize attendance, fees, assignments, users, announcements, and generate school reports.',
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

Administration:
- Fee records: $fees
- Announcements: $announcements

AI Note:
The school system is active. You can monitor students, parents, teachers, assignments, attendance, fees, and announcements directly from the admin dashboard.
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

  Future<String> generateMonthlyReport() async {
    final dashboard = await generateDashboardSummary();
    final attendance = await generateAttendanceSummary();
    final fees = await generateFeesSummary();
    final assignments = await generateAssignmentSummary();
    final announcements = await generateAnnouncementsSummary();

    return '''
MONTHLY SCHOOL REPORT

$dashboard

$attendance

$fees

$assignments

$announcements

Final AI Recommendation:
The admin should keep monitoring attendance, unpaid fees, assignment submissions, and announcements. The more teachers and parents use the platform, the more accurate the school report becomes.
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

  Widget quickAction({
    required String text,
    required IconData icon,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: AppColors.primaryBlue,
      ),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  quickAction(
                    text: 'Generate monthly report',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(width: 8),
                  quickAction(
                    text: 'Summarize attendance',
                    icon: Icons.fact_check_outlined,
                  ),
                  const SizedBox(width: 8),
                  quickAction(
                    text: 'Summarize fees',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(width: 8),
                  quickAction(
                    text: 'Summarize assignments',
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(width: 8),
                  quickAction(
                    text: 'Summarize announcements',
                    icon: Icons.campaign_outlined,
                  ),
                ],
              ),
            ),
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