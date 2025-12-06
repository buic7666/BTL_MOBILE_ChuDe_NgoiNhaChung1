import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // email for which password is being reset

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
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
    _newPasswordController.dispose();
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newPassword = _newPasswordController.text.trim();
      
      // Update password in AuthService
      final success = await AuthService().updatePassword(
        email: widget.email,
        newPassword: newPassword,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Lỗi khi cập nhật mật khẩu! Vui lòng thử lại.'),
              backgroundColor: Color.fromARGB(255, 229, 57, 53),
            ),
          );
        }
        return;
      }

      // Simulate saving password (mock delay)
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Mật khẩu đã được đặt lại thành công!'),
            backgroundColor: Color.fromARGB(255, 56, 142, 60),
          ),
        );
        // Navigate back to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                                color: AppColors.accentBlue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.lock_outline, size: 40, color: AppColors.bgWhite),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Đặt Mật khẩu Mới',
                          style: TextStyle(
                            color: AppColors.accentBlue,
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

                // Khối 2: Form area (animated fade in)
                FadeTransition(
                  opacity: _formOpacity,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New password field - focused green border
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_showNewPassword,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                            if (!AppUtils.isValidPassword(value)) return 'Mật khẩu phải có ít nhất 6 ký tự';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới',
                            hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
                            filled: true,
                            fillColor: AppColors.accentBlue.withOpacity(0.08),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showNewPassword ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accentBlue, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accentBlue, width: 2.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field - gray background, no border
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                              if (value != _newPasswordController.text) return 'Mật khẩu không trùng khớp';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Xác nhận mật khẩu mới',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Khối 3: Action - Reset button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.bgWhite, strokeWidth: 2))
                      : const Text(
                          'Đặt lại mật khẩu',
                          style: TextStyle(color: AppColors.bgWhite, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),

                const SizedBox(height: 20),

                // Khối 4: Footer - login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Nhớ mật khẩu? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tiếp tục với',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
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
