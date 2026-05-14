import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class TimetableScreen extends StatefulWidget {
  final String role;

  const TimetableScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  String currentRole = 'Student';
  String currentUserId = '';
  String currentUserName = '';

  List<Map<String, dynamic>> timetableItems = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> parentChildren = [];

  String selectedDay = 'Monday';
  String selectedClassId = '';
  String selectedClassName = '';
  String selectedSubjectId = '';
  String selectedSubjectName = '';
  String selectedTeacherId = '';
  String selectedTeacherName = '';

  TimeOfDay selectedStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay selectedEndTime = const TimeOfDay(hour: 10, minute: 0);

  final roomController = TextEditingController();
  final noteController = TextEditingController();

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  bool get canCreateTimetable {
    return currentRole == 'Admin';
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
    roomController.dispose();
    noteController.dispose();
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

      if (currentRole == 'Admin') {
        await loadAdminData();
      } else if (currentRole == 'Teacher') {
        await loadTeacherTimetable();
      } else if (currentRole == 'Parent') {
        await loadParentTimetable();
      } else {
        await loadStudentTimetable();
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

  Future<void> loadAdminData() async {
    await loadClasses();
    await loadTeachers();
    await loadAllSubjects();
    await loadAllTimetables();
  }

  Future<void> loadClasses() async {
    final snapshot = await firestore.collection('classes').get();

    classes = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'className': data['className'] ?? '',
        'level': data['level'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
      };
    }).toList();
  }

  Future<void> loadTeachers() async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Teacher')
        .where('isActive', isEqualTo: true)
        .get();

    teachers = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  }

  Future<void> loadAllSubjects() async {
    final snapshot = await firestore.collection('subjects').get();

    subjects = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'coefficient': data['coefficient'] ?? '',
      };
    }).toList();
  }

  Future<void> loadSubjectsByClass(String classId) async {
    final snapshot = await firestore
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();

    subjects = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'coefficient': data['coefficient'] ?? '',
      };
    }).toList();
  }

  Future<void> loadAllTimetables() async {
    final snapshot = await firestore.collection('timetables').get();

    timetableItems = snapshot.docs.map((doc) {
      return timetableFromData(doc.id, doc.data());
    }).toList();

    sortTimetables();
  }

  Future<void> loadTeacherTimetable() async {
    final snapshot = await firestore
        .collection('timetables')
        .where('teacherId', isEqualTo: currentUserId)
        .get();

    timetableItems = snapshot.docs.map((doc) {
      return timetableFromData(doc.id, doc.data());
    }).toList();

    sortTimetables();
  }

  Future<void> loadStudentTimetable() async {
    final userDoc = await firestore.collection('users').doc(currentUserId).get();

    if (!userDoc.exists) {
      timetableItems = [];
      return;
    }

    final userData = userDoc.data();
    final classId = userData?['classId'] ?? '';

    if (classId.toString().isEmpty) {
      timetableItems = [];
      return;
    }

    final snapshot = await firestore
        .collection('timetables')
        .where('classId', isEqualTo: classId)
        .get();

    timetableItems = snapshot.docs.map((doc) {
      return timetableFromData(doc.id, doc.data());
    }).toList();

    sortTimetables();
  }

  Future<void> loadParentTimetable() async {
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
      timetableItems = [];
      return;
    }

    final loadedTimetables = <Map<String, dynamic>>[];

    for (final classId in classIds) {
      final snapshot = await firestore
          .collection('timetables')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in snapshot.docs) {
        loadedTimetables.add(timetableFromData(doc.id, doc.data()));
      }
    }

    timetableItems = loadedTimetables;
    sortTimetables();
  }

  Map<String, dynamic> timetableFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    return {
      'id': id,
      'day': data['day'] ?? '',
      'dayIndex': data['dayIndex'] ?? 0,
      'startTime': data['startTime'] ?? '',
      'endTime': data['endTime'] ?? '',
      'startMinutes': data['startMinutes'] ?? 0,
      'endMinutes': data['endMinutes'] ?? 0,
      'classId': data['classId'] ?? '',
      'className': data['className'] ?? '',
      'subjectId': data['subjectId'] ?? '',
      'subjectName': data['subjectName'] ?? '',
      'teacherId': data['teacherId'] ?? '',
      'teacherName': data['teacherName'] ?? '',
      'room': data['room'] ?? '',
      'note': data['note'] ?? '',
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
    };
  }

  void sortTimetables() {
    timetableItems.sort((a, b) {
      final dayCompare = (a['dayIndex'] ?? 0).compareTo(b['dayIndex'] ?? 0);

      if (dayCompare != 0) {
        return dayCompare;
      }

      return (a['startMinutes'] ?? 0).compareTo(b['startMinutes'] ?? 0);
    });
  }

  int timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> pickStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedStartTime,
    );

    if (pickedTime == null) return;

    setState(() {
      selectedStartTime = pickedTime;
    });
  }

  Future<void> pickEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
    );

    if (pickedTime == null) return;

    setState(() {
      selectedEndTime = pickedTime;
    });
  }

  Future<void> saveTimetable() async {
    final room = roomController.text.trim();
    final note = noteController.text.trim();

    if (selectedClassId.isEmpty) {
      showSnackBar('Please select a class');
      return;
    }

    if (selectedSubjectId.isEmpty) {
      showSnackBar('Please select a subject');
      return;
    }

    if (selectedTeacherId.isEmpty) {
      showSnackBar('Please select a teacher');
      return;
    }

    final startMinutes = timeToMinutes(selectedStartTime);
    final endMinutes = timeToMinutes(selectedEndTime);

    if (endMinutes <= startMinutes) {
      showSnackBar('End time must be after start time');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await firestore.collection('timetables').add({
        'day': selectedDay,
        'dayIndex': days.indexOf(selectedDay),
        'startTime': formatTimeOfDay(selectedStartTime),
        'endTime': formatTimeOfDay(selectedEndTime),
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'classId': selectedClassId,
        'className': selectedClassName,
        'subjectId': selectedSubjectId,
        'subjectName': selectedSubjectName,
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'room': room,
        'note': note,
        'createdBy': currentUserId,
        'createdByName': currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      resetForm();

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Timetable created successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteTimetable(String timetableId) async {
    if (timetableId.isEmpty) {
      showSnackBar('Invalid timetable record');
      return;
    }

    try {
      await firestore.collection('timetables').doc(timetableId).delete();

      await loadInitialData();

      if (!mounted) return;

      showSnackBar('Timetable deleted successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDelete({
    required String timetableId,
    required String subjectName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Timetable'),
          content: Text('Are you sure you want to delete "$subjectName"?'),
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
      await deleteTimetable(timetableId);
    }
  }

  void resetForm() {
    selectedDay = 'Monday';
    selectedClassId = '';
    selectedClassName = '';
    selectedSubjectId = '';
    selectedSubjectName = '';
    selectedTeacherId = '';
    selectedTeacherName = '';
    selectedStartTime = const TimeOfDay(hour: 8, minute: 0);
    selectedEndTime = const TimeOfDay(hour: 10, minute: 0);
    roomController.clear();
    noteController.clear();
  }

  void showAddTimetableSheet() {
    resetForm();

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
                      'Create Timetable',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      items: days.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedDay = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: sheetContext,
                                initialTime: selectedStartTime,
                              );

                              if (pickedTime == null) return;

                              setModalState(() {
                                selectedStartTime = pickedTime;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'Start: ${formatTimeOfDay(selectedStartTime)}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: sheetContext,
                                initialTime: selectedEndTime,
                              );

                              if (pickedTime == null) return;

                              setModalState(() {
                                selectedEndTime = pickedTime;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'End: ${formatTimeOfDay(selectedEndTime)}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedClassId.isEmpty ? null : selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class',
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
                          selectedClassId = value;
                          selectedClassName = selectedClass['className'] ?? '';
                          selectedSubjectId = '';
                          selectedSubjectName = '';
                          subjects = [];
                        });

                        await loadSubjectsByClass(value);

                        setModalState(() {});
                      },
                    ),
                    if (classes.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No class found yet. Create a class first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedSubjectId.isEmpty ? null : selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['id'],
                          child: Text(
                            subject['subjectName'] ?? 'Unnamed Subject',
                          ),
                        );
                      }).toList(),
                      onChanged: subjects.isEmpty
                          ? null
                          : (value) {
                              if (value == null) return;

                              final selectedSubject = subjects.firstWhere(
                                (subject) => subject['id'] == value,
                                orElse: () => {},
                              );

                              setModalState(() {
                                selectedSubjectId = value;
                                selectedSubjectName =
                                    selectedSubject['subjectName'] ?? '';

                                selectedTeacherId =
                                    selectedSubject['teacherId'] ?? '';
                                selectedTeacherName =
                                    selectedSubject['teacherName'] ?? '';
                              });
                            },
                    ),
                    if (selectedClassId.isNotEmpty && subjects.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No subject found for this class. Create a subject first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedTeacherId.isEmpty ? null : selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: teachers.map((teacher) {
                        return DropdownMenuItem<String>(
                          value: teacher['id'],
                          child: Text(
                            teacher['fullName'] ?? 'Unnamed Teacher',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        final selectedTeacher = teachers.firstWhere(
                          (teacher) => teacher['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedTeacherId = value;
                          selectedTeacherName =
                              selectedTeacher['fullName'] ?? '';
                        });
                      },
                    ),
                    if (teachers.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No teacher found yet.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        hintText: 'Example: Room 2 / Lab A',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Optional note',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveTimetable,
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
                          isSaving ? 'Saving...' : 'Save Timetable',
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

  Widget timetableCard(Map<String, dynamic> item) {
    final timetableId = item['id'] ?? '';
    final subjectName = item['subjectName'] ?? 'No Subject';
    final className = item['className'] ?? '';
    final teacherName = item['teacherName'] ?? '';
    final startTime = item['startTime'] ?? '';
    final endTime = item['endTime'] ?? '';
    final room = item['room'] ?? '';
    final note = item['note'] ?? '';

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
              Icons.schedule_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (className.toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Class: $className',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (teacherName.toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Teacher: $teacherName',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (room.toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Room: $room',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (note.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: $note',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canCreateTimetable)
            IconButton(
              onPressed: () {
                confirmDelete(
                  timetableId: timetableId,
                  subjectName: subjectName,
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

  Widget daySection(String day) {
    final items = timetableItems.where((item) {
      return item['day'] == day;
    }).toList();

    if (items.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            return timetableCard(items[index]);
          },
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget emptyState() {
    String message = 'No timetable found yet.';

    if (currentRole == 'Admin') {
      message = 'No timetable found yet. Tap Add Timetable to create one.';
    }

    if (currentRole == 'Teacher') {
      message = 'No timetable found for your teacher account yet.';
    }

    if (currentRole == 'Student') {
      message =
          'No timetable found for your class yet. Ask Admin to create one.';
    }

    if (currentRole == 'Parent') {
      message =
          'No timetable found for your child yet. Make sure your child is assigned to a class.';
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Timetable';

    if (currentRole == 'Admin') title = 'Timetable Management';
    if (currentRole == 'Teacher') title = 'My Timetable';
    if (currentRole == 'Parent') title = 'Child Timetable';
    if (currentRole == 'Student') title = 'My Timetable';

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
      floatingActionButton: canCreateTimetable
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showAddTimetableSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Timetable'),
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
                : timetableItems.isEmpty
                    ? emptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: days.map((day) {
                            return daySection(day);
                          }).toList(),
                        ),
                      ),
      ),
    );
  }
}