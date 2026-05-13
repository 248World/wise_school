import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController messageController = TextEditingController();

  final List<String> prompts = [
    'Generate monthly report',
    'Summarize attendance trends',
    'Write announcement',
    'Create study plan',
  ];

  final List<Map<String, String>> messages = [
    {
      'sender': 'ai',
      'text': 'Hello! I am your Wise School AI assistant. How can I help today?',
    },
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'sender': 'user',
        'text': text,
      });

      messages.add({
        'sender': 'ai',
        'text':
            'AI response placeholder. The real AI backend will be connected later.',
      });

      messageController.clear();
    });
  }

  Widget messageBubble(Map<String, String> message) {
    final bool isUser = message['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            color: isUser ? AppColors.white : AppColors.textDark,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget promptChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        messageController.text = text;
      },
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
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: prompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return promptChip(prompts[index]);
                },
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return messageBubble(messages[index]);
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
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
                      decoration: const InputDecoration(
                        hintText: 'Ask the AI assistant...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}