// lib/services/sucess_popup.dart
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // <-- إضافة استيراد audioplayers

// التعريف لا يزال يقبل 3 وسائط
void showSuccessPopup(
  BuildContext context,
  ConfettiController confettiController,
  VoidCallback onNext,
) {
  // --- إضافة: إنشاء مشغل الصوت ---
  final AudioPlayer audioPlayer = AudioPlayer();
  // --- نهاية الإضافة ---

  try {
    confettiController.play();
    print("Playing confetti from showSuccessPopup");

    // --- إضافة: تشغيل الصوت هنا ---
    // تأكد أن المسار 'audio/success_sound.mp3' (أو اسم ملفك) صحيح
    // وأن الملف موجود في assets/audio/
    // وأن assets/audio/ معرفة في pubspec.yaml
    audioPlayer.play(AssetSource('audio/bravo.mp3')).catchError((error) { // <--- استخدم اسم ملف الصوت الصحيح
      print("Error playing sound from popup: $error");
    });
    // --- نهاية الإضافة ---

  } catch (e) {
    print("Warning: Could not play confetti or sound (controller might be disposed): $e");
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success Popup',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero, // لإزالة الـ padding الافتراضي
          content: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter, // لمحاذاة الـ confetti للأعلى
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: pi / 2, // من الأسفل للأعلى
                  shouldLoop: false, // لا تكرر
                  colors: const [
                    Colors.green, Colors.blue, Colors.pink,
                    Colors.orange, Colors.purple, Colors.yellow
                  ],
                  gravity: 0.1, // جاذبية خفيفة للقصاصات
                  numberOfParticles: 25, // عدد القصاصات
                  emissionFrequency: 0.05, // تردد الانبعاث
                  createParticlePath: (size) {
                    final path = Path();
                    path.addRect(Rect.fromLTWH(-5, -5, 10, 10)); // قصاصات مربعة
                    return path;
                  },
                  particleDrag: 0.05, // مقاومة الهواء
                  maxBlastForce: 8, // أقصى قوة للانفجار
                  minBlastForce: 4, // أدنى قوة للانفجار
                ),
              ),
              SizedBox(
                height: 260, // ارتفاع محتوى الـ AlertDialog
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉 برافو',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2C73D9)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2C73D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(180, 50),
                        elevation: 5,
                      ),
                      onPressed: () {
                        print("Popup 'Next' button pressed.");
                        // --- إضافة: إيقاف الصوت عند الضغط على التالي (اختياري) ---
                        audioPlayer.stop();
                        // --- نهاية الإضافة ---
                        Navigator.of(context).pop(); // أغلق النافذة الحالية
                        onNext(); // استدعاء دالة onNext
                      },
                      child: const Text('التالي',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  ).whenComplete(() {
    print("Success Popup closed (whenComplete).");
    try {
      if (confettiController.state == ConfettiControllerState.playing) {
        confettiController.stop();
        print("Stopped confetti on popup close.");
      }
    } catch (e) {
      print("Couldn't stop confetti on popup close (already disposed?).");
    }
    // --- إضافة: التخلص من مشغل الصوت عند إغلاق النافذة ---
    audioPlayer.dispose();
    print("Disposed audio player from popup.");
    // --- نهاية الإضافة ---
  });
}