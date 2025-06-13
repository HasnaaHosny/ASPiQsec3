// screens/symptoms_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SymptomsScreen extends StatelessWidget {
  const SymptomsScreen({super.key});

  // دالة لفتح رابط اليوتيوب
  Future<void> _launchYouTubeVideo() async {
    final Uri youtubeUrl = Uri.parse('https://youtu.be/CvBTb-LNqIw?si=HfUskpzpgRP9552m');
    if (!await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication)) {
      // يمكنك عرض رسالة خطأ للمستخدم هنا إذا فشل الفتح
      // مثلاً باستخدام SnackBar
    }
  }

  @override
  Widget build(BuildContext context) {
    const String question = "ما هي أبرز السمات والصعوبات؟";
    final Color themeColor = const Color(0xffffd700);
    final Color textColor = Colors.grey.shade800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        // تم حذف الـ AppBar بالكامل من هنا
        body: Stack(
          children: [
            // المحتوى الرئيسي القابل للتمرير
            ListView(
              padding: EdgeInsets.zero, // إزالة أي padding افتراضي من الـ ListView
              children: [
                // الجزء العلوي المدمج (بديل الـ AppBar)
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

                // بناء قائمة السمات ونقاط القوة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSymptomCategory(
                        icon: Icons.people_outline,
                        title: "صعوبات في التفاعل الاجتماعي",
                        points: [
                          """صعوبة في فهم الانفعالات: هذا هو جوهر التحدي. قد لا يتمكن الشخص من قراءة تعابير الوجه أو فهم نبرة الصوت بسهولة، مما يؤدي إلى سوء فهم كبير للنوايا والمشاعر.""",
                          "صعوبة في فهم الإشارات الاجتماعية غير اللفظية الأخرى، مثل لغة الجسد.",
                          "صعوبة في تكوين صداقات والحفاظ عليها بسبب هذه التحديات في الفهم المتبادل.",
                          "قد يفضلون العزلة والوحدة لأن التفاعل الاجتماعي يستهلك طاقة ذهنية كبيرة.",
                        ],
                        themeColor: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      _buildSymptomCategory(
                        icon: Icons.repeat_one_on_rounded,
                        title: "أنماط سلوكية مقيدة ومتكررة",
                        points: [
                          "اهتمامات مكثفة بمواضيع معينة.",
                          "صعوبة في تغيير الروتين والانزعاج منه.",
                          "القيام بحركات متكررة (هز اليدين، تأرجح).",
                        ],
                        themeColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildSymptomCategory(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: "صعوبات في التواصل",
                        points: [
                          "صعوبة في فهم الفكاهة أو السخرية.",
                          "قد يتحدثون بنبرة صوت رتيبة أو لديهم صعوبة في التحكم في مستوى الصوت.",
                          "يأخذون الكلام حرفيًا ويجدون صعوبة في فهم المعاني الضمنية.",
                        ],
                        themeColor: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildSymptomCategory(
                        icon: Icons.directions_bike,
                        title: "مهارات حركية غير متناسقة",
                        points: [
                          "قد يكون لديهم صعوبة في التنسيق الحركي، مثل الكتابة أو ركوب الدراجة.",
                          "قد تبدو حركاتهم غير متناسقة أو غريبة.",
                        ],
                        themeColor: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      _buildSymptomCategory(
                        icon: Icons.star_border_rounded,
                        title: "ولكن، هناك نقاط قوة مميزة!",
                        points: [
                          "قدرة فريدة على التركيز عند أداء بعض المهام.",
                          "اهتمام شديد بالتفاصيل وإدراك أدقها.",
                          "قوة المثابرة والإصرار.",
                          "ذاكرة قوية للمعلومات والحقائق.",
                          "صدق وولاء في العلاقات.",
                        ],
                        themeColor: Colors.deepPurple,
                      ),
                      const SizedBox(height: 90), // مساحة إضافية في الأسفل للزر العائم
                    ],
                  ),
                ),
              ],
            ),

            // زر الرجوع المخصص في الأعلى
            Positioned(
              top: 40, // اضبط المسافة من الأعلى
              right: 15, // اضبط المسافة من اليمين
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.15),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // زر الفيديو العائم في الأسفل
            Positioned(
              bottom: 25,
              left: 25,
              child: FloatingActionButton(
                onPressed: _launchYouTubeVideo,
                backgroundColor: Colors.red,
                tooltip: 'شاهد فيديو توضيحي',
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الويدجت المساعد لبناء بطاقات الأقسام
  Widget _buildSymptomCategory({
    required IconData icon,
    required String title,
    required List<String> points,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: themeColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}