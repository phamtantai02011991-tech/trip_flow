import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_state.dart';
import 'widgets/sms_notification_banner.dart';

/// Màn hình Nhập Mã Xác Thực OTP 6 Chữ Số gửi qua tin nhắn SMS.
/// Thiết kế 6 ô tách rời (46x54), tự động chuyển focus, hỗ trợ auto-fill từ banner SMS và đếm ngược 60s.
class OtpVerificationScreen extends StatefulWidget {
  final TripFlowAppState appState;
  final String phone;
  final String? fullName;
  final String? debugOtp;

  const OtpVerificationScreen({
    super.key,
    required this.appState,
    required this.phone,
    this.fullName,
    this.debugOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());
  final List<FocusNode> _keyboardFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  Timer? _timer;
  int _countdownSeconds = 60;
  bool _canResend = false;
  bool _isSubmitting = false;
  String? _currentDebugOtp;
  bool _showSmsBanner = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentDebugOtp = widget.debugOtp;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyboardFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdownSeconds = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
          _canResend = true;
        });
      }
    });
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  /// Ẩn số điện thoại: ví dụ 0987654321 -> 098 •••• 321
  String _maskedPhone(String phone) {
    if (phone.length >= 10) {
      final prefix = phone.substring(0, 3);
      final suffix = phone.substring(phone.length - 3);
      return '$prefix •••• $suffix';
    }
    return phone;
  }

  String _getEnteredOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void _applyOtp(String otp) {
    final clean = otp.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < _otpLength; i++) {
      if (i < clean.length) {
        _controllers[i].text = clean[i];
      } else {
        _controllers[i].text = '';
      }
    }
    if (clean.length >= _otpLength) {
      _focusNodes[_otpLength - 1].unfocus();
    } else if (clean.isNotEmpty) {
      _focusNodes[clean.length.clamp(0, _otpLength - 1)].requestFocus();
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.appState.sendPhoneOtp(
        phone: widget.phone,
        fullName: widget.fullName,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final newOtp = res['debug_otp']?.toString() ?? '888999';
        setState(() {
          _currentDebugOtp = newOtp;
          _showSmsBanner = true;
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ??
                  'Mã xác thực OTP mới đã được gửi qua SMS!',
            ),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Gửi lại mã OTP thất bại.',
            ),
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

  Future<void> _handleVerify() async {
    final otpCode = _getEnteredOtp();
    if (otpCode.length < _otpLength) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đủ $_otpLength chữ số mã OTP.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.appState.verifyOtpAndLogin(
        phone: widget.phone,
        otpCode: otpCode,
        fullName: widget.fullName,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Xác thực OTP thành công! Chào mừng ${widget.appState.userName}',
            ),
            backgroundColor: AppTheme.primaryTeal,
            duration: const Duration(seconds: 3),
          ),
        );

        // Quay trở lại màn hình trước hoặc màn hình gốc
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _errorMessage = res['message']?.toString() ??
              'Mã OTP không chính xác. Vui lòng kiểm tra lại tin nhắn SMS.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi xác thực: $e';
        });
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
        title: const Text('Xác Thực Mã OTP SMS'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner tin nhắn SMS mô phỏng giúp test và trải nghiệm dễ dàng
              if (_showSmsBanner &&
                  _currentDebugOtp != null &&
                  _currentDebugOtp!.isNotEmpty)
                SmsNotificationBanner(
                  phone: widget.phone,
                  otpCode: _currentDebugOtp!,
                  onAutoFillPressed: () => _applyOtp(_currentDebugOtp!),
                  onDismiss: () => setState(() => _showSmsBanner = false),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // Icon minh họa tin nhắn SMS
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF99F6E4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppTheme.primaryTeal,
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Xác Thực Mã OTP SMS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Mã xác thực gồm 6 chữ số đã được gửi qua tin nhắn SMS tới số điện thoại:\n',
                            ),
                            TextSpan(
                              text: _maskedPhone(widget.phone),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Cụm 6 ô nhập mã OTP tách rời
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_otpLength, (index) {
                        return SizedBox(
                          width: 46,
                          height: 54,
                          child: RawKeyboardListener(
                            focusNode: _keyboardFocusNodes[index],
                            onKey: (event) {
                              if (event is RawKeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.backspace) {
                                if (_controllers[index].text.isEmpty &&
                                    index > 0) {
                                  _controllers[index - 1].clear();
                                  _focusNodes[index - 1].requestFocus();
                                }
                              }
                            },
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null
                                        ? Colors.redAccent
                                        : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryTeal,
                                    width: 2.2,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val.isNotEmpty) {
                                  if (index < _otpLength - 1) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    _focusNodes[index].unfocus();
                                    _handleVerify();
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),

                    // Báo lỗi nếu có
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Đồng hồ đếm ngược 60s & Nút gửi lại
                    Center(
                      child: _canResend
                          ? TextButton.icon(
                              onPressed:
                                  _isSubmitting ? null : _handleResendOtp,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: AppTheme.primaryTeal,
                              ),
                              label: const Text(
                                'Gửi lại mã OTP qua tin nhắn SMS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Gửi lại mã sau ${_formatTimer(_countdownSeconds)}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 28),

                    // Nút xác nhận & Hoàn tất
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
                        onPressed: _isSubmitting ? null : _handleVerify,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          _isSubmitting
                              ? 'Đang xác thực...'
                              : 'Xác Nhận & Hoàn Tất',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Đổi số điện thoại khác
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Đổi số điện thoại khác',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
