// lib/screens/animated_break_screen.dart (اسم مقترح للملف)
// lib/screens/break_screen.dart
import 'dart:async'; // لاستخدام Timer
import 'package:flutter/material.dart';
import 'dart:math';

class BreakScreen extends StatefulWidget {
  final Duration duration; // استقبال المدة

  const BreakScreen({Key? key, required this.duration}) : super(key: key);

  @override
  _BreakScreenState createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _timerController;
  double waveOffset = 0.0;
  Timer? _popTimer;

  Duration get _remainingTime {
     if (!_timerController.isAnimating && !_timerController.isCompleted) {
         return widget.duration;
     }
     return widget.duration * (1.0 - _timerController.value);
  }

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..addListener(() {
        if (mounted) {
          setState(() {
            waveOffset += 0.02;
          });
        }
      })..repeat();

    _timerController = AnimationController(
        vsync: this,
        duration: widget.duration
    )..addListener(() {
       if(mounted) setState(() {});
    })..forward();

    _popTimer = Timer(widget.duration, () {
      print("BreakScreen: Timer finished, popping.");
      _popScreenSafely();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _timerController.dispose();
    _popTimer?.cancel();
    super.dispose();
  }

  void _popScreenSafely() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _skipBreak() {
    print("BreakScreen: Skip button pressed, popping.");
    _popTimer?.cancel();
    _popScreenSafely();
  }

   String formatBreakDuration(Duration duration) {
     duration = duration.isNegative ? Duration.zero : duration;
     String twoDigits(int n) => n.toString().padLeft(2, '0');
     final minutes = twoDigits(duration.inMinutes.remainder(60));
     final seconds = twoDigits(duration.inSeconds.remainder(60));
     return '$minutes:$seconds';
   }

    String _convertToArabicNumbers(String number) {
       const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
       const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
       String result = number;
       for (int i = 0; i < english.length; i++) { result = result.replaceAll(english[i], arabic[i]); }
       return result;
    }

  @override
  Widget build(BuildContext context) {
    const breakColor = Color(0xff2C73D9);
    // الحصول على مساحة الـ padding الآمنة (مثل شريط الحالة والنتوءات)
    final screenPadding = MediaQuery.of(context).padding;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية بيضاء
            Container(color: Colors.white),

            // --- رسم الموجة ---
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              painter: WavePainter(waveOffset, _timerController.value, breakColor),
            ),

            // --- محتوى الشاشة (العنوان والمؤقت) ---
            Positioned.fill(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text(
                     "وقت الاستراحة",
                     textAlign: TextAlign.center,
                     style: TextStyle( fontSize: 32, fontWeight: FontWeight.bold, color: breakColor, ),
                   ),
                   const SizedBox(height: 40),
                   Text(
                     _convertToArabicNumbers(formatBreakDuration(_remainingTime)),
                     textAlign: TextAlign.center,
                     style: const TextStyle( fontSize: 60, fontWeight: FontWeight.bold, color: breakColor, fontFamily: 'monospace'),
                     textDirection: TextDirection.ltr,
                   ),
                    const SizedBox(height: 10),
                    Text( "ثانية : دقيقة", style: TextStyle(color: breakColor.withOpacity(0.8), fontSize: 16), ),
                    const SizedBox(height: 60), // مسافة إضافية كانت قبل زر التخطي
                 ],
              ),
            ),

            // --- زر التخطي في الأعلى يسار ---
            Positioned(
              // نستخدم screenPadding.top لضمان عدم تداخل الزر مع شريط الحالة
              // ونضيف padding إضافي (e.g., 16.0) لجعله يبدو أفضل
              top: screenPadding.top + 16.0,
              left: 16.0, // padding من اليسار
              child: TextButton(
                onPressed: _skipBreak,
                style: TextButton.styleFrom(
                  foregroundColor: breakColor, // لون النص
                  backgroundColor: Colors.white.withOpacity(0.75), // خلفية بيضاء شبه شفافة لتمييزه
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 16, // يمكن تعديل حجم الخط
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder( // حواف دائرية للزر
                    borderRadius: BorderRadius.circular(8.0),
                  )
                ),
                child: const Text("تخطي"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- كلاس رسم الموجة (يبقى كما هو) ---
class WavePainter extends CustomPainter {
  final double waveOffset;
  final double timerProgress;
  final Color waveColor;

  WavePainter(this.waveOffset, this.timerProgress, this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = waveColor.withOpacity(0.6);
    Path path = Path();
    path.moveTo(0, size.height);
    double baseHeight = size.height * (0.8 * (1.0 - timerProgress));
    for (double x = 0; x <= size.width; x++) {
      double y = baseHeight + (sin((x * 0.015) + waveOffset) * 30);
      y = y.clamp(0.0, size.height);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    Paint paint2 = Paint()..color = waveColor.withOpacity(0.3);
    Path path2 = Path();
    path2.moveTo(0, size.height);
    double baseHeight2 = size.height * (0.83 * (1.0 - timerProgress));
    for (double x = 0; x <= size.width; x++) {
      double y = baseHeight2 + (sin((x * 0.012) + waveOffset * 0.8) * 35);
      y = y.clamp(0.0, size.height);
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}