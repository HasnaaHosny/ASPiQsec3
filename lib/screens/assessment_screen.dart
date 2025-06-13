// lib/screens/assessment_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

// --- استيراد الملفات الضرورية ---
import '../models/question_model.dart';
import 'assessment_data.dart';
import '../services/Api_services.dart';
import '../models/answer_model.dart';
import 'home_screen.dart'; // تأكد من وجود هذا الاستيراد

// --- نموذج لتمثيل رسالة في الشات ---
class ChattMessage {
  final String text;
  final bool isUserMessage;
  final Question? questionData;

  ChattMessage({required this.text, required this.isUserMessage, this.questionData});
}

// --- الشاشة الرئيسية للتقييم ---
class AssessmentScreen extends StatefulWidget {
  final String jwtToken;
  const AssessmentScreen({super.key, required this.jwtToken});

  @override
  AssessmentScreenState createState() => AssessmentScreenState();
}

class AssessmentScreenState extends State<AssessmentScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _uiMessage;
  bool _skipActive = false;
  String? _emotionToSkip;
  bool _isSessionProcessingComplete = false;

  final List<ChattMessage> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  final List<AnswerModel> _answersToSubmit = [];
  
  @override
  void initState() {
    super.initState();
    if (assessmentQuestions.isNotEmpty) {
      _startChatFlow();
    } else {
      _showUiMessage("خطأ: لم يتم تحميل أسئلة التقييم.");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  void _showUiMessage(String message) {
    if (!mounted) return;
    setState(() {
      _uiMessage = message;
    });
  }

  void _startChatFlow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatMessages.add(ChattMessage(
          text: "أهلاً بكِ. سأطرح عليكِ بعض الأسئلة حول ملاحظاتك لطفلك. يرجى الإجابة بنص حر أو استخدام الأزرار المقترحة.",
          isUserMessage: false,
        ));
        setState(() {});
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _askQuestionAtIndex(_currentIndex);
        });
      }
    });
  }

  void _askQuestionAtIndex(int index) {
    if (_isSessionProcessingComplete) return;

    if (index < assessmentQuestions.length && mounted) {
      final question = assessmentQuestions[index];
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isSessionProcessingComplete) {
          setState(() {
            _chatMessages.add(ChattMessage(text: question.text, isUserMessage: false, questionData: question));
            _isLoading = false;
            _uiMessage = null;
          });
          _scrollToBottom();
          _answerFocusNode.requestFocus();
        }
      });
    } else if (mounted && !_isSessionProcessingComplete) {
      _finalizeAndSubmitAllAnswers();
    }
  }

  void _showExplanation(Question question) {
    final explanationText = question.explanation;
    if (explanationText == null || explanationText.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Text("توضيح السؤال:", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const Divider(height: 25, thickness: 0.8),
                Text(explanationText, textAlign: TextAlign.start, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                const SizedBox(height: 25),
                Center(child: ElevatedButton(child: const Text("حسناً"), onPressed: () => Navigator.pop(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAnswer(String answerText) async {
    final trimmedAnswer = answerText.trim();
    if (trimmedAnswer.isEmpty || _isLoading || _isSessionProcessingComplete || _currentIndex >= assessmentQuestions.length) return;

    _answerFocusNode.unfocus();
    final currentQuestion = assessmentQuestions[_currentIndex];

    const explanationRequests = ["?", "شرح", "توضيح", "مش فاهمة", "يعني ايه"];
    if (explanationRequests.any((req) => trimmedAnswer.contains(req))) {
      _showExplanation(currentQuestion);
      _answerController.clear();
      return;
    }

    setState(() {
      _chatMessages.add(ChattMessage(text: trimmedAnswer, isUserMessage: true));
      _isLoading = true;
      _uiMessage = "جاري تحليل الإجابة...";
      _answerController.clear();
    });
    _scrollToBottom();

    String? classifiedAnswer;
    const validKeywords = ["نعم", "لا", "بمساعدة"];
    if (validKeywords.contains(trimmedAnswer)) {
      classifiedAnswer = trimmedAnswer;
    } else {
      classifiedAnswer = await ApiService.classifyAnswerWithModel(trimmedAnswer);
    }

    if (!mounted) return;

    if (classifiedAnswer == null || !validKeywords.contains(classifiedAnswer)) {
      setState(() {
        _chatMessages.removeLast();
        _isLoading = false;
        _uiMessage = "عذراً، لم أفهم الإجابة. يرجى استخدام الأزرار المقترحة.";
      });
      return;
    }
    
    setState(() {
      if (currentQuestion.dimension.trim() == "الفهم" && classifiedAnswer!.trim() == "لا") {
        _skipActive = true;
        _emotionToSkip = currentQuestion.emotion;
        debugPrint("!!! SKIP LOGIC ACTIVATED for emotion: '$_emotionToSkip' !!!");
      }
      _answersToSubmit.add(AnswerModel(sessionId: currentQuestion.id, answer: classifiedAnswer!));
      _uiMessage = null;
    });

    _moveToNextQuestionOrComplete();
  }

  void _moveToNextQuestionOrComplete() {
    if (_isSessionProcessingComplete) return;

    int nextIndex = _currentIndex + 1;

    while (nextIndex < assessmentQuestions.length) {
      final nextQuestion = assessmentQuestions[nextIndex];
      
      if (_skipActive && nextQuestion.emotion.trim() == _emotionToSkip?.trim()) {
        debugPrint("Skipping QID ${nextQuestion.id} for emotion: $_emotionToSkip");
        _answersToSubmit.add(AnswerModel(sessionId: nextQuestion.id, answer: "لا"));
        nextIndex++;
      } else {
        if (nextQuestion.emotion.trim() != _emotionToSkip?.trim() && _skipActive) {
          _skipActive = false;
          _emotionToSkip = null;
        }
        break;
      }
    }
    
    setState(() {
      _currentIndex = nextIndex;
    });

    _askQuestionAtIndex(_currentIndex);
  }

  // --- دالة الإرسال النهائي بعد تعديلها للانتقال المباشر ---
  Future<void> _finalizeAndSubmitAllAnswers() async {
    if (_isSessionProcessingComplete) return;
    setState(() {
      _isSessionProcessingComplete = true;
      _isLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("اكتملت الأسئلة. جاري حفظ النتائج..."),
        duration: Duration(seconds: 3),
      ),
    );

    debugPrint("Finalizing assessment. Total answers to submit: ${_answersToSubmit.length}");

    bool allSubmittedSuccessfully = await ApiService.submitAllAssessmentAnswers(_answersToSubmit, widget.jwtToken);
    
    if (!mounted) return;

    // الانتقال مباشرة إلى الشاشة الرئيسية
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
    
    // إظهار رسالة SnackBar في الشاشة الرئيسية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSubmittedSuccessfully ? "تم حفظ نتائج التقييم بنجاح!" : "عذراً، حدث خطأ أثناء حفظ النتائج."),
          backgroundColor: allSubmittedSuccessfully ? Colors.green : Colors.red,
        ),
      );
    });
  }
  
  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('لنتحدث عن طفلك'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C73D9),
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10.0),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUser = message.isUserMessage;
                final color = isUser ? const Color(0xFF2C73D9) : Colors.white;
                final textColor = isUser ? Colors.white : Colors.black87;
                final borderRadius = isUser
                    ? const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20), topRight: Radius.circular(5))
                    : const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20), topLeft: Radius.circular(5));
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0, bottom: 5),
                          child: CircleAvatar(backgroundColor: Color(0xFF2C73D9), radius: 15, child: Icon(Icons.psychology_alt_outlined, color: Colors.white, size: 18)),
                        ),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: borderRadius,
                            boxShadow: [BoxShadow(color: Colors.grey.withAlpha(38), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))]
                          ),
                          child: Text(message.text, textDirection: TextDirection.rtl, style: TextStyle(color: textColor, fontSize: 15.5, height: 1.45)),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 5),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_uiMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  _uiMessage!,
                  style: TextStyle(color: _uiMessage!.contains("خطأ") || _uiMessage!.contains("عذراً") ? Colors.redAccent : Colors.blueGrey.shade700, fontWeight: FontWeight.w600, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
              ),
          if (!_isSessionProcessingComplete)
            Container(
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withAlpha(51), spreadRadius: 0, blurRadius: 5, offset: const Offset(0, -1))]),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.0, 8.0, 12.0, MediaQuery.of(context).padding.bottom + 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0, left: 4, right: 4),
                      child: Row(children: [
                        Expanded(child: _buildSuggestionButton("نعم")),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSuggestionButton("لا")),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSuggestionButton("بمساعدة")),
                      ]),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            focusNode: _answerFocusNode,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: _isLoading ? "لحظات..." : "...أو اكتب إجابتك هنا",
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14.5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            enabled: !_isLoading,
                            onSubmitted: _isLoading ? null : (value) => _handleAnswer(value.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          onPressed: (_isLoading || _isSessionProcessingComplete) ? null : () => _handleAnswer(_answerController.text.trim()),
                          backgroundColor: (_isLoading || _isSessionProcessingComplete) ? Colors.grey.shade400 : const Color(0xFF2C73D9),
                          elevation: 2,
                          heroTag: "sendButton",
                          child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String text) {
    return ElevatedButton(
      onPressed: (_isLoading || _isSessionProcessingComplete) ? null : () => _handleAnswer(text),
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor.withAlpha(178), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
    );
  }
}