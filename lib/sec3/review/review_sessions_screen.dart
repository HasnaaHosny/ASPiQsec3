import 'package:flutter/material.dart';
import 'package:myfinalpro/sec3/review/session_list_model_v3.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReviewSessionsScreen extends StatefulWidget {
  const ReviewSessionsScreen({super.key});

  @override
  State<ReviewSessionsScreen> createState() => _ReviewSessionsScreenState();
}

class _ReviewSessionsScreenState extends State<ReviewSessionsScreen> {
  List<SessionV3> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _expandedIndices = {};

  final Map<int, WebViewController> _videoControllers = {};
  final Set<int> _playedVideos = {};

  static const Color cardBackgroundColor = Color(0x33C3E2FF);
  static const Color titleColor = Color(0xFF2C73D9);
  static const Color detailsBackgroundColor = Color(0xFF2C73D9);
  static const Color detailsTextColor = Colors.white;
  static const Color playIconColor = Colors.green;
  static const Color lockIconColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  // --- إصلاح التحذير: تم إزالة الكنترولر غير المستخدم من هنا ---
  @override
  void dispose() {
    super.dispose();
  }


  Future<void> _loadSessionData() async {
    // ... (هذه الدالة تبقى كما هي)
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }
      final fetchedSessions = await ApiService.getChildSessionsAll3(token);
      if (mounted) {
        setState(() {
          _sessions = fetchedSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _toggleExpand(int index) {
    if (!mounted) return;
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  void _playVideo(int detailId, String videoUrl) {
    if (_playedVideos.contains(detailId)) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(videoUrl));
    
    setState(() {
      _videoControllers[detailId] = controller;
      _playedVideos.add(detailId);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('مراجعة التمارين'),
          backgroundColor: titleColor,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadSessionData,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: titleColor));
    if (_errorMessage != null) return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text('خطأ: $_errorMessage', textAlign: TextAlign.center)));
    if (_sessions.isEmpty) return const Center(child: Text('لا توجد تمارين للمراجعة حاليًا.', style: TextStyle(fontSize: 17, color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isExpanded = _expandedIndices.contains(index);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: cardBackgroundColor,
          elevation: 3.0,
          shadowColor: titleColor.withAlpha(51),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: titleColor.withAlpha(38))
          ),
          child: InkWell(
            onTap: session.isOpen ? () => _toggleExpand(index) : null,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(session.isOpen ? Icons.play_circle_fill : Icons.lock_outline, color: session.isOpen ? playIconColor : lockIconColor, size: 30),
                      const SizedBox(width: 12),
                      Expanded(child: Text(session.title, style: const TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'))),
                      if (session.isOpen) Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: titleColor.withAlpha(178)),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                    child: Visibility(
                      visible: isExpanded && session.isOpen,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(color: detailsBackgroundColor, borderRadius: BorderRadius.circular(10.0)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildDetailItems(session.details.values)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDetailItems(List<DetailItemV3> details) {
    if (details.isEmpty) return [const Padding(padding: EdgeInsets.symmetric(vertical: 15.0), child: Center(child: Text('لا توجد تفاصيل لهذه الجلسة.', style: TextStyle(color: detailsTextColor, fontStyle: FontStyle.italic))))];
    
    List<Widget> detailWidgets = [];
    for (int i = 0; i < details.length; i++) {
      final detail = details[i];
      detailWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0), 
          child: _buildDetailItem(detail),
        )
      );

      if (i < details.length - 1) {
        detailWidgets.add(Divider(color: detailsTextColor.withAlpha(64), thickness: 0.8));
      }
    }
    return detailWidgets;
  }
  
  Widget _buildDetailItem(DetailItemV3 detail) {
    if (detail.dataTypeOfContent == 'Video' && detail.videoUrl != null) {
      
      // --- *** إصلاح هنا: استخدام detail.id بدلاً من detail.detailId *** ---
      final bool isVideoPlaying = _playedVideos.contains(detail.id);
      final WebViewController? controller = _videoControllers[detail.id];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [ BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 5, offset: const Offset(0, 2)) ]
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.black),
                  if (isVideoPlaying && controller != null)
                    WebViewWidget(controller: controller),
                  
                  if (!isVideoPlaying)
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
                      onPressed: () {
                        // --- إصلاح هنا: استخدام detail.id ---
                        _playVideo(detail.id, detail.videoUrl!);
                      },
                    ),
                ],
              ),
            ),
          ),
          if (detail.description != null && detail.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(detail.description!, textAlign: TextAlign.center, style: const TextStyle(color: detailsTextColor, fontSize: 14, height: 1.5)),
            ),
        ],
      );
    } 
    else if (detail.dataTypeOfContent == 'Text' && detail.text != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(detail.text!, textAlign: TextAlign.center, style: const TextStyle(color: detailsTextColor, fontSize: 15, height: 1.5)),
      );
    }
    
    return const SizedBox.shrink();
  }
}