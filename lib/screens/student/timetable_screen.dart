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

    classes.sort((a, b) {
      return (a['className'] ?? '').toString().compareTo(
            (b['className'] ?? '').toString(),
          );
    });
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

    teachers.sort((a, b) {
      return (a['fullName'] ?? '').toString().compareTo(
            (b['fullName'] ?? '').toString(),
          );
    });
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
        'coefficient': data['coefficient'] ?? 1,
      };
    }).toList();

    subjects.sort((a, b) {
      return (a['subjectName'] ?? '').toString().compareTo(
            (b['subjectName'] ?? '').toString(),
          );
    });
  }

  Future<List<Map<String, dynamic>>> getSubjectsByClass(String classId) async {
    final snapshot = await firestore
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();

    final loadedSubjects = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'coefficient': data['coefficient'] ?? 1,
      };
    }).toList();

    loadedSubjects.sort((a, b) {
      return (a['subjectName'] ?? '').toString().compareTo(
            (b['subjectName'] ?? '').toString(),
          );
    });

    return loadedSubjects;
  }

  Future<void> loadSubjectsByClass(String classId) async {
    subjects = await getSubjectsByClass(classId);
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
      'createdBy': data['createdBy'] ?? '',
      'createdByName': data['createdByName'] ?? '',
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

  TimeOfDay timeFromString(String value, TimeOfDay fallback) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return fallback;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return fallback;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<bool> hasTimeConflict({
    required String? editingId,
    required String classId,
    required String teacherId,
    required String day,
    required int startMinutes,
    required int endMinutes,
  }) async {
    final snapshot = await firestore
        .collection('timetables')
        .where('day', isEqualTo: day)
        .get();

    for (final doc in snapshot.docs) {
      if (editingId != null && doc.id == editingId) {
        continue;
      }

      final data = doc.data();
      final existingClassId = data['classId'] ?? '';
      final existingTeacherId = data['teacherId'] ?? '';
      final existingStart = data['startMinutes'] ?? 0;
      final existingEnd = data['endMinutes'] ?? 0;

      final overlaps = startMinutes < existingEnd && endMinutes > existingStart;
      final sameClass = existingClassId == classId;
      final sameTeacher =
          teacherId.toString().isNotEmpty && existingTeacherId == teacherId;

      if (overlaps && (sameClass || sameTeacher)) {
        return true;
      }
    }

    return false;
  }

  Future<void> saveTimetable({
    String? editingId,
  }) async {
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

    final conflict = await hasTimeConflict(
      editingId: editingId,
      classId: selectedClassId,
      teacherId: selectedTeacherId,
      day: selectedDay,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );

    if (conflict) {
      showSnackBar(
        'Time conflict found. This class or teacher already has a timetable at that time.',
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final data = {
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (editingId == null) {
        await firestore.collection('timetables').add({
          ...data,
          'createdBy': currentUserId,
          'createdByName': currentUserName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await firestore.collection('timetables').doc(editingId).update(data);
      }

      if (!mounted) return;

      Navigator.pop(context);

      resetForm();

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(
        editingId == null
            ? 'Timetable created successfully'
            : 'Timetable updated successfully',
      );
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
    subjects = [];
  }

  void prepareEditForm(Map<String, dynamic> item) {
    selectedDay = item['day'] ?? 'Monday';
    selectedClassId = item['classId'] ?? '';
    selectedClassName = item['className'] ?? '';
    selectedSubjectId = item['subjectId'] ?? '';
    selectedSubjectName = item['subjectName'] ?? '';
    selectedTeacherId = item['teacherId'] ?? '';
    selectedTeacherName = item['teacherName'] ?? '';
    selectedStartTime = timeFromString(
      item['startTime'] ?? '',
      const TimeOfDay(hour: 8, minute: 0),
    );
    selectedEndTime = timeFromString(
      item['endTime'] ?? '',
      const TimeOfDay(hour: 10, minute: 0),
    );
    roomController.text = item['room'] ?? '';
    noteController.text = item['note'] ?? '';
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

  Widget timeBox({
    required String label,
    required TimeOfDay value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label: ${formatTimeOfDay(value)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAddTimetableSheet() {
    resetForm();

    showTimetableFormSheet(
      title: 'Create Timetable',
      buttonText: 'Save Timetable',
      editingId: null,
    );
  }

  void showEditTimetableSheet(Map<String, dynamic> item) {
    prepareEditForm(item);

    showTimetableFormSheet(
      title: 'Edit Timetable',
      buttonText: 'Update Timetable',
      editingId: item['id'] ?? '',
    );
  }

  void showTimetableFormSheet({
    required String title,
    required String buttonText,
    required String? editingId,
  }) {
    List<Map<String, dynamic>> modalSubjects = [];
    bool isLoadingSubjects = false;
    bool didLoadInitialSubjects = false;

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
            Future<void> loadModalSubjects(String classId) async {
              setModalState(() {
                isLoadingSubjects = true;
              });

              final loadedSubjects = await getSubjectsByClass(classId);

              setModalState(() {
                modalSubjects = loadedSubjects;
                isLoadingSubjects = false;

                if (selectedSubjectId.isNotEmpty &&
                    !modalSubjects.any((subject) {
                      return subject['id'] == selectedSubjectId;
                    })) {
                  selectedSubjectId = '';
                  selectedSubjectName = '';
                  selectedTeacherId = '';
                  selectedTeacherName = '';
                }
              });
            }

            if (!didLoadInitialSubjects && selectedClassId.isNotEmpty) {
              didLoadInitialSubjects = true;
              Future.microtask(() {
                loadModalSubjects(selectedClassId);
              });
            }

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
                          imagePath: 'assets/icons/timetable.png',
                          fallbackIcon: Icons.calendar_month_outlined,
                          size: 48,
                          padding: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
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
                        timeBox(
                          label: 'Start',
                          value: selectedStartTime,
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
                        ),
                        const SizedBox(width: 12),
                        timeBox(
                          label: 'End',
                          value: selectedEndTime,
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

                        final chosenClass = classes.firstWhere(
                          (schoolClass) => schoolClass['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedClassId = value;
                          selectedClassName = chosenClass['className'] ?? '';
                          selectedSubjectId = '';
                          selectedSubjectName = '';
                          selectedTeacherId = '';
                          selectedTeacherName = '';
                          modalSubjects = [];
                        });

                        await loadModalSubjects(value);
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
                            selectedSubjectId.isEmpty ? null : selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
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

                                final chosenSubject = modalSubjects.firstWhere(
                                  (subject) => subject['id'] == value,
                                  orElse: () => {},
                                );

                                setModalState(() {
                                  selectedSubjectId = value;
                                  selectedSubjectName =
                                      chosenSubject['subjectName'] ?? '';
                                  selectedTeacherId =
                                      chosenSubject['teacherId'] ?? '';
                                  selectedTeacherName =
                                      chosenSubject['teacherName'] ?? '';
                                });
                              },
                      ),
                    if (selectedClassId.isNotEmpty &&
                        modalSubjects.isEmpty &&
                        !isLoadingSubjects) ...[
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

                        final chosenTeacher = teachers.firstWhere(
                          (teacher) => teacher['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedTeacherId = value;
                          selectedTeacherName =
                              chosenTeacher['fullName'] ?? '';
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
                        onPressed: isSaving
                            ? null
                            : () {
                                saveTimetable(
                                  editingId: editingId,
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
                          isSaving ? 'Saving...' : buttonText,
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

  Color dayColor(String day) {
    if (day == 'Monday') return AppColors.primaryBlue;
    if (day == 'Tuesday') return AppColors.softGreen;
    if (day == 'Wednesday') return Colors.orange;
    if (day == 'Thursday') return Colors.purple;
    if (day == 'Friday') return Colors.teal;
    return AppColors.danger;
  }

  Widget headerCard() {
    String title = 'Timetable';
    String subtitle = 'View your weekly school schedule.';

    if (currentRole == 'Admin') {
      title = 'Timetable Management';
      subtitle = 'Create and manage class schedules.';
    }

    if (currentRole == 'Teacher') {
      title = 'My Timetable';
      subtitle = 'View the classes assigned to your teaching schedule.';
    }

    if (currentRole == 'Parent') {
      title = 'Child Timetable';
      subtitle = 'Follow your child’s weekly class schedule.';
    }

    if (currentRole == 'Student') {
      title = 'My Timetable';
      subtitle = 'Check your weekly classes and rooms.';
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
                    'assets/icons/timetable.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.calendar_month_outlined,
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
                      '$subtitle ${timetableItems.length} record(s).',
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

  Widget timetableCard(Map<String, dynamic> item) {
    final timetableId = item['id'] ?? '';
    final subjectName = item['subjectName'] ?? 'No Subject';
    final className = item['className'] ?? '';
    final teacherName = item['teacherName'] ?? '';
    final startTime = item['startTime'] ?? '';
    final endTime = item['endTime'] ?? '';
    final room = item['room'] ?? '';
    final note = item['note'] ?? '';

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
                  imagePath: 'assets/icons/timetable.png',
                  fallbackIcon: Icons.schedule_outlined,
                  size: 54,
                  padding: 11,
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
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$startTime - $endTime',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (className.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        detailLine(
                          icon: Icons.class_outlined,
                          text: 'Class: $className',
                        ),
                      ],
                      if (teacherName.toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        detailLine(
                          icon: Icons.person_outline,
                          text: 'Teacher: $teacherName',
                        ),
                      ],
                      if (room.toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        detailLine(
                          icon: Icons.meeting_room_outlined,
                          text: 'Room: $room',
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
                      if (canCreateTimetable) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                showEditTimetableSheet(item);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                            OutlinedButton.icon(
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
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget daySection(String day) {
    final items = timetableItems.where((item) {
      return item['day'] == day;
    }).toList();

    if (items.isEmpty) {
      return const SizedBox();
    }

    final color = dayColor(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.today_outlined,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length} class(es)',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/timetable.png',
              fallbackIcon: Icons.calendar_month_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No timetable yet',
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
                    : RefreshIndicator(
                        onRefresh: loadInitialData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              headerCard(),
                              const SizedBox(height: 24),
                              ...days.map((day) {
                                return daySection(day);
                              }),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
