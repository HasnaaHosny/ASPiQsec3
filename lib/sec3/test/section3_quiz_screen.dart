import 'package:flutter/material.dart';
import 'package:myfinalpro/sec3/test/error_popup.dart';
import 'package:myfinalpro/sec3/test/section3_test_group.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/test/sucess_popup.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Section3QuizScreen extends StatefulWidget {
  final Section3TestDetail detail;
  final int sessionId;
  final String jwtToken;
  final Function(bool isCorrect, String? moreValue) onAnswerSelected;
  final bool isCompleting;

  const Section3QuizScreen({
    super.key,
    required this.detail,
    required this.sessionId,
    required this.jwtToken,
    required this.onAnswerSelected,
    this.isCompleting = false,
  });

  @override
  State<Section3QuizScreen> createState() => _Section3QuizScreenState();
}

class _Section3QuizScreenState extends State<Section3QuizScreen> {
  WebViewController? _webViewController;
  bool _isWebViewLoading = false;
  bool _isAnswerProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.detail.videoUrl != null) {
      _isWebViewLoading = true;
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isWebViewLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint("WebView Error: ${error.description}");
            if (mounted) setState(() => _isWebViewLoading = false);
          }
        ))
        ..loadRequest(Uri.parse(widget.detail.videoUrl!));
    }
  }

  Future<void> _checkAnswer(BuildContext context, String selectedAnswer) async {
    if (_isAnswerProcessing || widget.isCompleting) return;
    setState(() => _isAnswerProcessing = true);

    bool isCorrect = selectedAnswer == widget.detail.rightAnswer;
    
    if (isCorrect) {
      await showSuccessPopup(context, () {
        if (mounted) {
          widget.onAnswerSelected(true, null);
        }
      });
    } else {
      if (context.mounted) {
        await showErrorPopup(context, () {
          if (mounted) {
            widget.onAnswerSelected(false, widget.detail.more);
          }
        });
      }
    }
    
    if (mounted) setState(() => _isAnswerProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff2C73D9);
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Text(
                widget.detail.question ?? "ما هذه الحركة؟",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 32),
              if (widget.detail.videoUrl != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_webViewController != null)
                          WebViewWidget(controller: _webViewController!),
                        if (_isWebViewLoading)
                          const CircularProgressIndicator(color: Colors.white),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              ...widget.detail.answerOptions.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        onPressed: _isAnswerProcessing || widget.isCompleting ? null : () => _checkAnswer(context, option),
                        child: Text(option, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}