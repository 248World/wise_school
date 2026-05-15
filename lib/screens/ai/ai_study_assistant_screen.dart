import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AIStudyAssistantScreen extends StatefulWidget {
  const AIStudyAssistantScreen({super.key});

  @override
  State<AIStudyAssistantScreen> createState() => _AIStudyAssistantScreenState();
}

class _AIStudyAssistantScreenState extends State<AIStudyAssistantScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final questionController = TextEditingController();
  final notesController = TextEditingController();

  bool isLoading = true;
  bool isGenerating = false;
  String? errorMessage;

  String currentUserId = '';
  String currentUserName = '';
  String classId = '';
  String className = '';

  String aiResponse = '';
  List<Map<String, dynamic>> marks = [];
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> timetables = [];
  List<Map<String, dynamic>> history = [];

  final List<String> suggestedPrompts = [
    'Explain this lesson',
    'Create a study plan',
    'Summarize my notes',
    'Generate quiz questions',
    'Check my progress',
    'Help me prepare for exams',
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadStudentContext();
    });
  }

  @override
  void dispose() {
    questionController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadStudentContext() async {
    try {
      final authProvider = context.read<AuthProvider>();

      currentUserId = authProvider.userId ?? '';
      currentUserName = authProvider.fullName ?? 'Student';

      if (currentUserId.isEmpty) {
        throw Exception('User not found. Please login again.');
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userDoc = await firestore.collection('users').doc(currentUserId).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        classId = data?['classId'] ?? '';
        className = data?['className'] ?? '';
        currentUserName = data?['fullName'] ?? currentUserName;
      }

      final marksSnapshot = await firestore
          .collection('marks')
          .where('studentId', isEqualTo: currentUserId)
          .get();

      marks = marksSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'subjectName': data['subjectName'] ?? '',
          'mark': data['mark'] ?? 0,
          'grade': data['grade'] ?? '',
          'progress': data['progress'] ?? '',
          'comment': data['comment'] ?? '',
          'coefficient': data['coefficient'] ?? 1,
          'teacherName': data['teacherName'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();

      final attendanceSnapshot = await firestore
          .collection('attendance')
          .where('studentId', isEqualTo: currentUserId)
          .get();

      attendance = attendanceSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'status': data['status'] ?? '',
          'date': data['date'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();

      if (classId.isNotEmpty) {
        final assignmentsSnapshot = await firestore
            .collection('assignments')
            .where('classId', isEqualTo: classId)
            .get();

        assignments = assignmentsSnapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'subjectName': data['subjectName'] ?? '',
            'dueDate': data['dueDate'],
            'teacherName': data['teacherName'] ?? '',
            'createdAt': data['createdAt'],
          };
        }).toList();

        final timetableSnapshot = await firestore
            .collection('timetables')
            .where('classId', isEqualTo: classId)
            .get();

        timetables = timetableSnapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'day': data['day'] ?? '',
            'startTime': data['startTime'] ?? '',
            'endTime': data['endTime'] ?? '',
            'subjectName': data['subjectName'] ?? '',
            'teacherName': data['teacherName'] ?? '',
            'room': data['room'] ?? '',
            'dayIndex': data['dayIndex'] ?? 0,
            'startMinutes': data['startMinutes'] ?? 0,
          };
        }).toList();

        timetables.sort((a, b) {
          final dayCompare = (a['dayIndex'] ?? 0).compareTo(b['dayIndex'] ?? 0);

          if (dayCompare != 0) {
            return dayCompare;
          }

          return (a['startMinutes'] ?? 0).compareTo(b['startMinutes'] ?? 0);
        });
      }

      await loadHistory();

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

  Future<void> loadHistory() async {
    if (currentUserId.isEmpty) {
      history = [];
      return;
    }

    final snapshot = await firestore
        .collection('ai_study_chats')
        .where('userId', isEqualTo: currentUserId)
        .get();

    history = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'question': data['question'] ?? '',
        'answer': data['answer'] ?? '',
        'createdAt': data['createdAt'],
      };
    }).toList();

    history.sort((a, b) {
      final aTime = a['createdAt'];
      final bTime = b['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });
  }

  double parseNumber(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }

  double calculateAverage() {
    if (marks.isEmpty) return 0;

    double total = 0;
    double totalCoefficient = 0;

    for (final mark in marks) {
      final value = parseNumber(mark['mark']);
      final coefficient = parseNumber(mark['coefficient']) <= 0
          ? 1
          : parseNumber(mark['coefficient']);

      total += value * coefficient;
      totalCoefficient += coefficient;
    }

    if (totalCoefficient == 0) return 0;

    return total / totalCoefficient;
  }

  int attendanceCount(String status) {
    return attendance.where((item) {
      return item['status'] == status;
    }).length;
  }

  String attendanceRate() {
    if (attendance.isEmpty) return '0%';

    final present = attendanceCount('Present');
    final late = attendanceCount('Late');
    final rate = ((present + late) / attendance.length) * 100;

    return '${rate.toStringAsFixed(0)}%';
  }

  List<Map<String, dynamic>> weakSubjects() {
    final items = marks.where((mark) {
      return parseNumber(mark['mark']) < 10;
    }).toList();

    items.sort((a, b) {
      return parseNumber(a['mark']).compareTo(parseNumber(b['mark']));
    });

    return items;
  }

  List<Map<String, dynamic>> strongSubjects() {
    final items = marks.where((mark) {
      return parseNumber(mark['mark']) >= 14;
    }).toList();

    items.sort((a, b) {
      return parseNumber(b['mark']).compareTo(parseNumber(a['mark']));
    });

    return items;
  }

  String cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String buildProgressSummary() {
    final average = calculateAverage();
    final present = attendanceCount('Present');
    final absent = attendanceCount('Absent');
    final late = attendanceCount('Late');
    final weak = weakSubjects();
    final strong = strongSubjects();

    final buffer = StringBuffer();

    buffer.writeln('Here is your current study progress summary:');
    buffer.writeln('');
    buffer.writeln('Average result: ${average.toStringAsFixed(2)}/20.');
    buffer.writeln('Attendance rate: ${attendanceRate()} ($present present, $late late, $absent absent).');
    buffer.writeln('Assignments available: ${assignments.length}.');
    buffer.writeln('Timetable records: ${timetables.length}.');
    buffer.writeln('');

    if (strong.isNotEmpty) {
      buffer.writeln('Strong subjects:');
      for (final item in strong.take(3)) {
        buffer.writeln('- ${item['subjectName']}: ${parseNumber(item['mark']).toStringAsFixed(1)}/20');
      }
      buffer.writeln('');
    }

    if (weak.isNotEmpty) {
      buffer.writeln('Subjects needing support:');
      for (final item in weak.take(3)) {
        buffer.writeln('- ${item['subjectName']}: ${parseNumber(item['mark']).toStringAsFixed(1)}/20');
      }
      buffer.writeln('');
      buffer.writeln('Focus first on the weak subjects, revise the teacher comments, and practice small exercises daily.');
    } else if (marks.isNotEmpty) {
      buffer.writeln('No weak subject detected from your saved marks. Keep revising consistently.');
    } else {
      buffer.writeln('No result data is available yet, so I cannot calculate academic strengths or weaknesses.');
    }

    return buffer.toString();
  }

  String buildStudyPlan(String question, String notes) {
    final weak = weakSubjects();
    final buffer = StringBuffer();

    buffer.writeln('Here is a simple 7-day study plan for you:');
    buffer.writeln('');

    if (weak.isNotEmpty) {
      buffer.writeln('Priority subjects:');
      for (final item in weak.take(3)) {
        buffer.writeln('- ${item['subjectName']}');
      }
      buffer.writeln('');
    }

    buffer.writeln('Day 1: Review the lesson notes and identify the main definitions.');
    buffer.writeln('Day 2: Rewrite the lesson in your own words.');
    buffer.writeln('Day 3: Practice exercises from the weakest topic.');
    buffer.writeln('Day 4: Create flashcards for formulas, keywords, and examples.');
    buffer.writeln('Day 5: Answer quiz questions without looking at the notes.');
    buffer.writeln('Day 6: Correct mistakes and revise teacher comments.');
    buffer.writeln('Day 7: Do a final 30-minute recap and explain the lesson aloud.');
    buffer.writeln('');

    if (notes.isNotEmpty) {
      buffer.writeln('Based on your notes, start with this key idea:');
      buffer.writeln(cleanText(notes).length > 250 ? '${cleanText(notes).substring(0, 250)}...' : cleanText(notes));
    }

    return buffer.toString();
  }

  String buildNotesSummary(String notes) {
    if (notes.trim().isEmpty) {
      return 'Paste your notes in the notes box first, then tap “Summarize my notes”.';
    }

    final sentences = notes
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => cleanText(item))
        .where((item) => item.isNotEmpty)
        .toList();

    final buffer = StringBuffer();

    buffer.writeln('Summary of your notes:');
    buffer.writeln('');

    if (sentences.isEmpty) {
      buffer.writeln('- ${cleanText(notes)}');
    } else {
      for (final sentence in sentences.take(5)) {
        buffer.writeln('- $sentence');
      }
    }

    buffer.writeln('');
    buffer.writeln('What to remember:');
    buffer.writeln('- Identify the main definition.');
    buffer.writeln('- Memorize important keywords.');
    buffer.writeln('- Practice with examples, not only reading.');

    return buffer.toString();
  }

  String buildQuizQuestions(String question, String notes) {
    final source = notes.trim().isNotEmpty ? notes : question;
    final words = cleanText(source)
        .split(' ')
        .where((word) => word.length > 4)
        .take(8)
        .toList();

    final keyword = words.isEmpty ? 'the lesson' : words.first;

    final buffer = StringBuffer();

    buffer.writeln('Here are quiz questions to practice:');
    buffer.writeln('');
    buffer.writeln('1. Explain the main idea of $keyword in your own words.');
    buffer.writeln('2. Give one example related to this lesson.');
    buffer.writeln('3. What are the important keywords in this topic?');
    buffer.writeln('4. What mistake should a student avoid when answering this topic?');
    buffer.writeln('5. Create a short paragraph using the main terms from the lesson.');
    buffer.writeln('');

    if (words.length >= 3) {
      buffer.writeln('Bonus keywords to revise: ${words.take(5).join(', ')}.');
    }

    return buffer.toString();
  }

  String buildLessonExplanation(String question, String notes) {
    final topic = question
        .replaceAll('Explain', '')
        .replaceAll('explain', '')
        .replaceAll('this lesson', '')
        .trim();

    final buffer = StringBuffer();

    buffer.writeln('Let me explain it in a simple way:');
    buffer.writeln('');

    if (topic.isNotEmpty) {
      buffer.writeln('$topic is the topic you should break into three parts: meaning, example, and practice.');
    } else if (notes.isNotEmpty) {
      buffer.writeln('From your notes, the lesson should be studied by finding the main idea, the important terms, and the examples.');
    } else {
      buffer.writeln('Write the lesson topic or paste your notes, and I will make the explanation more specific.');
    }

    buffer.writeln('');
    buffer.writeln('How to understand it:');
    buffer.writeln('1. Start with the definition.');
    buffer.writeln('2. Connect it to a real example.');
    buffer.writeln('3. Practice one question about it.');
    buffer.writeln('4. Explain it aloud as if you are teaching someone else.');

    if (notes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('From your note, focus on:');
      buffer.writeln(cleanText(notes).length > 300 ? '${cleanText(notes).substring(0, 300)}...' : cleanText(notes));
    }

    return buffer.toString();
  }

  String buildExamPreparation(String notes) {
    final buffer = StringBuffer();

    buffer.writeln('Exam preparation plan:');
    buffer.writeln('');
    buffer.writeln('1. List all subjects/topics that will appear in the exam.');
    buffer.writeln('2. Start with the weakest subject first.');
    buffer.writeln('3. Study for 40 minutes, then rest for 10 minutes.');
    buffer.writeln('4. After each topic, answer at least 5 practice questions.');
    buffer.writeln('5. The night before the exam, revise summaries instead of learning new topics.');
    buffer.writeln('');

    if (marks.isNotEmpty) {
      final weak = weakSubjects();

      if (weak.isNotEmpty) {
        buffer.writeln('Based on your current marks, revise these first:');
        for (final item in weak.take(3)) {
          buffer.writeln('- ${item['subjectName']}');
        }
      } else {
        buffer.writeln('Your marks do not show a weak subject yet, so divide time equally between subjects.');
      }
    }

    if (notes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Use these notes as your revision base:');
      buffer.writeln(cleanText(notes).length > 250 ? '${cleanText(notes).substring(0, 250)}...' : cleanText(notes));
    }

    return buffer.toString();
  }

  String generateSmartResponse({
    required String question,
    required String notes,
  }) {
    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('study plan') ||
        lowerQuestion.contains('plan')) {
      return buildStudyPlan(question, notes);
    }

    if (lowerQuestion.contains('summarize') ||
        lowerQuestion.contains('summary') ||
        lowerQuestion.contains('notes')) {
      return buildNotesSummary(notes);
    }

    if (lowerQuestion.contains('quiz') ||
        lowerQuestion.contains('questions') ||
        lowerQuestion.contains('test')) {
      return buildQuizQuestions(question, notes);
    }

    if (lowerQuestion.contains('progress') ||
        lowerQuestion.contains('average') ||
        lowerQuestion.contains('result') ||
        lowerQuestion.contains('attendance')) {
      return buildProgressSummary();
    }

    if (lowerQuestion.contains('exam') ||
        lowerQuestion.contains('prepare')) {
      return buildExamPreparation(notes);
    }

    if (lowerQuestion.contains('explain') ||
        lowerQuestion.contains('lesson')) {
      return buildLessonExplanation(question, notes);
    }

    return '''
I understood your question: "$question"

Here is a helpful way to approach it:

1. Identify the main topic.
2. Write the definition in simple words.
3. Add one example.
4. Practice with one question.
5. Review your mistake and repeat.

${marks.isNotEmpty ? 'Your current average is ${calculateAverage().toStringAsFixed(2)}/20, so keep revising consistently and focus more on weak subjects.' : 'Once your marks are added, I can give a more personalized study recommendation.'}
''';
  }

  Future<void> askAI() async {
    final question = questionController.text.trim();
    final notes = notesController.text.trim();

    if (question.isEmpty && notes.isEmpty) {
      showSnackBar('Please enter a question or paste your notes.');
      return;
    }

    final actualQuestion = question.isEmpty ? 'Summarize my notes' : question;

    try {
      setState(() {
        isGenerating = true;
        aiResponse = '';
      });

      await Future.delayed(const Duration(milliseconds: 450));

      final response = generateSmartResponse(
        question: actualQuestion,
        notes: notes,
      );

      await firestore.collection('ai_study_chats').add({
        'userId': currentUserId,
        'userName': currentUserName,
        'role': 'Student',
        'question': actualQuestion,
        'notes': notes,
        'answer': response,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadHistory();

      if (!mounted) return;

      setState(() {
        aiResponse = response;
        isGenerating = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isGenerating = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void usePrompt(String prompt) {
    questionController.text = prompt;
    setState(() {});
  }

  Future<void> clearHistory() async {
    try {
      final snapshot = await firestore
          .collection('ai_study_chats')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch = firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await loadHistory();

      if (!mounted) return;

      setState(() {});

      showSnackBar('AI study history cleared');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month • $hour:$minute';
    }

    return 'Recently';
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
                    'assets/icons/ai_assistant.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.psychology_outlined,
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
                      'Study Smarter with AI',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      className.isEmpty
                          ? 'Ask questions, summarize notes, and prepare for exams.'
                          : 'Class: $className • Ask questions, summarize notes, and prepare for exams.',
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

  Widget promptChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: suggestedPrompts.map((prompt) {
        return ActionChip(
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.border),
          label: Text(
            prompt,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () {
            usePrompt(prompt);
          },
        );
      }).toList(),
    );
  }

  Widget contextSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          pngIconBox(
            imagePath: 'assets/icons/results.png',
            fallbackIcon: Icons.analytics_outlined,
            size: 50,
            padding: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                smallChip(
                  label: 'Average: ${calculateAverage().toStringAsFixed(2)}/20',
                  color: AppColors.primaryBlue,
                ),
                smallChip(
                  label: 'Attendance: ${attendanceRate()}',
                  color: AppColors.softGreen,
                ),
                smallChip(
                  label: '${assignments.length} Assignment(s)',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget smallChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget questionBox() {
    return TextField(
      controller: questionController,
      minLines: 3,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Ask your question',
        hintText: 'Example: Explain photosynthesis in simple words',
        prefixIcon: Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget notesBox() {
    return TextField(
      controller: notesController,
      minLines: 4,
      maxLines: 8,
      decoration: const InputDecoration(
        labelText: 'Paste notes here',
        hintText: 'Paste your lesson notes here for summary, quiz, or explanation.',
        prefixIcon: Icon(Icons.note_alt_outlined),
      ),
    );
  }

  Widget aiResponseCard() {
    final hasResponse = aiResponse.trim().isNotEmpty;

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
                  'AI Response',
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
          if (isGenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Text(
              hasResponse
                  ? aiResponse
                  : 'Ask a question or choose a suggested prompt. The assistant will use your notes, marks, attendance, assignments, and timetable data to give a useful response.',
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.55,
              ),
            ),
        ],
      ),
    );
  }

  Widget historySection() {
    if (history.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent AI Study History',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: clearHistory,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.take(5).length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final item = history[index];

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    questionController.text = item['question'] ?? '';
                    aiResponse = item['answer'] ?? '';
                  });
                },
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      pngIconBox(
                        imagePath: 'assets/icons/ai_assistant.png',
                        fallbackIcon: Icons.history_outlined,
                        size: 42,
                        padding: 9,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['question'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(item['createdAt']),
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
        title: const Text('AI Study Assistant'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadStudentContext,
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
                    onRefresh: loadStudentContext,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerCard(),
                          const SizedBox(height: 18),
                          contextSummaryCard(),
                          const SizedBox(height: 22),
                          const Text(
                            'Suggested Prompts',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          promptChips(),
                          const SizedBox(height: 22),
                          questionBox(),
                          const SizedBox(height: 14),
                          notesBox(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: isGenerating ? null : askAI,
                              icon: isGenerating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                isGenerating ? 'Generating...' : 'Ask AI',
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          aiResponseCard(),
                          const SizedBox(height: 22),
                          historySection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
