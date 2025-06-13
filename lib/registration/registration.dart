import 'package:flutter/material.dart';
import 'package:myfinalpro/login/login_view.dart';
import 'package:myfinalpro/registration/create Account.dart'; // Correct path

import '../widget/custom.dart'; // Assuming CustomTextField is here

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  bool _obscureText = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- Password Strength State ---
  double _passwordStrengthScore =
      0.0; // Score from 0 to 5 (number of criteria met)

  // --- UI Constants ---
  static const double kSpacingXs = 4.0;
  static const double kSpacingSmall = 8.0;
  static const double kSpacingMedium = 16.0;
  static const double kSpacingLarge = 24.0;
  static const double kSpacingXLarge = 32.0;
  static const double kSpacingXXLarge = 40.0;

  static const Color kPrimaryColor = Color(0xFF2C73D9);
  static const Color kTextColor = Color(0xFF4A4A4A);
  static final Color kPasswordRequirementTextColor = Colors.grey.shade700;
  static const Color kBorderColor = Colors.grey;

  static const Color kPasswordStrengthWeak = Colors.red;
  static const Color kPasswordStrengthMedium = Colors.orange;
  static const Color kPasswordStrengthStrong = Colors.green;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_calculatePasswordStrengthScore);
  }

  void _calculatePasswordStrengthScore() {
    String password = _passwordController.text;
    double score = 0;

    if (password.isEmpty) {
      setState(() {
        _passwordStrengthScore = 0;
      });
      return;
    }

    if (password.length >= 8) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;

    setState(() {
      _passwordStrengthScore = score;
      // print("Password: $password, Score: $_passwordStrengthScore"); // يمكنك إبقاء هذا للتحقق
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  String? _validatePasswordOnSubmit(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
    if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return 'يجب أن تحتوي على حرف كبير واحد على الأقل (A-Z)';
    if (!RegExp(r'[a-z]').hasMatch(value))
      return 'يجب أن تحتوي على حرف صغير واحد على الأقل (a-z)';
    if (!RegExp(r'[0-9]').hasMatch(value))
      return 'يجب أن تحتوي على رقم واحد على الأقل (0-9)';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value))
      return 'يجب أن تحتوي على رمز خاص واحد على الأقل (!@#\$%^&*)';
    return null;
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(now.year - 12, now.month, now.day);
    final DateTime maxDate = DateTime(now.year - 6, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kTextColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = "${picked.year.toString().padLeft(4, '0')}-"
            "${picked.month.toString().padLeft(2, '0')}-"
            "${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _navigateToCreateAccount() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> collectedUserData = {
        'name_': _nameController.text.trim(),
        'surname': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'birthDate': _selectedDate?.toUtc().toIso8601String(),
        'password': _passwordController.text,
      };
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CreateAccount(initialUserData: collectedUserData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تصحيح الأخطاء في النموذج')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: screenWidth * 0.1),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          "assets/images/logo.png",
                          width: screenWidth * 0.4,
                          height: screenHeight * 0.18,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_right_outlined,
                          size: kSpacingXXLarge,
                          color: kPrimaryColor,
                        ))
                  ],
                ),
                const Text(
                  "إنشاء حساب",
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kBorderColor, width: 2),
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.1,
                      height: 2,
                      color: kBorderColor,
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kPrimaryColor, width: 2),
                          ),
                        ),
                        Container(
                          width: screenWidth * 0.024,
                          height: screenWidth * 0.024,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingLarge),

                CustomTextField(
                  hintText: "ادخل اسم الطفل بالكامل",
                  obscureText: false,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم الطفل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: kSpacingMedium),

                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: AbsorbPointer(
                    child: CustomTextField(
                      hintText: "ادخل تاريخ ميلاد الطفل (6-12 سنة)",
                      obscureText: false,
                      controller: _birthDateController,
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال تاريخ الميلاد';
                        }
                        if (_selectedDate == null) {
                          return 'يرجى اختيار تاريخ الميلاد';
                        }
                        final DateTime now = DateTime.now();
                        final int age = now.year - _selectedDate!.year;
                        if (age < 6 || age > 12) {
                          return 'يجب أن يكون عمر الطفل بين 6 و 12 سنة';
                        }
                        return null;
                      },
                      suffixIcon: Icons.calendar_today,
                    ),
                  ),
                ),
                const SizedBox(height: kSpacingMedium),

                CustomTextField(
                  hintText: "ادخل اسم المستخدم (للأب/الأم)",
                  obscureText: false,
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المستخدم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: kSpacingMedium),

                CustomTextField(
                  hintText: "ادخل البريد الالكتروني",
                  obscureText: false,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: kSpacingMedium),

                CustomTextField(
                  hintText: "أدخل كلمة المرور",
                  obscureText: _obscureText,
                  controller: _passwordController,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  validator: _validatePasswordOnSubmit,
                ),
                const SizedBox(height: kSpacingXs),

                // --- Password Strength Indicator ---
                if (_passwordController.text.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: kSpacingSmall),
                    child: Row(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            decoration: BoxDecoration(
                              // ****** تعديل مهم هنا ******
                              color: index < _passwordStrengthScore
                                  ? (_passwordStrengthScore >= 4
                                      ? kPasswordStrengthStrong
                                      : (_passwordStrengthScore >= 2
                                          ? kPasswordStrengthMedium
                                          : kPasswordStrengthWeak))
                                  : Colors.grey[300],
                              // ****** نهاية التعديل ******
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                // --- End Password Strength Indicator ---

                const SizedBox(height: kSpacingSmall),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: kSpacingSmall),
                  child: Text(
                    "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل، وتشمل: حرفًا كبيرًا (A–Z)، حرفًا صغيرًا (a–z)، رقمًا (0–9)، ورمزًا خاصًا (مثل:!@#\$٪^&*).",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: kPasswordRequirementTextColor,
                      height: 1.4,
                    ),
                    softWrap: true,
                  ),
                ),

                const SizedBox(height: kSpacingLarge + kSpacingSmall),

                ElevatedButton(
                  onPressed: _navigateToCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kSpacingMedium),
                    ),
                  ),
                  child: const Text(
                    "التالي",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: kSpacingLarge),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginView()),
                        );
                      },
                      child: const Text(
                        " قم بتسجيل الدخول",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      " هل لديك حساب بالفعل ؟ ",
                      style: TextStyle(
                        color: kTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.removeListener(_calculatePasswordStrengthScore);
    _nameController.dispose();
    _birthDateController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
