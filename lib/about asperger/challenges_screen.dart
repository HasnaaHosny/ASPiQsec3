// screens/challenges_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  // دالة لفتح رابط الفيديو الجديد
  Future<void> _launchYouTubeVideo() async {
    final Uri youtubeUrl = Uri.parse('https://youtu.be/HEnprjqhVqo?si=HnEPM5mNgXqoia9i');
    if (!await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $youtubeUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    const String question = "التحديات وكيفية مواجهتها";
    final Color themeColor = const Color(0xff20b2aa); // لون بطاقة المشكلات
    final Color textColor = Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        // تم حذف الـ AppBar
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // الجزء العلوي المدمج
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, bottom: 25, left: 60, right: 60),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Text(
                    question,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // بطاقات التحديات والحلول
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildChallengeCard(
                        icon: Icons.social_distance_rounded,
                        color: Colors.redAccent,
                        title: "القلق الاجتماعي والحمل الزائد",
                        description: """القلق ليس مجرد 'خجل'، بل هو استنزاف للطاقة. كل موقف اجتماعي يتطلب مجهودًا واعيًا لفك شفرته. عندما تتراكم المحفزات، يحدث 'الحمل الحسي الزائد'، وهو شعور بالإرهاق الشديد قد يؤدي إلى 'انهيارات' أو 'انغلاقات'.

**الحل المبدئي:** تخصيص 'وقت استراحة' بعد المواقف الاجتماعية، وتعلم تقنيات تهدئة بسيطة مثل التنفس العميق.""",
                      ),
                      _buildChallengeCard(
                        icon: Icons.rule_rounded,
                        color: Colors.blueAccent,
                        title: "صعوبات الوظائف التنفيذية",
                        description: """هي المهارات التي تساعدنا على التخطيط والتنظيم. قد يجد الشخص صعوبة في البدء بمهمة ما، وهذا ليس كسلًا، بل هو تحدٍ في 'مركز القيادة' بالدماغ.

**الحل المبدئي:** استخدام أدوات مساعدة مثل الجداول البصرية، قوائم المهام الواضحة، وتقسيم المهام الكبيرة إلى خطوات صغيرة.""",
                      ),
                      _buildChallengeCard(
                        icon: Icons.person_off_rounded,
                        color: Colors.orangeAccent,
                        title: "سوء الفهم والتنمر",
                        description: """من أكثر الأمور إيلامًا هو أن يُساء فهم النوايا. الصدق المباشر قد يُفسر على أنه وقاحة. هذا الاختلاف يمكن أن يجعل الطفل هدفًا للتنمر.

**الحل المبدئي:** تعليم الطفل عبارات بسيطة لشرح نفسه، والأهم هو نشر الوعي في المدرسة والأسرة لخلق بيئة داعمة.""",
                      ),
                      // --- القسم الجديد الذي تمت إضافته ---
                      _buildChallengeCard(
                        icon: Icons.support_agent,
                        color: Colors.deepPurple,
                        title: "أهمية التدخل وتنمية المهارات",
                        description: """لا يمكن مواجهة هذه التحديات بدون دعم. الحل يكمن في التدخل المبكر والمستمر.

**متابعة مع أخصائي:** العمل مع أخصائي تعديل سلوك وتنمية مهارات هو حجر الأساس لوضع خطة فردية تساعد الطفل على فهم الانفعالات وتطوير المهارات الاجتماعية.

**المتابعة في المنزل:** دور الأهل لا يقل أهمية. تطبيق الاستراتيجيات والأنشطة في المنزل يعزز ما يتعلمه الطفل في الجلسات ويجعله جزءًا من حياته اليومية.

**وهنا يأتي دور تطبيقنا،** حيث نساعدك على توفير هذه الأنشطة والأدوات لمواصلة الدعم في المنزل.""",
                      ),
                      const SizedBox(height: 80), // مساحة للزر العائم
                    ],
                  ),
                ),
              ],
            ),
            
            // زر الرجوع المخصص
            Positioned(
              top: 40,
              right: 15,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.15),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            
            // زر الفيديو العائم
            Positioned(
              bottom: 25,
              left: 25,
              child: FloatingActionButton(
                onPressed: _launchYouTubeVideo,
                backgroundColor: Colors.red,
                tooltip: 'نصائح هامة جدا',
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الويدجت المساعد (لم يتغير)
  Widget _buildChallengeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}