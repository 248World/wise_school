import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String role;

  const ProfileScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isSaving = false;
  bool isLoggingOut = false;
  String? errorMessage;

  String currentUserId = '';
  String currentRole = '';
  String email = '';

  final fullNameController = TextEditingController();
  final userNameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final aboutController = TextEditingController();
  final profileImageUrlController = TextEditingController();

  String selectedGender = 'Not specified';

  final List<String> genders = [
    'Not specified',
    'Male',
    'Female',
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadProfile();
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    userNameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    addressController.dispose();
    aboutController.dispose();
    profileImageUrlController.dispose();

    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;

      currentUserId = firebaseUser?.uid ?? '';
      email = firebaseUser?.email ?? '';

      if (currentUserId.isEmpty) {
        throw Exception('User not found. Please login again.');
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userDoc =
          await firestore.collection('users').doc(currentUserId).get();

      if (!userDoc.exists) {
        currentRole = widget.role;

        fullNameController.text = firebaseUser?.displayName ?? '';
        userNameController.text = '';
        phoneController.text = '';
        cityController.text = '';
        addressController.text = '';
        aboutController.text = '';
        profileImageUrlController.text = firebaseUser?.photoURL ?? '';
        selectedGender = 'Not specified';

        await firestore.collection('users').doc(currentUserId).set({
          'fullName': fullNameController.text.trim(),
          'userName': '',
          'email': email,
          'phone': '',
          'city': '',
          'address': '',
          'about': '',
          'profileImageUrl': profileImageUrlController.text.trim(),
          'gender': selectedGender,
          'role': currentRole,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = userDoc.data();

        fullNameController.text =
            data?['fullName'] ?? firebaseUser?.displayName ?? '';
        userNameController.text = data?['userName'] ?? '';
        phoneController.text = data?['phone'] ?? '';
        cityController.text = data?['city'] ?? '';
        addressController.text = data?['address'] ?? '';
        aboutController.text = data?['about'] ?? '';
        profileImageUrlController.text =
            data?['profileImageUrl'] ?? firebaseUser?.photoURL ?? '';

        email = data?['email'] ?? email;
        currentRole = data?['role'] ?? widget.role;

        final gender = data?['gender'] ?? 'Not specified';

        if (genders.contains(gender)) {
          selectedGender = gender;
        } else {
          selectedGender = 'Not specified';
        }
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

  Future<void> updateProfile() async {
    final fullName = fullNameController.text.trim();
    final userName = userNameController.text.trim();
    final phone = phoneController.text.trim();
    final city = cityController.text.trim();
    final address = addressController.text.trim();
    final about = aboutController.text.trim();
    final profileImageUrl = profileImageUrlController.text.trim();

    if (fullName.isEmpty) {
      showSnackBar('Please enter your full name');
      return;
    }

    if (currentUserId.isEmpty) {
      showSnackBar('User not found. Please login again.');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await firestore.collection('users').doc(currentUserId).set({
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'phone': phone,
        'city': city,
        'address': address,
        'about': about,
        'profileImageUrl': profileImageUrl,
        'gender': selectedGender,
        'role': currentRole.isEmpty ? widget.role : currentRole,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final firebaseUser = firebaseAuth.currentUser;

      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(fullName);

        if (profileImageUrl.isNotEmpty) {
          await firebaseUser.updatePhotoURL(profileImageUrl);
        }
      }

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      await loadProfile();

      if (!mounted) return;

      showSnackBar('Profile updated successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
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
                'Logout',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      setState(() {
        isLoggingOut = true;
      });

      await firebaseAuth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  ImageProvider? getProfileImage() {
    final imageUrl = profileImageUrlController.text.trim();

    if (imageUrl.isEmpty) {
      return null;
    }

    return NetworkImage(imageUrl);
  }

  String cleanRole() {
    if (currentRole.isNotEmpty) return currentRole;
    return widget.role;
  }

  String roleImagePath() {
    final role = cleanRole().toLowerCase();

    if (role == 'admin') return 'assets/icons/admin.png';
    if (role == 'teacher') return 'assets/icons/teacher.png';
    if (role == 'parent') return 'assets/icons/parent.png';
    if (role == 'student') return 'assets/icons/student.png';

    return 'assets/icons/profile.png';
  }

  IconData roleIcon() {
    final role = cleanRole().toLowerCase();

    if (role == 'admin') return Icons.admin_panel_settings_outlined;
    if (role == 'teacher') return Icons.person_4_outlined;
    if (role == 'parent') return Icons.family_restroom_outlined;
    if (role == 'student') return Icons.school_outlined;

    return Icons.account_circle_outlined;
  }

  Widget rolePngIcon({
    required double size,
    required Color color,
  }) {
    return Image.asset(
      roleImagePath(),
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          roleIcon(),
          size: size,
          color: color,
        );
      },
    );
  }

  Widget profileHeader() {
    final imageProvider = getProfileImage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardBlueGradient,
        borderRadius: BorderRadius.circular(30),
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
            top: -38,
            right: -26,
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
            bottom: -44,
            left: -36,
            child: Container(
              height: 115,
              width: 115,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.white.withValues(alpha: 0.18),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? rolePngIcon(
                            size: 48,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fullNameController.text.trim().isEmpty
                    ? 'User Profile'
                    : fullNameController.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  cleanRole(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
    bool refreshHeader = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: refreshHeader
          ? (_) {
              setState(() {});
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget formSectionTitle({
    required String title,
    required IconData icon,
    required String imagePath,
  }) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  icon,
                  color: AppColors.primaryBlue,
                  size: 20,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget profileForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          formSectionTitle(
            title: 'Profile Information',
            icon: Icons.account_circle_outlined,
            imagePath: 'assets/icons/profile.png',
          ),
          const SizedBox(height: 18),
          profileField(
            controller: profileImageUrlController,
            label: 'Profile Image URL',
            hintText: 'Paste image link here',
            icon: Icons.image_outlined,
            keyboardType: TextInputType.url,
            refreshHeader: true,
          ),
          const SizedBox(height: 14),
          profileField(
            controller: fullNameController,
            label: 'Full Name',
            icon: Icons.badge_outlined,
            refreshHeader: true,
          ),
          const SizedBox(height: 14),
          profileField(
            controller: userNameController,
            label: 'Username',
            icon: Icons.alternate_email_outlined,
          ),
          const SizedBox(height: 14),
          profileField(
            controller: phoneController,
            label: 'Phone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          profileField(
            controller: cityController,
            label: 'City',
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 14),
          profileField(
            controller: addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.people_outline),
            ),
            items: genders.map((gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 14),
          profileField(
            controller: aboutController,
            label: 'About',
            hintText: 'Write something about yourself',
            icon: Icons.info_outline,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : updateProfile,
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
                isSaving ? 'Updating...' : 'Update Profile',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isLoggingOut ? null : logout,
              icon: isLoggingOut
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.logout_outlined,
                      color: AppColors.danger,
                    ),
              label: Text(
                isLoggingOut ? 'Logging out...' : 'Logout',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.danger,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingState() {
    return const Center(
      child: CircularProgressIndicator(),
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
            fontWeight: FontWeight.w600,
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
    String title = 'Profile';

    if (currentRole == 'Admin') title = 'Admin Profile';
    if (currentRole == 'Teacher') title = 'Teacher Profile';
    if (currentRole == 'Parent') title = 'Parent Profile';
    if (currentRole == 'Student') title = 'Student Profile';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadProfile,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? loadingState()
            : errorMessage != null
                ? errorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        profileHeader(),
                        const SizedBox(height: 18),
                        profileForm(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }
}