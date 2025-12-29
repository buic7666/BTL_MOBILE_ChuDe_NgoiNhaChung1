// ignore_for_file: avoid_print
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;

  bool get isAuthenticated => _auth.currentUser != null;

  /// Firebase user (for Firebase integration) - trả về user với uid thật
  UserProfile? get currentFirebaseUser => _currentUser;

  /// Đăng ký tài khoản mới (mock) - hỗ trợ email hoặc số điện thoại
  Future<bool> register({
=======
  /// Đăng ký tài khoản mới với Firebase Authentication
  /// Returns: {'success': true/false, 'error': error_code_string}
  Future<Map<String, dynamic>> register({
    required String contact,
    required bool isEmail,
    required String password,
    required String name,
  }) async {
    try {
      String emailToUse = contact;
      String? phoneToSave;

      if (!isEmail) {
        // Support phone registration without OTP by aliasing to an internal email
        var v = contact.trim();
        if (!v.startsWith('+')) {
          if (v.startsWith('0')) {
            v = '+84${v.substring(1)}';
          }
        }
        phoneToSave = v;
        final normalizedDigits = v.replaceAll(RegExp(r"[^0-9+]"), "");
        emailToUse = "$normalizedDigits@phone.local";
        print('Registering phone as alias email: $emailToUse (phone: $phoneToSave)');
      } else {
        print('Starting register with email: $contact');
      }

      // Tạo tài khoản Firebase với timeout 30 giây
      final userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailToUse,
            password: password,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Register timeout after 30 seconds',
            ),
          );

      print('FirebaseAuth user created: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        final now = DateTime.now();
        final user = UserProfile(
          uid: userCredential.user!.uid,
          email: emailToUse,
          name: name,
          avatar: null,
          phone: phoneToSave,
          createdAt: now,
          updatedAt: now,
        );

        // Lưu thông tin user vào Firestore
        print('Saving user to Firestore...');
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.name,
          'avatar': user.avatar,
          'phone': user.phone,
          'createdAt': Timestamp.fromDate(user.createdAt),
          'updatedAt': Timestamp.fromDate(user.updatedAt),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException(
            'Firestore save timeout after 10 seconds',
          ),
        );

        print('Updating display name...');
        // Cập nhật display name
        await userCredential.user!.updateDisplayName(name);

        _currentUser = user;
        print('Registered user successfully: $contact');
        return {'success': true};
      }
      return {'success': false, 'error': 'user-not-created'};
    } on TimeoutException catch (e) {
      print('Register timeout: $e');
      return {'success': false, 'error': 'timeout'};
    } on FirebaseAuthException catch (e) {
      // Các mã lỗi phổ biến: email-already-in-use, invalid-email, weak-password
      print('Register FirebaseAuthException: ${e.code} - ${e.message}');
      return {'success': false, 'error': e.code};
    } catch (e) {
      print('Register error (unexpected): $e');
      print('Error type: ${e.runtimeType}');
      return {'success': false, 'error': 'unknown'};
    }
  }

  /// Bắt đầu xác thực số điện thoại: gửi mã OTP
  /// Returns: {success: true, verificationId: '...'} hoặc {success: false, error: '...'}
  Future<Map<String, dynamic>> startPhoneVerification({
    required String phone,
  }) async {
    try {
      final completer = Completer<Map<String, dynamic>>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final cred = await _auth.signInWithCredential(credential);
            if (cred.user != null) {
              completer.complete({'success': true, 'autoSignedIn': true});
            } else {
              completer.complete({'success': false, 'error': 'auto-signin-failed'});
            }
          } catch (e) {
            completer.complete({'success': false, 'error': 'auto-signin-exception'});
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.complete({'success': false, 'error': e.code});
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete({'success': true, 'verificationId': verificationId});
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // User will enter code manually
        },
      );
      return completer.future
          .timeout(const Duration(seconds: 70), onTimeout: () => {'success': false, 'error': 'timeout'});
    } catch (e) {
      print('startPhoneVerification error: $e');
      return {'success': false, 'error': 'unknown'};
    }
  }

  /// Xác nhận OTP và tạo hồ sơ người dùng trong Firestore
  Future<Map<String, dynamic>> confirmSmsCodeAndCreateProfile({
    required String verificationId,
    required String smsCode,
    required String name,
    required String phone,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user == null) {
        return {'success': false, 'error': 'user-not-created'};
      }

      final now = DateTime.now();
      final uid = userCred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': null,
        'name': name,
        'avatar': null,
        'phone': phone,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      await userCred.user!.updateDisplayName(name);

      _currentUser = UserProfile(
        uid: uid,
        email: null,
        name: name,
        avatar: null,
        phone: phone,
        createdAt: now,
        updatedAt: now,
      );
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      print('confirmSmsCode error: ${e.code}');
      return {'success': false, 'error': e.code};
    } catch (e) {
      print('confirmSmsCode unexpected error: $e');
      return {'success': false, 'error': 'unknown'};
    }
  }

  /// Xác nhận OTP để đăng nhập (không tạo hồ sơ mới nếu chưa có)
  Future<Map<String, dynamic>> confirmSmsCodeSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user == null) {
        return {'success': false, 'error': 'user-not-created'};
      }

      // Load profile if exists
      try {
        final doc = await _firestore.collection('users').doc(userCred.user!.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _currentUser = UserProfile(
            uid: data['uid'],
            email: data['email'],
            name: data['name'],
            avatar: data['avatar'],
            phone: data['phone'],
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          );
        } else {
          // Minimal in-memory profile
          final now = DateTime.now();
          _currentUser = UserProfile(
            uid: userCred.user!.uid,
            email: userCred.user!.email,
            name: userCred.user!.displayName ?? 'Người dùng',
            avatar: null,
            phone: null,
            createdAt: now,
            updatedAt: now,
          );
        }
      } catch (_) {
        // Ignore profile load errors, stay signed-in
      }
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      print('confirmSmsCodeSignIn error: ${e.code}');
      return {'success': false, 'error': e.code};
    } catch (e) {
      print('confirmSmsCodeSignIn unexpected error: $e');
      return {'success': false, 'error': 'unknown'};
    }
  }

  /// Tạo hồ sơ cho user đã đăng nhập sẵn (trường hợp auto verification)
  Future<bool> createProfileForSignedInUser({
    required String name,
    required String phone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final now = DateTime.now();
      final uid = DateTime.now().millisecondsSinceEpoch.toString();
      final user = UserProfile(
        uid: uid,
        email: isEmail ? contact : null,
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': null,
        'name': name,
        'avatar': null,
        'phone': phone,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      await user.updateDisplayName(name);
      _currentUser = UserProfile(
        uid: user.uid,
        email: null,
        name: name,
        avatar: null,
        phone: phone,
        createdAt: now,
        updatedAt: now,
      );
      _userPasswords[contact] = password;
      _users[contact] = user;
      _currentUser = user;
      
      // Lưu name vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': isEmail ? contact : null,
        'phone': !isEmail ? contact : null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      
      print('Registered user (mock): $contact');
      return true;
    } catch (e) {
      print('createProfileForSignedInUser error: $e');
      return false;
    }
  }

  /// Đăng nhập với Firebase Authentication
  Future<bool> login({required String email, required String password}) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        try {
          // Lấy thông tin user từ Firestore
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data()!;
            _currentUser = UserProfile(
              uid: data['uid'],
              email: data['email'],
              name: data['name'],
              avatar: data['avatar'],
              phone: data['phone'],
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              updatedAt: (data['updatedAt'] as Timestamp).toDate(),
            );
          } else {
            // Nếu chưa có trong Firestore, tạo mới
            final now = DateTime.now();
            _currentUser = UserProfile(
              uid: userCredential.user!.uid,
              email: email,
              name: userCredential.user!.displayName ?? email.split('@').first,
              avatar: null,
              phone: null,
              createdAt: now,
              updatedAt: now,
            );

            await _firestore
                .collection('users')
                .doc(_currentUser!.uid)
                .set({
              'uid': _currentUser!.uid,
              'email': _currentUser!.email,
              'name': _currentUser!.name,
              'avatar': _currentUser!.avatar,
              'phone': _currentUser!.phone,
              'createdAt': Timestamp.fromDate(_currentUser!.createdAt),
              'updatedAt': Timestamp.fromDate(_currentUser!.updatedAt),
            }, SetOptions(merge: true));
          }
        } on FirebaseException catch (fe) {
          // Nếu offline (code: unavailable), vẫn cho đăng nhập với thông tin tối thiểu
          if (fe.code == 'unavailable') {
            final now = DateTime.now();
            _currentUser = UserProfile(
              uid: userCredential.user!.uid,
              email: email,
              name: userCredential.user!.displayName ?? email.split('@').first,
              avatar: null,
              phone: null,
              createdAt: now,
              updatedAt: now,
            );
            print('Login succeeded but Firestore offline; continuing in offline mode.');
          } else {
            rethrow;
          }
        }
      // If no registered user, accept any valid-looking credentials as guest login
      if (email.isNotEmpty && password.length >= 6) {
        final now = DateTime.now();
        final uid = DateTime.now().millisecondsSinceEpoch.toString();
        // Determine if email contains '@' to differentiate email vs phone
        final isEmail = email.contains('@');
        final userName = isEmail ? email.split('@').first : 'User';
        final user = UserProfile(
          uid: uid,
          email: isEmail ? email : null,
          name: userName,
          avatar: null,
          phone: !isEmail ? email : null,
          createdAt: now,
          updatedAt: now,
        );
        _currentUser = user;
        _users[email] = user;
        _userPasswords[email] = password;
        
        // Lưu name vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': userName,
          'email': isEmail ? email : null,
          'phone': !isEmail ? email : null,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
        
        print('Login as new mock user: $email');
        print('Login success for $email');
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
      await _auth.signOut();
      _currentUser = null;
      print('User logged out');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<bool> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
      return true;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }

  /// Cập nhật mật khẩu mới (yêu cầu user đã đăng nhập)
  Future<bool> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return false;
      }

      await user.updatePassword(newPassword);
      print('Password updated successfully');
      return true;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  /// Lấy user hiện tại từ Firestore
  Future<UserProfile?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      if (_currentUser != null) {
        return _currentUser;
      }

      // Lấy từ Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _currentUser = UserProfile(
          uid: data['uid'],
          email: data['email'],
          name: data['name'],
          avatar: data['avatar'],
          phone: data['phone'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
        return _currentUser;
      }

      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
}
