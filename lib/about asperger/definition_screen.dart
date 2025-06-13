// screens/definition_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DefinitionScreen extends StatelessWidget {
  const DefinitionScreen({super.key});

  Future<void> _launchYouTubeVideo() async {
    // تم تحديث رابط الفيديو حسب طلبك
    final Uri youtubeUrl = Uri.parse('https://youtu.be/Gq-dA6lxC50?si=vq_T12mn525pEoWJ');
    if (!await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $youtubeUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    const String question = "ما هي متلازمة أسبرجر؟";
    const String answer =
        """متلازمة أسبرجر هي نوع من أنواع اضطرابات طيف التوحد. في الوقت الحالي، لم يعد مصطلح "أسبرجر" شائعًا في التصنيفات الطبية الحديثة، وأصبح يُدرج تحت مظلة "اضطراب طيف التوحد" بمستويات مختلفة (بسيط، متوسط، شديد).

يتميز الأفراد المصابون بأسبرجر بصعوبات في التواصل الاجتماعي والتفاعل، مع وجود أنماط سلوكية واهتمامات متكررة ومحددة. على عكس أشكال التوحد الأخرى، لا يوجد عادةً تأخر كبير في تطور اللغة أو المهارات المعرفية.

غالبًا ما يُلاحظ على الطفل أنه "غريب الأطوار" أو "انطوائي"، على الرغم من ذكائه وقدراته اللغوية الجيدة. يجد صعوبة في فهم الإشارات الاجتماعية غير اللفظية (مثل تعابير الوجه ونبرة الصوت)، وقد يفسر الكلام بشكل حرفي. لديهم أيضًا حساسية عالية تجاه الأصوات أو الأضواء، ويتمسكون بشدة بالروتين.""";
    final Color themeColor = const Color(0xff7b68ee); // اللون البنفسجي الخاص بالتعريف

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        // ١. تم حذف الـ AppBar من هنا
        body: Stack(
          children: [
            // المحتوى الرئيسي
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // ٢. الجزء العلوي المدمج (بديل الـ AppBar)
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
                      BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Text(
                    question,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20, // تم تصغير الخط ليتناسب مع التصميم
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // تصميم الجواب
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Text(
                      answer,
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 17, height: 1.7, color: Colors.grey[800]),
                    ),
                  ),
                ),
                const SizedBox(height: 90), // مساحة للزر العائم
              ],
            ),
            
            // ٣. زر الرجوع المخصص
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
            
            // ٤. زر الفيديو العائم
            Positioned(
              bottom: 25,
              left: 25,
              child: FloatingActionButton(
                onPressed: _launchYouTubeVideo,
                backgroundColor: Colors.red,
                tooltip: 'شاهد الفيديو',
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}