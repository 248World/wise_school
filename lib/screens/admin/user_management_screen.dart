import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String selectedRole = 'All';

  final List<String> roles = [
    'All',
    'Admin',
    'Teacher',
    'Student',
    'Parent',
  ];

  final List<Map<String, String>> users = [
    {
      'name': 'School Admin',
      'email': 'admin@wiseschool.com',
      'role': 'Admin',
    },
    {
      'name': 'Mr. Johnson',
      'email': 'teacher@wiseschool.com',
      'role': 'Teacher',
    },
    {
      'name': 'Student One',
      'email': 'student@wiseschool.com',
      'role': 'Student',
    },
    {
      'name': 'Parent One',
      'email': 'parent@wiseschool.com',
      'role': 'Parent',
    },
  ];

  List<Map<String, String>> get filteredUsers {
    if (selectedRole == 'All') {
      return users;
    }

    return users.where((user) => user['role'] == selectedRole).toList();
  }

  Color roleColor(String role) {
    if (role == 'Admin') return AppColors.primaryBlue;
    if (role == 'Teacher') return AppColors.softGreen;
    if (role == 'Student') return Colors.orange;
    return Colors.purple;
  }

  void showAddUserPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add user form will be added later'),
      ),
    );
  }

  void showUserDetails(Map<String, String> user) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: roleColor(user['role']!).withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_outline,
                  size: 42,
                  color: roleColor(user['role']!),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user['name']!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user['email']!,
                style: const TextStyle(
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: roleColor(user['role']!).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user['role']!,
                  style: TextStyle(
                    color: roleColor(user['role']!),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        onPressed: showAddUserPlaceholder,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add User'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: DropdownButtonFormField<String>(
                value: selectedRole,
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
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = list[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => showUserDetails(user),
                    child: Container(
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
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                roleColor(user['role']!).withValues(alpha: 0.12),
                            child: Icon(
                              Icons.person_outline,
                              color: roleColor(user['role']!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['email']!,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  roleColor(user['role']!).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user['role']!,
                              style: TextStyle(
                                color: roleColor(user['role']!),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}