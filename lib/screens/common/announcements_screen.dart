import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String role;

  const AnnouncementsScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  String currentRole = 'Student';
  String currentUserId = '';
  String currentUserName = '';

  List<Map<String, dynamic>> announcements = [];

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  String selectedCategory = 'General';
  String selectedPriority = 'Normal';
  String selectedTargetAudience = 'All';

  final List<String> categories = [
    'General',
    'Academic',
    'Fees',
    'Exams',
    'Events',
    'Urgent',
  ];

  final List<String> priorities = [
    'Low',
    'Normal',
    'High',
    'Urgent',
  ];

  final List<String> targetAudiences = [
    'All',
    'Students',
    'Parents',
    'Teachers',
    'Admins',
  ];

  final List<String> reactionTypes = [
    'like',
    'love',
    'care',
    'laugh',
  ];

  bool get isAdmin => currentRole == 'Admin';

  @override
  void initState() {
    super.initState();
    Future.microtask(loadInitialData);
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      final user = firebaseAuth.currentUser;

      currentUserId = user?.uid ?? '';
      currentUserName = user?.displayName ?? widget.role;
      currentRole = widget.role;

      if (currentUserId.isNotEmpty) {
        final userDoc =
            await firestore.collection('users').doc(currentUserId).get();

        if (userDoc.exists) {
          final data = userDoc.data();
          currentUserName = data?['fullName'] ?? currentUserName;
          currentRole = data?['role'] ?? widget.role;
        }
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await loadAnnouncements();

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

  Future<void> loadAnnouncements() async {
    final snapshot = await firestore.collection('announcements').get();

    final loadedAnnouncements = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'body': data['body'] ?? '',
        'category': data['category'] ?? 'General',
        'priority': data['priority'] ?? 'Normal',
        'targetAudience': data['targetAudience'] ?? 'All',
        'createdBy': data['createdBy'] ?? '',
        'createdByName': data['createdByName'] ?? 'Admin',
        'reactions': data['reactions'] ??
            {
              'like': [],
              'love': [],
              'care': [],
              'laugh': [],
            },
        'reactionUsers': data['reactionUsers'] ?? {},
        'reactionsCount': data['reactionsCount'] ?? 0,
        'commentsCount': data['commentsCount'] ?? 0,
        'sharesCount': data['sharesCount'] ?? 0,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    if (isAdmin) {
      announcements = loadedAnnouncements;
    } else {
      announcements = loadedAnnouncements.where((announcement) {
        final targetAudience = announcement['targetAudience'] ?? 'All';

        if (targetAudience == 'All') return true;
        if (currentRole == 'Student' && targetAudience == 'Students') {
          return true;
        }
        if (currentRole == 'Parent' && targetAudience == 'Parents') {
          return true;
        }
        if (currentRole == 'Teacher' && targetAudience == 'Teachers') {
          return true;
        }

        return false;
      }).toList();
    }

    announcements.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });
  }

  Future<void> saveAnnouncement() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty) {
      showSnackBar('Please enter announcement title');
      return;
    }

    if (body.isEmpty) {
      showSnackBar('Please enter announcement message');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final announcementRef = await firestore.collection('announcements').add({
        'title': title,
        'body': body,
        'category': selectedCategory,
        'priority': selectedPriority,
        'targetAudience': selectedTargetAudience,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'reactions': {
          'like': [],
          'love': [],
          'care': [],
          'laugh': [],
        },
        'reactionUsers': {},
        'reactionsCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.notifyAnnouncementAudience(
        targetAudience: selectedTargetAudience,
        announcementId: announcementRef.id,
        announcementTitle: title,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: currentRole,
      );

      if (!mounted) return;

      Navigator.pop(context);

      titleController.clear();
      bodyController.clear();

      selectedCategory = 'General';
      selectedPriority = 'Normal';
      selectedTargetAudience = 'All';

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Announcement posted successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  String reactionLabel(String reaction) {
    if (reaction == 'love') return 'Love';
    if (reaction == 'care') return 'Care';
    if (reaction == 'laugh') return 'Laugh';
    return 'Like';
  }

  IconData reactionIcon(String reaction) {
    if (reaction == 'love') return Icons.favorite;
    if (reaction == 'care') return Icons.volunteer_activism_outlined;
    if (reaction == 'laugh') return Icons.emoji_emotions_outlined;
    return Icons.thumb_up_alt_outlined;
  }

  Color reactionColor(String reaction) {
    if (reaction == 'love') return AppColors.danger;
    if (reaction == 'care') return AppColors.softGreen;
    if (reaction == 'laugh') return Colors.orange;
    return AppColors.primaryBlue;
  }

  Map<String, List<String>> normalizeReactions(dynamic rawReactions) {
    final result = <String, List<String>>{
      'like': [],
      'love': [],
      'care': [],
      'laugh': [],
    };

    if (rawReactions is Map) {
      for (final reaction in reactionTypes) {
        final users = rawReactions[reaction];

        if (users is List) {
          result[reaction] = users.map((item) => item.toString()).toList();
        }
      }
    }

    return result;
  }

  Map<String, dynamic> normalizeReactionUsers(dynamic rawUsers) {
    if (rawUsers is Map) {
      return Map<String, dynamic>.from(rawUsers);
    }

    return {};
  }

  String userReaction(Map<String, dynamic> announcement) {
    final reactions = normalizeReactions(announcement['reactions']);

    for (final reaction in reactionTypes) {
      if ((reactions[reaction] ?? []).contains(currentUserId)) {
        return reaction;
      }
    }

    return '';
  }

  String reactionsText(Map<String, dynamic> announcement) {
    final reactions = normalizeReactions(announcement['reactions']);
    final parts = <String>[];

    for (final reaction in reactionTypes) {
      final count = reactions[reaction]?.length ?? 0;

      if (count > 0) {
        parts.add('$count ${reactionLabel(reaction)}');
      }
    }

    if (parts.isEmpty) return '0 Reactions';

    return parts.join(' • ');
  }

  Future<void> setReaction({
    required Map<String, dynamic> announcement,
    required String reaction,
  }) async {
    final announcementId = announcement['id'] ?? '';

    if (announcementId.toString().isEmpty || currentUserId.isEmpty) {
      return;
    }

    try {
      final ref = firestore.collection('announcements').doc(announcementId);
      final doc = await ref.get();

      if (!doc.exists) {
        showSnackBar('Announcement not found');
        return;
      }

      final data = doc.data();
      final reactions = normalizeReactions(data?['reactions']);
      final reactionUsers = normalizeReactionUsers(data?['reactionUsers']);

      String existingReaction = '';

      for (final item in reactionTypes) {
        if ((reactions[item] ?? []).contains(currentUserId)) {
          existingReaction = item;
        }

        reactions[item]?.remove(currentUserId);
      }

      if (existingReaction == reaction) {
        reactionUsers.remove(currentUserId);
      } else {
        reactions[reaction]?.add(currentUserId);

        reactionUsers[currentUserId] = {
          'userId': currentUserId,
          'userName': currentUserName,
          'userRole': currentRole,
          'reaction': reaction,
          'reactedAt': Timestamp.now(),
        };
      }

      int count = 0;

      for (final item in reactionTypes) {
        count += reactions[item]?.length ?? 0;
      }

      await ref.update({
        'reactions': reactions,
        'reactionUsers': reactionUsers,
        'reactionsCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadInitialData();
    } catch (error) {
      if (!mounted) return;
      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void showReactionPicker(Map<String, dynamic> announcement) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: reactionTypes.map((reaction) {
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  setReaction(
                    announcement: announcement,
                    reaction: reaction,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reactionIcon(reaction),
                        color: reactionColor(reaction),
                        size: 34,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reactionLabel(reaction),
                        style: TextStyle(
                          color: reactionColor(reaction),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void showReactionUsers(Map<String, dynamic> announcement) {
    final reactionUsers = normalizeReactionUsers(announcement['reactionUsers']);

    final users = reactionUsers.values.map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return <String, dynamic>{};
    }).where((item) {
      return item.isNotEmpty;
    }).toList();

    users.sort((a, b) {
      final aName = (a['userName'] ?? '').toString();
      final bName = (b['userName'] ?? '').toString();

      return aName.compareTo(bName);
    });

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
                'Reactions',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No reaction yet.',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final reaction = user['reaction'] ?? 'like';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              reactionColor(reaction).withValues(alpha: 0.15),
                          child: Icon(
                            reactionIcon(reaction),
                            color: reactionColor(reaction),
                          ),
                        ),
                        title: Text(
                          user['userName'] ?? 'User',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(user['userRole'] ?? ''),
                        trailing: Text(
                          reactionLabel(reaction),
                          style: TextStyle(
                            color: reactionColor(reaction),
                            fontWeight: FontWeight.bold,
                          ),
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

  Future<void> shareAnnouncement(Map<String, dynamic> announcement) async {
    final announcementId = announcement['id'] ?? '';
    final title = announcement['title'] ?? '';
    final body = announcement['body'] ?? '';

    await Clipboard.setData(
      ClipboardData(text: '$title\n\n$body'),
    );

    if (announcementId.toString().isNotEmpty) {
      await firestore.collection('announcements').doc(announcementId).update({
        'sharesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    showSnackBar('Announcement copied. You can now share it.');

    await loadInitialData();
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    if (announcementId.isEmpty) {
      showSnackBar('Invalid announcement');
      return;
    }

    try {
      await firestore.collection('announcements').doc(announcementId).delete();

      await loadInitialData();

      if (!mounted) return;

      showSnackBar('Announcement deleted successfully');
    } catch (error) {
      if (!mounted) return;
      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDeleteAnnouncement({
    required String announcementId,
    required String title,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteAnnouncement(announcementId);
    }
  }

  void showAddAnnouncementSheet() {
    titleController.clear();
    bodyController.clear();

    selectedCategory = 'General';
    selectedPriority = 'Normal';
    selectedTargetAudience = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Announcement',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Example: Exam schedule update',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: bodyController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Write announcement message',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.priority_high_outlined),
                      ),
                      items: priorities.map((priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTargetAudience,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: targetAudiences.map((audience) {
                        return DropdownMenuItem<String>(
                          value: audience,
                          child: Text(audience),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedTargetAudience = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveAnnouncement,
                        icon: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving ? 'Posting...' : 'Post Announcement',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color priorityColor(String priority) {
    if (priority == 'Urgent') return AppColors.danger;
    if (priority == 'High') return Colors.orange;
    if (priority == 'Low') return AppColors.textGrey;

    return AppColors.primaryBlue;
  }

  IconData categoryIcon(String category) {
    if (category == 'Academic') return Icons.school_outlined;
    if (category == 'Fees') return Icons.account_balance_wallet_outlined;
    if (category == 'Exams') return Icons.edit_note_outlined;
    if (category == 'Events') return Icons.event_outlined;
    if (category == 'Urgent') return Icons.warning_amber_outlined;

    return Icons.campaign_outlined;
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year • $hour:$minute';
    }

    return 'Recently';
  }

  Widget announcementCard(Map<String, dynamic> announcement) {
    final announcementId = announcement['id'] ?? '';
    final title = announcement['title'] ?? 'Announcement';
    final body = announcement['body'] ?? '';
    final category = announcement['category'] ?? 'General';
    final priority = announcement['priority'] ?? 'Normal';
    final targetAudience = announcement['targetAudience'] ?? 'All';
    final createdByName = announcement['createdByName'] ?? 'Admin';
    final createdAt = announcement['createdAt'];
    final commentsCount = announcement['commentsCount'] ?? 0;
    final sharesCount = announcement['sharesCount'] ?? 0;
    final currentReaction = userReaction(announcement);
    final hasReacted = currentReaction.isNotEmpty;
    final reactionsSummary = reactionsText(announcement);

    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await openAnnouncementDetail(announcementId);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: priorityColor(priority).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      categoryIcon(category),
                      color: priorityColor(priority),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          createdByName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(createdAt),
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      onPressed: () {
                        confirmDeleteAnnouncement(
                          announcementId: announcementId,
                          title: title,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.start,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  tagChip(text: category, color: AppColors.primaryBlue),
                  tagChip(text: priority, color: priorityColor(priority)),
                  tagChip(text: targetAudience, color: AppColors.softGreen),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showReactionUsers(announcement);
                      },
                      child: Text(
                        reactionsSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '$commentsCount Comments',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$sharesCount Shares',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Divider(height: 26),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        showReactionPicker(announcement);
                      },
                      icon: Icon(
                        hasReacted
                            ? reactionIcon(currentReaction)
                            : Icons.thumb_up_alt_outlined,
                        color: hasReacted
                            ? reactionColor(currentReaction)
                            : AppColors.textGrey,
                      ),
                      label: Text(
                        hasReacted ? reactionLabel(currentReaction) : 'React',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasReacted
                              ? reactionColor(currentReaction)
                              : AppColors.textGrey,
                          fontWeight:
                              hasReacted ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        await openAnnouncementDetail(announcementId);
                      },
                      icon: const Icon(
                        Icons.mode_comment_outlined,
                        color: AppColors.textGrey,
                      ),
                      label: const Text(
                        'Comment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        shareAnnouncement(announcement);
                      },
                      icon: const Icon(
                        Icons.share_outlined,
                        color: AppColors.textGrey,
                      ),
                      label: const Text(
                        'Share',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openAnnouncementDetail(String announcementId) async {
    if (announcementId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(
          announcementId: announcementId,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          currentRole: currentRole,
        ),
      ),
    );

    await loadInitialData();
  }

  Widget tagChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget emptyState() {
    String message = 'No announcement found yet.';

    if (isAdmin) {
      message = 'No announcement found yet. Tap Post to create one.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
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
    String title = 'Announcements';

    if (isAdmin) {
      title = 'Announcement Management';
    }

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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showAddAnnouncementSheet,
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            )
          : null,
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
                : announcements.isEmpty
                    ? emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: announcements.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          return announcementCard(announcements[index]);
                        },
                      ),
      ),
    );
  }
}

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  final String currentUserId;
  final String currentUserName;
  final String currentRole;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentRole,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSendingComment = false;
  String? errorMessage;

  Map<String, dynamic>? announcement;
  List<Map<String, dynamic>> comments = [];

  final commentController = TextEditingController();

  final List<String> reactionTypes = [
    'like',
    'love',
    'care',
    'laugh',
  ];

  bool get isAdmin => widget.currentRole == 'Admin';

  @override
  void initState() {
    super.initState();
    Future.microtask(loadDetailData);
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadDetailData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await loadAnnouncement();
      await loadComments();

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

  Future<void> loadAnnouncement() async {
    final doc = await firestore
        .collection('announcements')
        .doc(widget.announcementId)
        .get();

    if (!doc.exists) {
      throw Exception('Announcement not found.');
    }

    final data = doc.data();

    announcement = {
      'id': doc.id,
      'title': data?['title'] ?? '',
      'body': data?['body'] ?? '',
      'category': data?['category'] ?? 'General',
      'priority': data?['priority'] ?? 'Normal',
      'targetAudience': data?['targetAudience'] ?? 'All',
      'createdBy': data?['createdBy'] ?? '',
      'createdByName': data?['createdByName'] ?? 'Admin',
      'reactions': data?['reactions'] ??
          {
            'like': [],
            'love': [],
            'care': [],
            'laugh': [],
          },
      'reactionUsers': data?['reactionUsers'] ?? {},
      'reactionsCount': data?['reactionsCount'] ?? 0,
      'commentsCount': data?['commentsCount'] ?? 0,
      'sharesCount': data?['sharesCount'] ?? 0,
      'createdAt': data?['createdAt'],
      'updatedAt': data?['updatedAt'],
    };
  }

  Future<void> loadComments() async {
    final snapshot = await firestore
        .collection('announcements')
        .doc(widget.announcementId)
        .collection('comments')
        .get();

    comments = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'text': data['text'] ?? '',
        'userId': data['userId'] ?? '',
        'userName': data['userName'] ?? '',
        'userRole': data['userRole'] ?? '',
        'parentCommentId': data['parentCommentId'] ?? '',
        'isEdited': data['isEdited'] ?? false,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    }).toList();

    comments.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return aCreated.compareTo(bCreated);
      }

      return 0;
    });
  }

  String reactionLabel(String reaction) {
    if (reaction == 'love') return 'Love';
    if (reaction == 'care') return 'Care';
    if (reaction == 'laugh') return 'Laugh';
    return 'Like';
  }

  IconData reactionIcon(String reaction) {
    if (reaction == 'love') return Icons.favorite;
    if (reaction == 'care') return Icons.volunteer_activism_outlined;
    if (reaction == 'laugh') return Icons.emoji_emotions_outlined;
    return Icons.thumb_up_alt_outlined;
  }

  Color reactionColor(String reaction) {
    if (reaction == 'love') return AppColors.danger;
    if (reaction == 'care') return AppColors.softGreen;
    if (reaction == 'laugh') return Colors.orange;
    return AppColors.primaryBlue;
  }

  Map<String, List<String>> normalizeReactions(dynamic rawReactions) {
    final result = <String, List<String>>{
      'like': [],
      'love': [],
      'care': [],
      'laugh': [],
    };

    if (rawReactions is Map) {
      for (final reaction in reactionTypes) {
        final users = rawReactions[reaction];

        if (users is List) {
          result[reaction] = users.map((item) => item.toString()).toList();
        }
      }
    }

    return result;
  }

  Map<String, dynamic> normalizeReactionUsers(dynamic rawUsers) {
    if (rawUsers is Map) {
      return Map<String, dynamic>.from(rawUsers);
    }

    return {};
  }

  String userReaction() {
    final item = announcement;

    if (item == null) return '';

    final reactions = normalizeReactions(item['reactions']);

    for (final reaction in reactionTypes) {
      if ((reactions[reaction] ?? []).contains(widget.currentUserId)) {
        return reaction;
      }
    }

    return '';
  }

  String reactionsText() {
    final item = announcement;

    if (item == null) return '0 Reactions';

    final reactions = normalizeReactions(item['reactions']);
    final parts = <String>[];

    for (final reaction in reactionTypes) {
      final count = reactions[reaction]?.length ?? 0;

      if (count > 0) {
        parts.add('$count ${reactionLabel(reaction)}');
      }
    }

    if (parts.isEmpty) return '0 Reactions';

    return parts.join(' • ');
  }

  Future<void> setReaction(String reaction) async {
    if (widget.announcementId.isEmpty || widget.currentUserId.isEmpty) {
      return;
    }

    try {
      final ref =
          firestore.collection('announcements').doc(widget.announcementId);

      final doc = await ref.get();

      if (!doc.exists) {
        showSnackBar('Announcement not found');
        return;
      }

      final data = doc.data();
      final reactions = normalizeReactions(data?['reactions']);
      final reactionUsers = normalizeReactionUsers(data?['reactionUsers']);

      String existingReaction = '';

      for (final item in reactionTypes) {
        if ((reactions[item] ?? []).contains(widget.currentUserId)) {
          existingReaction = item;
        }

        reactions[item]?.remove(widget.currentUserId);
      }

      if (existingReaction == reaction) {
        reactionUsers.remove(widget.currentUserId);
      } else {
        reactions[reaction]?.add(widget.currentUserId);

        reactionUsers[widget.currentUserId] = {
          'userId': widget.currentUserId,
          'userName': widget.currentUserName,
          'userRole': widget.currentRole,
          'reaction': reaction,
          'reactedAt': Timestamp.now(),
        };
      }

      int count = 0;

      for (final item in reactionTypes) {
        count += reactions[item]?.length ?? 0;
      }

      await ref.update({
        'reactions': reactions,
        'reactionUsers': reactionUsers,
        'reactionsCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadDetailData();
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void showReactionPicker() {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: reactionTypes.map((reaction) {
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  setReaction(reaction);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reactionIcon(reaction),
                        color: reactionColor(reaction),
                        size: 34,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reactionLabel(reaction),
                        style: TextStyle(
                          color: reactionColor(reaction),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void showReactionUsers() {
    final item = announcement;

    if (item == null) return;

    final reactionUsers = normalizeReactionUsers(item['reactionUsers']);

    final users = reactionUsers.values.map((user) {
      if (user is Map) {
        return Map<String, dynamic>.from(user);
      }

      return <String, dynamic>{};
    }).where((user) {
      return user.isNotEmpty;
    }).toList();

    users.sort((a, b) {
      final aName = (a['userName'] ?? '').toString();
      final bName = (b['userName'] ?? '').toString();

      return aName.compareTo(bName);
    });

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
                'Reactions',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No reaction yet.',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final reaction = user['reaction'] ?? 'like';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              reactionColor(reaction).withValues(alpha: 0.15),
                          child: Icon(
                            reactionIcon(reaction),
                            color: reactionColor(reaction),
                          ),
                        ),
                        title: Text(
                          user['userName'] ?? 'User',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(user['userRole'] ?? ''),
                        trailing: Text(
                          reactionLabel(reaction),
                          style: TextStyle(
                            color: reactionColor(reaction),
                            fontWeight: FontWeight.bold,
                          ),
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

  Future<void> sendComment({
    String parentCommentId = '',
  }) async {
    final text = commentController.text.trim();

    if (text.isEmpty) return;

    if (widget.currentUserId.isEmpty) {
      showSnackBar('User not found. Please login again.');
      return;
    }

    try {
      setState(() {
        isSendingComment = true;
      });

      final announcementRef =
          firestore.collection('announcements').doc(widget.announcementId);

      final commentRef = announcementRef.collection('comments').doc();

      final batch = firestore.batch();

      batch.set(commentRef, {
        'text': text,
        'userId': widget.currentUserId,
        'userName': widget.currentUserName,
        'userRole': widget.currentRole,
        'parentCommentId': parentCommentId,
        'isEdited': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(announcementRef, {
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      commentController.clear();

      await loadDetailData();

      if (!mounted) return;

      setState(() {
        isSendingComment = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSendingComment = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> sendReply(Map<String, dynamic> comment) async {
    final replyController = TextEditingController();

    final replyText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reply to Comment'),
          content: TextField(
            controller: replyController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Write your reply...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  replyController.text.trim(),
                );
              },
              child: const Text('Reply'),
            ),
          ],
        );
      },
    );

    if (replyText == null || replyText.trim().isEmpty) {
      return;
    }

    try {
      final announcementRef =
          firestore.collection('announcements').doc(widget.announcementId);

      final replyRef = announcementRef.collection('comments').doc();

      final batch = firestore.batch();

      batch.set(replyRef, {
        'text': replyText.trim(),
        'userId': widget.currentUserId,
        'userName': widget.currentUserName,
        'userRole': widget.currentRole,
        'parentCommentId': comment['id'] ?? '',
        'isEdited': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(announcementRef, {
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await NotificationService.notifyCommentReply(
        receiverId: comment['userId'] ?? '',
        announcementId: widget.announcementId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderRole: widget.currentRole,
      );

      await loadDetailData();

      if (!mounted) return;

      showSnackBar('Reply sent');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> editComment(Map<String, dynamic> comment) async {
    final commentId = comment['id'] ?? '';

    if (commentId.toString().isEmpty) return;

    final canEdit = isAdmin || comment['userId'] == widget.currentUserId;

    if (!canEdit) {
      showSnackBar('You can only edit your own comment');
      return;
    }

    final editController = TextEditingController(
      text: comment['text'] ?? '',
    );

    final updatedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: editController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Update your comment...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  editController.text.trim(),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (updatedText == null || updatedText.trim().isEmpty) {
      return;
    }

    try {
      await firestore
          .collection('announcements')
          .doc(widget.announcementId)
          .collection('comments')
          .doc(commentId)
          .update({
        'text': updatedText.trim(),
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadDetailData();

      if (!mounted) return;

      showSnackBar('Comment updated');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteComment(Map<String, dynamic> comment) async {
    final commentId = comment['id'] ?? '';

    if (commentId.toString().isEmpty) return;

    final canDelete = isAdmin || comment['userId'] == widget.currentUserId;

    if (!canDelete) {
      showSnackBar('You can only delete your own comment');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final announcementRef =
          firestore.collection('announcements').doc(widget.announcementId);

      final commentsRef = announcementRef.collection('comments');

      final repliesToDelete = comments.where((reply) {
        return reply['parentCommentId'] == commentId;
      }).toList();

      final batch = firestore.batch();

      batch.delete(commentsRef.doc(commentId));

      int deleteCount = 1;

      for (final reply in repliesToDelete) {
        final replyId = reply['id'] ?? '';

        if (replyId.toString().isNotEmpty) {
          batch.delete(commentsRef.doc(replyId));
          deleteCount++;
        }
      }

      batch.update(announcementRef, {
        'commentsCount': FieldValue.increment(-deleteCount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await loadDetailData();

      if (!mounted) return;

      showSnackBar('Comment deleted');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> shareAnnouncement() async {
    final item = announcement;

    if (item == null) return;

    final title = item['title'] ?? '';
    final body = item['body'] ?? '';

    await Clipboard.setData(
      ClipboardData(text: '$title\n\n$body'),
    );

    await firestore.collection('announcements').doc(widget.announcementId).update({
      'sharesCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    showSnackBar('Announcement copied. You can now share it.');

    await loadDetailData();
  }

  Color priorityColor(String priority) {
    if (priority == 'Urgent') return AppColors.danger;
    if (priority == 'High') return Colors.orange;
    if (priority == 'Low') return AppColors.textGrey;

    return AppColors.primaryBlue;
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year • $hour:$minute';
    }

    return 'Recently';
  }

  Widget detailHeader() {
    final item = announcement;

    if (item == null) {
      return const SizedBox();
    }

    final title = item['title'] ?? '';
    final body = item['body'] ?? '';
    final category = item['category'] ?? 'General';
    final priority = item['priority'] ?? 'Normal';
    final targetAudience = item['targetAudience'] ?? 'All';
    final createdByName = item['createdByName'] ?? 'Admin';
    final createdAt = item['createdAt'];
    final currentReaction = userReaction();
    final hasReacted = currentReaction.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            createdByName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatDate(createdAt),
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tagChip(text: category, color: AppColors.primaryBlue),
              tagChip(text: priority, color: priorityColor(priority)),
              tagChip(text: targetAudience, color: AppColors.softGreen),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: showReactionUsers,
            child: Text(
              reactionsText(),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: showReactionPicker,
                  icon: Icon(
                    hasReacted
                        ? reactionIcon(currentReaction)
                        : Icons.thumb_up_alt_outlined,
                    color: hasReacted
                        ? reactionColor(currentReaction)
                        : AppColors.textGrey,
                  ),
                  label: Text(
                    hasReacted ? reactionLabel(currentReaction) : 'React',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasReacted
                          ? reactionColor(currentReaction)
                          : AppColors.textGrey,
                      fontWeight:
                          hasReacted ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: shareAnnouncement,
                  icon: const Icon(
                    Icons.share_outlined,
                    color: AppColors.textGrey,
                  ),
                  label: Text(
                    '${item['sharesCount'] ?? 0} Share',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget tagChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget commentsSection() {
    final mainComments = comments.where((comment) {
      return (comment['parentCommentId'] ?? '').toString().isEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${comments.length})',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          const Text(
            'No comments yet. Be the first to comment.',
            style: TextStyle(color: AppColors.textGrey),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mainComments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return commentCard(mainComments[index]);
            },
          ),
      ],
    );
  }

  Widget commentCard(Map<String, dynamic> comment) {
    final replies = comments.where((item) {
      return item['parentCommentId'] == comment['id'];
    }).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commentContent(comment),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                sendReply(comment);
              },
              icon: const Icon(Icons.reply_outlined),
              label: const Text('Reply'),
            ),
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                children: replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        ),
                      ),
                      child: commentContent(reply, isReply: true),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget commentContent(
    Map<String, dynamic> comment, {
    bool isReply = false,
  }) {
    final canManage = isAdmin || comment['userId'] == widget.currentUserId;
    final isEdited = comment['isEdited'] == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 16 : 18,
          backgroundColor: comment['userRole'] == 'Admin'
              ? AppColors.primaryBlue
              : AppColors.softGreen,
          child: Icon(
            comment['userRole'] == 'Admin'
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            color: AppColors.white,
            size: isReply ? 17 : 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    comment['userName'] ?? 'User',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '• ${comment['userRole'] ?? ''}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  if (isEdited)
                    const Text(
                      '• edited',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment['text'] ?? '',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatDate(comment['createdAt']),
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (canManage)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                editComment(comment);
              }

              if (value == 'delete') {
                deleteComment(comment);
              }
            },
            itemBuilder: (_) {
              return const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ];
            },
          ),
      ],
    );
  }

  Widget commentInput() {
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
              controller: commentController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                prefixIcon: Icon(Icons.mode_comment_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 50,
            width: 50,
            child: ElevatedButton(
              onPressed: isSendingComment ? null : sendComment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSendingComment
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

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = announcement;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcement'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadDetailData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
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
                : item == null
                    ? const Center(
                        child: Text(
                          'Announcement not found.',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  detailHeader(),
                                  const SizedBox(height: 18),
                                  commentsSection(),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                          commentInput(),
                        ],
                      ),
      ),
    );
  }
}