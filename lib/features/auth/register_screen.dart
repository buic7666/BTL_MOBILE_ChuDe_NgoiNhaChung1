import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController(); // email or phone
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
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

    _headerOffset = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut)),
    );
    _headerOpacity = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _formOpacity = CurvedAnimation(parent: _animController, curve: const Interval(0.35, 1.0, curve: Curves.easeIn));

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
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final contactInfo = _contactController.text.trim();
      final isEmail = contactInfo.contains('@');
      
      final result = await _authService.register(
        contact: contactInfo,
        isEmail: isEmail,
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Đăng ký thành công!'),
              backgroundColor: Color.fromARGB(255, 21, 6, 234),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Đăng ký thất bại! Tài khoản đã tồn tại.'),
              backgroundColor: Color.fromARGB(255, 229, 57, 53),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton({required IconData icon, required String label, required VoidCallback onTap}) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                              child: const Icon(Icons.person_add, size: 40, color: AppColors.bgWhite),
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
                            borderSide: BorderSide(color: AppColors.borderLight, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 19, 11, 240), width: 2.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập họ tên';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Contact field - email or phone (accepts both)
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.text,
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
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email hoặc Số điện thoại',
                          hintText: 'example@mail.com hoặc 0123456789',
                          filled: true,
                          fillColor: AppColors.bgWhite,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderLight, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 27, 11, 240), width: 2.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password - gray background, no border
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Confirm password - gray background, no border
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 6,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.bgWhite, strokeWidth: 2))
                      : const Text(
                          'Đăng ký',
                          style: TextStyle(color: AppColors.bgWhite, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),

                const SizedBox(height: 20),

                // Khối 4: Footer - navigation + social
                const SizedBox(height: 14),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(icon: Icons.g_mobiledata, label: 'G', onTap: () {}),
                    const SizedBox(width: 12),
                    _buildSocialButton(icon: Icons.facebook, label: 'F', onTap: () {}),
                    const SizedBox(width: 12),
                    _buildSocialButton(icon: Icons.apple, label: 'A', onTap: () {}),
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
