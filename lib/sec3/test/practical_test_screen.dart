// lib/sec3/test/practical_test_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PracticalTestScreen extends StatefulWidget {
  final Function(File videoFile) onVideoSubmitted;

  const PracticalTestScreen({
    super.key,
    required this.onVideoSubmitted,
  });

  @override
  State<PracticalTestScreen> createState() => _PracticalTestScreenState();
}

class _PracticalTestScreenState extends State<PracticalTestScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickAndSubmitVideo(ImageSource source) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final XFile? video = await _picker.pickVideo(source: source);
      if (video != null && mounted) {
        widget.onVideoSubmitted(File(video.path));
      } else {
        // إذا ألغى المستخدم الاختيار، أوقف التحميل
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء اختيار الفيديو: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  // --- *** ويدجت مساعدة لعرض كل تعليمة مع أيقونتها *** ---
  Widget _buildInstructionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Cairo',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff2C73D9);
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "جاري معالجة الفيديو...",
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
                  ),
                ],
              )
            : SingleChildScrollView( // لتجنب أي مشاكل في الشاشات الصغيرة
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "قم بأداء الحركة المطلوبة أمام الكاميرا",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 30),

                      // --- *** قسم التعليمات الجديد الذي تم إضافته *** ---
                      const Text(
                        "لأفضل النتائج، اتبع التعليمات التالية:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionRow(Icons.timer_outlined, "أن تكون مدة الفيديو أكثر من 3 ثواني."),
                      _buildInstructionRow(Icons.movie_filter_outlined, "أن يكون الفيديو بصيغة MP4."),
                      _buildInstructionRow(Icons.accessibility_new_rounded, "أن تكون الحركة واضحة وكاملة."),
                      _buildInstructionRow(Icons.lightbulb_outline_rounded, "أن تكون إضاءة الفيديو جيدة."),
                      _buildInstructionRow(Icons.check_circle_outline_rounded, "أن يكون محتوى الفيديو مناسبًا."),
                      const SizedBox(height: 40),
                      // --- *** نهاية قسم التعليمات *** ---

                      ElevatedButton.icon(
                        icon: const Icon(Icons.videocam),
                        label: const Text("تسجيل فيديو الآن"),
                        onPressed: () => _pickAndSubmitVideo(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.video_library),
                        label: const Text("اختيار من المعرض"),
                        onPressed: () => _pickAndSubmitVideo(ImageSource.gallery),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}