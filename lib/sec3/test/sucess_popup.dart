import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

Future<void> showSuccessPopup(BuildContext context, VoidCallback onClosed) async {
  final ConfettiController confettiController = ConfettiController(duration: const Duration(seconds: 1));
  final AudioPlayer audioPlayer = AudioPlayer();

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success Popup',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          confettiController.play();
          audioPlayer.play(AssetSource('audio/bravo.mp3')).catchError((error) {
            print("Error playing sound: $error");
          });
        }
      });

      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Stack(
            alignment: Alignment.center,
            children: [
              ConfettiWidget(
                confettiController: confettiController,
                blastDirection: -pi / 2,
                shouldLoop: true,
                colors: const [ Colors.red, Colors.green, Color(0xff2C73D9), Colors.yellow, Colors.purple ],
                gravity: 0.3,
                numberOfParticles: 20,
                emissionFrequency: 0.05,
              ),
              SizedBox(
                height: 250,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉 برافو', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff2C73D9)), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2C73D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(180, 50),
                      ),
                      onPressed: () {
                        confettiController.stop();
                        audioPlayer.stop();
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('التالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    audioPlayer.dispose();
    onClosed();
  });
}