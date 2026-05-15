import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  String selectedRole = 'All';

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> parents = [];

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  String selectedEditRole = 'Student';
  String selectedClassId = '';
  String selectedClassName = '';
  String selectedParentId = '';
  String selectedParentName = '';

  final List<String> roles = [
    'All',
    'Admin',
    'Teacher',
    'Student',
    'Parent',
  ];

  final List<String> editableRoles = [
    'Admin',
    'Teacher',
    'Student',
    'Parent',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final usersSnapshot = await firestore.collection('users').get();
      final classesSnapshot = await firestore.collection('classes').get();

      final loadedUsers = usersSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? '',
          'userName': data['userName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? 'Student',
          'gender': data['gender'] ?? '',
          'city': data['city'] ?? '',
          'address': data['address'] ?? '',
          'about': data['about'] ?? '',
          'profileImage': data['profileImage'] ?? '',
          'profileImageUrl': data['profileImageUrl'] ?? data['profileImage'] ?? '',
          'isActive': data['isActive'] ?? true,
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'parentId': data['parentId'] ?? '',
          'parentName': data['parentName'] ?? '',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();

      loadedUsers.sort((a, b) {
        return (a['fullName'] ?? '').toString().compareTo(
              (b['fullName'] ?? '').toString(),
            );
      });

      final loadedClasses = classesSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'className': data['className'] ?? '',
          'level': data['level'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();

      loadedClasses.sort((a, b) {
        return (a['className'] ?? '').toString().compareTo(
              (b['className'] ?? '').toString(),
            );
      });

      final loadedParents = loadedUsers.where((user) {
        return user['role'] == 'Parent' && user['isActive'] == true;
      }).toList();

      if (!mounted) return;

      setState(() {
        users = loadedUsers;
        classes = loadedClasses;
        parents = loadedParents;
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

  List<Map<String, dynamic>> filteredUsers() {
    if (selectedRole == 'All') {
      return users;
    }

    return users.where((user) => user['role'] == selectedRole).toList();
  }

  Color roleColor(String role) {
    if (role == 'Admin') return AppColors.primaryBlue;
    if (role == 'Teacher') return AppColors.softGreen;
    if (role == 'Student') return Colors.orange;
    if (role == 'Parent') return Colors.purple;

    return AppColors.textGrey;
  }

  IconData roleFallbackIcon(String role) {
    if (role == 'Admin') return Icons.admin_panel_settings_outlined;
    if (role == 'Teacher') return Icons.person_4_outlined;
    if (role == 'Student') return Icons.school_outlined;
    if (role == 'Parent') return Icons.family_restroom_outlined;

    return Icons.account_circle_outlined;
  }

  String roleImagePath(String role) {
    if (role == 'Admin') return 'assets/icons/admin.png';
    if (role == 'Teacher') return 'assets/icons/teacher.png';
    if (role == 'Student') return 'assets/icons/student.png';
    if (role == 'Parent') return 'assets/icons/parent.png';

    return 'assets/icons/profile.png';
  }

  Future<void> recalculateClassStudentCount(String classId) async {
    if (classId.isEmpty) return;

    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .get();

    await firestore.collection('classes').doc(classId).set(
      {
        'studentCount': snapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
    required String oldClassId,
  }) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (oldClassId.isNotEmpty) {
        await recalculateClassStudentCount(oldClassId);
      }

      await loadData();

      showSnackBar(isActive ? 'User activated' : 'User disabled');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateUser({
    required String userId,
    required String oldRole,
    required String oldClassId,
  }) async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (fullName.isEmpty) {
      showSnackBar('Please enter full name');
      return;
    }

    if (email.isEmpty) {
      showSnackBar('Please enter email');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final updateData = <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': selectedEditRole,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (selectedEditRole == 'Student') {
        updateData['classId'] = selectedClassId;
        updateData['className'] = selectedClassName;
        updateData['parentId'] = selectedParentId;
        updateData['parentName'] = selectedParentName;
      } else {
        updateData['classId'] = '';
        updateData['className'] = '';
        updateData['parentId'] = '';
        updateData['parentName'] = '';
      }

      await firestore.collection('users').doc(userId).update(updateData);

      if (oldClassId.isNotEmpty) {
        await recalculateClassStudentCount(oldClassId);
      }

      if (selectedClassId.isNotEmpty) {
        await recalculateClassStudentCount(selectedClassId);
      }

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        isSaving = false;
      });

      await loadData();

      showSnackBar('User updated successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteUser({
    required String userId,
    required String fullName,
    required String role,
    required String oldClassId,
  }) async {
    try {
      final batch = firestore.batch();
      final userRef = firestore.collection('users').doc(userId);

      batch.delete(userRef);

      if (role == 'Teacher') {
        final classesSnapshot = await firestore
            .collection('classes')
            .where('teacherId', isEqualTo: userId)
            .get();

        for (final classDoc in classesSnapshot.docs) {
          batch.update(classDoc.reference, {
            'teacherId': '',
            'teacherName': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final subjectsSnapshot = await firestore
            .collection('subjects')
            .where('teacherId', isEqualTo: userId)
            .get();

        for (final subjectDoc in subjectsSnapshot.docs) {
          batch.update(subjectDoc.reference, {
            'teacherId': '',
            'teacherName': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (role == 'Parent') {
        final childrenSnapshot = await firestore
            .collection('users')
            .where('parentId', isEqualTo: userId)
            .get();

        for (final childDoc in childrenSnapshot.docs) {
          batch.update(childDoc.reference, {
            'parentId': '',
            'parentName': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (oldClassId.isNotEmpty) {
        await recalculateClassStudentCount(oldClassId);
      }

      await loadData();

      showSnackBar('$fullName deleted from users');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDeleteUser(Map<String, dynamic> user) async {
    final userId = user['id'] ?? '';
    final fullName = user['fullName'] ?? 'User';
    final role = user['role'] ?? '';
    final oldClassId = user['classId'] ?? '';

    if (userId.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to delete $fullName? This removes the user profile from Firestore. Related class/parent assignments will be cleaned safely.',
          ),
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
      await deleteUser(
        userId: userId,
        fullName: fullName,
        role: role,
        oldClassId: oldClassId,
      );
    }
  }

  void showAddUserPlaceholder() {
    showSnackBar(
      'Use the Register screen to create the Firebase Auth account first. Admin edit/delete controls are available here.',
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
    final list = filteredUsers();

    return Container(
      width: double.infinity,
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
                    'assets/icons/users.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.manage_accounts_outlined,
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
                      'User Management',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedRole == 'All'
                          ? '${users.length} user account(s) registered.'
                          : '${list.length} $selectedRole account(s) found.',
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

  Widget smallStatusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  void prepareEditUser(Map<String, dynamic> user) {
    fullNameController.text = user['fullName'] ?? '';
    emailController.text = user['email'] ?? '';
    phoneController.text = user['phone'] ?? '';
    selectedEditRole = user['role'] ?? 'Student';
    selectedClassId = user['classId'] ?? '';
    selectedClassName = user['className'] ?? '';
    selectedParentId = user['parentId'] ?? '';
    selectedParentName = user['parentName'] ?? '';
  }

  void showEditUserSheet(Map<String, dynamic> user) {
    final userId = user['id'] ?? '';
    final oldRole = user['role'] ?? 'Student';
    final oldClassId = user['classId'] ?? '';

    prepareEditUser(user);

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
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          imagePath: roleImagePath(selectedEditRole),
                          fallbackIcon: roleFallbackIcon(selectedEditRole),
                          color: roleColor(selectedEditRole),
                          size: 48,
                          padding: 10,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit User',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedEditRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.manage_accounts_outlined),
                      ),
                      items: editableRoles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedEditRole = value ?? 'Student';

                          if (selectedEditRole != 'Student') {
                            selectedClassId = '';
                            selectedClassName = '';
                            selectedParentId = '';
                            selectedParentName = '';
                          }
                        });
                      },
                    ),
                    if (selectedEditRole == 'Student') ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedClassId.isEmpty ? null : selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Assign Class',
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
                        onChanged: (value) {
                          final selectedClass = classes.firstWhere(
                            (item) => item['id'] == value,
                            orElse: () => {},
                          );

                          setModalState(() {
                            selectedClassId = value ?? '';
                            selectedClassName =
                                selectedClass['className'] ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedParentId.isEmpty ? null : selectedParentId,
                        decoration: const InputDecoration(
                          labelText: 'Assign Parent',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                        items: parents.map((parent) {
                          return DropdownMenuItem<String>(
                            value: parent['id'],
                            child: Text(parent['fullName'] ?? 'Parent'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          final parent = parents.firstWhere(
                            (item) => item['id'] == value,
                            orElse: () => {},
                          );

                          setModalState(() {
                            selectedParentId = value ?? '';
                            selectedParentName = parent['fullName'] ?? '';
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () {
                                updateUser(
                                  userId: userId,
                                  oldRole: oldRole,
                                  oldClassId: oldClassId,
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
                        label: Text(isSaving ? 'Saving...' : 'Save Changes'),
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

  void showUserDetails(Map<String, dynamic> user) {
    final userId = user['id'] ?? '';
    final fullName = user['fullName'] ?? 'Unknown User';
    final email = user['email'] ?? 'No email';
    final phone = user['phone'] ?? 'No phone';
    final role = user['role'] ?? 'Student';
    final isActive = user['isActive'] ?? true;
    final className = user['className'] ?? '';
    final parentName = user['parentName'] ?? '';
    final classId = user['classId'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                sheetHandle(),
                const SizedBox(height: 18),
                pngIconBox(
                  imagePath: roleImagePath(role),
                  fallbackIcon: roleFallbackIcon(role),
                  color: roleColor(role),
                  size: 82,
                  padding: 18,
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    smallStatusChip(
                      text: role,
                      color: roleColor(role),
                    ),
                    smallStatusChip(
                      text: isActive ? 'Active' : 'Disabled',
                      color: isActive ? AppColors.softGreen : AppColors.danger,
                    ),
                  ],
                ),
                if (role == 'Student') ...[
                  const SizedBox(height: 16),
                  infoTile(
                    icon: Icons.class_outlined,
                    imagePath: 'assets/icons/classes.png',
                    title: className.isEmpty ? 'No class assigned' : className,
                    subtitle: 'Student class',
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 10),
                  infoTile(
                    icon: Icons.family_restroom_outlined,
                    imagePath: 'assets/icons/parent.png',
                    title: parentName.isEmpty ? 'No parent assigned' : parentName,
                    subtitle: 'Assigned parent',
                    color: Colors.purple,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showEditUserSheet(user);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          updateUserStatus(
                            userId: userId,
                            isActive: !isActive,
                            oldClassId: classId,
                          );
                        },
                        icon: Icon(
                          isActive
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          color: isActive ? AppColors.danger : AppColors.softGreen,
                        ),
                        label: Text(
                          isActive ? 'Disable' : 'Activate',
                          style: TextStyle(
                            color:
                                isActive ? AppColors.danger : AppColors.softGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      confirmDeleteUser(user);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Delete User',
                      style: TextStyle(color: AppColors.danger),
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

  Widget infoTile({
    required IconData icon,
    required String imagePath,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          pngIconBox(
            imagePath: imagePath,
            fallbackIcon: icon,
            color: color,
            size: 42,
            padding: 9,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget userCard(Map<String, dynamic> user) {
    final fullName = user['fullName'] ?? 'Unknown User';
    final email = user['email'] ?? 'No email';
    final role = user['role'] ?? 'Student';
    final isActive = user['isActive'] ?? true;
    final className = user['className'] ?? '';
    final parentName = user['parentName'] ?? '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showUserDetails(user),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              pngIconBox(
                imagePath: roleImagePath(role),
                fallbackIcon: roleFallbackIcon(role),
                color: roleColor(role),
                size: 56,
                padding: 11,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
                    if (role == 'Student') ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          smallStatusChip(
                            text: className.isEmpty
                                ? 'No class'
                                : 'Class: $className',
                            color: AppColors.primaryBlue,
                          ),
                          smallStatusChip(
                            text: parentName.isEmpty
                                ? 'No parent'
                                : 'Parent: $parentName',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    smallStatusChip(
                      text: isActive ? 'Active' : 'Disabled',
                      color: isActive ? AppColors.softGreen : AppColors.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    showUserDetails(user);
                  }

                  if (value == 'edit') {
                    showEditUserSheet(user);
                  }

                  if (value == 'status') {
                    updateUserStatus(
                      userId: user['id'] ?? '',
                      isActive: !isActive,
                      oldClassId: user['classId'] ?? '',
                    );
                  }

                  if (value == 'delete') {
                    confirmDeleteUser(user);
                  }
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit User'),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(isActive ? 'Disable User' : 'Activate User'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete User'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/users.png',
              fallbackIcon: Icons.people_outline,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No users found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No users found yet. Register a user first, then come back here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
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
    final list = filteredUsers();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        onPressed: showAddUserPlaceholder,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add User'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? errorState()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            headerCard(),
                            const SizedBox(height: 18),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Filter by Role',
                                prefixIcon: Icon(Icons.filter_list_outlined),
                              ),
                              items: roles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (list.isEmpty)
                        Expanded(child: emptyState())
                      else
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: loadData,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 90),
                              itemCount: list.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 12);
                              },
                              itemBuilder: (context, index) {
                                return userCard(list[index]);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
