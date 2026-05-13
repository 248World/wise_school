class AuthService {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Firebase Authentication login will be added later.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    // Firebase Authentication register will be added later.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    // Firebase password reset will be added later.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> logout() async {
    // Firebase logout will be added later.
    await Future.delayed(const Duration(milliseconds: 300));
  }
}