import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/services/auth_service.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEmailSelected = true; // Email is primary (focused)
  bool _isLoading = false;
  // Store generated OTP for demo
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
    _emailController.dispose();
    _phoneController.dispose();
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
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final contactInfo = _isEmailSelected
          ? _emailController.text.trim()
          : _phoneController.text.trim();

      // Check if account exists
      final accountExists = await AuthService().resetPassword(
        email: contactInfo,
      );

      if (!accountExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Tài khoản không tồn tại!'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
        return;
      }

      // Generate OTP for demo
      final generatedOTP = AppUtils.generateOTP(length: 6);

      // Print OTP to console/terminal for testing
      print('═══════════════════════════════════════════════════');
      print('🔐 OTP CODE FOR TESTING: $generatedOTP');
      print('═══════════════════════════════════════════════════');

      // Simulate sending reset code (mock)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Mã đặt lại đã được gửi đến $contactInfo\n(Xem terminal để lấy mã)',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        // Navigate to code verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(
              contactInfo: contactInfo,
              correctOTP: generatedOTP,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: Icon(icon, color: AppColors.accentBlue),
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
                const SizedBox(height: 20),
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
                                color: const Color.fromARGB(255, 32, 8, 244),
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
                                Icons.lock_reset,
                                size: 40,
                                color: AppColors.bgWhite,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quên Mật khẩu',
                          style: TextStyle(
                            color: Color.fromARGB(255, 20, 12, 252),
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Khối 2: Selection Area (email/phone choice) - animated fade in
                FadeTransition(
                  opacity: _formOpacity,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email input - Primary (focused, green border)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isEmailSelected
                                  ? const Color.fromARGB(255, 8, 20, 240)
                                  : AppColors.borderLight,
                              width: _isEmailSelected ? 2.0 : 1.0,
                            ),
                            color: _isEmailSelected
                                ? const Color.fromARGB(
                                    255,
                                    14,
                                    33,
                                    241,
                                  ).withOpacity(0.08)
                                : AppColors.bgWhite,
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onTap: () =>
                                setState(() => _isEmailSelected = true),
                            validator: (value) {
                              if (_isEmailSelected) {
                                if (value == null || value.isEmpty)
                                  return 'Vui lòng nhập email';
                                if (!AppUtils.isValidEmail(value))
                                  return 'Email không hợp lệ';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'example@mail.com',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Divider "or"
                        Center(
                          child: Text(
                            'hoặc',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 14, 14, 14),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phone input - Secondary (gray background)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            onTap: () =>
                                setState(() => _isEmailSelected = false),
                            validator: (value) {
                              if (!_isEmailSelected) {
                                if (value == null || value.isEmpty)
                                  return 'Vui lòng nhập số điện thoại';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Số điện thoại',
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

                const SizedBox(height: 32),

                // Khối 3: Action - Send button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 14, 29, 241),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
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
                          'Gửi mã',
                          style: TextStyle(
                            color: AppColors.bgWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Khối 4: Footer - navigation + social
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: Color.fromARGB(255, 17, 29, 249),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tiếp tục với',
                  style: TextStyle(
                    color: Color.fromARGB(255, 21, 21, 21),
                    fontSize: 14,
                  ),
                ),
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
