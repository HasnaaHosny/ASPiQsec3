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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff2C73D9);
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        //title: const Text("الاختبار العملي", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
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
                  Text("جاري معالجة الفيديو...", style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo')),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "قم بأداء الحركة المطلوبة أمام الكاميرا",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text("تسجيل فيديو الآن"),
                      onPressed: () => _pickAndSubmitVideo(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}