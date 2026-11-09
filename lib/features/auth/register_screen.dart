import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'widgets/auth_text_field.dart';

/// Màn hình Đăng Ký Tài Khoản bằng Họ và Tên + Số Điện Thoại di động Việt Nam.
/// Hệ thống gửi mã xác thực 6 số qua tin nhắn SMS tới số điện thoại này.
class RegisterScreen extends StatefulWidget {
  final TripFlowAppState appState;

  const RegisterScreen({super.key, required this.appState});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _agreedToTerms = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Chuẩn hóa số điện thoại: loại bỏ khoảng trắng, dấu cộng, chuyển đầu 84 thành 0
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

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản sử dụng của TripFlow!'),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
      return;
    }

    final fullName = _nameController.text.trim();
    final normalizedPhone = _normalizePhone(_phoneController.text.trim());

    setState(() => _isSubmitting = true);

    try {
      final res = await widget.appState.sendPhoneOtp(
        phone: normalizedPhone,
        fullName: fullName,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final debugOtp = res['debug_otp']?.toString();
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
              phone: normalizedPhone,
              fullName: fullName,
              debugOtp: debugOtp,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Gửi mã OTP thất bại, vui lòng thử lại.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo & Tiêu đề
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryTeal, Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withOpacity(0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Tham Gia TripFlow',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Đăng ký nhanh bằng Tên & Số điện thoại để nhận mã OTP qua SMS và đồng bộ lịch trình cá nhân',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Card Form Nhập liệu
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Họ và tên
                      AuthTextField(
                        controller: _nameController,
                        label: 'Họ và tên du khách',
                        hintText: 'VD: Nguyễn Văn Du Khách',
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên của bạn';
                          }
                          if (value.trim().length < 2) {
                            return 'Họ và tên phải có tối thiểu 2 ký tự';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Số điện thoại di động Việt Nam
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          final normalized = _normalizePhone(value.trim());
                          if (!_isValidVnPhone(normalized)) {
                            return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 03, 05, 07, 08, 09)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Ghi chú SMS OTP
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.sms_rounded,
                            size: 16,
                            color: Color(0xFF0D9488),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hệ thống sẽ gửi mã OTP gồm 6 chữ số qua tin nhắn SMS tới số này.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Checkbox Điều khoản dịch vụ
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: AppTheme.primaryTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (val) {
                                setState(() => _agreedToTerms = val ?? true);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tôi đồng ý với Điều khoản sử dụng & Chính sách bảo mật của TripFlow',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Nút "Nhận mã xác thực OTP qua SMS"
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _handleSendOtp,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sms_rounded, size: 20),
                          label: Text(
                            _isSubmitting
                                ? 'Đang gửi mã OTP...'
                                : 'Nhận mã xác thực OTP qua SMS',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Footer: Đã có tài khoản -> Đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(appState: widget.appState),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),

                // Tiếp tục với vai trò Khách (Guest Mode)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    label: const Text(
                      'Khám phá ngay không cần đăng nhập',
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
      ),
    );
  }
}
