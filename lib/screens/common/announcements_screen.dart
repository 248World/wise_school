import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

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

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> announcements = [];

  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String selectedAudience = 'All';

  final List<String> audiences = [
    'All',
    'Students',
    'Parents',
    'Teachers',
    'Admins',
  ];

  bool get canCreateAnnouncement {
    return widget.role == 'Admin';
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadAnnouncements();
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> loadAnnouncements() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final snapshot = await firestore.collection('announcements').get();

      final loadedAnnouncements = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'audience': data['audience'] ?? 'All',
          'createdBy': data['createdBy'] ?? '',
          'createdByName': data['createdByName'] ?? '',
          'createdByRole': data['createdByRole'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).where((announcement) {
        final audience = announcement['audience'] ?? 'All';

        if (audience == 'All') return true;

        if (widget.role == 'Student' && audience == 'Students') return true;
        if (widget.role == 'Parent' && audience == 'Parents') return true;
        if (widget.role == 'Teacher' && audience == 'Teachers') return true;
        if (widget.role == 'Admin' && audience == 'Admins') return true;

        return false;
      }).toList();

      loadedAnnouncements.sort((a, b) {
        final aCreated = a['createdAt'];
        final bCreated = b['createdAt'];

        if (aCreated is Timestamp && bCreated is Timestamp) {
          return bCreated.compareTo(aCreated);
        }

        return 0;
      });

      if (!mounted) return;

      setState(() {
        announcements = loadedAnnouncements;
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

  Future<void> saveAnnouncement() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty) {
      showSnackBar('Please enter announcement title');
      return;
    }

    if (message.isEmpty) {
      showSnackBar('Please enter announcement message');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final authProvider = context.read<AuthProvider>();

      await firestore.collection('announcements').add({
        'title': title,
        'message': message,
        'audience': selectedAudience,
        'createdBy': authProvider.userId ?? '',
        'createdByName': authProvider.fullName ?? 'Admin',
        'createdByRole': authProvider.role ?? 'Admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      titleController.clear();
      messageController.clear();
      selectedAudience = 'All';

      await loadAnnouncements();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Announcement created successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await firestore.collection('announcements').doc(announcementId).delete();

      await loadAnnouncements();

      if (!mounted) return;

      showSnackBar('Announcement deleted successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDelete({
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
    messageController.clear();
    selectedAudience = 'All';

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
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: messageController,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        prefixIcon: Icon(Icons.campaign_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAudience,
                      decoration: const InputDecoration(
                        labelText: 'Audience',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: audiences.map((audience) {
                        return DropdownMenuItem<String>(
                          value: audience,
                          child: Text(audience),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedAudience = value;
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
                          isSaving ? 'Saving...' : 'Save Announcement',
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

  String formatDate(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Recently';
  }

  Color audienceColor(String audience) {
    if (audience == 'Students') return AppColors.primaryBlue;
    if (audience == 'Parents') return Colors.purple;
    if (audience == 'Teachers') return AppColors.softGreen;
    if (audience == 'Admins') return Colors.orange;

    return AppColors.textGrey;
  }

  Widget announcementCard(Map<String, dynamic> announcement) {
    final announcementId = announcement['id'] ?? '';
    final title = announcement['title'] ?? 'Untitled';
    final message = announcement['message'] ?? '';
    final audience = announcement['audience'] ?? 'All';
    final createdByName = announcement['createdByName'] ?? 'Admin';
    final createdAt = announcement['createdAt'];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'By $createdByName • ${formatDate(createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: audienceColor(audience).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    audience,
                    style: TextStyle(
                      color: audienceColor(audience),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canCreateAnnouncement)
            IconButton(
              onPressed: () {
                confirmDelete(
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
    );
  }

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No announcements found yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Announcements';

    if (widget.role == 'Student') title = 'Notices';
    if (widget.role == 'Parent') title = 'Parent Notices';
    if (widget.role == 'Teacher') title = 'Teacher Notices';
    if (widget.role == 'Admin') title = 'Announcements';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadAnnouncements,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: canCreateAnnouncement
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showAddAnnouncementSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Notice'),
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