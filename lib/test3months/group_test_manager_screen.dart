import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

import 'test_group_model.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/screens/common/loading_indicator.dart';
import 'package:myfinalpro/screens/home_screen.dart';
import 'group_test_question_display_screen.dart';

import 'package:myfinalpro/models/notification_item.dart' as notif_model;
import 'package:myfinalpro/services/notification_manager.dart';
import 'package:myfinalpro/widgets/Notifictionicon.dart'; // تأكد من أن اسم الملف صحيح (NotificationIcon)

// GeneratedQuestion class
class GeneratedQuestion {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? imagePath1;
  final String? textContent1;
  final String? imagePath2;
  final String? textContent2;
  final bool isTwoElements;
  final String? mainItemName;
  final String? secondItemName;
  final int originalDetailId;
  final String sectionTitle;
  final bool isImageOptions;
  final List<String?> optionImagePaths;
  final int parentSessionId;

  GeneratedQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.originalDetailId,
    required this.sectionTitle,
    required this.parentSessionId,
    this.imagePath1,
    this.textContent1,
    this.imagePath2,
    this.textContent2,
    this.isTwoElements = false,
    this.mainItemName,
    this.secondItemName,
    this.isImageOptions = false,
    this.optionImagePaths = const [],
  });
}

class GroupTestManagerScreen extends StatefulWidget {
  final TestGroupResponse testGroupData;
  final String jwtToken;
  final GlobalKey<NotificationIconState>? notificationIconKey;

  const GroupTestManagerScreen({
    super.key,
    required this.testGroupData,
    required this.jwtToken,
    this.notificationIconKey,
  });

  @override
  State<GroupTestManagerScreen> createState() => _GroupTestManagerScreenState();
}

