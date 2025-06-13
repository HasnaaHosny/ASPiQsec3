// screens/centers_screen.dart
import 'package:flutter/material.dart';

class CentersScreen extends StatelessWidget {
  const CentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildDefaultScreen(
      title: "الأماكن والمراكز",
      imagePath: "assets/images/centers_banner.png",
      content: """العثور على المركز أو المختص المناسب خطوة حاسمة.

**عند البحث، اسأل عن:**
- **الترخيص والخبرة:** هل الفريق متخصص في طيف التوحد؟
- **الخطة الفردية:** هل الخطة مصممة خصيصًا لطفلك؟
- **مشاركة الأهل:** هل يشجعونك على المشاركة ويعطونك استراتيجيات للمنزل؟

(سيتم إضافة قائمة بالمراكز المعتمدة قريبًا).""",
      themeColor: const Color(0xffff6347),
    );
  }

  Widget _buildDefaultScreen({required String title, required String imagePath, required String content, required Color themeColor}) {
    // الصق هنا نفس الدالة المساعدة من شاشة المشكلات أو الأعراض
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(content))));
  }
}