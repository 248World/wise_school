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

      final userDoc = await firestore.collection('users').doc(currentUserId).get();

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

  Widget profileHeader() {
    final imageProvider = getProfileImage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryBlue,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(
                    Icons.person_outline,
                    color: AppColors.white,
                    size: 48,
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            fullNameController.text.trim().isEmpty
                ? 'User Profile'
                : fullNameController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            currentRole.isEmpty ? widget.role : currentRole,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(
                color: AppColors.textGrey,
              ),
            ),
          ],
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

  Widget profileForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
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
            value: selectedGender,
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