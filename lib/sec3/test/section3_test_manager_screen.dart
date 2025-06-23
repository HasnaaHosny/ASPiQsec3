// lib/sec3/test/section3_test_manager_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

// تأكد من أن هذه المسارات صحيحة وتطابق بنية مشروعك
import 'package:myfinalpro/sec3/home3.dart';
import 'package:myfinalpro/sec3/test/analysis_failed_popup.dart';
import 'package:myfinalpro/sec3/test/end_test_screen_v3.dart';
import 'package:myfinalpro/sec3/test/error_popup.dart';
import 'package:myfinalpro/sec3/test/practical_test_screen.dart';
import 'package:myfinalpro/sec3/test/section3_quiz_screen.dart';
import 'package:myfinalpro/sec3/test/section3_test_group.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/test/sucess_popup.dart';

enum TestPhase { theoretical, practical, finished }

class Section3TestManagerScreen extends StatefulWidget {
  final Section3TestGroup testGroup;
  final String jwtToken;

  const Section3TestManagerScreen({
    super.key,
    required this.testGroup,
    required this.jwtToken,
  });

  @override
  State<Section3TestManagerScreen> createState() =>
      _Section3TestManagerScreenState();
}

class _Section3TestManagerScreenState extends State<Section3TestManagerScreen> {
  int _currentQuestionIndex = 0;
  int _correctAnswersCount = 0;
  final List<String> _incorrectMores = [];
  TestPhase _currentPhase = TestPhase.theoretical;

  void _handleTheoreticalAnswer(bool wasCorrect, String? moreValue) {
    if (wasCorrect) {
      _correctAnswersCount++;
    } else {
      if (moreValue != null && moreValue.isNotEmpty) {
        _incorrectMores.add(moreValue);
      }
    }

    bool hasMoreQuestions =
        _currentQuestionIndex < widget.testGroup.details.length - 1;

    if (hasMoreQuestions) {
      setState(() => _currentQuestionIndex++);
    } else {
      setState(() => _currentPhase = TestPhase.practical);
    }
  }

  // --- *** تم تعديل هذه الدالة لتشمل السيناريوهات الثلاثة *** ---
  Future<void> _handlePracticalAnswer(File videoFile) async {
    setState(() => _currentPhase = TestPhase.finished);

    String? analysisResult;
    try {
      analysisResult = await ApiService.analyzeVideo(widget.jwtToken, videoFile);
    } catch (e) {
      debugPrint("Error in analyzeVideo API call: $e");
      analysisResult = null;
    }

    // السيناريو 1: فشل تقني في الاتصال بـ API التحليل
    if (analysisResult == null) {
      debugPrint("Technical failure in video analysis (API returned null).");
      _handleAnalysisFailure();
      return; // الخروج من الدالة
    }

    // السيناريو 2: إجابة عملية صحيحة
    if (analysisResult == widget.testGroup.groupNameEnglish) {
      debugPrint("Practical test PASSED.");
      await showSuccessPopup(context, () {
        _finalizeAndNavigate(); // ننتقل لتقييم الجزء النظري
      });
    }
    // السيناريو 3: حالة خاصة عندما يرجع النموذج "No"
    else if (analysisResult == "No") {
      debugPrint("Analysis result is 'No'. Treating as a retryable failure.");
      _handleAnalysisFailure(); // نعرض نافذة إعادة المحاولة فقط، بدون تسجيل فشل
    }
    // السيناريو 4: أي إجابة خاطئة أخرى (مثل "Don't know")
    else {
      debugPrint("Practical test FAILED. User's answer: '$analysisResult', Expected: '${widget.testGroup.groupNameEnglish}'");
      
      // تنفيذ إجراءات الفشل الكامل
      await ApiService.relevelAllSection3(widget.jwtToken, widget.testGroup.sessionId);
      await ApiService.addSection3Comment(widget.jwtToken, widget.testGroup.sessionId, "0");
      
      await showErrorPopup(context, () {
        _navigateToFinalScreen(false); // الانتقال لشاشة النهاية بنتيجة "فشل"
      });
    }
  }
  // --- *** نهاية الجزء المعدل *** ---

  Future<void> _handleAnalysisFailure() async {
    if (!mounted) return;
    final userChoice = await showAnalysisFailedPopup(context);
    
    if (userChoice == RetryOption.retry) {
      setState(() => _currentPhase = TestPhase.practical);
    } else {
      _navigateToHome();
    }
  }

  Future<void> _finalizeAndNavigate() async {
    bool theoreticalTestPassed = _correctAnswersCount >= widget.testGroup.level;
    debugPrint("Theoretical test result: ${theoreticalTestPassed ? "PASSED" : "FAILED"} (Correct: $_correctAnswersCount, Required: ${widget.testGroup.level})");

    if (theoreticalTestPassed) {
      // نجاح كلي
      await ApiService.markTestGroupDone(widget.jwtToken, widget.testGroup.groupId);
      final apiService = ApiService(); 
      await apiService.markSessionDone(widget.testGroup.sessionId);
      _navigateToFinalScreen(true);
    } else {
      // فشل نظري
      for (final more in _incorrectMores) {
        await ApiService.relevelSection3(widget.jwtToken, widget.testGroup.sessionId, more);
        await ApiService.addSection3Comment(widget.jwtToken, widget.testGroup.sessionId, more);
      }
      _navigateToFinalScreen(false);
    }
  }
  
  void _navigateToFinalScreen(bool didPass) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EndTestScreenV3(testPassed: didPass)),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SocialSkillsScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPhase) {
      case TestPhase.theoretical:
        final currentDetail = widget.testGroup.details[_currentQuestionIndex];
        return Section3QuizScreen(
          key: ValueKey(currentDetail.detailId),
          detail: currentDetail,
          sessionId: widget.testGroup.sessionId,
          jwtToken: widget.jwtToken,
          onAnswerSelected: _handleTheoreticalAnswer,
        );
      case TestPhase.practical:
        return PracticalTestScreen(
          onVideoSubmitted: _handlePracticalAnswer,
        );
      case TestPhase.finished:
        return const Scaffold(
          backgroundColor: Color(0xff2C73D9),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text("جاري تحليل الفيديو...", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo')),
              ],
            ),
          ),
        );
    }
  }
}