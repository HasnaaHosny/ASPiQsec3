// screens/plan_screen.dart
import 'package:flutter/material.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تصميم فريد: بطاقات صغيرة داخل الشاشة
    return Scaffold(
      appBar: AppBar(title: Text("خطة الدعم المتكاملة")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPlanCard(
              icon: Icons.psychology,
              title: "أخصائي نفسي",
              description: "للمساعدة في إدارة القلق، بناء الثقة بالنفس، وتقديم العلاج السلوكي المعرفي (CBT).",
              color: Colors.purple,
            ),
            _buildPlanCard(
              icon: Icons.record_voice_over,
              title: "معالج نطق ولغة",
              description: "للتركيز على لغة التواصل الاجتماعي، مثل كيفية بدء حوار وفهم التلميحات.",
              color: Colors.orange,
            ),
            _buildPlanCard(
              icon: Icons.accessibility_new,
              title: "معالج وظيفي",
              description: "خبير في التعامل مع التحديات الحسية وتطوير المهارات الحياتية اليومية.",
              color: Colors.green,
            ),
            _buildPlanCard(
              icon: Icons.school,
              title: "مرشد تربوي",
              description: "لتقديم الدعم الأكاديمي والاجتماعي داخل البيئة المدرسية.",
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({required IconData icon, required String title, required String description, required Color color}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}