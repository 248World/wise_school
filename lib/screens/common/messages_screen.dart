import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class MessagesScreen extends StatefulWidget {
  final String role;

  const MessagesScreen({
    super.key,
    this.role = 'Parent',
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController messageController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;
  String? errorMessage;

  String currentRole = 'Parent';
  String currentUserId = '';
  String currentUserName = '';

  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> messages = [];

  String selectedConversationId = '';
  String selectedParentName = '';
  String selectedParentId = '';

  bool get isAdmin {
    return currentRole == 'Admin';
  }

  bool get isParent {
    return currentRole == 'Parent';
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadInitialData();
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();

      currentRole = widget.role;
      currentUserId = authProvider.userId ?? '';
      currentUserName = authProvider.fullName ?? currentRole;

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (isParent) {
        await loadParentConversation();
      } else if (isAdmin) {
        await loadAdminConversations();
      } else {
        await loadUserConversation();
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

  Future<void> loadParentConversation() async {
    if (currentUserId.isEmpty) {
      conversations = [];
      messages = [];
      return;
    }

    final conversationRef =
        firestore.collection('parent_admin_chats').doc(currentUserId);

    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      await conversationRef.set({
        'parentId': currentUserId,
        'parentName': currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'lastSenderName': '',
        'lastSenderRole': '',
        'unreadByAdmin': false,
        'unreadByParent': false,
      });
    }

    selectedConversationId = currentUserId;
    selectedParentId = currentUserId;
    selectedParentName = currentUserName;

    await loadMessages(selectedConversationId);

    await conversationRef.update({
      'unreadByParent': false,
    });
  }

  Future<void> loadUserConversation() async {
    await loadParentConversation();
  }

  Future<void> loadAdminConversations() async {
    final snapshot = await firestore.collection('parent_admin_chats').get();

    conversations = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'parentId': data['parentId'] ?? '',
        'parentName': data['parentName'] ?? 'Parent',
        'lastMessage': data['lastMessage'] ?? '',
        'lastMessageAt': data['lastMessageAt'],
        'lastSenderId': data['lastSenderId'] ?? '',
        'lastSenderName': data['lastSenderName'] ?? '',
        'lastSenderRole': data['lastSenderRole'] ?? '',
        'unreadByAdmin': data['unreadByAdmin'] ?? false,
        'unreadByParent': data['unreadByParent'] ?? false,
        'createdAt': data['createdAt'],
      };
    }).toList();

    conversations.sort((a, b) {
      final aTime = a['lastMessageAt'];
      final bTime = b['lastMessageAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });

    if (conversations.isNotEmpty && selectedConversationId.isEmpty) {
      final firstConversation = conversations.first;

      selectedConversationId = firstConversation['id'] ?? '';
      selectedParentId = firstConversation['parentId'] ?? '';
      selectedParentName = firstConversation['parentName'] ?? 'Parent';

      await loadMessages(selectedConversationId);

      await firestore
          .collection('parent_admin_chats')
          .doc(selectedConversationId)
          .update({
        'unreadByAdmin': false,
      });
    }
  }

  Future<void> loadMessages(String conversationId) async {
    if (conversationId.isEmpty) {
      messages = [];
      return;
    }

    final snapshot = await firestore
        .collection('parent_admin_chats')
        .doc(conversationId)
        .collection('messages')
        .get();

    messages = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'senderId': data['senderId'] ?? '',
        'senderName': data['senderName'] ?? '',
        'senderRole': data['senderRole'] ?? '',
        'text': data['text'] ?? '',
        'createdAt': data['createdAt'],
      };
    }).toList();

    messages.sort((a, b) {
      final aTime = a['createdAt'];
      final bTime = b['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return aTime.compareTo(bTime);
      }

      return 0;
    });
  }

  Future<void> refreshCurrentConversation() async {
    if (isAdmin) {
      await loadAdminConversations();

      if (selectedConversationId.isNotEmpty) {
        await loadMessages(selectedConversationId);
      }
    } else {
      await loadParentConversation();
    }

    if (!mounted) return;

    setState(() {});
  }

  Future<void> selectConversation(Map<String, dynamic> conversation) async {
    final conversationId = conversation['id'] ?? '';

    if (conversationId.isEmpty) {
      showSnackBar('Invalid conversation');
      return;
    }

    setState(() {
      selectedConversationId = conversationId;
      selectedParentId = conversation['parentId'] ?? '';
      selectedParentName = conversation['parentName'] ?? 'Parent';
      isLoading = true;
    });

    await loadMessages(conversationId);

    await firestore.collection('parent_admin_chats').doc(conversationId).update({
      'unreadByAdmin': false,
    });

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (currentUserId.isEmpty) {
      showSnackBar('Invalid user account');
      return;
    }

    if (selectedConversationId.isEmpty) {
      if (isParent) {
        selectedConversationId = currentUserId;
        selectedParentId = currentUserId;
        selectedParentName = currentUserName;
      } else {
        showSnackBar('Please select a parent conversation');
        return;
      }
    }

    try {
      setState(() {
        isSending = true;
      });

      final conversationRef =
          firestore.collection('parent_admin_chats').doc(selectedConversationId);

      final messageRef = conversationRef.collection('messages').doc();

      final batch = firestore.batch();

      batch.set(messageRef, {
        'senderId': currentUserId,
        'senderName': currentUserName,
        'senderRole': currentRole,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        conversationRef,
        {
          'parentId': selectedParentId.isNotEmpty
              ? selectedParentId
              : selectedConversationId,
          'parentName': selectedParentName.isNotEmpty
              ? selectedParentName
              : currentUserName,
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': currentUserId,
          'lastSenderName': currentUserName,
          'lastSenderRole': currentRole,
          'unreadByAdmin': isParent,
          'unreadByParent': isAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      messageController.clear();

      await refreshCurrentConversation();

      if (!mounted) return;

      setState(() {
        isSending = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSending = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> showStartChatSheet() async {
    final parentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Parent')
        .where('isActive', isEqualTo: true)
        .get();

    final parents = parentsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? 'Parent',
        'email': data['email'] ?? '',
      };
    }).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Start Chat with Parent',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              if (parents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No parent account found yet.',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: parents.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final parent = parents[index];

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryBlue,
                          child: Icon(
                            Icons.person_outline,
                            color: AppColors.white,
                          ),
                        ),
                        title: Text(parent['fullName'] ?? 'Parent'),
                        subtitle: Text(parent['email'] ?? ''),
                        onTap: () async {
                          Navigator.pop(context);

                          await openParentConversation(
                            parentId: parent['id'] ?? '',
                            parentName: parent['fullName'] ?? 'Parent',
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> openParentConversation({
    required String parentId,
    required String parentName,
  }) async {
    if (parentId.isEmpty) {
      showSnackBar('Invalid parent account');
      return;
    }

    final conversationRef =
        firestore.collection('parent_admin_chats').doc(parentId);

    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      await conversationRef.set({
        'parentId': parentId,
        'parentName': parentName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'lastSenderName': '',
        'lastSenderRole': '',
        'unreadByAdmin': false,
        'unreadByParent': false,
      });
    }

    selectedConversationId = parentId;
    selectedParentId = parentId;
    selectedParentName = parentName;

    await loadMessages(parentId);
    await loadAdminConversations();

    if (!mounted) return;

    setState(() {});
  }

  String formatTime(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    return '';
  }

  String formatDateTime(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Recently';
  }

  Widget conversationTile(Map<String, dynamic> conversation) {
    final conversationId = conversation['id'] ?? '';
    final parentName = conversation['parentName'] ?? 'Parent';
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageAt = conversation['lastMessageAt'];
    final unreadByAdmin = conversation['unreadByAdmin'] == true;
    final isSelected = selectedConversationId == conversationId;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        selectConversation(conversation);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.10)
              : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryBlue,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.white,
                  ),
                ),
                if (unreadByAdmin)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parentName,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.toString().isEmpty
                        ? 'No message yet'
                        : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatDateTime(lastMessageAt),
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageBubble(Map<String, dynamic> message) {
    final senderId = message['senderId'] ?? '';
    final senderName = message['senderName'] ?? '';
    final senderRole = message['senderRole'] ?? '';
    final text = message['text'] ?? '';
    final createdAt = message['createdAt'];

    final isMine = senderId == currentUserId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                '$senderName • $senderRole',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            if (!isMine) const SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: isMine ? AppColors.white : AppColors.textDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formatTime(createdAt),
              style: TextStyle(
                color: isMine
                    ? AppColors.white.withValues(alpha: 0.8)
                    : AppColors.textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminConversationList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Parent Conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: showStartChatSheet,
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Start'),
              ),
            ],
          ),
        ),
        if (conversations.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No parent conversation yet. Tap Start to begin a chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              itemCount: conversations.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                return conversationTile(conversations[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget chatHeader() {
    final title = isAdmin
        ? selectedParentName.isEmpty
            ? 'Select Parent'
            : selectedParentName
        : 'School Admin';

    final subtitle = isAdmin
        ? 'Admin ↔ Parent chat'
        : 'Send messages to the school admin';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: Icon(
              Icons.chat_outlined,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: refreshCurrentConversation,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
    );
  }

  Widget chatMessagesArea() {
    if (selectedConversationId.isEmpty && isAdmin) {
      return const Expanded(
        child: Center(
          child: Text(
            'Select a parent conversation to view messages.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    if (messages.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No messages yet. Start the conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return messageBubble(messages[index]);
        },
      ),
    );
  }

  Widget messageInputArea() {
    if (selectedConversationId.isEmpty && isAdmin) {
      return const SizedBox();
    }

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
                hintText: 'Write a message...',
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 50,
            width: 50,
            child: ElevatedButton(
              onPressed: isSending ? null : sendMessage,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSending
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

  Widget parentChatLayout() {
    return Column(
      children: [
        chatHeader(),
        chatMessagesArea(),
        messageInputArea(),
      ],
    );
  }

  Widget adminChatLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        if (isWide) {
          return Row(
            children: [
              SizedBox(
                width: 320,
                child: adminConversationList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    chatHeader(),
                    chatMessagesArea(),
                    messageInputArea(),
                  ],
                ),
              ),
            ],
          );
        }

        if (selectedConversationId.isEmpty) {
          return adminConversationList();
        }

        return Column(
          children: [
            Container(
              color: AppColors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedConversationId = '';
                        selectedParentId = '';
                        selectedParentName = '';
                        messages = [];
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'Back to Conversations',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            chatHeader(),
            chatMessagesArea(),
            messageInputArea(),
          ],
        );
      },
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
    String title = 'Messages';

    if (currentRole == 'Admin') title = 'Parent Messages';
    if (currentRole == 'Parent') title = 'Admin Chat';
    if (currentRole == 'Teacher') title = 'Messages';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadInitialData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : isAdmin
                    ? adminChatLayout()
                    : parentChatLayout(),
      ),
    );
  }
}