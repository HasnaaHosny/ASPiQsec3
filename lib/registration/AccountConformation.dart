import 'package:flutter/material.dart';
import 'package:myfinalpro/enums.dart';
// تأكدي من أن هذا هو المسار الصحيح لملف CodeVerification
import 'Code verification.dart'; // <<--- المسار الصحيح لـ CodeVerification
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/login/login_view.dart'; // استيراد للرجوع للوجن
import 'dart:math';

class AccountConformation extends StatefulWidget {
  final String email;
  final String? phone; // الهاتف اختياري

  const AccountConformation({
    super.key,
    required this.email,
    this.phone,
  });

  @override
  State<AccountConformation> createState() => _AccountConformationState();
}

class _AccountConformationState extends State<AccountConformation> {
  ConfirmationMethod? _selectedMethod;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendOtp(ConfirmationMethod method) async {
    if (_isLoading) return;

    print(
        "[AccountConformation _sendOtp] --- Entered function for method: $method ---");
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedMethod = method;
    });

    String? identifier;
    String apiMethodTypeForPayload; // هذا للـ payload الخاص بـ Send-OTP

    if (method == ConfirmationMethod.email) {
      identifier = widget.email;
      apiMethodTypeForPayload = 'email'; // الـ API يتوقع 'email' كـ type
      print("[AccountConformation _sendOtp] >>> Using EMAIL: '$identifier'");
    } else if (method == ConfirmationMethod.phone) {
      identifier = widget.phone;
      apiMethodTypeForPayload =
          'sms'; // افترض أن الـ API يتوقع 'sms' أو 'phone' للـ type
      print("[AccountConformation _sendOtp] >>> Using PHONE: '$identifier'");
      if (identifier == null || identifier.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "رقم الهاتف غير متوفر لاختيار هذا الخيار.";
            _selectedMethod = null;
          });
        }
        return;
      }
    } else {
      // Should not happen
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "طريقة تحقق غير معروفة.";
          _selectedMethod = null;
        });
      }
      return;
    }

    if (identifier == null || identifier.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = method == ConfirmationMethod.phone
              ? "رقم الهاتف غير متوفر"
              : "البريد الإلكتروني غير متوفر";
          _selectedMethod = null;
        });
      }
      return;
    }

    try {
      print(
          "[AccountConformation _sendOtp] >>> Calling ApiService.sendOtp with identifier: '$identifier', type: '$apiMethodTypeForPayload'");
      final result =
          await ApiService.sendOtp(identifier, apiMethodTypeForPayload);
      print(
          "[AccountConformation _sendOtp] <<< ApiService.sendOtp result: $result");

      if (!mounted) {
        print(
            "[AccountConformation _sendOtp] !! Widget not mounted after API call.");
        return;
      }

      if (result['success']) {
        String? tempOtpToken; // هذا هو التوكن المؤقت لـ verifyEmailOtp
        if (method == ConfirmationMethod.email) {
          // التوكن المؤقت حاليًا يُرجع فقط مع الإيميل
          tempOtpToken = result['token'];
          if (tempOtpToken == null || tempOtpToken.isEmpty) {
            print(
                "[AccountConformation _sendOtp] !! CRITICAL: Token is null/empty from API on successful email OTP send.");
            throw Exception(
                'Token was not returned by the API upon successful OTP send for email.');
          }
          print(
              "[AccountConformation _sendOtp] >>> Temporary OTP Token (for email verification) received: $tempOtpToken");
        }
        // otpReference قد يكون مفيدًا إذا كان API الهاتف يستخدم نظام مرجعي مختلف
        // String? otpReference = result['data']?['reference'];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CodeVerification(
                token: tempOtpToken ?? '',
                email: widget.email,
                isReset: false,
              ),
            ),
          );
        }
      } else {
        print(
            "[AccountConformation _sendOtp] !! API sendOtp FAILED: ${result['message']}");
        if (mounted) {
          setState(() {
            _errorMessage =
                result['message'] ?? 'فشل إرسال الرمز. حاول مرة أخرى.';
            _selectedMethod = null;
          });
        }
      }
    } catch (e) {
      print("[AccountConformation _sendOtp] !! EXCEPTION caught: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "حدث خطأ: ${e.toString().substring(0, min(e.toString().length, 100))}"; // عرض جزء من الخطأ
          _selectedMethod = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    bool canUsePhone = widget.phone != null && widget.phone!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Text(
            "تأكيد الحساب",
            style: TextStyle(
              color: Color(0xFF2C73D9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: IconButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        // الرجوع إلى شاشة تسجيل الدخول عند الضغط على السهم
                        print(
                            "[AccountConformation AppBar] Back button pressed -> Navigating to LoginView");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginView(
                                  initialEmail: widget
                                      .email)), // يمكن تمرير الإيميل هنا أيضًا
                          (Route<dynamic> route) => false,
                        );
                      },
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  size: 40,
                  color: Color(0xFF2C73D9),
                )),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.05),
            Center(
              child: Image.asset(
                "assets/images/Group 1171275992.png",
                width: screenWidth * 0.8,
                height: screenHeight * 0.29,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // معالجة خطأ تحميل الصورة
                  print("Error loading image Group 1171275992.png: $error");
                  return Icon(Icons.image_not_supported,
                      size: 100, color: Colors.grey);
                },
              ),
            ),
            SizedBox(
              height: screenHeight * 0.07,
            ),
            Text(
              "كيف تفضل تأكيد الحساب؟",
              style: TextStyle(
                color: Color(0xFF2C73D9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: screenHeight * 0.02,
            ),
            InkWell(
              onTap: (_isLoading && _selectedMethod != ConfirmationMethod.email)
                  ? null
                  : () => _sendOtp(ConfirmationMethod.email),
              child: Opacity(
                opacity:
                    _isLoading && _selectedMethod != ConfirmationMethod.email
                        ? 0.5
                        : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedMethod == ConfirmationMethod.email
                              ? Colors.blue
                              : Colors.transparent,
                          border: Border.all(
                              color: _selectedMethod == ConfirmationMethod.email
                                  ? Colors.blue
                                  : Color(0xFF2C73D9),
                              width: 2),
                        ),
                        child: _selectedMethod == ConfirmationMethod.email
                            ? Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "عبر البريد الإلكتروني",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.002),
                            Text(
                              widget.email,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2C73D9),
                            ),
                          ),
                          if (_isLoading &&
                              _selectedMethod == ConfirmationMethod.email)
                            SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          else
                            Icon(
                              Icons.alternate_email,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * 0.02,
            ),
            InkWell(
              onTap: (!canUsePhone ||
                      (_isLoading &&
                          _selectedMethod != ConfirmationMethod.phone))
                  ? null
                  : () => _sendOtp(ConfirmationMethod.phone),
              child: Opacity(
                opacity: !canUsePhone ||
                        (_isLoading &&
                            _selectedMethod != ConfirmationMethod.phone)
                    ? 0.5
                    : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedMethod == ConfirmationMethod.phone
                              ? Colors.blue
                              : Colors.transparent,
                          border: Border.all(
                              color: !canUsePhone
                                  ? Colors.grey
                                  : (_selectedMethod == ConfirmationMethod.phone
                                      ? Colors.blue
                                      : Color(0xFF2C73D9)),
                              width: 2),
                        ),
                        child: _selectedMethod == ConfirmationMethod.phone
                            ? Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              " عبر رقم الهاتف",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color:
                                    !canUsePhone ? Colors.grey : Colors.black,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.002),
                            Text(
                              canUsePhone
                                  ? widget.phone!
                                  : "رقم الهاتف غير متاح",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !canUsePhone
                                  ? Colors.grey
                                  : Color(0xFF2C73D9),
                            ),
                          ),
                          if (_isLoading &&
                              _selectedMethod == ConfirmationMethod.phone)
                            SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          else
                            Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
