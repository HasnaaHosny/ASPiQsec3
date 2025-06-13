// SideBarMenuTest.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// --- استيراد الشاشات ---
// تأكد من أن كل هذه المسارات صحيحة في مشروعك
import 'package:myfinalpro/widget/about_app.dart';
import 'package:myfinalpro/widget/editaccount.dart';
import 'package:myfinalpro/login/login_view.dart';
import 'package:myfinalpro/widget/page_route_names.dart';
import 'package:myfinalpro/screens/home_screen.dart';
import 'package:myfinalpro/Report/report_list_screen.dart';
import 'package:myfinalpro/about asperger/card_screen.dart';

// ١. تعريف GlobalKey للوصول إلى حالة القائمة الجانبية من أي مكان في التطبيق
final GlobalKey<SideBarMenuTestState> sideBarKey = GlobalKey<SideBarMenuTestState>();

class SideBarMenuTest extends StatefulWidget {
  // ٢. إضافة المفتاح (key) إلى الـ constructor
  const SideBarMenuTest({Key? key}) : super(key: key);

  @override
  // ٣. تغيير اسم الكلاس State ليكون عامًا (بإزالة الشرطة السفلية)
  SideBarMenuTestState createState() => SideBarMenuTestState();
}

// ٤. تغيير اسم الكلاس State ليكون عامًا
class SideBarMenuTestState extends State<SideBarMenuTest> {
  String _childName = "اسم الطفل";
  String _userEmail = "البريد الإلكتروني";
  String? _childImageUrl;

  @override
  void initState() {
    super.initState();
    loadDataForDrawer(); // تحميل البيانات الأولية
  }

  // ٥. جعل دالة تحميل البيانات عامة ليتم استدعاؤها من الخارج
  Future<void> loadDataForDrawer() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final childName = prefs.getString('child_name');
      final childImageUrl = prefs.getString('child_image_url');
      final userEmail = prefs.getString('user_email');

      print("Sidebar Reloading Data -> Name: $childName, Image: $childImageUrl");

      if (mounted) {
        setState(() {
          _childName = childName ?? "اسم الطفل";
          _userEmail = userEmail ?? "البريد الإلكتروني";
          _childImageUrl = childImageUrl;
        });
      }
    } catch (e) {
      print("Error reloading data in Sidebar: $e");
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.095,
                        backgroundColor: Colors.grey.shade200,
                        key: ValueKey(_childImageUrl), // مهم لتحديث الصورة
                        backgroundImage: (_childImageUrl != null && _childImageUrl!.isNotEmpty && _childImageUrl!.startsWith('http'))
                            ? NetworkImage(_childImageUrl!)
                            : const AssetImage("assets/images/default_avatar.png") as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditAccountScreen()));
                            },
                            child: Container(
                               padding: const EdgeInsets.all(5),
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: Colors.white,
                                 border: Border.all(color: Colors.grey.shade300, width: 1),
                               ),
                               child: Icon(Icons.edit_outlined, size: screenWidth * 0.045, color: Colors.blueGrey.shade700)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _childName,
                          style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _userEmail,
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // قائمة العناصر
            _buildDrawerItem(icon: Icons.person_outline, text: "تعديل الملف الشخصي", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditAccountScreen()));
            }),
            _buildDrawerItem(icon: Icons.home_outlined, text: "الصفحة الرئيسية", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            }),
            _buildDrawerItem(icon: Icons.bar_chart_outlined, text: "التقارير", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ReportListScreen()));
            }),
            _buildDrawerItem(icon: Icons.smart_toy_outlined, text: "المساعد الذكي", onTap: () {
               if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
               Navigator.pushNamed(context, PageRouteName.smartAssistant);
            }),
            _buildDrawerItem(icon: Icons.dashboard, text: "حول أسبرجر", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CardScreen()));
            }),
            _buildDrawerItem(icon: Icons.info_outline, text: "حول التطبيق", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const About_App()));
            }),
            const Divider(height: 15, thickness: 0.8, indent: 16, endIndent: 16),
            _buildDrawerItem(
              icon: Icons.logout,
              text: "تسجيل الخروج",
              onTap: _logout,
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap, Color? color}) {
     final itemColor = color ?? const Color(0xFF2C73D9);
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 26),
      title: Text(text, style: TextStyle(fontSize: 16, color: itemColor)),
      trailing: Icon(Icons.keyboard_arrow_left, color: itemColor.withOpacity(0.6)),
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
        Future.delayed(const Duration(milliseconds: 150), onTap);
      },
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
    );
  }
}