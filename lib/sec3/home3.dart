// lib/sec3/home3.dart

import 'dart:async';
import 'package:flutter/material.dart';

// --- !!! استيراد جديد: تأكد من أن هذا هو المسار الصحيح لشاشتك الرئيسية !!! ---
import 'package:myfinalpro/screens/home_screen.dart'; // <--- قد تحتاج لتعديل هذا المسار

import 'package:myfinalpro/login/login_view.dart';
// --- استيراد الملفات اللازمة للإشعارات ---
import 'package:myfinalpro/models/notification_item.dart';
import 'package:myfinalpro/services/notification_manager.dart';
// ------------------------------------------
import 'package:myfinalpro/sec3/session/simple_message_response.dart';
import 'package:myfinalpro/sec3/session/type3_session_response.dart';
import 'package:myfinalpro/sec3/session/social_session_intro_screen.dart';
import 'package:myfinalpro/sec3/review/review_sessions_screen.dart';
import 'package:myfinalpro/sec3/test/section3_test_group.dart';
import 'package:myfinalpro/sec3/test/section3_test_manager_screen.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialSkillsScreen extends StatefulWidget {
  const SocialSkillsScreen({super.key});

  @override
  State<SocialSkillsScreen> createState() => _SocialSkillsScreenState();
}

class _SocialSkillsScreenState extends State<SocialSkillsScreen> {
  bool _isLoading = true;
  bool _isStartingSession = false;
  bool _isFetchingTest = false;
  String? _jwtToken;

  bool isSessionAvailable = false;
  bool isDuringCooldown = false;
  Duration remainingTime = Duration.zero;
  Timer? cooldownTimer;
  static const cooldownDuration = Duration(seconds: 30);
  static const Color primaryBlue = Color(0xFF2C73D9);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadInitialData() async {
    setStateIfMounted(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _jwtToken = prefs.getString('auth_token');
      if (_jwtToken == null || _jwtToken!.isEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (route) => false);
        }
        return;
      }
      
      bool isInCooldown = await _isDeviceInCooldown(prefs);

