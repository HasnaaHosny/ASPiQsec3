// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- تم تغيير اسم الاستيراد هنا ليتوافق مع اسم الكلاس الفعلي ---
import 'package:myfinalpro/screens/start_test_screen.dart'
    as monthly_test_intro_screen; // Timetest
// --- نهاية التغيير ---
// import 'package:myfinalpro/screens/skills.dart'; // <-- إذا لم يكن مستخدمًا، يمكنك إزالته
import 'package:myfinalpro/widget/side_bar_menu.dart.dart';
import 'package:myfinalpro/widgets/Notifictionicon.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/login/login_view.dart';
import 'package:myfinalpro/session/session_intro_screen.dart';
import 'package:myfinalpro/session/models/session_model.dart';
import 'package:myfinalpro/emotion/sequential_session_screen.dart'; // إذا لم يكن مستخدمًا، يمكنك إزالته
import 'package:myfinalpro/test3months/test_group_model.dart';
import 'package:myfinalpro/test3months/group_test_manager_screen.dart';
import 'package:myfinalpro/emotion/training_sessions_screen_v2.dart';
import 'package:myfinalpro/models/notification_item.dart' as notif_model;
import 'package:myfinalpro/services/notification_manager.dart';
import '../Report/progress_bar.dart';
// --- استيراد موديل الاختبار الشهري ---
import 'package:myfinalpro/monthly_test/monthly_test_response.dart';
// --- استيراد Failure ---
import 'package:myfinalpro/core/errors/failures.dart'; // تأكد أن هذا المسار صحيح لملف failures.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSessionAvailable = false;
  bool isSessionInProgressOrCoolingDown = true;
  Duration remainingTime = Duration.zero;
  Timer? cooldownTimer;
  bool _isLoading = true;
  String? _errorMessage;
  String? _jwtToken;
  Session? _nextSessionData;
  bool _isFetchingTestGroup = false;
  bool _isFetchingMonthlyTest = false;

  final GlobalKey<NotificationIconState> _notificationIconKey =
      GlobalKey<NotificationIconState>();
  static const sessionCooldownDuration = Duration(days: 2);

  @override
  void initState() {
    super.initState();
    debugPrint("--- HomeScreen initState START ---");
    _loadTokenAndInitialData();
    debugPrint("--- HomeScreen initState END ---");
  }

  @override
  void dispose() {
    debugPrint("--- HomeScreen dispose ---");
    cooldownTimer?.cancel();
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _updateSessionNotifications() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final lastSessionTimestamp = prefs.getInt('lastSessionStartTime') ?? 0;

    if (isSessionInProgressOrCoolingDown && lastSessionTimestamp > 0) {
      await NotificationManager.addOrUpdateNotification(
          notif_model.NotificationItem(
        id: 'session_status_ended',
        title:
            "انتهت الجلسة ${notif_model.formatTimeAgo(DateTime.fromMillisecondsSinceEpoch(lastSessionTimestamp))}",
        createdAt: DateTime.now(),
        type: notif_model.NotificationType.sessionEnded,
      ));
      if (remainingTime.inSeconds > 0) {
        await NotificationManager.addOrUpdateNotification(
            notif_model.NotificationItem(
          id: 'session_status_upcoming',
          title:
              "الجلسة القادمة بعد ${_convertToArabicNumbers(formatDuration(remainingTime))}",
          createdAt: DateTime.now(),
          type: notif_model.NotificationType.sessionUpcoming,
        ));
      }
    } else if (isSessionAvailable &&
        _nextSessionData != null &&
        _nextSessionData!.typeId != 99) {
      await NotificationManager.addOrUpdateNotification(
          notif_model.NotificationItem(
        id: 'session_status_ready_${_nextSessionData!.id}',
        title: "حان وقت الجلسة! (${_nextSessionData?.title ?? 'غير محدد'})",
        createdAt: DateTime.now(),
        type: notif_model.NotificationType.sessionReady,
      ));
    }
    _notificationIconKey.currentState?.refreshNotifications();
  }

  Future<void> _loadTokenAndInitialData() async {
    if (!mounted) return;
    if (!_isLoading &&
        !_isFetchingTestGroup &&
        !_isFetchingMonthlyTest &&
        (cooldownTimer == null || !cooldownTimer!.isActive)) {
      setStateIfMounted(() => _isLoading = true);
    }
    setStateIfMounted(() => _errorMessage = null);

    try {
      final prefs = await SharedPreferences.getInstance();
      _jwtToken = prefs.getString('auth_token');
      if (!mounted) return;

      if (_jwtToken == null || _jwtToken!.isEmpty) {
        debugPrint("HomeScreen: Token not found. Redirecting to Login.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false);
          }
        });
        if (mounted) setStateIfMounted(() => _isLoading = false);
        return;
      }
      debugPrint("HomeScreen: Token loaded successfully.");
      await _loadSessionCooldownDataFromPrefs(prefs);
    } catch (e, s) {
      debugPrint("HomeScreen: Error during initial data load: $e\n$s");
      if (mounted) {
        setStateIfMounted(() {
          _errorMessage = "حدث خطأ أثناء تحميل البيانات الأولية.";
          _isLoading = false;
        });
      }
    } finally {
      if (mounted &&
          !_isFetchingTestGroup &&
          !_isFetchingMonthlyTest &&
          (cooldownTimer == null ||
              !cooldownTimer!.isActive ||
              !isSessionInProgressOrCoolingDown)) {
        setStateIfMounted(() => _isLoading = false);
      }
      await _updateSessionNotifications();
      debugPrint(
          "HomeScreen: Load finished. Loading: $_isLoading, ErrorMsg: $_errorMessage, SessionAvailable: $isSessionAvailable, CoolingDown: $isSessionInProgressOrCoolingDown, FetchingGroup: $_isFetchingTestGroup, FetchingMonthly: $_isFetchingMonthlyTest");
    }
  }

  Future<void> _loadSessionCooldownDataFromPrefs(
      SharedPreferences prefs) async {
    final lastSessionTimestamp = prefs.getInt('lastSessionStartTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (lastSessionTimestamp == 0) {
      debugPrint(
          "HomeScreen: Cooldown not active (first time/reset). Fetching.");
      if (mounted) {
        setStateIfMounted(() {
          isSessionInProgressOrCoolingDown = false;
          remainingTime = Duration.zero;
        });
      }
      cooldownTimer?.cancel();
      await _fetchNextSessionDataFromApi();
      return;
    }
    final elapsedTime = currentTime - lastSessionTimestamp;
    if (elapsedTime >= sessionCooldownDuration.inMilliseconds) {
      debugPrint("HomeScreen: Cooldown completed. Fetching.");
      if (mounted) {
        setStateIfMounted(() {
          isSessionInProgressOrCoolingDown = false;
          remainingTime = Duration.zero;
          isSessionAvailable = false;
          _nextSessionData = null;
        });
      }
      cooldownTimer?.cancel();
      await _fetchNextSessionDataFromApi();
    } else {
      final remainingMs = sessionCooldownDuration.inMilliseconds - elapsedTime;
      debugPrint(
          "HomeScreen: Cooldown active. Remaining: ${Duration(milliseconds: remainingMs)}");
      if (mounted) {
        if (isSessionAvailable) isSessionAvailable = false;
        if (_nextSessionData != null) _nextSessionData = null;
        setStateIfMounted(() {
          isSessionInProgressOrCoolingDown = true;
          remainingTime = Duration(milliseconds: remainingMs);
        });
      }
      _startUiUpdateTimer(lastSessionTimestamp);
    }
  }

  Future<void> _fetchNextSessionDataFromApi() async {
    if (isSessionInProgressOrCoolingDown &&
        cooldownTimer != null &&
        cooldownTimer!.isActive) {
      debugPrint("HomeScreen: Cooldown active via timer, skipping fetch.");
      return;
    }
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      if (mounted) setStateIfMounted(() => _errorMessage = "Token مفقود.");
      if (mounted && !_isFetchingTestGroup && !_isFetchingMonthlyTest) {
        setStateIfMounted(() => _isLoading = false);
      }
      return;
    }
    if (!_isLoading && !_isFetchingTestGroup && !_isFetchingMonthlyTest) {
      setStateIfMounted(() => _isLoading = true);
    }
    try {
      _nextSessionData = await ApiService.getNextPendingSession(_jwtToken!);
      if (!mounted) return;
      if (_nextSessionData != null) {
        debugPrint(
            "HomeScreen: Fetched _nextSessionData: ID=${_nextSessionData!.sessionId}, Title='${_nextSessionData!.title}', TypeID=${_nextSessionData!.typeId}, Attrs=${_nextSessionData!.attributes}");
        await _checkAndGenerateTestNotificationsBasedOnSessionObject(
            _nextSessionData!);
        if (_nextSessionData!.typeId != 99 &&
            _nextSessionData!.title != null &&
            _nextSessionData!.title != "رسالة نظام" &&
            _nextSessionData!.title != "تنبيه هام") {
          setStateIfMounted(() {
            isSessionAvailable = true;
            _errorMessage = null;
          });
        } else {
          setStateIfMounted(() {
            isSessionAvailable = false;
            if (_errorMessage == null &&
                (_nextSessionData!.attributes == null ||
                    _nextSessionData!.attributes!.isEmpty ||
                    (_nextSessionData!.attributes!['monthly_test_message'] ==
                            null &&
                        _nextSessionData!
                                .attributes!['three_month_test_message'] ==
                            null))) {
              _errorMessage = _nextSessionData!.description ??
                  _nextSessionData!.title ??
                  "لا توجد مهام جديدة.";
            } else if (_nextSessionData!.attributes != null &&
                (_nextSessionData!.attributes!['monthly_test_message'] !=
                        null ||
                    _nextSessionData!.attributes!['three_month_test_message'] !=
                        null)) {
              _errorMessage = null;
            }
          });
        }
      } else {
        setStateIfMounted(() {
          isSessionAvailable = false;
          if (_errorMessage == null) _errorMessage = "اكتملت الخطة التدريبية.";
        });
      }
    } on Exception catch (e) {
      if (!mounted) return;
      String errorMsg = "خطأ جلب الجلسة.";
      if (e.toString().contains('Unauthorized')) {
        errorMsg = "انتهت صلاحية الدخول.";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false);
          }
        });
      } else if (e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket')) {
        errorMsg = "خطأ في الشبكة.";
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorMsg = "انتهت مهلة الطلب.";
      }
      debugPrint("HomeScreen _fetchNextSessionDataFromApi Error: $e");
      setStateIfMounted(() {
        _nextSessionData = null;
        isSessionAvailable = false;
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted && !_isFetchingTestGroup && !_isFetchingMonthlyTest) {
        setStateIfMounted(() => _isLoading = false);
      }
      await _updateSessionNotifications();
    }
  }

  Future<void> _checkAndGenerateTestNotificationsBasedOnSessionObject(
      Session sessionData) async {
    if (!mounted) return;
    bool inAppNotificationCreated = false;
    final monthlyTestMessage =
        sessionData.attributes?['monthly_test_message'] as String?;
    if (monthlyTestMessage != null && monthlyTestMessage.isNotEmpty) {
      bool alreadySent =
          await NotificationManager.isMonthlyTestNotificationSent();
      if (!alreadySent) {
        final String id =
            'monthly_test_available_${sessionData.attributes?['monthly_test_session_id'] ?? sessionData.sessionId ?? DateTime.now().millisecondsSinceEpoch}';
        await NotificationManager.addOrUpdateNotification(
            notif_model.NotificationItem(
                id: id,
                title: monthlyTestMessage,
                createdAt: DateTime.now(),
                type: notif_model.NotificationType.monthlyTestAvailable));
        await NotificationManager.setMonthlyTestNotificationSent(true);
        inAppNotificationCreated = true;
        debugPrint(
            "HomeScreen: Monthly Test IN-APP Notification CREATED: $monthlyTestMessage");
      } else {
        debugPrint("HomeScreen: Monthly Test Notification was ALREADY SENT.");
      }
    }
    final threeMonthTestMessage =
        sessionData.attributes?['three_month_test_message'] as String?;
    if (threeMonthTestMessage != null && threeMonthTestMessage.isNotEmpty) {
      bool alreadySent =
          await NotificationManager.isThreeMonthTestNotificationSent();
      if (!alreadySent) {
        final String id =
            '3_month_test_available_${DateTime.now().millisecondsSinceEpoch}';
        await NotificationManager.addOrUpdateNotification(
            notif_model.NotificationItem(
                id: id,
                title: threeMonthTestMessage,
                createdAt: DateTime.now(),
                type: notif_model.NotificationType.threeMonthTestAvailable));
        await NotificationManager.setThreeMonthTestNotificationSent(true);
        inAppNotificationCreated = true;
        debugPrint(
            "HomeScreen: 3-Month Test IN-APP Notification CREATED: $threeMonthTestMessage");
      } else {
        debugPrint("HomeScreen: 3-Month Test Notification was ALREADY SENT.");
      }
    }
    if (inAppNotificationCreated) {
      _notificationIconKey.currentState?.refreshNotifications();
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
      if (elapsedMillis >= sessionCooldownDuration.inMilliseconds) {
        cooldownTimer?.cancel();
        if (mounted) {
          setStateIfMounted(() {
            isSessionInProgressOrCoolingDown = false;
            remainingTime = Duration.zero;
            isSessionAvailable = false;
            _nextSessionData = null;
          });
        }
        await _fetchNextSessionDataFromApi();
      } else {
        final newRemainingTime =
            sessionCooldownDuration - Duration(milliseconds: elapsedMillis);
        if (mounted && isSessionInProgressOrCoolingDown) {
          if (remainingTime.inSeconds != newRemainingTime.inSeconds) {
            setStateIfMounted(() => remainingTime = newRemainingTime);
          }
        } else if (mounted && !isSessionInProgressOrCoolingDown) {
          cooldownTimer?.cancel();
        }
      }
      if (mounted) await _updateSessionNotifications();
    }

    if (isSessionInProgressOrCoolingDown) {
      updateRemainingTimeCallback();
      cooldownTimer = Timer.periodic(
          const Duration(seconds: 1), (timer) => updateRemainingTimeCallback());
    }
  }

  String formatDuration(Duration duration) {
    duration = duration.isNegative ? Duration.zero : duration;
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

  Future<void> _startSession() async {
    if (!isSessionAvailable ||
        _nextSessionData == null ||
        _jwtToken == null ||
        _nextSessionData!.typeId == 99) {
      debugPrint(
          "HomeScreen: Cannot start session. Available: $isSessionAvailable, Data: ${_nextSessionData != null}, Token: ${_jwtToken != null}, Type: ${_nextSessionData?.typeId}");
      if (_nextSessionData?.typeId == 99 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "هذا تنبيه لاختبار، يرجى الذهاب للاختبار من الزر المخصص.",
                textDirection: TextDirection.rtl)));
      } else if (!isSessionAvailable && _errorMessage == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("لا توجد جلسة متاحة.", textDirection: TextDirection.rtl)));
      }
      return;
    }
    try {
      if (!mounted) return;
      final sessionResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (context) => SessionIntroScreen(
                  session: _nextSessionData!, jwtToken: _jwtToken!)));
      if (sessionResult == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('lastSessionStartTime', nowMillis);
        setStateIfMounted(() {
          isSessionAvailable = false;
          isSessionInProgressOrCoolingDown = true;
          remainingTime = sessionCooldownDuration;
          _nextSessionData = null;
          _errorMessage = null;
        });
        _startUiUpdateTimer(nowMillis);
      } else if (mounted && !isSessionInProgressOrCoolingDown) {
        await _fetchNextSessionDataFromApi();
      }
    } catch (e) {
      debugPrint("HomeScreen: Error in _startSession nav: $e");
    }
    if (mounted) await _updateSessionNotifications();
  }

  Future<void> _showInfoDialog(String title, String message) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C73D9),
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 16.0, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'حسنًا',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: Color(0xFF2C73D9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _startThreeMonthTest() async {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      if (mounted) _showLoginRedirectSnackbar();
      return;
    }
    if (_isFetchingTestGroup) return;
    setStateIfMounted(() => _isFetchingTestGroup = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("جاري تحميل اختبار الـ 3 شهور...",
              textDirection: TextDirection.rtl),
          duration: Duration(seconds: 2)));
    }

    try {
      final TestGroupResponse? testGroupData =
          await ApiService.fetchNextTestGroup(_jwtToken!);
      if (!mounted) return;

      if (testGroupData != null && testGroupData.sessions.isNotEmpty) {
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GroupTestManagerScreen(
                        testGroupData: testGroupData,
                        jwtToken: _jwtToken!,
                        notificationIconKey: _notificationIconKey)))
            .then((_) => _loadTokenAndInitialData());
      } else {
        if (mounted) {
          _showInfoDialog(
            "تنبيه",
            "لا يوجد اختبار 3 شهور متاح حاليًا.",
          );
        }
      }
    } catch (e) {
      debugPrint("HomeScreen: Error starting 3-month test: $e");
      if (mounted) {
        String msg = "خطأ تحميل اختبار الـ 3 شهور.";
        if (e.toString().contains('Unauthorized')) {
          msg = "انتهت صلاحية الدخول.";
        }
        _showInfoDialog(
          "خطأ",
          msg,
        );
      }
    } finally {
      if (mounted) setStateIfMounted(() => _isFetchingTestGroup = false);
    }
  }

  // --- *** بداية دالة _startMonthlyTest المعدلة *** ---
  Future<void> _startMonthlyTest() async {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      if (mounted) _showLoginRedirectSnackbar();
      return;
    }
    if (_isFetchingMonthlyTest) return;
    setStateIfMounted(() => _isFetchingMonthlyTest = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("جاري التحقق من توفر التقييم الشهري...",
              textDirection: TextDirection.rtl),
          duration: Duration(seconds: 2)));
    }

    try {
      // استخدم كائن ApiService المعرف في الكلاس إذا كان لديك واحد،
      // أو قم بإنشاء واحد هنا إذا كانت الدالة getMonthlyTestDetails غير static.
      // بما أن getMonthlyTestDetails في الكود الذي قدمته هي instance method،
      // سنحتاج إلى إنشاء كائن ApiService.
      final ApiService apiService =
          ApiService(); // إذا لم يكن لديك كائن ApiService عام
      final result = await apiService
          .getMonthlyTestDetails(); // لا تحتاج jwtToken هنا إذا كانت الدالة تتعامل معه داخليًا

      if (!mounted) return;

      result.fold((failure) {
        debugPrint(
            "HomeScreen: Failed to fetch monthly test - ${failure.message}");
        String userMessage;
        // --- *** تعديل هنا لتخصيص رسالة الخطأ *** ---
        if (failure is ServerFailure &&
            (failure.message
                    .toLowerCase()
                    .contains("لم يتم إنهاء جلسة التدريب بعد") ||
                failure.message
                    .toLowerCase()
                    .contains("لا يمكن بدء اختبار الشهر") ||
                failure.message.toLowerCase().contains(
                    "cannot start monthly test yet") // إضافة تحقق بالإنجليزية
            )) {
          userMessage =
              "لا يوجد اختبار شهر متاح الآن. يرجى إكمال جلسات التدريب الخاصة بك أولاً.";
        } else if (failure is NotFoundFailure) {
          userMessage =
              "لا يوجد تقييم شهري متاح حاليًا. يرجى إكمال المزيد من الجلسات التدريبية أولاً.";
        } else if (failure is ServerFailure &&
            failure.message.contains("Unauthorized")) {
          userMessage = "انتهت صلاحية الدخول. يرجى تسجيل الدخول مرة أخرى.";
        } else if (failure is ServerFailure) {
          userMessage =
              "حدث خطأ من الخادم أثناء محاولة تحميل الاختبار الشهري. حاول مرة أخرى لاحقًا.";
        } else {
          userMessage =
              "فشل تحميل بيانات التقييم الشهري (${failure.message}). حاول مرة أخرى أو أكمل جلساتك.";
        }
        // --- *** نهاية التعديل هنا *** ---
        _showInfoDialog("تنبيه", userMessage);
      }, (monthlyTestResponse) {
        bool isTestAvailable = false;
        String unavailabilityMessage =
            "لا يوجد تقييم شهري متاح حاليًا. يرجى إكمال المزيد من الجلسات التدريبية أولاً.";

        // --- *** تعديل هنا لتخصيص رسالة عدم التوفر *** ---
        if (monthlyTestResponse.messageFromApi != null) {
          String apiMsgLower =
              monthlyTestResponse.messageFromApi!.toLowerCase();
          if (apiMsgLower.contains("لم يتم إنهاء جلسة التدريب بعد") ||
                  apiMsgLower.contains("لا يمكن بدء اختبار الشهر") ||
                  apiMsgLower.contains(
                      "cannot start monthly test yet") // إضافة تحقق بالإنجليزية
              ) {
            isTestAvailable = false;
            unavailabilityMessage =
                "لا يوجد اختبار شهر متاح الآن. يرجى إكمال جلسات التدريب الخاصة بك أولاً.";
          } else if (apiMsgLower.contains("not available") ||
              apiMsgLower.contains("غير متاح") ||
              apiMsgLower.contains("لا يوجد اختبار")) {
            isTestAvailable = false;
            unavailabilityMessage =
                "${monthlyTestResponse.messageFromApi}. يرجى إكمال المزيد من الجلسات التدريبية.";
          } else if (monthlyTestResponse.details.isNotEmpty ||
              monthlyTestResponse.newDetails.isNotEmpty) {
            isTestAvailable = true;
          } else {
            isTestAvailable = false;
          }
        } else if (monthlyTestResponse.details.isNotEmpty ||
            monthlyTestResponse.newDetails.isNotEmpty) {
          isTestAvailable = true;
        } else {
          isTestAvailable = false;
        }
        // --- *** نهاية التعديل هنا *** ---

        if (isTestAvailable) {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const monthly_test_intro_screen.Timetest()))
              .then((_) => _loadTokenAndInitialData());
        } else {
          _showInfoDialog("تنبيه", unavailabilityMessage);
        }
      });
    } catch (e) {
      debugPrint("HomeScreen: Unexpected error in _startMonthlyTest: $e");
      if (mounted) {
        _showInfoDialog(
          "خطأ",
          "حدث خطأ غير متوقع أثناء محاولة بدء التقييم الشهري.",
        );
      }
    } finally {
      if (mounted) setStateIfMounted(() => _isFetchingMonthlyTest = false);
    }
  }
  // --- *** نهاية دالة _startMonthlyTest المعدلة *** ---

  void _showLoginRedirectSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("يرجى تسجيل الدخول أولاً.",
              textDirection: TextDirection.rtl)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2C73D9);
    bool showAppLoadingIndicator = _isLoading &&
        !_isFetchingTestGroup &&
        !_isFetchingMonthlyTest &&
        (cooldownTimer == null || !cooldownTimer!.isActive);

    const pageHorizontalPadding = 16.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        endDrawer: const SideBarMenuTest(),
        appBar: AppBar(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          actions: [
            Padding(
                padding: const EdgeInsets.only(
                  left: pageHorizontalPadding,
                  top: 8.0,
                ),
                child: Builder(
                    builder: (context) => IconButton(
                        icon: const Icon(Icons.menu,
                            color: primaryBlue, size: 32.0),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        tooltip: MaterialLocalizations.of(context)
                            .openAppDrawerTooltip))),
          ],
          leading: NotificationIcon(
              key: _notificationIconKey,
              onNotificationsUpdated: _loadTokenAndInitialData),
        ),
        body: showAppLoadingIndicator
            ? const Center(
                child: CircularProgressIndicator(
                    color: primaryBlue, strokeWidth: 3.0))
            : RefreshIndicator(
                onRefresh: _loadTokenAndInitialData,
                color: primaryBlue,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: pageHorizontalPadding, vertical: 16.0),
                  children: [
                    const Center(
                        child: Text('مرحبا !',
                            style: TextStyle(
                                fontSize: 28,
                                color: primaryBlue,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16.0),
                    if (_errorMessage != null &&
                        !isSessionInProgressOrCoolingDown &&
                        !_isFetchingTestGroup &&
                        !_isFetchingMonthlyTest &&
                        !_isLoading)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Center(
                              child: Text(_errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: _errorMessage!
                                                  .contains("اكتملت") ||
                                              _errorMessage!.contains("متاحة")
                                          ? Colors.green.shade700
                                          : Colors.redAccent,
                                      fontFamily: 'Cairo',
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500)))),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 112.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8.0,
                                offset: const Offset(0, 4.0))
                          ]),
                      child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (Widget child,
                                  Animation<double> animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: isSessionInProgressOrCoolingDown
                              ? Column(
                                  key: const ValueKey('timer_view'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      const Text('تبقى على الجلسة القادمة',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.0,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8.0),
                                      Text(
                                          _convertToArabicNumbers(
                                              formatDuration(remainingTime)),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 40.0,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace'),
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 8.0),
                                      const Text('ثانية : دقيقة : ساعة ',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16.0,
                                              fontFamily: 'Cairo'),
                                          textAlign: TextAlign.center)
                                    ])
                              : Container(
                                  key: const ValueKey('start_session_view'),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            flex: 5,
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                      (isSessionAvailable &&
                                                              _nextSessionData !=
                                                                  null &&
                                                              _nextSessionData!
                                                                      .typeId !=
                                                                  99)
                                                          ? 'حان وقت جلسة${_nextSessionData!.title != null && _nextSessionData!.title!.isNotEmpty ? " ${_nextSessionData!.title}" : "!"}'
                                                          : (_errorMessage !=
                                                                      null &&
                                                                  (_errorMessage!
                                                                          .contains(
                                                                              "اكتملت") ||
                                                                      _errorMessage!
                                                                          .contains(
                                                                              "متاحة"))
                                                              ? _errorMessage!
                                                              : "لا توجد جلسات تدريبية متاحة حاليًا"),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18.0,
                                                          fontFamily: 'Cairo',
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      textAlign:
                                                          TextAlign.center),
                                                  const SizedBox(height: 16.0),
                                                  ElevatedButton(
                                                      onPressed: (isSessionAvailable &&
                                                              _nextSessionData !=
                                                                  null &&
                                                              _nextSessionData!
                                                                      .typeId !=
                                                                  99 &&
                                                              !_isFetchingTestGroup &&
                                                              !_isFetchingMonthlyTest)
                                                          ? _startSession
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.white,
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 40.0,
                                                              vertical: 16.0),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      24.0)),
                                                          disabledBackgroundColor: Colors
                                                              .white
                                                              .withAlpha(178),
                                                          disabledForegroundColor:
                                                              primaryBlue
                                                                  .withAlpha(128),
                                                          elevation: 4.0),
                                                      child: Text('لنبدأ', style: TextStyle(color: (isSessionAvailable && _nextSessionData != null && _nextSessionData!.typeId != 99 && !_isFetchingTestGroup && !_isFetchingMonthlyTest) ? primaryBlue : Colors.grey.shade400, fontSize: 16.0, fontFamily: 'Cairo', fontWeight: FontWeight.bold)))
                                                ])),
                                        Expanded(
                                            flex: 4,
                                            child: Image.asset(
                                                "assets/images/session.png",
                                                height: 96.0,
                                                fit: BoxFit.contain,
                                                errorBuilder: (ctx, err, st) =>
                                                    SizedBox(
                                                        height: 96.0,
                                                        child: Center(
                                                            child: Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color: Colors
                                                                    .white54,
                                                                size: 48.0)))))
                                      ]))),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _buildAssessmentCard(
                            title: 'التقييم الشهري',
                            subtitle: 'تقييم شهري لمتابعة التطورات خطوة بخطوة.',
                            buttonText: 'ابدأ الاختبار',
                            onPressed:
                                _isFetchingMonthlyTest || _isFetchingTestGroup
                                    ? null
                                    : _startMonthlyTest,
                            isLoading: _isFetchingMonthlyTest,
                          )),
                          const SizedBox(width: 8.0),
                          Expanded(
                              child: _buildAssessmentCard(
                            title: 'اختبار الـ 3 شهور',
                            subtitle:
                                'تقييم شامل كل ثلاثة أشهر لقياس التقدم العام.',
                            buttonText: 'ابدأ الاختبار',
                            onPressed:
                                _isFetchingMonthlyTest || _isFetchingTestGroup
                                    ? null
                                    : _startThreeMonthTest,
                            isLoading: _isFetchingTestGroup,
                          )),
                        ]),
                    const SizedBox(height: 16.0),
                    const Padding(
                        padding: EdgeInsets.only(right: 8.0, bottom: 8.0),
                        child: Text('تطوير المهارات وإدارة الانفعالات',
                            style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: primaryBlue))),
                    ProgressBarCard(
                      title: 'الانفعالات',
                      description:
                          'تمارين للتعرف على المشاعر وإدارتها بفعالية.',
                      endpoint: 'http://aspiq.runasp.net/api/Reports/progress1',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TrainingSessionsScreen())),
                    ),
                    const SizedBox(height: 8.0),
                    ProgressBarCard(
                      title: 'تنمية المهارات',
                      description:
                          'استكشف تمارين قيمة لتطوير مهاراتك الشخصية والاجتماعية!',
                      endpoint: 'http://aspiq.runasp.net/api/Reports/progress2',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  TrainingSessionsScreenV2())),
                    ),
                    const SizedBox(height: 40.0),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAssessmentCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback? onPressed,
    required bool isLoading,
    Color cardBgColor = const Color(0xFFE3F2FD),
    Color textColor = const Color(0xFF2C73D9),
    Color buttonBgColor = const Color(0xFF2C73D9),
    Color buttonFgColor = Colors.white,
  }) {
    return Container(
        constraints: const BoxConstraints(minHeight: 176.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4.0))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: textColor)),
                const SizedBox(height: 8.0),
                Text(subtitle,
                    style: TextStyle(
                        color: textColor.withAlpha(191),
                        fontSize: 12.0,
                        fontFamily: 'Cairo',
                        height: 1.3))
              ]),
              const SizedBox(height: 16.0),
              Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                      onPressed: onPressed,
                      child: isLoading
                          ? const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.0, color: Colors.white))
                          : Text(buttonText,
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.0)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBgColor,
                          foregroundColor: buttonFgColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 8.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)))))
            ]));
  }
}
