import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// Enum لتحديد اختيار المستخدم من النافذة
enum RetryOption { retry, cancel }

Future<RetryOption?> showAnalysisFailedPopup(BuildContext context) async {
  final AudioPlayer audioPlayer = AudioPlayer();

  audioPlayer.play(AssetSource('audio/error_sound.mp3')).catchError((error) {
    debugPrint("Failed to play analysis failure sound: $error");
  });

  return showDialog<RetryOption>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'فشل التحليل',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'فشل في تحليل الفيديو و حاول مره اخري ب فيديو بصيغة mp4', // تم تعديل النص ليتوافق مع الصورة
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          // --- *** هذا هو الجزء الذي تم تعديله *** ---
          actions: <Widget>[
            Column( // 1. نلف الأزرار في عمود
              crossAxisAlignment: CrossAxisAlignment.stretch, // 2. نجعل الأزرار تمتد بعرض العمود
              mainAxisSize: MainAxisSize.min, // ليأخذ العمود أقل مساحة ممكنة
              children: [
                // زر المحاولة مرة أخرى
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('المحاولة مرة أخرى', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2C73D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // لجعله أكثر دائرية
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(RetryOption.retry);
                  },
                ),
                const SizedBox(height: 8), // مسافة بين الزرين

                // زر الإلغاء
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(RetryOption.cancel);
                  },
                  child: const Text(
                    'إلغاء والعودة للرئيسية',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                ),
              ],
            )
          ],
          // --- *** نهاية الجزء المعدل *** ---
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        ),
      );
    },
  ).whenComplete(() {
    audioPlayer.dispose();
  });
}