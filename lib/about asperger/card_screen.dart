// card_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- استيراد كل الشاشات المنفصلة ---
// تأكد من أن هذه المسارات صحيحة لمشروعك وأن الملفات موجودة
import 'definition_screen.dart';
import 'symptoms_screen.dart';   
import 'challenges_screen.dart'; 
import 'plan_screen.dart';      
import 'methods_screen.dart';    
import 'centers_screen.dart';    
//import 'story_detail_screen.dart';   
import 'stories_list_screen.dart'; 
import 'faq_screen.dart';      


// نموذج بيانات البطاقة
class CardInfo {
  final String title;
  final Color color;
  final IconData icon;
  final Widget destinationScreen;

  CardInfo({
    required this.title,
    required this.color,
    required this.icon,
    required this.destinationScreen,
  });
}

class CardScreen extends StatelessWidget {
  const CardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة البطاقات مع ربط كل بطاقة بشاشتها المنفصلة
    final List<CardInfo> cardItems = [
      CardInfo(
          title: "التعريف",
          color: const Color(0xff7b68ee),
          icon: Icons.info_outline,
          destinationScreen: const DefinitionScreen()),
      CardInfo(
          title: "الأعراض",
          color: const Color(0xffffd700),
          icon: Icons.sick_outlined,
          destinationScreen: const SymptomsScreen()),
      CardInfo(
          title: "التحديات وكيفية مواجهتها",
          color: const Color(0xff20b2aa),
          icon: Icons.warning_amber_rounded,
          destinationScreen: const ChallengesScreen()),
      
      /* --- البطاقات المخفية مؤقتًا ---
      CardInfo(
          title: "برنامج العلاج",
          color: const Color(0xff4169e1),
          icon: Icons.playlist_add_check_rounded,
          destinationScreen: const PlanScreen()),
      CardInfo(
          title: "أساليب العلاج",
          color: const Color(0xff00bfff),
          icon: Icons.healing_outlined,
          destinationScreen: const MethodsScreen()),
      CardInfo(
          title: "الأماكن والمراكز",
          color: const Color(0xffff6347),
          icon: Icons.location_on_outlined,
          destinationScreen: const CentersScreen()),
      */

      CardInfo(
          title: "اشخاص قهروا اسبرجر",
          color: const Color(0xff32CD32),
          icon: Icons.emoji_events_outlined,
          destinationScreen: const StoriesListScreen()),
      CardInfo(
          title: "أسئلة شائعة",
          color: const Color(0xff9370DB),
          icon: Icons.quiz_outlined,
          destinationScreen: const FaqScreen()),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الواجهة الرئيسية'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            _buildBackgroundCircles(),
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: cardItems.length,
              itemBuilder: (context, index) {
                final item = cardItems[index];
                return _buildListCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  // هذه الدالة لم تتغير
  Widget _buildBackgroundCircles() {
    return Container(
      color: Colors.grey[100],
      child: Stack(
        children: [
          _buildCircle(color: Colors.pink, size: 200, top: -50, left: -90),
          _buildCircle(color: Colors.blue, size: 250, top: 120, right: -120),
          _buildCircle(color: Colors.yellow, size: 180, top: 380, left: -60),
          _buildCircle(color: Colors.green, size: 220, top: 550, right: -100),
          _buildCircle(color: Colors.orange, size: 130, top: 20, right: 20),
          _buildCircle(color: Colors.purple, size: 160, bottom: 30, left: 100),
          _buildCircle(color: Colors.teal, size: 100, bottom: -40, right: 40),
        ],
      ),
    );
  }

  // هذه الدالة لم تتغير
  Widget _buildCircle(
      {required Color color, required double size, double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
      ),
    );
  }

  // --- دالة بناء البطاقة بعد تعديل حجمها ---
  Widget _buildListCard(BuildContext context, CardInfo item) {
    return Padding(
      // ١. زيادة المسافة الرأسية بين البطاقات لتوفير مساحة أكبر
      padding: const EdgeInsets.only(bottom: 20.0), 
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item.destinationScreen),
          );
        },
        child: Container(
          // ٢. زيادة الـ padding العمودي بشكل كبير لزيادة ارتفاع البطاقة
          padding: const EdgeInsets.symmetric(vertical: 45.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(28), // زيادة دائرية الحواف قليلاً
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ٣. تكبير حجم الأيقونة لتتناسب مع الحجم الجديد
              Icon(
                item.icon,
                color: Colors.white,
                size: 55, // يمكنك زيادة هذا الرقم أكثر إذا أردت
              ),
              const SizedBox(width: 20),
              // ٤. تكبير حجم الخط
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // خط أكبر وأكثر وضوحًا
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8.0, color: Colors.black45, offset: Offset(1.5, 1.5))],
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