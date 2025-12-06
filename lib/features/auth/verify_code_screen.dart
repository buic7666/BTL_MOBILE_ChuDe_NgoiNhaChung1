import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String contactInfo; // email or phone that code was sent to
  final String correctOTP; // correct OTP code for validation

  const VerifyCodeScreen({Key? key, required this.contactInfo, required this.correctOTP}) : super(key: key);

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
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
    _codeController.dispose();
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

  Future<void> _handleConfirmCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Simulate verifying code (mock)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        // Check if entered OTP matches the correct OTP
        if (_codeController.text.trim() == widget.correctOTP) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Mã xác nhận chính xác! Vui lòng đặt mật khẩu mới.')),
          );
          // Navigate to reset password screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: widget.contactInfo),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✗ Mã xác nhận không chính xác! Vui lòng thử lại.')),
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
                              child: const Icon(Icons.verified_user, size: 40, color: AppColors.bgWhite),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quên Mật khẩu',
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

                // Khối 2: Code input area (animated fade in)
                FadeTransition(
                  opacity: _formOpacity,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info text
                        Center(
                          child: Text(
                            'Mã xác nhận đã được gửi đến\n${widget.contactInfo}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Code input - Primary (focused, green border)
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Vui lòng nhập mã xác nhận';
                            if (value.length < 4) return 'Mã phải có ít nhất 4 ký tự';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Nhập mã',
                            hintText: '○ ○ ○ ○',
                            filled: true,
                            fillColor: AppColors.accentBlue.withOpacity(0.08),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accentBlue, width: 2.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accentBlue, width: 2.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Khối 3: Action - Confirm button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleConfirmCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.bgWhite, strokeWidth: 2))
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(color: AppColors.bgWhite, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),

                const SizedBox(height: 20),

                // Khối 4: Footer - navigation + social
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
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
