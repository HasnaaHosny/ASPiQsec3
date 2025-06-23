import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:myfinalpro/sec3/session/type3_session_response.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/session/break.dart';
import 'end_social_session_screen.dart';

class SocialSessionDetailsScreen extends StatefulWidget {
  final Type3SessionResponse sessionData;
  final String jwtToken;

  const SocialSessionDetailsScreen({
    super.key,
    required this.sessionData,
    required this.jwtToken,
  });

  @override
  State<SocialSessionDetailsScreen> createState() =>
      _SocialSessionDetailsScreenState();
}

class _SocialSessionDetailsScreenState
    extends State<SocialSessionDetailsScreen> {
  int _currentStepIndex = 0;
  final List<int> _completedDetailIds = [];
  WebViewController? _webViewController;
  bool _isWebViewLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prepareStepContent();
  }
  
  void _prepareStepContent() {
    final currentDetail = widget.sessionData.details[_currentStepIndex];
    if (currentDetail.dataTypeOfContent == 'Video' && currentDetail.videoUrl != null) {
      setState(() => _isWebViewLoading = true);
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) setState(() => _isWebViewLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
               if (mounted) setState(() => _isWebViewLoading = false);
               debugPrint("WebView Error: ${error.description}");
            },
          ),
        )
        ..loadRequest(Uri.parse(currentDetail.videoUrl!));
    }
  }

  Future<void> _submitCompletedDetails() async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);
    
    debugPrint("Submitting ${_completedDetailIds.length} completed detail IDs...");

    for (final id in _completedDetailIds) {
      bool success = await ApiService.completeDetail(widget.jwtToken, id);
      if (success) {
        debugPrint("Successfully submitted detail ID: $id");
      } else {
        debugPrint("Failed to submit detail ID: $id. Will continue.");
      }
    }
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EndSocialSessionScreen()),
      );
    }
  }

  Future<void> _goToNextStep() async {
    if (_isSubmitting) return;

    final currentDetail = widget.sessionData.details[_currentStepIndex];
    if (!_completedDetailIds.contains(currentDetail.id)) {
        _completedDetailIds.add(currentDetail.id);
    }
    debugPrint("Completed detail ID: ${currentDetail.id}. List: $_completedDetailIds");

    final isLastStep = _currentStepIndex == widget.sessionData.details.length - 1;

    if (isLastStep) {
      await _submitCompletedDetails();
      return;
    }

    if (_currentStepIndex == 1) { 
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BreakScreen(duration: Duration(seconds: 30)),
            ),
        );
    }
    
    if (mounted) {
      setState(() {
        _currentStepIndex++;
      });
      _prepareStepContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDetail = widget.sessionData.details[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / widget.sessionData.details.length;
    
    const Color primaryColor = Color(0xFF2C73D9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryColor, // لون الخلفية الأزرق
        // --- *** بداية التعديل هنا *** ---
        appBar: AppBar(
          backgroundColor: primaryColor, // 1. جعل خلفية الشريط زرقاء
          elevation: 0, // 2. إزالة الظل لدمج الشريط مع الجسم
          // 3. جعل العنوان أبيض ليكون مرئيًا
          title: Text(
            widget.sessionData.sessionTitle ?? 'تمارين الجلسة', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
          ),
          // 4. جعل أيقونات الشريط بيضاء
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false, // لا يزال كما هو
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: progress,
              // 5. تعديل ألوان شريط التقدم ليظهر على الخلفية الزرقاء
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        // --- *** نهاية التعديل هنا *** ---
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
            child: _buildStepContent(currentDetail),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                elevation: 4,
              ),
              child: _isSubmitting 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                    )
                  : const Text('التالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(Type3SessionDetail detail) {
    if (detail.dataTypeOfContent == 'Text' && detail.text != null) {
      return Card(
        color: Colors.white, // التأكد من أن الكارد أبيض
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 40, color: Color(0xFF2C73D9)),
              const SizedBox(height: 16),
              Text(
                detail.text!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, height: 1.5, fontFamily: 'Cairo', color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    } 
    else if (detail.dataTypeOfContent == 'Video' && detail.videoUrl != null) {
       return Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_webViewController != null)
                      WebViewWidget(controller: _webViewController!),
                    if (_isWebViewLoading)
                       const CircularProgressIndicator(color: Colors.white), // جعل المؤشر أبيض
                  ],
                ),
              ),
            ),
         ],
       );
    } 
    else {
      return const Text("لا يوجد محتوى لهذا التمرين.", style: TextStyle(color: Colors.white)); // جعل النص أبيض
    }
  }
}