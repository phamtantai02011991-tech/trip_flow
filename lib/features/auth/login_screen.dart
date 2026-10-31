import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_text_field.dart';

/// Màn hình Đăng Nhập TripFlow:
/// - Phương thức chính: Đăng nhập nhanh qua Số điện thoại + Xác thực mã OTP SMS
/// - Phương thức phụ: Đăng nhập bằng Mật khẩu truyền thống cho Admin và tài khoản cũ
class LoginScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(text: 'traveler@tripflow.vn');
  final _passwordController = TextEditingController(text: 'User@123');

  bool _isPasswordMode = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'[\s\-\.\(\)\+]'), '');
    if (cleaned.startsWith('84') && cleaned.length == 11) {
      cleaned = '0${cleaned.substring(2)}';
    }
    return cleaned;
  }

  bool _isValidVnPhone(String phone) {
    final reg = RegExp(r'^0(3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$');
    return reg.hasMatch(phone);
  }

  Future<void> _handleSendOtpLogin() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập số điện thoại');
      return;
    }
    final normalized = _normalizePhone(rawPhone);
    if (!_isValidVnPhone(normalized)) {
      setState(() => _errorMessage =
          'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 03, 05, 07, 08, 09)');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.appState.sendPhoneOtp(phone: normalized);

      if (!mounted) return;

      if (res['success'] == true) {
        final debugOtp = res['debug_otp']?.toString() ?? '888999';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ??
                  'Mã xác thực OTP đã được gửi qua tin nhắn SMS!',
            ),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              appState: widget.appState,
              phone: normalized,
              debugOtp: debugOtp,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              res['message']?.toString() ?? 'Gửi mã OTP thất bại, vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handlePasswordLogin() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email');
      return;
    }

    widget.appState.loginUser(
      email: email,
      fullName: email.contains('admin') ? 'Nguyễn Quản Trị' : 'Hoàng Du Khách',
      phone: email.contains('admin') ? '0987654321' : '0901234567',
      isOtpVerified: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đăng nhập thành công với tài khoản $email!'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đăng Nhập Tài Khoản'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Center(
                child: Text(
                  'Chào Mừng Trở Lại',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Đăng nhập để đồng bộ lịch trình cá nhân và danh sách địa điểm yêu thích',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Chuyển đổi tab phương thức đăng nhập
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isPasswordMode = false;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isPasswordMode
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isPasswordMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Số điện thoại & OTP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !_isPasswordMode
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: !_isPasswordMode
                                    ? AppTheme.primaryTeal
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isPasswordMode = true;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isPasswordMode
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isPasswordMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Mật khẩu (Admin)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isPasswordMode
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _isPasswordMode
                                    ? AppTheme.primaryTeal
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form nhập liệu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isPasswordMode) ...[
                      // Đăng nhập bằng SĐT + OTP SMS
                      AuthTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại di động Việt Nam',
                        hintText: '0987 654 321',
                        isPhoneField: true,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Mã xác thực 6 số sẽ được gửi qua tin nhắn SMS sau khi bấm.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                              _isSubmitting ? null : _handleSendOtpLogin,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sms_rounded, size: 18),
                          label: Text(
                            _isSubmitting
                                ? 'Đang gửi...'
                                : 'Nhận mã OTP đăng nhập qua SMS',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Đăng nhập bằng Email & Password
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email đăng nhập',
                        hintText: 'traveler@tripflow.vn',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _handlePasswordLogin,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text(
                            'Đăng nhập với Mật khẩu',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Footer: Chưa có tài khoản -> Đăng ký ngay
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterScreen(appState: widget.appState),
                        ),
                      );
                    },
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),

              // Bỏ qua đăng nhập
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Tiếp tục với vai trò Khách (Guest Mode)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
