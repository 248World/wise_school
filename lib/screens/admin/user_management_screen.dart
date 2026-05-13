import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';

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

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<UserProvider>().loadUsers();
    });
  }

  List<Map<String, dynamic>> filteredUsers(List<Map<String, dynamic>> users) {
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
        content: Text('Admin add user form will be connected later'),
      ),
    );
  }

  void showUserDetails(Map<String, dynamic> user) {
    final userId = user['id'] ?? '';
    final fullName = user['fullName'] ?? 'Unknown User';
    final email = user['email'] ?? 'No email';
    final phone = user['phone'] ?? 'No phone';
    final role = user['role'] ?? 'Student';
    final isActive = user['isActive'] ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final currentUser = userProvider.users.firstWhere(
              (item) => item['id'] == userId,
              orElse: () => user,
            );

            final currentIsActive = currentUser['isActive'] ?? isActive;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: roleColor(role).withValues(alpha: 0.12),
                    child: Icon(
                      Icons.person_outline,
                      size: 42,
                      color: roleColor(role),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor(role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: roleColor(role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentIsActive
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                          color: currentIsActive
                              ? AppColors.softGreen
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentIsActive
                                ? 'Account Active'
                                : 'Account Disabled',
                            style: TextStyle(
                              color: currentIsActive
                                  ? AppColors.softGreen
                                  : AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: currentIsActive,
                          activeThumbColor: AppColors.primaryBlue,
                          onChanged: (value) async {
                            if (userId.isEmpty) return;

                            await userProvider.updateUserStatus(
                              userId: userId,
                              isActive: value,
                            );
                          },
                        ),
                      ],
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

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No users found yet. Register a user first, then come back here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final list = filteredUsers(userProvider.users);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            onPressed: userProvider.isLoading
                ? null
                : () {
                    context.read<UserProvider>().loadUsers();
                  },
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: DropdownButtonFormField<String>(
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
            ),
            if (userProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    userProvider.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (userProvider.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (list.isEmpty)
              Expanded(
                child: emptyState(),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                  itemCount: list.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final user = list[index];

                    final fullName = user['fullName'] ?? 'Unknown User';
                    final email = user['email'] ?? 'No email';
                    final role = user['role'] ?? 'Student';
                    final isActive = user['isActive'] ?? true;

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
                                  roleColor(role).withValues(alpha: 0.12),
                              child: Icon(
                                Icons.person_outline,
                                color: roleColor(role),
                              ),
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
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isActive ? 'Active' : 'Disabled',
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.softGreen
                                          : AppColors.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                                color: roleColor(role).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  color: roleColor(role),
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