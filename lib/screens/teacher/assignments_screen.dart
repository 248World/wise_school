import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../student/assignment_submit_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  final String role;

  const AssignmentsScreen({
    super.key,
    this.role = 'Teacher',
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> submissions = [];
  List<Map<String, dynamic>> parentChildren = [];

  String currentRole = 'Student';
  String currentUserId = '';
  String currentUserName = '';

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  bool get canCreateAssignment {
    return currentRole == 'Teacher' || currentRole == 'Admin';
  }

  bool get isStudent {
    return currentRole == 'Student';
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
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();

      currentRole = authProvider.role ?? widget.role;
      currentUserId = authProvider.userId ?? '';
      currentUserName = authProvider.fullName ?? currentRole;

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (currentRole == 'Student') {
        await loadStudentAssignments();
      } else if (currentRole == 'Parent') {
        await loadParentAssignments();
      } else {
        await loadAdminTeacherAssignments();
      }

      await loadSubmissions();

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

  Future<void> loadAdminTeacherAssignments() async {
    final classesSnapshot = await firestore.collection('classes').get();

    classes = classesSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'className': data['className'] ?? '',
        'level': data['level'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
      };
    }).toList();

    final assignmentsSnapshot = await firestore.collection('assignments').get();

    assignments = assignmentsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'subjectId': data['subjectId'] ?? '',
        'subjectName': data['subjectName'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'dueDate': data['dueDate'],
        'createdAt': data['createdAt'],
      };
    }).toList();

    sortAssignments();
  }

  Future<void> loadStudentAssignments() async {
    final userDoc = await firestore.collection('users').doc(currentUserId).get();

    if (!userDoc.exists) {
      assignments = [];
      return;
    }

    final userData = userDoc.data();
    final classId = userData?['classId'] ?? '';

    if (classId.toString().isEmpty) {
      assignments = [];
      return;
    }

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
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'subjectId': data['subjectId'] ?? '',
        'subjectName': data['subjectName'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'dueDate': data['dueDate'],
        'createdAt': data['createdAt'],
      };
    }).toList();

    sortAssignments();
  }

  Future<void> loadParentAssignments() async {
    final childrenSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('parentId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .get();

    parentChildren = childrenSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
      };
    }).toList();

    final classIds = parentChildren
        .map((child) => child['classId'] ?? '')
        .where((classId) => classId.toString().isNotEmpty)
        .toSet()
        .toList();

    if (classIds.isEmpty) {
      assignments = [];
      return;
    }

    final loadedAssignments = <Map<String, dynamic>>[];

    for (final classId in classIds) {
      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();

        loadedAssignments.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'subjectId': data['subjectId'] ?? '',
          'subjectName': data['subjectName'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'dueDate': data['dueDate'],
          'createdAt': data['createdAt'],
        });
      }
    }

    assignments = loadedAssignments;
    sortAssignments();
  }

  Future<void> loadSubmissions() async {
    if (currentRole == 'Student') {
      final snapshot = await firestore
          .collection('assignment_submissions')
          .where('studentId', isEqualTo: currentUserId)
          .get();

      submissions = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return;
    }

    if (currentRole == 'Parent') {
      final childIds = parentChildren.map((child) => child['id']).toList();

      final loadedSubmissions = <Map<String, dynamic>>[];

      for (final childId in childIds) {
        final snapshot = await firestore
            .collection('assignment_submissions')
            .where('studentId', isEqualTo: childId)
            .get();

        for (final doc in snapshot.docs) {
          loadedSubmissions.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }

      submissions = loadedSubmissions;
      return;
    }

    final snapshot = await firestore.collection('assignment_submissions').get();

    submissions = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  void sortAssignments() {
    assignments.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });
  }

  Map<String, dynamic>? getStudentSubmission(String assignmentId) {
    try {
      return submissions.firstWhere(
        (submission) {
          return submission['assignmentId'] == assignmentId &&
              submission['studentId'] == currentUserId;
        },
      );
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getAssignmentSubmissions(String assignmentId) {
    return submissions.where((submission) {
      return submission['assignmentId'] == assignmentId;
    }).toList();
  }

  List<Map<String, dynamic>> getParentChildrenForAssignment(
    Map<String, dynamic> assignment,
  ) {
    final assignmentClassId = assignment['classId'] ?? '';

    return parentChildren.where((child) {
      return child['classId'] == assignmentClassId;
    }).toList();
  }

  List<Map<String, dynamic>> getParentSubmissionsForAssignment(
    String assignmentId,
  ) {
    return submissions.where((submission) {
      return submission['assignmentId'] == assignmentId;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentsForAssignmentClass(
    String classId,
  ) async {
    final studentsSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .get();

    return studentsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> loadSubjectsByClass(String classId) async {
    final subjectsSnapshot = await firestore
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();

    return subjectsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
      };
    }).toList();
  }

  Future<void> pickDueDate({
    required BuildContext modalContext,
    required DateTime currentDate,
    required void Function(DateTime date) onPicked,
  }) async {
    final pickedDate = await showDatePicker(
      context: modalContext,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    onPicked(pickedDate);
  }

  Future<void> saveAssignment({
    required String title,
    required String description,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    required DateTime dueDate,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();

    if (cleanTitle.isEmpty) {
      showSnackBar('Please enter assignment title');
      return;
    }

    if (cleanDescription.isEmpty) {
      showSnackBar('Please enter assignment description');
      return;
    }

    if (classId.trim().isEmpty) {
      showSnackBar('Please select a class');
      return;
    }

    if (subjectId.trim().isEmpty) {
      showSnackBar('Please select a subject');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final assignmentRef = await firestore.collection('assignments').add({
        'title': cleanTitle,
        'description': cleanDescription,
        'classId': classId,
        'className': className,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'teacherId': currentUserId,
        'teacherName': currentUserName,
        'dueDate': Timestamp.fromDate(dueDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.notifyAssignmentToClass(
        classId: classId,
        assignmentId: assignmentRef.id,
        assignmentTitle: cleanTitle,
        senderId: currentUserId,
        senderName: currentUserName,
        senderRole: currentRole,
      );

      if (!mounted) return;

      Navigator.pop(context);

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Assignment created successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await firestore.collection('assignments').doc(assignmentId).delete();

      final submissionSnapshot = await firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final batch = firestore.batch();

      for (final doc in submissionSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await loadInitialData();

      if (!mounted) return;

      showSnackBar('Assignment deleted successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDelete(String assignmentId, String title) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Assignment'),
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
      await deleteAssignment(assignmentId);
    }
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
    String title = 'Assignments';
    String subtitle = 'View and manage class assignments.';

    if (currentRole == 'Student') {
      title = 'My Assignments';
      subtitle = 'Check your assignments and submit your comments.';
    }

    if (currentRole == 'Parent') {
      title = 'Child Assignments';
      subtitle = 'Follow your child’s assignment progress.';
    }

    if (currentRole == 'Admin') {
      title = 'Assignment Records';
      subtitle = 'Review assignments and student submissions.';
    }

    if (currentRole == 'Teacher') {
      title = 'Assignments';
      subtitle = 'Create assignments and track submissions.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardBlueGradient,
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
                    'assets/icons/assignments.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.assignment_outlined,
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
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$subtitle ${assignments.length} assignment(s).',
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

  Widget detailLine({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.textLight,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget smallStatusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  void showAddAssignmentSheet() {
    titleController.clear();
    descriptionController.clear();

    String modalClassId = '';
    String modalClassName = '';
    String modalSubjectId = '';
    String modalSubjectName = '';
    List<Map<String, dynamic>> modalSubjects = [];
    DateTime modalDueDate = DateTime.now().add(const Duration(days: 7));
    bool isLoadingSubjects = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                          imagePath: 'assets/icons/assignments.png',
                          fallbackIcon: Icons.assignment_outlined,
                          size: 48,
                          padding: 10,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Create Assignment',
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
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Title',
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: modalClassId.isEmpty ? null : modalClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      items: classes.map((schoolClass) {
                        return DropdownMenuItem<String>(
                          value: schoolClass['id'],
                          child: Text(
                            schoolClass['className'] ?? 'Unnamed Class',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value == null) return;

                        final selectedClass = classes.firstWhere(
                          (schoolClass) => schoolClass['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          modalClassId = value;
                          modalClassName = selectedClass['className'] ?? '';
                          modalSubjectId = '';
                          modalSubjectName = '';
                          modalSubjects = [];
                          isLoadingSubjects = true;
                        });

                        final loadedSubjects = await loadSubjectsByClass(value);

                        setModalState(() {
                          modalSubjects = loadedSubjects;
                          isLoadingSubjects = false;
                        });
                      },
                    ),
                    if (classes.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No class found yet. Admin must create a class first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (isLoadingSubjects)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue:
                            modalSubjectId.isEmpty ? null : modalSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Select Subject',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                        items: modalSubjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject['id'],
                            child: Text(
                              subject['subjectName'] ?? 'Unnamed Subject',
                            ),
                          );
                        }).toList(),
                        onChanged: modalSubjects.isEmpty
                            ? null
                            : (value) {
                                if (value == null) return;

                                final selectedSubject =
                                    modalSubjects.firstWhere(
                                  (subject) => subject['id'] == value,
                                  orElse: () => {},
                                );

                                setModalState(() {
                                  modalSubjectId = value;
                                  modalSubjectName =
                                      selectedSubject['subjectName'] ?? '';
                                });
                              },
                      ),
                    if (modalClassId.isNotEmpty &&
                        modalSubjects.isEmpty &&
                        !isLoadingSubjects) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No subject found for this class. Admin must create a subject first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        pickDueDate(
                          modalContext: sheetContext,
                          currentDate: modalDueDate,
                          onPicked: (date) {
                            setModalState(() {
                              modalDueDate = date;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.softBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Due Date: ${modalDueDate.day}/${modalDueDate.month}/${modalDueDate.year}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () {
                                saveAssignment(
                                  title: titleController.text,
                                  description: descriptionController.text,
                                  classId: modalClassId,
                                  className: modalClassName,
                                  subjectId: modalSubjectId,
                                  subjectName: modalSubjectName,
                                  dueDate: modalDueDate,
                                );
                              },
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
                          isSaving ? 'Saving...' : 'Save Assignment',
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

  Future<void> showAssignmentRecords(Map<String, dynamic> assignment) async {
    final assignmentId = assignment['id'] ?? '';
    final classId = assignment['classId'] ?? '';

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
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: getStudentsForAssignmentClass(classId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final students = snapshot.data ?? [];
            final assignmentSubmissions =
                getAssignmentSubmissions(assignmentId);

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      pngIconBox(
                        imagePath: 'assets/icons/assignments.png',
                        fallbackIcon: Icons.assignment_outlined,
                        size: 46,
                        padding: 10,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          assignment['title'] ?? 'Assignment Records',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${assignmentSubmissions.length}/${students.length} submitted',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: students.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        final student = students[index];

                        Map<String, dynamic>? submission;

                        try {
                          submission = assignmentSubmissions.firstWhere(
                            (item) => item['studentId'] == student['id'],
                          );
                        } catch (_) {
                          submission = null;
                        }

                        final submitted = submission != null;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['fullName'] ?? 'Unknown Student',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                submitted ? 'Submitted' : 'Pending',
                                style: TextStyle(
                                  color: submitted
                                      ? AppColors.softGreen
                                      : AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (submitted) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Comment: ${submission?['comment'] ?? ''}',
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
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
      },
    );
  }

  String formatDueDate(dynamic dueDate) {
    if (dueDate is Timestamp) {
      final date = dueDate.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'No due date';
  }

  Widget studentSubmissionStatus(String assignmentId) {
    final submission = getStudentSubmission(assignmentId);
    final submitted = submission != null;

    return smallStatusChip(
      text: submitted ? 'Submitted' : 'Pending',
      color: submitted ? AppColors.softGreen : AppColors.danger,
    );
  }

  Widget parentProgressWidget(Map<String, dynamic> assignment) {
    final assignmentId = assignment['id'] ?? '';
    final relatedChildren = getParentChildrenForAssignment(assignment);
    final assignmentSubmissions =
        getParentSubmissionsForAssignment(assignmentId);

    if (relatedChildren.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: relatedChildren.map((child) {
        Map<String, dynamic>? submission;

        try {
          submission = assignmentSubmissions.firstWhere(
            (item) => item['studentId'] == child['id'],
          );
        } catch (_) {
          submission = null;
        }

        final submitted = submission != null;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${child['fullName']}: ${submitted ? 'Submitted' : 'Pending'}',
            style: TextStyle(
              color: submitted ? AppColors.softGreen : AppColors.danger,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget adminTeacherProgressWidget(Map<String, dynamic> assignment) {
    final assignmentId = assignment['id'] ?? '';
    final submittedCount = getAssignmentSubmissions(assignmentId).length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$submittedCount submission(s) received',
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget assignmentCard(Map<String, dynamic> assignment) {
    final assignmentId = assignment['id'] ?? '';
    final title = assignment['title'] ?? 'Untitled Assignment';
    final description = assignment['description'] ?? '';
    final className = assignment['className'] ?? '';
    final subjectName = assignment['subjectName'] ?? '';
    final teacherName = assignment['teacherName'] ?? '';
    final dueDate = assignment['dueDate'];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -26,
              right: -24,
              child: Container(
                height: 82,
                width: 82,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.045),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pngIconBox(
                  imagePath: 'assets/icons/assignments.png',
                  fallbackIcon: Icons.assignment_outlined,
                  size: 56,
                  padding: 11,
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
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          smallStatusChip(
                            text: subjectName.isEmpty ? 'No subject' : subjectName,
                            color: AppColors.primaryBlue,
                          ),
                          smallStatusChip(
                            text: 'Due: ${formatDueDate(dueDate)}',
                            color: AppColors.softGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (className.toString().isNotEmpty)
                        detailLine(
                          icon: Icons.class_outlined,
                          text: 'Class: $className',
                        )
                      else
                        detailLine(
                          icon: Icons.class_outlined,
                          text: 'No class',
                        ),
                      const SizedBox(height: 6),
                      detailLine(
                        icon: Icons.person_outline,
                        text: teacherName.isEmpty
                            ? 'Teacher not assigned'
                            : 'Teacher: $teacherName',
                      ),
                      if (description.toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (isStudent) ...[
                        const SizedBox(height: 12),
                        studentSubmissionStatus(assignmentId),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignmentSubmitScreen(
                                    assignment: assignment,
                                  ),
                                ),
                              );

                              if (updated == true) {
                                await loadInitialData();

                                if (!mounted) return;

                                showSnackBar('Assignment submitted successfully');
                              }
                            },
                            icon: const Icon(Icons.comment_outlined),
                            label: Text(
                              getStudentSubmission(assignmentId) == null
                                  ? 'Submit Comment'
                                  : 'Update Comment',
                            ),
                          ),
                        ),
                      ],
                      if (isParent) parentProgressWidget(assignment),
                      if (canCreateAssignment) adminTeacherProgressWidget(assignment),
                      if (canCreateAssignment) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showAssignmentRecords(assignment);
                            },
                            icon: const Icon(Icons.list_alt_outlined),
                            label: const Text('View Records'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canCreateAssignment)
                  IconButton(
                    onPressed: () {
                      confirmDelete(assignmentId, title);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    String message = 'No assignments found yet.';

    if (currentRole == 'Student') {
      message =
          'No assignments found for your class yet. Ask your teacher to create assignments.';
    }

    if (currentRole == 'Parent') {
      message =
          'No assignments found for your child yet. Make sure your child is assigned to a class.';
    }

    if (currentRole == 'Teacher' || currentRole == 'Admin') {
      message = 'No assignments found yet. Tap Add Assignment to create one.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/assignments.png',
              fallbackIcon: Icons.assignment_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No assignments yet',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    String title = 'Assignments';

    if (currentRole == 'Student') title = 'My Assignments';
    if (currentRole == 'Parent') title = 'Child Assignments';
    if (currentRole == 'Admin') title = 'Assignment Records';
    if (currentRole == 'Teacher') title = 'Assignments';

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
      floatingActionButton: canCreateAssignment
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showAddAssignmentSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Assignment'),
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
                : assignments.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadInitialData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                          itemCount: assignments.length + 1,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: headerCard(),
                              );
                            }

                            return assignmentCard(assignments[index - 1]);
                          },
                        ),
                      ),
      ),
    );
  }
}
