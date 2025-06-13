import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../login/login_view.dart'; // تأكد من المسار الصحيح
import '../services/Api_services.dart'; // تأكد من المسار الصحيح
import '../login/New_password.dart'; // استيراد شاشة كلمة المرور الجديدة

class CodeVerification extends StatefulWidget {
  final String email;
  final String token;
  final bool isReset; // true for reset, false for registration
  final String? password; // كلمة المرور اختيارية هنا

  const CodeVerification({
    Key? key,
    required this.email,
    required this.token,
    required this.isReset,
    this.password,
  }) : super(key: key);

  @override
  State<CodeVerification> createState() => _CodeVerificationState();
}

class _CodeVerificationState extends State<CodeVerification> {
  static const int otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(otpLength, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(otpLength, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  static const double kVerticalSpaceSmall = 10.0; // تقليل قليل
  static const double kVerticalSpaceMedium = 18.0; // تقليل قليل
  static const double kVerticalSpaceLarge = 26.0; // تقليل قليل

  @override
  void initState() {
    super.initState();
    // ... (initState كما هو)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtpCode() async {
    final currentOtp = _otpCode;
    if (currentOtp.length != otpLength) {
      if (mounted)
        setState(() => _errorMessage = 'يرجى إدخال $otpLength أرقام');
      _clearOtpFields();
      if (mounted && _focusNodes.isNotEmpty)
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      return;
    }
    if (_focusNodes.isNotEmpty &&
        _focusNodes.length == otpLength &&
        _focusNodes[otpLength - 1].hasFocus) {
      _focusNodes[otpLength - 1].unfocus();
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      Map<String, dynamic> result;
      if (widget.isReset) {
        // Password reset flow - use verifyOtp
        result = await ApiService.verifyOtp(widget.token, currentOtp);
        print("[_verifyOtpCode] Password reset verification result: $result");
      } else {
        // Registration flow - use verifyEmailOtp
        result = await ApiService.verifyEmailOtp(widget.token, currentOtp);
        print("[_verifyOtpCode] Registration verification result: $result");
      }

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'تم التحقق بنجاح.')));
        if (widget.isReset) {
          // For password reset, we keep the same token from step 1
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(token: widget.token),
            ),
          );
        } else {
          // Registration: go to login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => LoginView(initialEmail: widget.email)),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        _clearOtpFields();
        if (mounted && _focusNodes.isNotEmpty) {
          FocusScope.of(context).requestFocus(_focusNodes[0]);
          setState(() => _errorMessage = result['message'] ?? 'فشل التحقق.');
        }
      }
    } catch (e) {
      print("[_verifyOtpCode] Error during verification: $e");
      _clearOtpFields();
      if (mounted && _focusNodes.isNotEmpty)
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      if (mounted)
        setState(() => _errorMessage =
            'حدث خطأ: ${e.toString().substring(0, min(100, e.toString().length))}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearOtpFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (!mounted) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      final resendResult = await ApiService.sendOtp(widget.email, 'email');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resendResult['message'] ??
              (resendResult['success']
                  ? 'تم إعادة الإرسال.'
                  : 'فشل إعادة الإرسال.'))));
      if (resendResult['success']) {
        _clearOtpFields();
        if (mounted && _focusNodes.isNotEmpty)
          FocusScope.of(context).requestFocus(_focusNodes[0]);
      } else {
        if (mounted)
          setState(() =>
              _errorMessage = resendResult['message'] ?? 'فشل إعادة الإرسال.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'خطأ في الشبكة.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // --- تعديلات هنا لمحاولة حل Overflow ---
    double horizontalPagePadding =
        screenWidth * 0.1; // Padding جانبي للصفحة (يمكن تقليله إذا لزم الأمر)
    double spaceBetweenBoxes = 8.0; // تقليل المسافة بين المربعات
    double totalSpacingForBoxes = spaceBetweenBoxes * (otpLength - 1);
    double availableWidthForOtp =
        screenWidth - horizontalPagePadding - totalSpacingForBoxes;
    double boxSize = availableWidthForOtp / otpLength;

    // وضع حدود أكثر تحفظًا لحجم المربع
    boxSize = min(boxSize, 45.0); // تقليل الحد الأقصى للمربع
    boxSize = max(boxSize, 35.0); // تقليل الحد الأدنى للمربع قليلاً

    double otpFontSize = boxSize * 0.5; // نسبة من حجم المربع للخط
    otpFontSize = min(otpFontSize, 18.0); // حد أقصى لحجم الخط
    otpFontSize = max(otpFontSize, 14.0); // حد أدنى لحجم الخط

    double boxHeight = boxSize + 5; // تعديل طفيف لارتفاع المربع

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text("التحقق من الرمز",
              style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, right: 16.0, left: 8.0),
            child: IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginView(
                            initialEmail: widget
                                .email, /*password: widget.password ?? ""*/
                          )), // مرر كلمة المرور
                  (Route<dynamic> route) => false,
                );
              },
              icon: Icon(Icons.arrow_forward_ios,
                  size: 28, color: Color(0xFF2C73D9)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPagePadding / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.03),
              Center(
                child: Image.asset(
                  "assets/images/pana.png",
                  width: screenWidth * 0.65,
                  height: screenHeight * 0.22,
                  fit: BoxFit.contain, // تصغير الصورة قليلاً
                  errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey),
                ),
              ),
              SizedBox(height: kVerticalSpaceMedium),
              Text("الرجاء إدخال رمز التحقق المكون من $otpLength أرقام",
                  style: TextStyle(
                      color: Color(0xFF2C73D9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center), // تصغير الخط قليلاً
              SizedBox(height: kVerticalSpaceMedium),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  // استخدام spaceEvenly لتوزيع المسافات تلقائيًا
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(otpLength, (index) {
                    // لا حاجة لـ Padding إضافي حول كل مربع هنا لأن spaceEvenly سيتولى الأمر
                    return Container(
                      width: boxSize,
                      height: boxHeight,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1)
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: otpFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        decoration: InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Color(0xFF0054A6), width: 1.5)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: EdgeInsets
                              .zero, // محاولة لإزالة أي padding داخلي إضافي
                        ),
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() {
                            _errorMessage = null;
                          });
                          if (value.isNotEmpty) {
                            if (index < otpLength - 1) {
                              _focusNodes[index].unfocus();
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[index + 1]);
                            } else {
                              _focusNodes[index].unfocus();
                              if (_otpCode.length == otpLength)
                                _verifyOtpCode();
                            }
                          } else {
                            if (index > 0) {
                              _focusNodes[index].unfocus();
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[index - 1]);
                            }
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                    padding: const EdgeInsets.only(top: kVerticalSpaceMedium),
                    child: Text(_errorMessage!,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center)),
              SizedBox(height: kVerticalSpaceLarge),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: ElevatedButton(
                  onPressed: _isLoading || _isResending ? null : _verifyOtpCode,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C73D9),
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24))),
                  child: _isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text("تحقق",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: kVerticalSpaceSmall),
              TextButton(
                onPressed: _isLoading || _isResending ? null : _resendOtp,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
                child: _isResending
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Color(0xFF007BFF))),
                        SizedBox(width: 8),
                        Text("جاري...",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14))
                      ])
                    : Text("لم تستلم الرمز؟ إعادة الإرسال",
                        style: TextStyle(
                            color: Color(0xFF2C73D9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
