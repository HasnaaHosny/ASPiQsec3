// screens/methods_screen.dart
import 'package:flutter/material.dart';

class MethodsScreen extends StatelessWidget {
  const MethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildDefaultScreen(
      title: "أساليب الدعم الفعالة",
      imagePath: "assets/images/methods_banner.png",
      content: """هناك عدة استراتيجيات فعالة ومثبتة علميًا لدعم أطفال طيف أسبرجر:
      
1.  **القصص الاجتماعية (Social Stories):** قصص قصيرة وبسيطة تشرح موقفًا اجتماعيًا معينًا والسلوك المتوقع فيه، مما يقلل من القلق.
2.  **تحليل السلوك التطبيقي (ABA):** يركز على تعليم مهارات جديدة ومفيدة عبر التعزيز الإيجابي.
3.  **العلاج بالتكامل الحسي:** مساعدة الفرد على تنظيم استجابته للمدخلات الحسية (اللمس، الصوت، الضوء).
4.  **مجموعات المهارات الاجتماعية:** بيئة آمنة للتدرب على التفاعلات الاجتماعية مع الأقران تحت إشراف متخصص.""",
      themeColor: const Color(0xff00bfff),
    );
  }

  Widget _buildDefaultScreen({required String title, required String imagePath, required String content, required Color themeColor}) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(content))));
  }
}