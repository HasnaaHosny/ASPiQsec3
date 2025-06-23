import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

Future<void> showErrorPopup(BuildContext context, VoidCallback onClosed) async {
  final AudioPlayer audioPlayer = AudioPlayer();

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Error Popup',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      audioPlayer.play(AssetSource('audio/error_sound.mp3')).catchError((error) {
        print("Error playing error sound: $error");
      });

      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SizedBox(
            height: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('😟', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                const Text('إجابة خاطئة!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.redAccent)),
                const SizedBox(height: 12),
                const Text('لا بأس، حاول التركيز في السؤال القادم.', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: Colors.black54), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(180, 50),
                  ),
                  onPressed: () {
                    audioPlayer.stop();
                    if (Navigator.canPop(dialogContext)) {
                       Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('التالي', style: TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    audioPlayer.dispose();
    onClosed();
  });
}