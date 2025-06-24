// lib/sec3/test/analysis_failed_popup.dart

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// Enum لتحديد اختيار المستخدم من النافذة
enum RetryOption { retry, cancel }

// --- *** تم تعديل الدالة لتقبل رسالة مخصصة *** ---
Future<RetryOption?> showAnalysisFailedPopup(BuildContext context,
    {String? message}) async {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'فشل التحليل',
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // --- *** استخدام الرسالة المخصصة أو رسالة افتراضية *** ---
          content: Text(
            message ??
                'فشل في تحليل الفيديو. يرجى المحاولة مرة أخرى بفيديو واضح وبصيغة MP4.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('المحاولة مرة أخرى',
                      style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2C73D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(RetryOption.retry);
                  },
                ),
                const SizedBox(height: 8),
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
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        ),
      );
    },
  ).whenComplete(() {
    audioPlayer.dispose();
  });
}