class _GroupTestManagerScreenState extends State<GroupTestManagerScreen> {
  int _currentGlobalQuestionIndex = 0;
  List<GeneratedQuestion> _allGeneratedQuestions = [];
  bool _isLoadingScreen = true;
  bool _isProcessingAnswer = false;
  bool _isCompletingGroup = false;
  int _totalCorrectAnswers = 0;
  List<String> _objectImagePaths = [];
  final Random _random = Random();
  int _buildCount = 0;
  late ConfettiController _confettiController;

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    debugPrint(
        "GroupTestManager: initState - Screen Initializing. Total Sessions: ${widget.testGroupData.sessions.length}");
    _initializeScreenData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    debugPrint(
        "GroupTestManager: dispose. GroupID: ${widget.testGroupData.groupId}");
    super.dispose();
  }

  Future<void> _initializeScreenData() async {
    setStateIfMounted(() => _isLoadingScreen = true);
    await _loadObjectImagePathsFromAssets();
    _generateAllQuestionsAndRefreshUI();
  }

  Future<void> _loadObjectImagePathsFromAssets() async {
    try {
      const String assetPathPrefix = 'assets/objects/';
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      _objectImagePaths = manifestMap.keys
          .where((String key) =>
              key.startsWith(assetPathPrefix) &&
              key != assetPathPrefix &&
              (key.endsWith('.png') ||
                  key.endsWith('.jpg') ||
                  key.endsWith('.jpeg') ||
                  key.endsWith('.gif') ||
                  key.endsWith('.webp')))
          .toList();
      debugPrint(
          "GroupTestManager: Loaded ${_objectImagePaths.length} random images from '$assetPathPrefix'");
      if (_objectImagePaths.isEmpty) {
        debugPrint(
            "GroupTestManager: Warning - No distractor images found in '$assetPathPrefix'.");
      }
    } catch (e) {
      debugPrint(
          "GroupTestManager: Error loading object image paths from assets: $e");
      _objectImagePaths = [];
    }
  }

  String? _getRandomObjectImagePath() {
    if (_objectImagePaths.isEmpty) return null;
    String? randomPath;
    int attempts = 0;
    const maxAttempts = 5;
    String? currentComparisonPath;
    if (_currentGlobalQuestionIndex < _allGeneratedQuestions.length) {
      final currentQuestion =
          _allGeneratedQuestions[_currentGlobalQuestionIndex];
      currentComparisonPath = currentQuestion.imagePath1 ??
          (currentQuestion.optionImagePaths.isNotEmpty
              ? currentQuestion.optionImagePaths
                  .firstWhere((p) => p != null, orElse: () => null)
              : null);
    }
    do {
      randomPath = _objectImagePaths[_random.nextInt(_objectImagePaths.length)];
      attempts++;
    } while (randomPath == currentComparisonPath &&
        _objectImagePaths.length > 1 &&
        attempts < maxAttempts);
    return randomPath;
  }

  void _generateAllQuestionsAndRefreshUI() {
    if (!mounted) return;
    if (!_isLoadingScreen &&
        _currentGlobalQuestionIndex == 0 &&
        _allGeneratedQuestions.isEmpty) {
      setStateIfMounted(() => _isLoadingScreen = true);
    }

    List<GeneratedQuestion> allQuestionsCollector = [];
    final String mainGroupName = widget.testGroupData.groupName;
    debugPrint(
        "GroupTestManager: Generating Questions for group: '$mainGroupName'. Sessions: ${widget.testGroupData.sessions.length}");

    for (int sessionIdx = 0;
        sessionIdx < widget.testGroupData.sessions.length;
        sessionIdx++) {
      final currentSession = widget.testGroupData.sessions[sessionIdx];
      final String currentSessionTitle = currentSession.title.isNotEmpty
          ? currentSession.title
          : mainGroupName;
      final int currentParentSessionId = currentSession.sessionId;

      debugPrint(
          "  Processing Session ${sessionIdx + 1}: '$currentSessionTitle' (ID: ${currentSession.sessionId}) with ${currentSession.details.length} details, newDetail ID: ${currentSession.newDetail.detailId}");

      final bool isSpecialSession = currentSession.sessionId > 28;

      if (isSpecialSession) {
        for (final detail in currentSession.details) {
          allQuestionsCollector.add(GeneratedQuestion(
            originalDetailId: detail.detailId,
            sectionTitle: currentSessionTitle,
            questionText:"هل هذا التصرف صح ام خطأ؟",
            options: ["صح", "خطأ"],
            correctAnswer: detail.rightAnswer,
            imagePath1: detail.localAssetPath,
            textContent1: detail.textContent,
            mainItemName: mainGroupName,
            isImageOptions: false,
            optionImagePaths: [],
            parentSessionId: currentParentSessionId,
          ));
          debugPrint(
              "      Special Session Q: '${allQuestionsCollector.last.questionText}' (detailId: ${detail.detailId})");
        }
      } else if (sessionIdx == 0 &&
          currentSession.title.contains("فهم") &&
          currentSession.sessionId <= 28) {
        final detailsForFahm = currentSession.details;
        final newDetailForFahm = currentSession.newDetail;

        if (detailsForFahm.isNotEmpty) {
          final detail0 = detailsForFahm[0];
          allQuestionsCollector.add(GeneratedQuestion(
            originalDetailId: detail0.detailId,
            sectionTitle: currentSessionTitle,
            parentSessionId: currentParentSessionId,
            questionText: detail0.questions ?? "ما الشعور؟",
            options: detail0.answerOptions.isNotEmpty
                ? detail0.answerOptions
                : ["خيار1", "خيار2"],
            correctAnswer: detail0.rightAnswer.isNotEmpty
                ? detail0.rightAnswer
                : (detail0.answerOptions.isNotEmpty
                    ? detail0.answerOptions[0]
                    : "خيار1"),
            imagePath1: detail0.localAssetPath,
            textContent1: detail0.textContent,
            mainItemName: mainGroupName,
            isImageOptions: false,
          ));
          debugPrint(
              "      Fahm Q1 Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail0.detailId})");
        } else {
          debugPrint(
              "      Fahm Q1: SKIPPED - No details[0] in 'فهم' session.");
        }

        if (detailsForFahm.length >= 2 &&
            newDetailForFahm.detailId != 0 &&
            newDetailForFahm.localAssetPath != null) {
          final detail1 = detailsForFahm[1];
          if (detail1.localAssetPath != null) {
            List<String?> imageOptionsPaths = [
              detail1.localAssetPath,
              newDetailForFahm.localAssetPath
            ];
            String correctAnswerValue = detail1.rightAnswer.isNotEmpty
                ? detail1.rightAnswer
                : "correct_img_${detail1.detailId}";
            String distractorValue = (newDetailForFahm.rightAnswer.isNotEmpty &&
                    newDetailForFahm.rightAnswer != correctAnswerValue)
                ? newDetailForFahm.rightAnswer
                : "distractor_img_${newDetailForFahm.detailId}";
            List<String> optionValues = [correctAnswerValue, distractorValue];

            allQuestionsCollector.add(GeneratedQuestion(
              originalDetailId: detail1.detailId,
              sectionTitle: currentSessionTitle,
              parentSessionId: currentParentSessionId,
              questionText: "من يكون ${widget.testGroupData.groupName}؟",
              options: optionValues,
              correctAnswer: correctAnswerValue,
              isImageOptions: true,
              optionImagePaths: imageOptionsPaths,
              mainItemName: mainGroupName,
            ));
            debugPrint(
                "      Fahm Q2 Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail1.detailId})");
          } else {
            debugPrint(
                "      Fahm Q2: SKIPPED - detail[1].localAssetPath is null.");
          }
        } else {
          debugPrint(
              "      Fahm Q2: SKIPPED - Data insufficient. Details: ${detailsForFahm.length}, newDetail ID: ${newDetailForFahm.detailId}");
        }

        if (detailsForFahm.length >= 3) {
          final detail2 = detailsForFahm[2];
          if (detail2.localAssetPath != null) {
            final randomImagePath = _getRandomObjectImagePath();
            if (randomImagePath != null) {
              List<String?> imageOptionsPaths = [
                detail2.localAssetPath,
                randomImagePath
              ];
              String correctAnswerValue = detail2.rightAnswer.isNotEmpty
                  ? detail2.rightAnswer
                  : "correct_img_${detail2.detailId}";
              String distractorValue = "random_img_distractor";
              List<String> optionValues = [correctAnswerValue, distractorValue];

              allQuestionsCollector.add(GeneratedQuestion(
                originalDetailId: detail2.detailId,
                sectionTitle: currentSessionTitle,
                parentSessionId: currentParentSessionId,
                questionText: "من يكون ${widget.testGroupData.groupName}؟",
                options: optionValues,
                correctAnswer: correctAnswerValue,
                isImageOptions: true,
                optionImagePaths: imageOptionsPaths,
                mainItemName: mainGroupName,
              ));
              debugPrint(
                  "      Fahm Q3 Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail2.detailId})");
            } else {
              debugPrint(
                  "      Fahm Q3: SKIPPED - No random distractor image.");
            }
          } else {
            debugPrint(
                "      Fahm Q3: SKIPPED - detail[2].localAssetPath is null.");
          }
        } else {
          debugPrint(
              "      Fahm Q3: SKIPPED - Data insufficient. Details: ${detailsForFahm.length}");
        }
      } else {
        int questionsAddedFromThisSession = 0;
        for (int detailIndex = 0;
            detailIndex < currentSession.details.length &&
                questionsAddedFromThisSession < 3;
            detailIndex++) {
          final detail = currentSession.details[detailIndex];
          allQuestionsCollector.add(GeneratedQuestion(
            originalDetailId: detail.detailId,
            sectionTitle: currentSessionTitle,
            parentSessionId: currentParentSessionId,
            questionText: detail.questions ?? "بماذا يشعر؟",
            options: detail.answerOptions.isNotEmpty
                ? detail.answerOptions
                : ["خيار1", "خيار2"],
            correctAnswer: detail.rightAnswer.isNotEmpty
                ? detail.rightAnswer
                : (detail.answerOptions.isNotEmpty
                    ? detail.answerOptions[0]
                    : "خيار1"),
            imagePath1: detail.localAssetPath,
            textContent1: detail.textContent,
            mainItemName: mainGroupName,
            isImageOptions: false,
          ));
          questionsAddedFromThisSession++;
          debugPrint(
              "      Session '$currentSessionTitle' Q$questionsAddedFromThisSession Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail.detailId})");
        }
        if (questionsAddedFromThisSession == 0 &&
            currentSession.details.isEmpty) {
          debugPrint(
              "      No details for session '$currentSessionTitle'.");
        }
      }
    }

    setStateIfMounted(() {
      _allGeneratedQuestions = allQuestionsCollector;
      _currentGlobalQuestionIndex = 0;
      _isLoadingScreen = false;
      debugPrint(
          "GroupTestManager: setState after generating questions. Total: ${_allGeneratedQuestions.length}. isLoading: $_isLoadingScreen");
      if (_allGeneratedQuestions.isEmpty && mounted && !_isCompletingGroup) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCompletingGroup) {
            _completeTestGroup(
                showError: true,
                errorMessage: "لم يتم العثور على أسئلة صالحة للاختبار.");
          }
        });
      }
    });
  }

  Future<void> _showInternalSuccessDialog() async {
    if (!mounted) return;
    final AudioPlayer audioPlayer = AudioPlayer();
    audioPlayer.setReleaseMode(ReleaseMode.stop);

    _confettiController.play();
    audioPlayer.play(AssetSource('audio/bravo.mp3')).catchError((error) {
      debugPrint("GroupTestManager: Error playing sound from internal success dialog: $error");
    });

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  emissionFrequency: 0.03,
                  colors: const [
                    Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
                  ],
                ),
              ),
              const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text('🎉 برافو',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Color(0xff2C73D9),
                          fontWeight: FontWeight.bold,
                          fontSize: 22)))
            ],
          ),
          content: const Text(
            'إجابة صحيحة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2C73D9),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                textStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              child: const Text('التالي'),
              onPressed: () {
                if (_confettiController.state == ConfettiControllerState.playing) {
                  _confettiController.stop();
                }
                audioPlayer.stop().catchError((e) => debugPrint("Error stopping audio on next: $e"));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      debugPrint("GroupTestManager: Internal Success Dialog closed.");
      audioPlayer.dispose().catchError((e) => debugPrint("Error disposing audio on success dialog close: $e"));
    });
  }

  // --- *** دالة جديدة لعرض Popup الإجابة الخاطئة *** ---
  Future<void> _showIncorrectAnswerDialog() async {
    if (!mounted) return;
    // يمكنك إضافة صوت مختلف هنا إذا أردت أن يكون أكثر هدوءًا أو مختلفًا عن صوت النجاح
    // final AudioPlayer incorrectAudioPlayer = AudioPlayer();
    // incorrectAudioPlayer.setReleaseMode(ReleaseMode.stop);
    // incorrectAudioPlayer.play(AssetSource('audio/try_again.mp3')); // مثال

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // المستخدم يجب أن يضغط على الزر
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            "للأسف!", // يمكنك تغيير العنوان إذا أردت
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 207, 61, 13), // لون مختلف للإشارة للخطأ
              fontSize: 22,
            ),
          ),
          content: const Text(
            "إجابة خاطئة، حاول مرة أخرى!",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16.0, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 182, 47, 10), // لون زر مختلف
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                textStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('حاول مرة أخرى'),
              onPressed: () {
                // incorrectAudioPlayer.dispose().catchError((e) => debugPrint("Error disposing incorrect audio: $e")); // إذا أضفت صوتًا للخطأ
                Navigator.of(dialogContext).pop(); // أغلق الـ Dialog فقط
              },
            ),
          ],
        );
      },
    );
    // .whenComplete(() { // لا حاجة لـ whenComplete هنا إذا كان الصوت يتم التخلص منه في onPressed
    //   // incorrectAudioPlayer.dispose().catchError((e) => debugPrint("Error disposing incorrect audio on dialog close: $e"));
    // });
  }
  // --- *** نهاية دالة Popup الإجابة الخاطئة *** ---

  void _handleAnswer(bool isCorrect) async {
    if (_isLoadingScreen || _isProcessingAnswer || _isCompletingGroup) return;
    setStateIfMounted(() => _isProcessingAnswer = true);

    final currentQuestionProcessed =
        _allGeneratedQuestions[_currentGlobalQuestionIndex];
    final int originalQuestionDetailId =
        currentQuestionProcessed.originalDetailId;
    final int parentSessionIdForComment = currentQuestionProcessed.parentSessionId;

    debugPrint(
        "GroupTestManager: _handleAnswer. Correct: $isCorrect. Q_idx: $_currentGlobalQuestionIndex. DetailID: $originalQuestionDetailId. ParentSessionID: $parentSessionIdForComment. Processing SET TRUE.");

    await ApiService.markTestDetailAsNotComplete( // تأكد من أن هذه الدالة موجودة في ApiService
        widget.jwtToken, originalQuestionDetailId);
    debugPrint(
        "GroupTestManager: Called markTestDetailAsNotComplete for DetailID: $originalQuestionDetailId");

    if (isCorrect) {
      _totalCorrectAnswers++;
      debugPrint(
          "GroupTestManager: Correct answer. Total correct: $_totalCorrectAnswers.");
      if (mounted) {
        _showInternalSuccessDialog().then((_) {
          if (mounted) {
            debugPrint(
                "GroupTestManager: Success dialog closed. Advancing.");
            _advanceToNextGlobalQuestion();
            setStateIfMounted(() {
              _isProcessingAnswer = false;
              debugPrint("GroupTestManager: Processing SET FALSE (after success).");
            });
          }
        }).catchError((error) {
          debugPrint("GroupTestManager: Error or success dialog dismissed: $error");
          if (mounted) setStateIfMounted(() => _isProcessingAnswer = false);
        });
      } else {
        _isProcessingAnswer = false;
      }
    } else {
      // --- *** بداية التعديل هنا: استدعاء _showIncorrectAnswerDialog *** ---
      debugPrint(
          "GroupTestManager: Incorrect answer. DetailID: $originalQuestionDetailId. Calling addIncorrectAnswerComment with SessionID: $parentSessionIdForComment.");
      if (widget.jwtToken.isNotEmpty) {
        bool commentAdded = await ApiService.addIncorrectAnswerComment(
            widget.jwtToken, parentSessionIdForComment);
        debugPrint(
            "GroupTestManager: Comment added for incorrect on SessionID $parentSessionIdForComment (DetailID: $originalQuestionDetailId): $commentAdded");
      } else {
        debugPrint("GroupTestManager: JWT Token empty. Cannot add comment.");
      }

      if (mounted) {
        // استدعاء الـ Popup الجديد بدلاً من SnackBar
        _showIncorrectAnswerDialog().then((_) {
           // بعد إغلاق الـ Popup، قم بتحديث الحالة
           if (mounted) {
             setStateIfMounted(() {
               _isProcessingAnswer = false;
               debugPrint(
                   "GroupTestManager: ProcessingAnswer SET FALSE (after incorrect answer dialog).");
             });
           }
        });
      } else {
        _isProcessingAnswer = false;
      }
      // --- *** نهاية التعديل هنا *** ---
    }
  }

  void _advanceToNextGlobalQuestion() {
    if (!mounted) return;
    int newGlobalIndex = _currentGlobalQuestionIndex + 1;
    if (newGlobalIndex >= _allGeneratedQuestions.length) {
      debugPrint("GroupTestManager: All questions done. Calling _completeTestGroup.");
      if (!_isCompletingGroup) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCompletingGroup) _completeTestGroup();
        });
      }
    } else {
      debugPrint("GroupTestManager: Advanced to Q_idx: $newGlobalIndex");
      setStateIfMounted(() => _currentGlobalQuestionIndex = newGlobalIndex);
    }
  }

  Future<void> _completeTestGroup(
      {bool showError = false, String? errorMessage}) async {
    if (!mounted || _isCompletingGroup) return;
    setStateIfMounted(() => _isCompletingGroup = true);
    debugPrint(
        "GroupTestManager: _completeTestGroup. GroupID: ${widget.testGroupData.groupId}. Correct: $_totalCorrectAnswers. Error: $showError. Msg: $errorMessage");

    bool successMarkingDone = false;
    if (!showError) {
      // تأكد أن هذه الدالة موجودة في ApiService
      successMarkingDone = await ApiService.markTestGroupDone(
          widget.jwtToken, widget.testGroupData.groupId);
    }

    await NotificationManager.deactivateNotificationsByType(
        notif_model.NotificationType.threeMonthTestAvailable);
    await NotificationManager.setThreeMonthTestNotificationSent(false);
    debugPrint("GroupTestManagerScreen: 3-Month notification handled and flag reset.");
    widget.notificationIconKey?.currentState?.refreshNotifications();

    if (mounted) {
      String dialogTitle = showError
          ? "خطأ بالاختبار"
          : (successMarkingDone ? "اختبار مكتمل" : "خطأ في الحفظ");
      String dialogContent = errorMessage ??
          (showError
              ? "لم يتم تحميل الأسئلة بشكل صحيح."
              : (successMarkingDone
                  ? "أحسنت! لقد أكملت هذا الاختبار بنجاح."
                  : "حدث خطأ أثناء محاولة حفظ نتيجة الاختبار."));

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(dialogTitle, style: const TextStyle(fontFamily: 'Cairo')),
          content: Text(dialogContent, style: const TextStyle(fontFamily: 'Cairo')),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2C73D9),
                  foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const HomeScreen()), // تأكد من استيراد HomeScreen
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("العودة للرئيسية",
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint(
        "GroupTestManager BUILD #$_buildCount: isLoading: $_isLoadingScreen, Q_idx: $_currentGlobalQuestionIndex, TotalQs: ${_allGeneratedQuestions.length}, Completing: $_isCompletingGroup, ProcessingAns: $_isProcessingAnswer");

    final String appBarDefaultTitle = widget.testGroupData.groupName.isNotEmpty
        ? widget.testGroupData.groupName
        : "اختبار الـ 3 شهور";

    if (_isLoadingScreen) {
      return Scaffold(
        appBar: AppBar(
            title: Text(appBarDefaultTitle,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            backgroundColor: const Color(0xFF2C73D9),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false),
        body: const LoadingIndicator( // تأكد من استيراد LoadingIndicator
            message: "جاري تجهيز أسئلة اختبار الـ 3 شهور..."),
      );
    }

    if (_isCompletingGroup) {
      return Scaffold(
          appBar: AppBar(
              title: Text(appBarDefaultTitle,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              backgroundColor: const Color(0xFF2C73D9),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false),
          body: const LoadingIndicator(
              message: "جاري إنهاء الاختبار وحفظ النتائج..."));
    }

    if (_allGeneratedQuestions.isEmpty &&
        !_isLoadingScreen &&
        !_isCompletingGroup) {
      debugPrint("GroupTestManager BUILD: Empty questions. Triggering completeTestGroup.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCompletingGroup) {
          _completeTestGroup(
              showError: true,
              errorMessage: "فشل تحميل أسئلة الاختبار بشكل كامل.");
        }
      });
      return Scaffold(
          appBar: AppBar(
              title: Text(appBarDefaultTitle,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              backgroundColor: const Color(0xFF2C73D9),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false),
          body: const LoadingIndicator(
              message: "خطأ في تحميل أسئلة الاختبار..."));
    }

    if (_currentGlobalQuestionIndex >= _allGeneratedQuestions.length &&
        !_isCompletingGroup) {
      debugPrint("GroupTestManager BUILD: Index out of bounds. Triggering completeTestGroup.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCompletingGroup) _completeTestGroup();
      });
      return Scaffold(
          appBar: AppBar(
              title: Text(appBarDefaultTitle,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              backgroundColor: const Color(0xFF2C73D9),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false),
          body: const LoadingIndicator(message: "جاري تجميع النتائج..."));
    }

    final currentGeneratedQuestion =
        _allGeneratedQuestions[_currentGlobalQuestionIndex];
    final String appBarQuestionTitle =
        "${currentGeneratedQuestion.sectionTitle} (${_currentGlobalQuestionIndex + 1}/${_allGeneratedQuestions.length})";

    return GroupTestQuestionDisplayScreen( // تأكد من استيراد GroupTestQuestionDisplayScreen
      key: ValueKey(
          'group_q_global_${_currentGlobalQuestionIndex}_${currentGeneratedQuestion.originalDetailId}'),
      appBarTitle: appBarQuestionTitle,
      question: currentGeneratedQuestion,
      isLoading: _isProcessingAnswer || _isCompletingGroup,
      onAnswerSelected: _handleAnswer,
    );
  }
}