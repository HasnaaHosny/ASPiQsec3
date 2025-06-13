// screens/story_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryDetailScreen extends StatelessWidget {
  final String name;
  final String imagePath;
  final String story;
  final String? videoUrl;

  const StoryDetailScreen({
    super.key,
    required this.name,
    required this.imagePath,
    required this.story,
    this.videoUrl,
  });

  Future<void> _launchVideo() async {
    if (videoUrl != null) {
      final Uri uri = Uri.parse(videoUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $videoUrl');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- الجزء العلوي مع الصورة الواضحة ---
                Container(
                  height: 250,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  // --- تم تعديل هذا الجزء ---
                  // أزلنا الـ Stack والـ Container الذي كان يضيف اللون الشفاف
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover, // الصورة تملأ المساحة
                    errorBuilder: (c, e, s) => Container(color: Colors.grey),
                  ),
                ),
                
                // اسم الشخصية
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.grey[850]),
                  ),
                ),

                // القصة التفصيلية
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 100.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                    ),
                    child: Text(
                      story,
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 17, height: 1.7, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
            
            // زر الرجوع المخصص (لا يزال يعمل بشكل جيد)
            Positioned(
              top: 40,
              right: 15,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.35), // يمكنك زيادة شفافية الخلفية قليلاً
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            
            // زر الفيديو (لا يزال يعمل بشكل جيد)
            if (videoUrl != null)
              Positioned(
                bottom: 25,
                left: 25,
                child: FloatingActionButton(
                  onPressed: _launchVideo,
                  backgroundColor: Colors.red,
                  tooltip: 'شاهد فيديو عن الشخصية',
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
              ),
          ],
        ),
      ),
    );
  }
}