      // إذا لم يكن الجهاز في فترة انتظار، قم بفحص الجلسات تلقائيًا
      if (!isInCooldown) {
        await _checkSessionStatusAutomatically();
      }
      
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    } finally {
      setStateIfMounted(() => _isLoading = false);
    }
  }
  
  // دالة جديدة لفحص حالة الجلسات تلقائياً عند تحميل الشاشة
  Future<void> _checkSessionStatusAutomatically() async {
    if (_jwtToken == null) return;
    
    try {
      // ApiService.getType3Session سيقوم بإرسال الإشعار تلقائيًا إذا كانت الاستجابة رسالة
      await ApiService.getType3Session(_jwtToken!);
    } catch (e) {
      debugPrint("Auto-check for Type 3 session failed: $e");
    }
  }

  Future<bool> _isDeviceInCooldown(SharedPreferences prefs) async {
    final lastSessionTimestamp = prefs.getInt('lastSocialSessionStartTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (lastSessionTimestamp == 0) {
      setStateIfMounted(() {
        isDuringCooldown = false;
        remainingTime = Duration.zero;
        isSessionAvailable = true;
      });
      cooldownTimer?.cancel();
      return false; // ليس في فترة انتظار
    }

    final elapsedTime = currentTime - lastSessionTimestamp;

    if (elapsedTime >= cooldownDuration.inMilliseconds) {
      setStateIfMounted(() {
        isDuringCooldown = false;
        remainingTime = Duration.zero;
        isSessionAvailable = true;
      });
      cooldownTimer?.cancel();
      return false; // ليس في فترة انتظار
    } else {
      final remainingMs = cooldownDuration.inMilliseconds - elapsedTime;
      setStateIfMounted(() {
        isDuringCooldown = true;
        isSessionAvailable = false;
        remainingTime = Duration(milliseconds: remainingMs);
      });
      _startUiUpdateTimer(lastSessionTimestamp);
      return true; // نعم، هو في فترة انتظار
    }
  }
  
  void _startUiUpdateTimer(int sessionStartTimeReferenceMillis) {
    cooldownTimer?.cancel();
    updateRemainingTimeCallback() async {
      if (!mounted) {
        cooldownTimer?.cancel();
        return;
      }
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final elapsedMillis = nowMillis - sessionStartTimeReferenceMillis;

      if (elapsedMillis >= cooldownDuration.inMilliseconds) {
        cooldownTimer?.cancel();
        
        // --- المنطق الجديد لإرسال الإشعار عند انتهاء المؤقت ---
        if (isDuringCooldown) { 
           final readyNotification = NotificationItem(
              id: 'session_ready_${DateTime.now().millisecondsSinceEpoch}',
              title: 'حان وقت الجلسة! 🚀',
              createdAt: DateTime.now(),
              type: NotificationType.sessionReady,
           );
           await NotificationManager.addOrUpdateNotification(readyNotification, playSound: true);
        }
        
        setStateIfMounted(() {
          isDuringCooldown = false;
          remainingTime = Duration.zero;
          isSessionAvailable = true;
        });
        
      } else {
        final newRemainingTime = cooldownDuration - Duration(milliseconds: elapsedMillis);
        if (mounted && isDuringCooldown && remainingTime.inSeconds != newRemainingTime.inSeconds) {
          setStateIfMounted(() => remainingTime = newRemainingTime);
        }
      }
    }

    if (isDuringCooldown) {
      updateRemainingTimeCallback();
      cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) => updateRemainingTimeCallback());
    }
  }

  Future<void> _startSession() async {
    if (_jwtToken == null || isDuringCooldown) return;
    setStateIfMounted(() => _isStartingSession = true);
    try {
      final response = await ApiService.getType3Session(_jwtToken!);
      if (!mounted) return;
      
      if (response is Type3SessionResponse) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SocialSessionIntroScreen(sessionData: response, jwtToken: _jwtToken!)));
      } else if (response is SimpleMessageResponse) {
        _showInfoDialog("تنبيه", response.message);
      }
    } catch (e) {
      _showInfoDialog("خطأ", e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setStateIfMounted(() => _isStartingSession = false);
    }
  }

  Future<void> _startTest() async {
    if (_jwtToken == null) return;
    setStateIfMounted(() => _isFetchingTest = true);
    try {
      final response = await ApiService.getSection3TestGroup(_jwtToken!);
      if (!mounted) return;
      if (response is Section3TestGroup) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Section3TestManagerScreen(
              testGroup: response,
              jwtToken: _jwtToken!,
            ),
          ),
        );
      } else if (response is SimpleMessageResponse) {
        _showInfoDialog("تنبيه", response.message);
      }
    } catch (e) {
      _showInfoDialog("خطأ", e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setStateIfMounted(() => _isFetchingTest = false);
    }
  }

  Future<void> _showInfoDialog(String title, String message) async {
    if (!mounted) return;
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: primaryBlue)),
              content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16.0, height: 1.5)),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0))),
                  child: const Text('حسنًا', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                )
              ],
            ));
  }

  String formatDuration(Duration duration) {
    String td(int n) => n.toString().padLeft(2, '0');
    final h = td(duration.inHours);
    final m = td(duration.inMinutes.remainder(60));
    final s = td(duration.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  String _convertToArabicNumbers(String number) {
    const e = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':'];
    const a = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', ':'];
    String r = number;
    for (int i = 0; i < e.length; i++) {
      r = r.replaceAll(e[i], a[i]);
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التواصل الاجتماعي', style: TextStyle(fontFamily: 'Cairo', color: primaryBlue)),
          backgroundColor: Colors.grey[100],
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryBlue),
          // --- *** هذا هو الجزء الذي تم تعديله *** ---
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // بدلاً من الرجوع للخلف، ننتقل مباشرة إلى الشاشة الرئيسية ونمسح ما قبلها
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minHeight: 112.0),
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8.0, offset: const Offset(0, 4.0))],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: isDuringCooldown ? _buildCooldownView() : _buildStartSessionView(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTestCard(),
                    const SizedBox(height: 16),
                    _buildReviewCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStartSessionView() {
    return Column(
        key: const ValueKey('start_session_view'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("هل أنت مستعد لبدء جلسة تدريبية جديدة في مهارات التواصل الاجتماعي؟", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          const SizedBox(height: 24.0),
          ElevatedButton(
              onPressed: _isStartingSession || !isSessionAvailable || _isFetchingTest ? null : _startSession,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                  disabledBackgroundColor: Colors.white.withAlpha(178)),
              child: _isStartingSession
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: primaryBlue))
                  : const Text('لنبدأ الجلسة', style: TextStyle(fontSize: 16.0, fontFamily: 'Cairo', fontWeight: FontWeight.bold)))
        ]);
  }

  Widget _buildCooldownView() {
    return Column(
        key: const ValueKey('timer_view'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تبقى على الجلسة القادمة', style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Text(_convertToArabicNumbers(formatDuration(remainingTime)), style: const TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textDirection: TextDirection.ltr, textAlign: TextAlign.center),
          const SizedBox(height: 8.0),
          const Text('ثانية : دقيقة : ساعة', style: TextStyle(color: Colors.white70, fontSize: 16.0, fontFamily: 'Cairo'), textAlign: TextAlign.center)
        ]);
  }

  Widget _buildTestCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6.0)],
      ),
      child: Column(
        children: [
          const Text("اختبار مهارات التواصل الاجتماعي", style: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 8),
          Text("تقييم لقياس مدى التقدم في مهارات التواصل.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontFamily: 'Cairo')),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: _isFetchingTest || _isStartingSession ? null : _startTest,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0))),
              child: _isFetchingTest
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('ابدأ الاختبار', style: TextStyle(fontSize: 16.0, fontFamily: 'Cairo', fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6.0)],
      ),
      child: Column(
        children: [
          const Text(
            "مراجعة التمارين",
            style: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 8),
          Text(
            "شاهد كل التمارين السابقة التي تم إنجازها.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReviewSessionsScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
            ),
            child: const Text('عرض التمارين', style: TextStyle(fontSize: 16.0, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}