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

  // --- *** تم تعديل هذه الدالة لتستخدم if/else if لتكون أكثر مرونة *** ---
  Future<void> _handlePracticalAnswer(File videoFile) async {
    setState(() => _currentPhase = TestPhase.finished);

    final analysisResult = await ApiService.analyzeVideo(
        videoFile, widget.testGroup.groupNameEnglish);

    if (!mounted) return;

    // استخدام if/else if للتعامل مع الحالات المختلفة بمرونة أكبر
    if (analysisResult == "Yes") {
      debugPrint("Practical test PASSED.");
      await showSuccessPopup(context, () {
        _finalizeAndNavigate();
      });
    } else if (analysisResult == "No") {
      debugPrint("Practical test FAILED. The model returned 'No'.");
      await ApiService.relevelAllSection3(
          widget.jwtToken, widget.testGroup.sessionId);
      await ApiService.addSection3Comment(
          widget.jwtToken, widget.testGroup.sessionId, "0");
      
      await showErrorPopup(context, () {
        _navigateToFinalScreen(false);
      });
    } else if (analysisResult == "Video is too short") {
      debugPrint("Analysis failed: Video is too short.");
      await _handleAnalysisFailure(
        customMessage: 'مدة الفيديو قصيرة جدًا. يرجى تسجيل فيديو أطول بوضوح ثم المحاولة مرة أخرى.',
      );
    } 
    // --- *** هذا هو التعديل الأساسي: استخدام startsWith *** ---
    else if (analysisResult != null && analysisResult.startsWith("Gemini blocked")) {
      debugPrint("Analysis failed: Content blocked by service (Invalid format).");
      await _handleAnalysisFailure(
        customMessage: 'هذا الفيديو غير صالح. يرجى المحاولة مرة أخرى بفيديو بصيغة MP4.',
      );
    } 
    else if (analysisResult == null) {
      debugPrint("Technical failure in video analysis (API returned null or failed).");
      await _handleAnalysisFailure(
        customMessage: 'حدث خطأ في الاتصال. يرجى التحقق من اتصالك بالإنترنت ثم المحاولة مرة أخرى.',
      );
    } 
    // --- الحالة الافتراضية لأي خطأ آخر ---
    else {
      debugPrint("Practical test FAILED with unexpected response: '$analysisResult'");
      await _handleAnalysisFailure(
        customMessage: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
      );
    }
  }

  Future<void> _handleAnalysisFailure({String? customMessage}) async {
    if (!mounted) return;

    final userChoice =
        await showAnalysisFailedPopup(context, message: customMessage);

    if (userChoice == RetryOption.retry) {
      setState(() => _currentPhase = TestPhase.practical);
    } else {
      _navigateToHome();
    }
  }
  
  Future<void> _finalizeAndNavigate() async {
    bool theoreticalTestPassed =
        _correctAnswersCount >= widget.testGroup.level;
    debugPrint(
        "Theoretical test result: ${theoreticalTestPassed ? "PASSED" : "FAILED"} (Correct: $_correctAnswersCount, Required: ${widget.testGroup.level})");

    if (theoreticalTestPassed) {
      // نجاح كلي
      await ApiService.markTestGroupDone(
          widget.jwtToken, widget.testGroup.groupId);
      final apiService = ApiService();
      await apiService.markSessionDone(widget.testGroup.sessionId);
      _navigateToFinalScreen(true);
    } else {
      // فشل نظري
      for (final more in _incorrectMores) {
        await ApiService.relevelSection3(
            widget.jwtToken, widget.testGroup.sessionId, more);
        await ApiService.addSection3Comment(
            widget.jwtToken, widget.testGroup.sessionId, more);
      }
      _navigateToFinalScreen(false);
    }
  }

  void _navigateToFinalScreen(bool didPass) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => EndTestScreenV3(testPassed: didPass)),
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
                Text("جاري تحليل الفيديو...",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Cairo')),
              ],
            ),
          ),
        );
    }
  }
}