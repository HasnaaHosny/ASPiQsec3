// screens/faq_screen.dart
import 'package:flutter/material.dart';

// نموذج بسيط لكل سؤال وجواب
class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- القائمة الكاملة للأسئلة مقسمة إلى فئات ---

    final List<FaqItem> generalQuestions = [
      FaqItem(
          question: "ما الفرق بين التوحد ومتلازمة أسبرجر؟",
          answer: "سابقًا، كان أسبرجر تشخيصًا منفصلاً. الآن، كلاهما يندرج تحت 'اضطراب طيف التوحد' (ASD). الفرق الرئيسي هو أن أصحاب متلازمة أسبرجر لا يعانون من تأخر في تطور اللغة أو الذكاء."),
      FaqItem(
          question: "هل أسبرجر مرض؟ هل يمكن الشفاء منه؟",
          answer: "لا، هو ليس مرضًا، بل اختلاف في النمو العصبي. لذلك، لا يوجد 'شفاء' بل هناك دعم وتنمية مهارات للتعامل مع التحديات والنجاح في الحياة."),
      FaqItem(
          question: "هل اللقاحات تسبب التوحد؟",
          answer: "لا، بشكل قاطع. هذه خرافة تم دحضها علميًا في مئات الدراسات الموثوقة حول العالم. لا توجد أي صلة بين اللقاحات والتوحد."),
      FaqItem(
          question: "ما هي الأسباب المعروفة لأسبرجر؟",
          answer: "الأسباب غير معروفة بدقة، لكن يعتقد أنها مزيج معقد من العوامل الوراثية والبيولوجية. هو ليس ناتجًا عن سوء التربية إطلاقًا."),
      FaqItem(
          question: "هل أسبرجر وراثي؟",
          answer: "هناك مكون وراثي قوي. غالبًا ما نجد سمات مشابهة لدى أحد الوالدين أو الأقارب."),
      FaqItem(
          question: "متى تظهر أعراض أسبرجر عادةً؟",
          answer: "قد تظهر بعض السمات في الطفولة المبكرة، لكن التشخيص غالبًا ما يتم عند دخول الطفل المدرسة، حيث تصبح التحديات الاجتماعية أكثر وضوحًا."),
      FaqItem(
          question: "هل يمكن لشخص بالغ أن يتم تشخيصه بأسبرجر؟",
          answer: "نعم، الكثير من البالغين يتم تشخيصهم في وقت متأخر من حياتهم، وغالبًا ما يكون التشخيص مصدر راحة كبيرة لهم لأنه يفسر الكثير من التحديات التي واجهوها."),
    ];

    final List<FaqItem> socialQuestions = [
      FaqItem(
          question: "لماذا يجد طفلي صعوبة في تكوين صداقات؟",
          answer: "لأنه يجد صعوبة في فهم 'القواعد غير المكتوبة' للتفاعل الاجتماعي، مثل كيفية بدء محادثة، أو فهم لغة الجسد والنكت. هو يرغب في الصداقة لكنه لا يعرف 'كيف'."),
      FaqItem(
          question: "لماذا يتجنب طفلي التواصل البصري؟",
          answer: "ليس بسبب الخجل أو عدم الاحترام. غالبًا ما يكون النظر في العيون مرهقًا جدًا بالنسبة له، لأنه يتطلب معالجة كم هائل من المعلومات العاطفية في لحظة واحدة."),
      FaqItem(
          question: "لماذا يتحدث طفلي باستمرار عن موضوع واحد؟",
          answer: "هذه هي طريقته في المشاركة والتواصل. اهتماماته هي شغفه ومصدر راحته، ويريد أن يشاركك هذا الشغف. حاول أن تظهر اهتمامًا ثم توجهه بلطف إلى موضوع آخر."),
      FaqItem(
          question: "هل يعني الانعزال أن طفلي حزين أو مكتئب؟",
          answer: "ليس بالضرورة. غالبًا ما يحتاج الأفراد من طيف أسبرجر إلى وقت بمفردهم 'لإعادة شحن بطارياتهم الاجتماعية' بعد يوم طويل ومرهق حسيًا واجتماعيًا."),
      FaqItem(
          question: "كيف أساعد طفلي على فهم مشاعر الآخرين؟",
          answer: "استخدم القصص الاجتماعية، الأفلام، والحديث المباشر. قل له صراحة: 'صديقك يبدو حزينًا لأنك أخذت لعبته. كيف يمكننا أن نجعله يشعر بتحسن؟'."),
    ];

    final List<FaqItem> behaviorQuestions = [
       FaqItem(
          question: "لماذا يغضب طفلي بشدة عند تغيير الروتين؟",
          answer: "الروتين يوفر له الأمان والقدرة على التنبؤ في عالم قد يبدو فوضويًا. تغيير الروتين يجعله يشعر بفقدان السيطرة والقلق الشديد."),
       FaqItem(
          question: "ما هي 'الانهيارات' (Meltdowns) ولماذا تحدث؟",
          answer: "الانهيار ليس نوبة غضب للفت الانتباه. إنه رد فعل لا إرادي ناتج عن 'الحمل الحسي أو العاطفي الزائد'، حيث لا يستطيع الدماغ معالجة المزيد من المحفزات. الحل هو إبعاد الطفل إلى مكان هادئ وآمن حتى يهدأ."),
       FaqItem(
          question: "لماذا يقوم طفلي بحركات متكررة مثل الرفرفة؟",
          answer: "هذه الحركات، المعروفة بـ 'التحفيز الذاتي' (Stimming)، هي طريقة لتنظيم المدخلات الحسية وتهدئة النفس عند الشعور بالقلق أو الإثارة. هي ليست ضارة ما لم تكن مؤذية."),
       FaqItem(
          question: "كيف أتعامل مع العناد الشديد؟",
          answer: "غالبًا ما يكون العناد نابعًا من القلق أو صعوبة في التكيف مع التغيير. بدلًا من المواجهة، حاول فهم السبب وراء الرفض. قدم خيارات محدودة، استخدم جداول بصرية، وحضر الطفل لأي تغيير قادم مسبقًا."),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("أسئلة شائعة")),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildCategoryHeader("أسئلة عامة"),
            ...generalQuestions.map((item) => _buildFaqTile(item)).toList(),
            
            const SizedBox(height: 20),
            _buildCategoryHeader("التواصل والتفاعل الاجتماعي"),
            ...socialQuestions.map((item) => _buildFaqTile(item)).toList(),

            const SizedBox(height: 20),
            _buildCategoryHeader("السلوك والروتين"),
            ...behaviorQuestions.map((item) => _buildFaqTile(item)).toList(),
            // يمكنك إضافة المزيد من الفئات والأسئلة هنا بنفس الطريقة
          ],
        ),
      ),
    );
  }

  // ويدجت لبناء عنوان كل فئة
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  // ويدجت لبناء كل سؤال وجواب
  Widget _buildFaqTile(FaqItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          item.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topRight,
        children: [
          Text(
            item.answer,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey[700],
            ),
          )
        ],
      ),
    );
  }
}