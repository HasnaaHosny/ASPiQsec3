/*import 'package:flutter/material.dart';
import 'package:myfinalpro/widget/page_route_names.dart';
import 'package:myfinalpro/widget/routes_generator.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASPIQ',
      debugShowCheckedModeBanner: false,
      initialRoute: PageRouteName.initial,
      onGenerateRoute: RoutesGenerator.onGenerateRoute,
    );
  }يص
}*/
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // <-- *** 1. استيراد Provider ***

// ! تأكد من صحة هذه المسارات
import 'package:myfinalpro/core/serveses/shared_preferance_servace.dart';
import 'package:myfinalpro/services/bloc_observer.dart';
import 'package:myfinalpro/widget/page_route_names.dart';
import 'package:myfinalpro/widget/routes_generator.dart';
import 'package:myfinalpro/services/Api_services.dart'; // <-- *** 2. استيراد ApiService ***
import 'package:myfinalpro/services/notification_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SharedPreferenceServices.init();
    print("SharedPreferences Initialized Successfully in main.");
  } catch (e, s) {
    print("!!!!!!!! ERROR initializing SharedPreferences in main: $e !!!!!!!!");
    print("Stacktrace: $s");
  }

  try {
    Bloc.observer = MyBlocObserver();
    print("BlocObserver Initialized.");
  } catch (e) {
    print("Error initializing BlocObserver: $e");
  }

  // Initialize local notifications
  await NotificationManager.initializeLocalNotifications();
  // Request iOS permissions
  await NotificationManager.flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  // Send a welcome notification only once after install
  final prefs = await SharedPreferences.getInstance();
  final hasSentWelcome = prefs.getBool('welcome_notification_sent') ?? false;
  if (!hasSentWelcome) {
    await NotificationManager.flutterLocalNotificationsPlugin.show(
      0,
      'مرحبًا بك!',
      'في ASPIQ، نحن سعداء لانضمامك إلينا',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'app_channel_id',
          'App Notifications',
          channelDescription: 'Notifications from the app',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: 'ic_stat_logo',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    await prefs.setBool('welcome_notification_sent', true);
  }

  // --- الخطوة 4: تشغيل التطبيق ---
  // لا تغيير هنا، الـ Provider سيكون داخل MyApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- *** 3. تغليف MaterialApp بـ Provider *** ---
    return Provider<ApiService>(
      // إنشاء نسخة واحدة من ApiService عند بداية التطبيق
      create: (_) => ApiService(),
      child: MaterialApp(
        title: 'ASPIQ',
        debugShowCheckedModeBanner: false,
        // --- دعم اللغة العربية ---
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // supportedLocales: const [
        //   Locale('ar', ''), // العربية
        // ],
        locale: const Locale('ar', ''), // تحديد العربية كلغة افتراضية
        theme: ThemeData(
          primaryColor: const Color(0xff2C73D9),
          fontFamily: 'Cairo', // استخدام الخط Cairo
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2C73D9)),
          useMaterial3: true,
        ),
        initialRoute: PageRouteName.initial,
        onGenerateRoute: RoutesGenerator.onGenerateRoute,
      ),
    );
    // --- *** نهاية التغليف *** ---
  }
}
