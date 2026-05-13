import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AIStudyAssistantScreen extends StatefulWidget {
  const AIStudyAssistantScreen({super.key});

  @override
  State<AIStudyAssistantScreen> createState() => _AIStudyAssistantScreenState();
}

class _AIStudyAssistantScreenState extends State<AIStudyAssistantScreen> {
  final questionController = TextEditingController();

  bool showAnswer = false;

  final List<String> prompts = [
    'Explain this lesson',
    'Create a study plan',
    'Summarize my notes',
    'Generate quiz questions',
  ];

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  void askAI() {
    if (questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question'),
        ),
      );
      return;
    }

    setState(() {
      showAnswer = true;
    });
  }

  Widget promptChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        questionController.text = text;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Study Assistant'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Study Smarter with AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Ask questions, summarize notes, create study plans, and prepare for exams.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Suggested Prompts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: prompts.map(promptChip).toList(),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: questionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Ask your question',
                  hintText: 'Example: Explain photosynthesis in simple words...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.question_answer_outlined),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.upload_file_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload notes placeholder. File upload will be added later with Firebase Storage.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: askAI,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Ask AI'),
                ),
              ),

              const SizedBox(height: 24),

              if (showAnswer)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'AI Response',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Text(
                        'This is a placeholder AI response. Later, this screen will connect to a real AI API to explain lessons, summarize notes, and generate study plans.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          height: 1.5,
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
  }
}