import 'package:flutter/material.dart';
import 'package:myfinalpro/sec3/home3.dart';

class EndTestScreenV3 extends StatelessWidget {
  final bool testPassed;

  const EndTestScreenV3({super.key, required this.testPassed});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff2C73D9);
    String message = testPassed
        ? '🎉 تهانينا! لقد اجتزت الاختبار بنجاح 🎉'
        : 'لم يحالفك الحظ هذه المرة. سيتم إعادة تقييم المستوى، حاول مرة أخرى!';
    IconData iconData = testPassed ? Icons.celebration_rounded : Icons.sentiment_dissatisfied_rounded;
    Color iconColor = testPassed ? primaryColor : Colors.orange.shade700;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 60, color: iconColor),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SocialSkillsScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  ),
                  child: const Text('العودة', style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}