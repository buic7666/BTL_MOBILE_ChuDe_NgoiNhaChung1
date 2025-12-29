import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_utils.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController(); // email or phone
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isEmailMode = true;
  late final AnimationController _animController;
  late final AnimationController _logoController;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _formOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void dispose() {
    _animController.dispose();
    _logoController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerOffset =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
          ),
        );
    _headerOpacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _formOpacity = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );

    // Logo animation controller (repeating scale + fade)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoController.repeat(reverse: true);

    // start entrance animation
    _animController.forward();

    // detect email vs phone mode from contact field
    _contactController.addListener(() {
      final v = _contactController.text.trim();
      final nowEmail = v.contains('@');
      if (nowEmail != _isEmailMode) {
        setState(() {
          _isEmailMode = nowEmail;
        });
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final contactInfo = _contactController.text.trim();
      final isEmail = contactInfo.contains('@');
      if (isEmail) {
        final result = await _authService.register(
          contact: contactInfo,
          isEmail: true,
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Đăng ký thành công!'),
                backgroundColor: Color.fromARGB(255, 21, 6, 234),
              ),
            );
            Navigator.pop(context);
          } else {
            await _handleRegisterError(result['error'], contactInfo);
          }
        }
      } else {
        // Phone registration without OTP: require password and name
        final result = await _authService.register(
          contact: contactInfo,
          isEmail: false,
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Đăng ký bằng SĐT thành công!'),
                backgroundColor: Color.fromARGB(255, 21, 6, 234),
              ),
            );
            Navigator.pop(context);
          } else {
            await _handleRegisterError(result['error'], contactInfo);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegisterError(String? errorCode, String contactInfo) async {
    final code = errorCode ?? 'unknown';
    String errorMsg = '❌ Đăng ký thất bại! [$code]';
    if (code == 'weak-password') {
      errorMsg = '❌ Mật khẩu quá yếu (tối thiểu 6 ký tự)!';
    } else if (code == 'invalid-email') {
      errorMsg = '❌ Email không hợp lệ!';
    } else if (code == 'operation-not-allowed') {
      errorMsg = '❌ Chức năng đăng ký chưa được kích hoạt!';
    } else if (code == 'configuration-not-found') {
      errorMsg = '❌ Firebase chưa được cấu hình đúng!\nVui lòng bật Email/Password trong Firebase Console.';
    } else if (code == 'timeout') {
      errorMsg = '❌ Timeout! Kết nối Firebase quá chậm.';
    } else if (code == 'email-already-in-use') {
      await _showEmailInUseDialog(contactInfo);
      return;
    } else if (code == 'invalid-phone-number') {
      errorMsg = '❌ Số điện thoại không hợp lệ!';
    } else if (code == 'session-expired') {
      errorMsg = '❌ Mã OTP hết hạn, vui lòng thử lại!';
    } else if (code == 'quota-exceeded') {
      errorMsg = '❌ Vượt quá hạn mức SMS OTP!';
    }
    print('REGISTER ERROR: $code - Message: $errorMsg');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: const Color.fromARGB(255, 229, 57, 53),
        duration: const Duration(seconds: 5),
      ),
    );
  }
  Future<void> _showEmailInUseDialog(String email) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Email đã tồn tại'),
          content: Text(
            'Email $email đã được đăng ký. Bạn muốn đăng nhập hoặc gửi email đặt lại mật khẩu?',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Gửi email đặt lại mật khẩu
                final ok = await _authService.resetPassword(email: email);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Đã gửi email đặt lại mật khẩu tới $email'
                            : 'Gửi email đặt lại mật khẩu thất bại',
                      ),
                      backgroundColor: ok
                          ? const Color.fromARGB(255, 21, 208, 97)
                          : const Color.fromARGB(255, 229, 57, 53),
                    ),
                  );
                }
              },
              child: const Text('Gửi reset mật khẩu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Điều hướng sang màn hình đăng nhập
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.bgWhite,
        child: Icon(icon, color: const Color.fromARGB(255, 42, 13, 232)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.bgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Khối 1: Header (animated)
                const SizedBox(height: 6),
                SlideTransition(
                  position: _headerOffset,
                  child: FadeTransition(
                    opacity: _headerOpacity,
                    child: Column(
                      children: [
                        // Animated logo
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 42, 7, 237),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add,
                                size: 40,
                                color: AppColors.bgWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            color: Color.fromARGB(255, 59, 11, 235),
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tạo một tài khoản để bạn có thể đăng nhập',
                          style: TextStyle(
                            color: Color.fromARGB(255, 26, 15, 239),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Khối 2: Form area (fade in)
                FadeTransition(
                  opacity: _formOpacity,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field (optional)
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            hintText: 'Nhập họ tên của bạn',
                            filled: true,
                            fillColor: AppColors.bgWhite,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.borderLight,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 19, 11, 240),
                                width: 2.0,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập họ tên';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Contact field - email or phone (accepts both)
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập email hoặc số điện thoại';
                            }
                            // Basic validation: either email format or non-empty
                            final isEmail = value.contains('@');
                            if (isEmail && !AppUtils.isValidEmail(value)) {
                              return 'Email không hợp lệ';
                            }
                            if (!isEmail && value.length < 9) {
                              return 'Số điện thoại quá ngắn';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email hoặc Số điện thoại',
                            hintText: 'example@mail.com hoặc 0123456789',
                            filled: true,
                            fillColor: AppColors.bgWhite,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.borderLight,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 27, 11, 240),
                                width: 2.0,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password - yêu cầu cho cả email và số điện thoại
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                              if (!AppUtils.isValidPassword(value)) return 'Mật khẩu phải có ít nhất 6 ký tự';
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Mật khẩu',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Confirm password - yêu cầu cho cả email và số điện thoại
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                              if (value != _passwordController.text) return 'Mật khẩu không trùng khớp';
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Xác nhận mật khẩu',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Khối 3: Action - Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 10, 13, 241),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 6,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.bgWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Đăng ký',
                          style: TextStyle(
                            color: AppColors.bgWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Khối 4: Footer - navigation + social
                const SizedBox(height: 14),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      label: 'G',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      icon: Icons.facebook,
                      label: 'F',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _buildSocialButton(
                      icon: Icons.apple,
                      label: 'A',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
