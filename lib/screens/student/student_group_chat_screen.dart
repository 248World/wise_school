import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class StudentGroupChatScreen extends StatefulWidget {
  const StudentGroupChatScreen({super.key});

  @override
  State<StudentGroupChatScreen> createState() => _StudentGroupChatScreenState();
}

class _StudentGroupChatScreenState extends State<StudentGroupChatScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final groupNameController = TextEditingController();
  final messageController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;
  bool isCreatingGroup = false;
  String? errorMessage;

  String currentUserId = '';
  String currentUserName = '';
  String currentClassId = '';
  String currentClassName = '';

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> messages = [];

  String selectedGroupId = '';
  String selectedGroupName = '';
  String selectedAdminId = '';
  String selectedAdminName = '';
  List<String> selectedMemberIds = [];
  List<String> selectedMemberNames = [];

  bool get hasClass => currentClassId.trim().isNotEmpty;
  bool get isGroupAdmin => selectedAdminId == currentUserId;

  @override
  void initState() {
    super.initState();
    Future.microtask(loadInitialData);
  }

  @override
  void dispose() {
    groupNameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
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

      final userDoc =
          await firestore.collection('users').doc(currentUserId).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        currentClassId = data?['classId'] ?? '';
        currentClassName = data?['className'] ?? '';
        currentUserName = data?['fullName'] ?? currentUserName;
      }

      if (!hasClass) {
        groups = [];
        messages = [];

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      await loadGroups();

      if (groups.isNotEmpty && selectedGroupId.isEmpty) {
        await selectGroup(groups.first);
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

  Future<void> loadGroups() async {
    if (!hasClass || currentUserId.isEmpty) {
      groups = [];
      return;
    }

    final snapshot = await firestore
        .collection('student_group_chats')
        .where('classId', isEqualTo: currentClassId)
        .where('members', arrayContains: currentUserId)
        .get();

    groups = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'groupName': data['groupName'] ?? 'Class Group',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'createdBy': data['createdBy'] ?? '',
        'createdByName': data['createdByName'] ?? '',
        'adminId': data['adminId'] ?? '',
        'adminName': data['adminName'] ?? '',
        'members': List<String>.from(data['members'] ?? []),
        'memberNames': List<String>.from(data['memberNames'] ?? []),
        'lastMessage': data['lastMessage'] ?? '',
        'lastMessageAt': data['lastMessageAt'],
        'createdAt': data['createdAt'],
      };
    }).toList();

    groups.sort((a, b) {
      final aTime = a['lastMessageAt'];
      final bTime = b['lastMessageAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return (a['groupName'] ?? '').toString().compareTo(
            (b['groupName'] ?? '').toString(),
          );
    });
  }

  Future<void> selectGroup(Map<String, dynamic> group) async {
    selectedGroupId = group['id'] ?? '';
    selectedGroupName = group['groupName'] ?? 'Class Group';
    selectedAdminId = group['adminId'] ?? '';
    selectedAdminName = group['adminName'] ?? '';
    selectedMemberIds = List<String>.from(group['members'] ?? []);
    selectedMemberNames = List<String>.from(group['memberNames'] ?? []);

    await loadMessages();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> loadMessages() async {
    if (selectedGroupId.isEmpty) {
      messages = [];
      return;
    }

    final snapshot = await firestore
        .collection('student_group_chats')
        .doc(selectedGroupId)
        .collection('messages')
        .get();

    messages = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'senderId': data['senderId'] ?? '',
        'senderName': data['senderName'] ?? '',
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

  Future<void> refreshData() async {
    await loadGroups();

    if (selectedGroupId.isNotEmpty) {
      final existingGroup = groups.where((group) {
        return group['id'] == selectedGroupId;
      }).toList();

      if (existingGroup.isNotEmpty) {
        await selectGroup(existingGroup.first);
      } else {
        selectedGroupId = '';
        selectedGroupName = '';
        selectedAdminId = '';
        selectedAdminName = '';
        selectedMemberIds = [];
        selectedMemberNames = [];
        messages = [];

        if (groups.isNotEmpty) {
          await selectGroup(groups.first);
        }
      }
    } else if (groups.isNotEmpty) {
      await selectGroup(groups.first);
    }

    if (!mounted) return;

    setState(() {});
  }

  Future<void> createGroup() async {
    final groupName = groupNameController.text.trim();

    if (groupName.isEmpty) {
      showSnackBar('Please enter group name');
      return;
    }

    if (!hasClass) {
      showSnackBar('You must be assigned to a class before creating a group.');
      return;
    }

    try {
      setState(() {
        isCreatingGroup = true;
      });

      final docRef = await firestore.collection('student_group_chats').add({
        'groupName': groupName,
        'classId': currentClassId,
        'className': currentClassName,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'adminId': currentUserId,
        'adminName': currentUserName,
        'members': [currentUserId],
        'memberNames': [currentUserName],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      groupNameController.clear();

      if (!mounted) return;

      Navigator.pop(context);

      await refreshData();

      final createdGroup = groups.where((group) {
        return group['id'] == docRef.id;
      }).toList();

      if (createdGroup.isNotEmpty) {
        await selectGroup(createdGroup.first);
      }

      if (!mounted) return;

      setState(() {
        isCreatingGroup = false;
      });

      showSnackBar('Group created successfully. You are the group admin.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isCreatingGroup = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<Map<String, dynamic>>> loadAvailableClassmates({
    required bool onlyNotInGroup,
  }) async {
    if (!hasClass) {
      return [];
    }

    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: currentClassId)
        .where('isActive', isEqualTo: true)
        .get();

    final classmates = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? 'Student',
        'email': data['email'] ?? '',
      };
    }).where((student) {
      final studentId = student['id'] ?? '';

      if (studentId == currentUserId) {
        return false;
      }

      if (onlyNotInGroup) {
        return !selectedMemberIds.contains(studentId);
      }

      return true;
    }).toList();

    classmates.sort((a, b) {
      return (a['fullName'] ?? '').toString().compareTo(
            (b['fullName'] ?? '').toString(),
          );
    });

    return classmates;
  }

  Future<void> addMember(Map<String, dynamic> student) async {
    if (!isGroupAdmin) {
      showSnackBar('Only the group admin can add members.');
      return;
    }

    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Student';

    if (studentId.isEmpty || selectedGroupId.isEmpty) {
      showSnackBar('Invalid student or group');
      return;
    }

    try {
      await firestore.collection('student_group_chats').doc(selectedGroupId).set(
        {
          'members': FieldValue.arrayUnion([studentId]),
          'memberNames': FieldValue.arrayUnion([studentName]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await refreshData();

      if (!mounted) return;

      showSnackBar('$studentName added to the group');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> removeMember({
    required String memberId,
    required String memberName,
  }) async {
    if (!isGroupAdmin) {
      showSnackBar('Only the group admin can remove members.');
      return;
    }

    if (memberId == currentUserId) {
      showSnackBar('You cannot remove yourself as the group admin.');
      return;
    }

    try {
      await firestore.collection('student_group_chats').doc(selectedGroupId).set(
        {
          'members': FieldValue.arrayRemove([memberId]),
          'memberNames': FieldValue.arrayRemove([memberName]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await refreshData();

      if (!mounted) return;

      showSnackBar('$memberName removed from the group');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (selectedGroupId.isEmpty) {
      showSnackBar('Please select or create a group first');
      return;
    }

    if (!selectedMemberIds.contains(currentUserId)) {
      showSnackBar('You are not a member of this group.');
      return;
    }

    try {
      setState(() {
        isSending = true;
      });

      final groupRef =
          firestore.collection('student_group_chats').doc(selectedGroupId);

      final messageRef = groupRef.collection('messages').doc();

      final batch = firestore.batch();

      batch.set(messageRef, {
        'senderId': currentUserId,
        'senderName': currentUserName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        groupRef,
        {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': currentUserId,
          'lastSenderName': currentUserName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      messageController.clear();

      await refreshData();

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

  String formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    return '';
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');

      return '$day/$month';
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

  Widget sheetHandle() {
    return Center(
      child: Container(
        height: 5,
        width: 44,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 12),
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
      child: Row(
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
                'assets/icons/group_chat.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.groups_2_outlined,
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
                  'Student Group Chat',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasClass
                      ? 'Create groups with classmates from $currentClassName.'
                      : 'You must be assigned to a class before using group chat.',
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
    );
  }

  Widget groupTile(Map<String, dynamic> group) {
    final groupId = group['id'] ?? '';
    final groupName = group['groupName'] ?? 'Class Group';
    final adminName = group['adminName'] ?? '';
    final memberIds = List<String>.from(group['members'] ?? []);
    final lastMessage = group['lastMessage'] ?? '';
    final lastMessageAt = group['lastMessageAt'];
    final isSelected = groupId == selectedGroupId;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          selectGroup(group);
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.08)
                : AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
            ),
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
                imagePath: 'assets/icons/group_chat.png',
                fallbackIcon: Icons.groups_2_outlined,
                size: 50,
                padding: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage.toString().isEmpty
                          ? 'Admin: $adminName • ${memberIds.length} member(s)'
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
                formatDate(lastMessageAt),
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chatHeader() {
    if (selectedGroupId.isEmpty) {
      return const SizedBox();
    }

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
          pngIconBox(
            imagePath: 'assets/icons/group_chat.png',
            fallbackIcon: Icons.groups_2_outlined,
            size: 46,
            padding: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedGroupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isGroupAdmin
                      ? 'You are admin • ${selectedMemberIds.length} member(s)'
                      : 'Admin: $selectedAdminName • ${selectedMemberIds.length} member(s)',
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
          IconButton(
            onPressed: showMembersSheet,
            icon: const Icon(Icons.group_outlined),
          ),
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
    );
  }

  Widget messageBubble(Map<String, dynamic> message) {
    final senderId = message['senderId'] ?? '';
    final senderName = message['senderName'] ?? '';
    final text = message['text'] ?? '';
    final createdAt = message['createdAt'];

    final isMine = senderId == currentUserId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 285),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 6),
            bottomRight: Radius.circular(isMine ? 6 : 20),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Text(
                senderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w800,
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
                    ? AppColors.white.withValues(alpha: 0.78)
                    : AppColors.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget messagesArea() {
    if (selectedGroupId.isEmpty) {
      return Expanded(
        child: emptyStateBox(
          title: 'No group selected',
          message: 'Create or select a group to start chatting.',
          icon: Icons.groups_2_outlined,
        ),
      );
    }

    if (messages.isEmpty) {
      return Expanded(
        child: emptyStateBox(
          title: 'No messages yet',
          message: 'Start the conversation with your classmates.',
          icon: Icons.chat_bubble_outline,
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
    if (selectedGroupId.isEmpty) {
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
                  hintText: 'Write a message...',
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!isSending) {
                    sendMessage();
                  }
                },
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
      ),
    );
  }

  Widget groupsArea() {
    return Column(
      children: [
        headerCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'My Groups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: hasClass ? showCreateGroupSheet : null,
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Create'),
              ),
            ],
          ),
        ),
        if (!hasClass)
          Expanded(
            child: emptyStateBox(
              title: 'No class assigned',
              message:
                  'Ask Admin to assign you to a class before using student group chat.',
              icon: Icons.class_outlined,
            ),
          )
        else if (groups.isEmpty)
          Expanded(
            child: emptyStateBox(
              title: 'No groups yet',
              message: 'Create a class group and add your classmates.',
              icon: Icons.groups_2_outlined,
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshData,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                itemCount: groups.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemBuilder: (context, index) {
                  return groupTile(groups[index]);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget chatArea() {
    return Column(
      children: [
        chatHeader(),
        messagesArea(),
        messageInputArea(),
      ],
    );
  }

  Widget emptyStateBox({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/group_chat.png',
              fallbackIcon: icon,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showCreateGroupSheet() {
    groupNameController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    pngIconBox(
                      imagePath: 'assets/icons/group_chat.png',
                      fallbackIcon: Icons.groups_2_outlined,
                      size: 48,
                      padding: 10,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Create Group Chat',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Example: Class A Study Group',
                    prefixIcon: Icon(Icons.groups_2_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Class: ${currentClassName.isEmpty ? 'No class' : currentClassName}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isCreatingGroup ? null : createGroup,
                    icon: isCreatingGroup
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      isCreatingGroup ? 'Creating...' : 'Create Group',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showAddClassmateSheet() async {
    final classmates = await loadAvailableClassmates(onlyNotInGroup: true);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  pngIconBox(
                    imagePath: 'assets/icons/student.png',
                    fallbackIcon: Icons.school_outlined,
                    size: 48,
                    padding: 10,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Classmates',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (classmates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No classmates available to add.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: classmates.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final classmate = classmates[index];

                      return ListTile(
                        leading: pngIconBox(
                          imagePath: 'assets/icons/student.png',
                          fallbackIcon: Icons.school_outlined,
                          size: 44,
                          padding: 9,
                        ),
                        title: Text(classmate['fullName'] ?? 'Student'),
                        subtitle: Text(classmate['email'] ?? ''),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () async {
                          Navigator.pop(context);
                          await addMember(classmate);
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

  void showMembersSheet() {
    if (selectedGroupId.isEmpty) {
      showSnackBar('Please select a group first');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  pngIconBox(
                    imagePath: 'assets/icons/group_chat.png',
                    fallbackIcon: Icons.groups_2_outlined,
                    size: 48,
                    padding: 10,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$selectedGroupName Members',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isGroupAdmin
                    ? 'You can add or remove classmates from this group.'
                    : 'Only the group admin can manage members.',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (isGroupAdmin)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: showAddClassmateSheet,
                    icon: const Icon(Icons.person_add_alt_outlined),
                    label: const Text('Add Classmate'),
                  ),
                ),
              if (isGroupAdmin) const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedMemberIds.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final memberId = selectedMemberIds[index];
                    final memberName = index < selectedMemberNames.length
                        ? selectedMemberNames[index]
                        : 'Student';
                    final isAdminMember = memberId == selectedAdminId;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          pngIconBox(
                            imagePath: 'assets/icons/student.png',
                            fallbackIcon: Icons.school_outlined,
                            size: 42,
                            padding: 9,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isAdminMember
                                  ? '$memberName • Admin'
                                  : memberName,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isGroupAdmin && !isAdminMember)
                            IconButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                await removeMember(
                                  memberId: memberId,
                                  memberName: memberName,
                                );
                              },
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.danger,
                              ),
                            ),
                        ],
                      ),
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
        title: const Text('Group Chat'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : refreshData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: hasClass && selectedGroupId.isEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showCreateGroupSheet,
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            )
          : null,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
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
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 760;

                      if (isWide) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 350,
                              child: groupsArea(),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: chatArea(),
                            ),
                          ],
                        );
                      }

                      if (selectedGroupId.isEmpty) {
                        return groupsArea();
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
                                      selectedGroupId = '';
                                      selectedGroupName = '';
                                      selectedAdminId = '';
                                      selectedAdminName = '';
                                      selectedMemberIds = [];
                                      selectedMemberNames = [];
                                      messages = [];
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Back to Groups',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: chatArea(),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
