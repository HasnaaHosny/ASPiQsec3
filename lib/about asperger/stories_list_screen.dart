// screens/stories_list_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'story_detail_screen.dart';

// نموذج بيانات الشخصية
class StoryCharacter {
  final String name;
  final String imagePath;
  final String story;
  final String? videoUrl;

  StoryCharacter({required this.name, required this.imagePath, required this.story, this.videoUrl});
}

class StoriesListScreen extends StatelessWidget {
  const StoriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // القائمة الكاملة للشخصيات مع المحتوى المفصل
    final List<StoryCharacter> characters = [
      StoryCharacter(
        name: "غريتا تونبرج",
        imagePath: "assets/images/greta_thunberg.jpeg",
        story: """غريتا تونبرج، الناشطة السويدية الشابة، هي مثال حي على كيف يمكن لشخص واحد أن يحدث فرقًا عالميًا. تم تشخيصها بمتلازمة أسبرجر، وهي تقول إن هذا التشخيص ليس عائقًا، بل هو "قوتها الخارقة".
        
بفضل قدرتها على التركيز الشديد والنظر إلى العالم من منظور مختلف، استطاعت غريتا أن ترى خطر تغير المناخ بوضوح لا يراه الكثيرون. لم تكتفِ بالمعرفة، بل حولتها إلى فعل، فبدأت إضرابًا مدرسيًا بمفردها أمام البرلمان السويدي، وهو ما ألهم ملايين الشباب حول العالم للانضمام إليها.
        
في عام 2019، اختارتها مجلة "تايم" كشخصية العام، لتصبح أصغر شخصية تحصل على هذا اللقب. قصة غريتا تعلمنا أن الشغف والتركيز، حتى لو جاءا مع تحديات اجتماعية، يمكن أن يكونا أقوى محرك للتغيير في العالم.""",
      ),
      StoryCharacter(
        name: "دانيال تاميت",
        imagePath: "assets/images/danialT.jpeg",
        videoUrl: 'https://www.youtube.com/watch?v=AbASOcqc1Ss',
        story: """يُعتبر دانيال تاميت حالة فريدة ومذهلة في عالم طيف التوحد. فهو 'متلازم موهبة' (Savant) بقدرات عقلية خارقة. يصف دانيال تجربته مع الأرقام بأنها ليست مجرد رموز، بل يراها كأشكال وألوان ومشاعر. هذه القدرة الفريدة على 'رؤية' الأرقام مكنته من حساب مسائل رياضية معقدة للغاية في ذهنه، وحفظ أكثر من 22,500 رقم من ثابت باي (Pi).

رحلته مع أسبرجر لم تكن سهلة، فقد عانى من العزلة وصعوبة فهم التفاعلات الاجتماعية. لكنه تعلم كيفية 'ترجمة' مشاعر الناس كما يترجم اللغات. نجح في تحويل اختلافه إلى قوة، وأصبح كاتبًا عالميًا، حيث يشارك قصته وتجربته الفريدة مع العالم، ملهمًا الملايين للنظر إلى التوحد كاختلاف غني وليس كقصور.""",
      ),
      StoryCharacter(
        name: "إيلون ماسك",
        imagePath: "assets/images/elon_musk.jpeg",
        videoUrl: 'https://www.youtube.com/watch?v=kYJyrb-gyrE',
        story: """صرح رجل الأعمال الملياردير إيلون ماسك بمعاناته مع متلازمة أسبرجر، مؤكدًا أنه تعلم "العمل مع دماغه وليس ضده". في طفولته، عانى من صعوبات اجتماعية حادة وشعور بالعزلة، لكنه وجد في العلوم والتكنولوجيا ملاذه وشغفه.
        
هذا التركيز الشديد، الذي هو سمة أساسية في أسبرجر، أصبح أقوى أسلحته. حوّل قدرته على الغوص في التفاصيل المعقدة إلى محرك للابتكار، مما قاده لتأسيس شركات غيرت وجه العالم مثل Tesla وSpaceX. قصة إيلون هي رسالة أمل قوية: العقل الذي يعمل بشكل مختلف، هو الذي يملك القدرة على رؤية المستقبل وصناعته.""",
      ),
      StoryCharacter(
        name: "ليونيل ميسي",
        imagePath: "assets/images/lionel_messi.jpeg",
        story: """على الرغم من عدم تأكيده رسميًا، يعتقد العديد من الخبراء والأطباء أن ليونيل ميسي، أسطورة كرة القدم، يُظهر العديد من سمات متلازمة أسبرجر. منذ طفولته، كان معروفًا بتركيزه الشديد والمطلق على كرة القدم، مع اهتمام أقل بالتفاعلات الاجتماعية المعقدة.

في الملعب، يُترجم هذا التركيز إلى قدرة استثنائية على قراءة اللعبة وتوقع حركة الكرة واللاعبين بدقة مذهلة. نجاحه يُظهر كيف يمكن للشغف والتركيز العميق، حتى مع وجود تحديات اجتماعية، أن يصنعا التميز والعبقرية في المجال الذي يختاره الشخص.""",
      ),
      StoryCharacter(
        name: "ألبيرت أينشتاين",
        imagePath: "assets/images/albert_einstein.jpeg",
        story: """العالم الشهير الذي غير الفيزياء، أثبتت التحليلات التاريخية لأسلوب حياته وكتاباته أنه كان يمتلك العديد من سمات أسبرجر. كان يجد صعوبة في التفاعلات الاجتماعية التقليدية، وكان يفضل العزلة للتفكير العميق. واجه صعوبات في التعبير اللفظي في طفولته، لكنه امتلك قدرة لا مثيل لها على التفكير البصري والمجرد. هذه القدرة على 'رؤية' الفيزياء هي التي قادته إلى نظرياته الثورية التي غيرت فهمنا للكون.""",
      ),
       StoryCharacter(
        name: "بيل جيتس",
        imagePath: "assets/images/bill_gates.jpeg",
        story: """يُلاحظ على بيل جيتس، مؤسس إمبراطورية مايكروسوفت، أنه يتجنب التواصل البصري المباشر، ويتحرك بشكل متأرجح، ويتكلم بنبرة صوت رتيبة، وهي كلها سمات تتوافق مع طيف أسبرجر.

ورغم هذه التحديات في التواصل التقليدي، إلا أنه تفوق في لغة يفهمها بعمق: لغة الأنظمة والبرمجة. بفضل معدل ذكائه الفذ وقدرته على التركيز الشديد، استطاع بناء نظام تشغيل غيّر وجه العالم.""",
      ),
      StoryCharacter(
        name: "إسحاق نيوتن",
        imagePath: "assets/images/isaac_newton.jpeg",
        story: """يعتبر المؤرخون أن السير إسحاق نيوتن، أحد أعظم العلماء في التاريخ، كان مصابًا بالتوحد. كان شديد الانعزال، قليل الكلام، ويكرس كل وقته لعمله لدرجة أنه كان ينسى تناول الطعام. هذا التركيز المطلق والانعزال عن المشتتات هو ما سمح له بوضع أسس الفيزياء الكلاسيكية وقوانين الحركة والجاذبية.""",
      ),
    ];

    // باقي الكود يبقى كما هو بدون تغيير
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("شخصيات ملهمة"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            return _buildCharacterCard(context, character);
          },
        ),
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, StoryCharacter character) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryDetailScreen(
                name: character.name,
                imagePath: character.imagePath,
                story: character.story,
                videoUrl: character.videoUrl,
              ),
            ),
          );
        },
        child: Container(
          height: 140,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(character.imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300)),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
              Center(
                child: Text(
                  character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}