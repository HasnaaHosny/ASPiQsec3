// lib/login/login_view.dart
import 'package:flutter/material.dart';
import 'package:myfinalpro/login/forgetPassword.dart';
import 'package:myfinalpro/registration/registration.dart'; // تأكدي من اسم الملف الصحيح
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/assessment_screen.dart';
import '../screens/home_screen.dart';

import '../services/Api_services.dart';
import '../widget/custom.dart';

class LoginView extends StatefulWidget {
  final String? initialEmail;

  const LoginView({
    super.key,
    this.initialEmail,
  });

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscureText = true;
  bool isSelected = false;
  bool isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    //  ******   طباعة عند بداية initState   ******
    print("[LoginView initState] >>> Constructor initialEmail: '${widget.initialEmail}'");
    //  ******************************************

    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      //  ******   طباعة بعد تعيين الكنترولر   ******
      print("[LoginView initState] >>> _emailController.text AFTER being set from initialEmail: '${_emailController.text}'");
      //  ******************************************
      // isSelected = true; // يمكنك تفعيل هذا إذا أردتِ
    } else {
      print("[LoginView initState] >>> initialEmail is null or empty, attempting to load saved email.");
      _loadSavedEmail(); // استدعاء تحميل الإيميل المحفوظ
    }
    print("[LoginView initState] >>> END of initState, _emailController.text is now: '${_emailController.text}'");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print("LoginView: Token only saved.");
    } catch (e) {
      print("LoginView: Error saving token: $e");
    }
  }

  Future<void> _saveUserDataAndImage(String token, String name, String email, String? imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await prefs.setString('user_image_url', imageUrl);
        print("LoginView: Image URL saved: $imageUrl");
      } else {
        await prefs.remove('user_image_url');
        print("LoginView: Image URL removed or not provided.");
      }
      print("LoginView: User data saved - Name: $name, Email: $email");
    } catch (e) {
      print("LoginView: Error saving user data and image: $e");
    }
  }

  Future<void> _loadSavedEmail() async {
    print("[LoginView _loadSavedEmail] >>> Attempting to load saved email from SharedPreferences.");
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      print("[LoginView _loadSavedEmail] >>> Fetched saved_email from prefs: '$savedEmail'");
      if (mounted && savedEmail != null) {
        // فقط قم بتعيين إذا لم يكن قد تم تعيينه بالفعل من initialEmail
        if (_emailController.text.isEmpty) {
           print("[LoginView _loadSavedEmail] >>> _emailController is empty, setting from savedEmail: '$savedEmail'");
          _emailController.text = savedEmail;
        } else {
          print("[LoginView _loadSavedEmail] >>> _emailController already has value: '${_emailController.text}', not overwriting with savedEmail.");
        }
        isSelected = true; // دائماً حدد "تذكرني" إذا كان هناك إيميل محفوظ
        if(mounted) setState(() {}); // تحديث الواجهة لإظهار التغيير في isSelected
      } else {
        print("[LoginView _loadSavedEmail] >>> No saved email found or widget not mounted.");
      }
    } catch (e) {
      print("LoginView: Error loading saved email: $e");
    }
  }

  Future<void> _login() async {
    if(isLoading) return;
    if (!mounted) return;

    setState(() { isLoading = true; _errorMessage = null; });

    try {
      final result = await ApiService.loginUser(
          _emailController.text.trim(),
          _passwordController.text
      );

      if (!mounted) return;

      if (result['success'] == true && result['token'] != null) {
        final String receivedToken = result['token'];
        final bool hasCompletedAssessment = result['hasCompletedAssessment'] ?? false;
        print("Login Successful. Token received. Has Completed Assessment: $hasCompletedAssessment");

        final profileResult = await ApiService.getUserProfile(receivedToken);
        if (!mounted) return;

        String fullName = "المستخدم";
        String userEmail = _emailController.text.trim();
        String? imageUrl;

        if (profileResult['success'] == true && profileResult['data'] != null && profileResult['data'] is Map) {
          final profileData = profileResult['data'] as Map<String, dynamic>;
          final String firstName = profileData['name'] ?? profileData['Name'] ?? '';
          final String lastName = profileData['surname'] ?? profileData['Surname'] ?? '';
          userEmail = profileData['email'] ?? profileData['Email'] ?? userEmail;
          imageUrl = profileData['image_url']?.toString() ?? profileData['Image_']?.toString() ?? profileData['profilePicture']?.toString();
          fullName = '$firstName $lastName'.trim();
          if (fullName.isEmpty) fullName = "مستخدم جديد";
          await _saveUserDataAndImage(receivedToken, fullName, userEmail, imageUrl);
        } else {
          print("Warning: Login successful, but failed to fetch/parse profile details: ${profileResult['message']}");
          await _saveToken(receivedToken);
        }

        if (isSelected) { // حفظ الإيميل إذا تم تحديد "تذكرني"
          try {
            final prefs = await SharedPreferences.getInstance();
            if (mounted) {
              await prefs.setString('saved_email', _emailController.text.trim());
              print("LoginView: Email saved for 'Remember Me'.");
            }
          } catch (e) {
            print("LoginView: Error saving email for 'Remember Me': $e");
          }
        } else { // إذا لم يتم تحديد "تذكرني"
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_email');
            print("LoginView: Saved email removed (Remember Me unchecked).");
          } catch (e) {
            print("LoginView: Error removing saved email: $e");
          }
        }

        if (!mounted) return;

        if (hasCompletedAssessment) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AssessmentScreen(jwtToken: receivedToken)),
                (Route<dynamic> route) => false,
          );
        }

      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'فشل تسجيل الدخول. تأكد من البريد وكلمة المرور.';
          });
        }
      }
    } catch (e, s) {
      print("Login View - General Error Catch: $e");
      print("Login View - Stacktrace: $s");
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع. تحقق من اتصالك بالإنترنت أو حاول مرة أخرى.';
        });
      }
    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    //  ******   طباعة قبل بناء حقل الإيميل   ******
    print("[LoginView build] >>> _emailController.text BEFORE CustomTextField: '${_emailController.text}'");
    //  *******************************************

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.1),
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: screenWidth * 0.5,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "تسجيل الدخول",
                  style: TextStyle(
                    color: Color(0xFF2C73D9),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  hintText: "أدخل البريد الإلكتروني",
                  obscureText: false,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'صيغة البريد الإلكتروني غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  hintText: "أدخل كلمة المرور",
                  obscureText: _obscureText,
                  controller: _passwordController,
                  suffixIcon: _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'كلمة المرور مطلوبة';
                    }
                    return null;
                  },
                ),
                Visibility(
                  visible: _errorMessage != null,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 5),
                    child: Text(
                      _errorMessage ?? '',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => setState(() { isSelected = !isSelected; }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24, height: 24,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() { isSelected = value ?? false; });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              activeColor: const Color(0xFF2C73D9),
                            ),
                          ),
                          const Text(
                            "تذكرني",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (!isLoading) {
                          Navigator.push( context, MaterialPageRoute( builder: (context) => const ForgetPassword()),);
                        }
                      },
                      child: const Text(
                        "هل نسيت كلمة المرور؟",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C73D9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C73D9),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    "تسجيل الدخول",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "لا تمتلك حساب؟",
                      style: TextStyle(
                        color: Color(0xFF4A4A4A),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        if (!isLoading) {
                          Navigator.push( context, MaterialPageRoute( builder: (context) => const RegistrationView()),);
                        }
                      },
                      child: const Text(
                        "أنشئ حساب جديد",
                        style: TextStyle(
                          color: Color(0xFF2C73D9),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}