// ignore_for_file: avoid_print

import '../../models/user_profile.dart';

class AuthService {
  // Mock implementation - sẽ được kết nối với Firebase sau
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _seedDemoUser();
  }

  // Seed a demo user for development convenience
  // Email: demo@demo.com  Password: demo123
  // This runs once when AuthService singleton is created
  void _seedDemoUser() {
    final demoEmail = 'demo@demo.com';
    if (!_userPasswords.containsKey(demoEmail)) {
      final now = DateTime.now();
      final demo = UserProfile(
        uid: 'demo_user_1',
        email: demoEmail,
        name: 'Demo User',
        avatar: null,
        phone: null,
        createdAt: now,
        updatedAt: now,
      );
      _users[demoEmail] = demo;
      _userPasswords[demoEmail] = 'demo123';
      print('Seeded demo user: $demoEmail / demo123');
    }
  }

  // (seeding is called from the private constructor)

  UserProfile? _currentUser;
  final Map<String, String> _userPasswords = {}; // email -> password
  final Map<String, UserProfile> _users = {}; // email -> UserProfile

  UserProfile? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  /// Đăng ký tài khoản mới (mock) - hỗ trợ email hoặc số điện thoại
  Future<bool> register({
    required String contact,
    required bool isEmail,
    required String password,
    required String name,
  }) async {
    try {
      // Simple in-memory registration for dev/testing
      if (_userPasswords.containsKey(contact)) {
        // already exists
        return false;
      }

      final now = DateTime.now();
      final user = UserProfile(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        email: isEmail ? contact : null,
        name: name,
        avatar: null,
        phone: !isEmail ? contact : null,
        createdAt: now,
        updatedAt: now,
      );
      _userPasswords[contact] = password;
      _users[contact] = user;
      _currentUser = user;
      print('Registered user (mock): $contact');
      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// Đăng nhập (mock) - hỗ trợ email hoặc số điện thoại
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      // If there is a registered user, validate password
      if (_userPasswords.containsKey(email)) {
        if (_userPasswords[email] == password) {
          _currentUser = _users[email];
          print('Login success (mock) for $email');
          return true;
        }
        return false;
      }

      // If no registered user, accept any valid-looking credentials as guest login
      if (email.isNotEmpty && password.length >= 6) {
        final now = DateTime.now();
        // Determine if email contains '@' to differentiate email vs phone
        final isEmail = email.contains('@');
        final user = UserProfile(
          uid: DateTime.now().millisecondsSinceEpoch.toString(),
          email: isEmail ? email : null,
          name: isEmail ? email.split('@').first : 'User',
          avatar: null,
          phone: !isEmail ? email : null,
          createdAt: now,
          updatedAt: now,
        );
        _currentUser = user;
        _users[email] = user;
        _userPasswords[email] = password;
        print('Login as new mock user: $email');
        return true;
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      _currentUser = null;
      print('User logged out');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// Đặt lại mật khẩu (mock) - kiểm tra tài khoản tồn tại
  Future<bool> resetPassword({required String email}) async {
    try {
      if (_userPasswords.containsKey(email)) {
        print('Password reset (mock) for: $email');
        return true;
      }
      return false;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  /// Cập nhật mật khẩu mới (sau khi xác minh OTP)
  Future<bool> updatePassword({required String email, required String newPassword}) async {
    try {
      if (!_userPasswords.containsKey(email)) {
        print('Email not found for password update: $email');
        return false;
      }
      _userPasswords[email] = newPassword;
      print('Password updated successfully for: $email');
      return true;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  /// Lấy user hiện tại
  Future<UserProfile?> getCurrentUser() async {
    try {
      return _currentUser;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
}