import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class MessagesScreen extends StatefulWidget {
  final String role;
  final String targetRole;

  const MessagesScreen({
    super.key,
    this.role = 'Parent',
    this.targetRole = 'Admin',
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
  String selectedReceiverName = '';
  String selectedReceiverId = '';
  String selectedReceiverRole = '';

  bool get isAdmin {
    return currentRole == 'Admin';
  }

  bool get isParent {
    return currentRole == 'Parent';
  }

  bool get isTeacher {
    return currentRole == 'Teacher';
  }

  bool get isTeacherChat {
    return currentRole == 'Teacher' || widget.targetRole == 'Teacher';
  }

  String get collectionName {
    if (isTeacherChat) {
      return 'teacher_admin_chats';
    }

    return 'parent_admin_chats';
  }

  String get userRoleLabel {
    if (isTeacherChat) {
      return 'Teacher';
    }

    return 'Parent';
  }

  String get unreadForAdminKey {
    return 'unreadByAdmin';
  }

  String get unreadForUserKey {
    if (isTeacherChat) {
      return 'unreadByTeacher';
    }

    return 'unreadByParent';
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

      if (isAdmin) {
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

  Future<String> findFirstAdminId() async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Admin')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return '';
    }

    return snapshot.docs.first.id;
  }

  Future<String> getReceiverIdForNotification() async {
    if (isAdmin) {
      if (selectedReceiverId.isNotEmpty) {
        return selectedReceiverId;
      }

      if (selectedConversationId.isNotEmpty) {
        return selectedConversationId;
      }

      return '';
    }

    return findFirstAdminId();
  }

  String getReceiverRoleForNotification() {
    if (isAdmin) {
      if (selectedReceiverRole.isNotEmpty) {
        return selectedReceiverRole;
      }

      return userRoleLabel;
    }

    return 'Admin';
  }

  Future<void> loadUserConversation() async {
    if (currentUserId.isEmpty) {
      conversations = [];
      messages = [];
      return;
    }

    final conversationRef = firestore.collection(collectionName).doc(currentUserId);

    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      await conversationRef.set({
        'userId': currentUserId,
        'userName': currentUserName,
        'userRole': currentRole,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'lastSenderName': '',
        'lastSenderRole': '',
        unreadForAdminKey: false,
        unreadForUserKey: false,
      });
    }

    selectedConversationId = currentUserId;
    selectedReceiverId = await findFirstAdminId();
    selectedReceiverName = 'School Admin';
    selectedReceiverRole = 'Admin';

    await loadMessages(selectedConversationId);

    await conversationRef.update({
      unreadForUserKey: false,
    });
  }

  Future<void> loadAdminConversations() async {
    final snapshot = await firestore.collection(collectionName).get();

    conversations = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'userId': data['userId'] ?? doc.id,
        'userName': data['userName'] ?? userRoleLabel,
        'userRole': data['userRole'] ?? userRoleLabel,
        'lastMessage': data['lastMessage'] ?? '',
        'lastMessageAt': data['lastMessageAt'],
        'lastSenderId': data['lastSenderId'] ?? '',
        'lastSenderName': data['lastSenderName'] ?? '',
        'lastSenderRole': data['lastSenderRole'] ?? '',
        unreadForAdminKey: data[unreadForAdminKey] ?? false,
        unreadForUserKey: data[unreadForUserKey] ?? false,
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
      selectedReceiverId = firstConversation['userId'] ?? '';
      selectedReceiverName = firstConversation['userName'] ?? userRoleLabel;
      selectedReceiverRole = firstConversation['userRole'] ?? userRoleLabel;

      await loadMessages(selectedConversationId);

      await firestore.collection(collectionName).doc(selectedConversationId).update({
        unreadForAdminKey: false,
      });
    }
  }

  Future<void> loadMessages(String conversationId) async {
    if (conversationId.isEmpty) {
      messages = [];
      return;
    }

    final snapshot = await firestore
        .collection(collectionName)
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
      await loadUserConversation();
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
      selectedReceiverId = conversation['userId'] ?? '';
      selectedReceiverName = conversation['userName'] ?? userRoleLabel;
      selectedReceiverRole = conversation['userRole'] ?? userRoleLabel;
      isLoading = true;
    });

    await loadMessages(conversationId);

    await firestore.collection(collectionName).doc(conversationId).update({
      unreadForAdminKey: false,
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
      if (!isAdmin) {
        selectedConversationId = currentUserId;
        selectedReceiverId = await findFirstAdminId();
        selectedReceiverName = 'School Admin';
        selectedReceiverRole = 'Admin';
      } else {
        showSnackBar('Please select a conversation');
        return;
      }
    }

    try {
      setState(() {
        isSending = true;
      });

      final conversationRef =
          firestore.collection(collectionName).doc(selectedConversationId);

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
          'userId': isAdmin
              ? selectedReceiverId
              : currentUserId,
          'userName': isAdmin
              ? selectedReceiverName
              : currentUserName,
          'userRole': isAdmin
              ? getReceiverRoleForNotification()
              : currentRole,
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': currentUserId,
          'lastSenderName': currentUserName,
          'lastSenderRole': currentRole,
          unreadForAdminKey: !isAdmin,
          unreadForUserKey: isAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      final receiverId = await getReceiverIdForNotification();

      await NotificationService.notifyMessageReceiver(
        receiverId: receiverId,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: currentRole,
        messageText: text,
        conversationId: selectedConversationId,
      );

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
    final searchRole = isTeacherChat ? 'Teacher' : 'Parent';

    final usersSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: searchRole)
        .where('isActive', isEqualTo: true)
        .get();

    final users = usersSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? searchRole,
        'email': data['email'] ?? '',
        'role': data['role'] ?? searchRole,
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
              Text(
                'Start Chat with $searchRole',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No $searchRole account found yet.',
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final user = users[index];

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
                        title: Text(user['fullName'] ?? searchRole),
                        subtitle: Text(user['email'] ?? ''),
                        onTap: () async {
                          Navigator.pop(context);

                          await openUserConversation(
                            userId: user['id'] ?? '',
                            userName: user['fullName'] ?? searchRole,
                            userRole: searchRole,
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

  Future<void> openUserConversation({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    if (userId.isEmpty) {
      showSnackBar('Invalid account');
      return;
    }

    final conversationRef = firestore.collection(collectionName).doc(userId);

    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      await conversationRef.set({
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'lastSenderName': '',
        'lastSenderRole': '',
        unreadForAdminKey: false,
        unreadForUserKey: false,
      });
    }

    selectedConversationId = userId;
    selectedReceiverId = userId;
    selectedReceiverName = userName;
    selectedReceiverRole = userRole;

    await loadMessages(userId);
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
    final userName = conversation['userName'] ?? userRoleLabel;
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageAt = conversation['lastMessageAt'];
    final unreadByAdmin = conversation[unreadForAdminKey] == true;
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
                    userName,
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
              Expanded(
                child: Text(
                  '$userRoleLabel Conversations',
                  style: const TextStyle(
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
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No $userRoleLabel conversation yet. Tap Start to begin a chat.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
        ? selectedReceiverName.isEmpty
            ? 'Select $userRoleLabel'
            : selectedReceiverName
        : 'School Admin';

    final subtitle = isAdmin
        ? 'Admin ↔ $userRoleLabel chat'
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
      return Expanded(
        child: Center(
          child: Text(
            'Select a $userRoleLabel conversation to view messages.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey),
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

  Widget userChatLayout() {
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
                        selectedReceiverId = '';
                        selectedReceiverName = '';
                        selectedReceiverRole = '';
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

    if (currentRole == 'Admin' && isTeacherChat) title = 'Teacher Messages';
    if (currentRole == 'Admin' && !isTeacherChat) title = 'Parent Messages';
    if (currentRole == 'Parent') title = 'Admin Chat';
    if (currentRole == 'Teacher') title = 'Admin Chat';

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
                    : userChatLayout(),
      ),
    );
  }
}