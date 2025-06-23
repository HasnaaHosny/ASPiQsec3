import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:myfinalpro/sec3/home3.dart'; // <-- *** تغيير مهم: العودة إلى شاشة المهارات الاجتماعية ***
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class EndSocialSessionScreen extends StatefulWidget {
  const EndSocialSessionScreen({super.key});

  @override
  _EndSocialSessionScreenState createState() => _EndSocialSessionScreenState();
}

class _EndSocialSessionScreenState extends State<EndSocialSessionScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- *** هذا هو المنطق المنسوخ من EndTestScreen *** ---
  Future<void> _startCooldownAndNavigateBack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cooldownStartTimeMillis = DateTime.now().millisecondsSinceEpoch;
      // استخدم مفتاحًا فريدًا لهذه الشاشة
      await prefs.setInt('lastSocialSessionStartTime', cooldownStartTimeMillis);
      debugPrint("EndSocialSessionScreen: Cooldown timer started. Ref time saved: $cooldownStartTimeMillis");

      if (!mounted) return;

      // العودة إلى شاشة المهارات الاجتماعية وإزالة كل ما قبلها
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SocialSkillsScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error saving cooldown start time: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ في بدء مؤقت الانتظار.')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SocialSkillsScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff2C73D9);

    // لا حاجة لـ PopScope لأننا نستخدم pushAndRemoveUntil
    return Scaffold(
      backgroundColor: Color(0xff2C73D9),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              shouldLoop: false,
              colors: const [
                primaryColor, Colors.white, Colors.purple,
                Colors.yellow, Colors.green, Colors.redAccent
              ],
            ),
          ),
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_rounded, size: 60, color: primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'رائع! لقد أنهيت الجلسة بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  // استدعاء الدالة الجديدة عند الضغط
                  onPressed: _startCooldownAndNavigateBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text('العودة',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}