import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'models/session_model.dart'; // تأكد من المسار الصحيح
import '../services/Api_services.dart'; // تأكد من المسار الصحيح
import 'break.dart'; // تأكد من المسار الصحيح
import 'timetest.dart'; //  لاستخدام شاشة StartTest الجديدة
import 'dart:math';

class RandomImageInfo {
  final String path;
  final String name;
  RandomImageInfo(this.path, this.name);
}

class SessionDetailsScreen extends StatefulWidget {
  final Session initialSession;
  final String jwtToken;

  const SessionDetailsScreen({
    super.key,
    required this.initialSession,
    required this.jwtToken,
  });

  @override
  _SessionDetailsScreenState createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  late Session _currentSession;
  int _currentStepIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _breakTimer;
  Timer? _stepTimer;

  RandomImageInfo? _randomImageInfo;
  List<RandomImageInfo> _objectImageInfos = [];
  final List<int> _completedDetailIds = [];

  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  // Durations
  static const Duration imageDisplayDuration = Duration(minutes: 7);
  static const Duration textDisplayDuration = Duration(minutes: 10);
  static const Duration videoDisplayDuration = Duration(minutes: 10);
  static const Duration breakDuration = Duration(seconds: 5);

  // Paths
  static const String localImagePathBase = 'assets/';
  static const String objectsFolderPath = 'assets/objects/';

  // Colors
  static const Color screenBgColor = Color(0xFF2C73D9);
  static const Color appBarElementsColor = Colors.white;
  static const Color cardBgColor = Colors.white;
  static const Color cardTextColor = Color(0xFF2C73D9);
  static const Color progressBarColor = Color.fromARGB(255, 255, 255, 255);
  static final Color progressBarBgColor = Colors.white.withOpacity(0.3);
  static const Color buttonBgColor = Colors.white;
  static const Color buttonFgColor = Color(0xFF2C73D9);
  static const Color loadingIndicatorColor = Colors.white;
  static const Color errorTextColor = Colors.redAccent;
  static const Color videoPlaceholderColor = Colors.black54;

  // 8-point grid values
  static const double spacingUnit = 8.0;
  static const double spacingSmall = spacingUnit; // 8.0
  static const double spacingMedium = spacingUnit * 2; // 16.0
  static const double spacingLarge = spacingUnit * 3; // 24.0
  static const double spacingXLarge = spacingUnit * 4; // 32.0
  static const double spacingXXLarge = spacingUnit * 5; // 40.0

  @override
  void initState() {
    super.initState();
    _currentSession = widget.initialSession;

    if (_currentSession.details.isEmpty) {
      _errorMessage = "لا توجد تمارين في هذه الجلسة.";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      debugPrint("--- Session Details Screen Initialized ---");
      _printSessionDetails();
      _loadObjectImageInfos();
      _prepareStepContent();
      _startStepTimer();
    }
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _stepTimer?.cancel();
    _videoController?.dispose();
    debugPrint("--- Session Details Screen Disposed ---");
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _printSessionDetails() {
    debugPrint("--- Available Exercise Details (from details list) ---");
    for (int i = 0; i < _currentSession.details.length; i++) {
      final detail = _currentSession.details[i];
      debugPrint(
          "Exercise $i: ID=${detail.id}, Type=${detail.datatypeOfContent}, Image=${detail.hasImage}, Text=${detail.hasText}, Video=${detail.hasVideo}, Desc=${detail.hasDesc}");
      if (detail.hasVideo && detail.video != null) {
        debugPrint("  Video Path: ${detail.video}");
      }
    }
    if (_currentSession.newDetail != null) {
      debugPrint(
          "--- New Detail Data: ID=${_currentSession.newDetail!.id}, Type=${_currentSession.newDetail!.datatypeOfContent}, Image=${_currentSession.newDetail!.hasImage}, Text=${_currentSession.newDetail!.hasText}, Video=${_currentSession.newDetail!.hasVideo}, Desc=${_currentSession.newDetail!.hasDesc}");
    }
    debugPrint("------------------------------------------------------");
  }

  Widget _buildImageErrorWidget(BuildContext context, Object error,
      StackTrace? stackTrace, String? attemptedPath) {
    debugPrint("Error loading asset image: $attemptedPath\n$error");
    return Container(
      padding: const EdgeInsets.all(spacingMedium),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(spacingSmall),
          border: Border.all(color: Colors.red.shade200)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined,
              color: Colors.red.shade400, size: spacingXXLarge),
          const SizedBox(height: spacingSmall),
          Text('خطأ تحميل الصورة',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: spacingMedium,
                  fontWeight: FontWeight.w500)),
          if (attemptedPath != null)
            Padding(
              padding: const EdgeInsets.only(top: spacingSmall),
              child: Text(
                '(المسار: $attemptedPath)',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: spacingSmall * 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadObjectImageInfos() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      _objectImageInfos = manifestMap.keys
          .where((String key) =>
              key.startsWith(objectsFolderPath) &&
              key !=
                  objectsFolderPath &&
              (key.endsWith('.png') ||
                  key.endsWith('.jpg') ||
                  key.endsWith('.jpeg') ||
                  key.endsWith('.gif') ||
                  key.endsWith('.webp')))
          .map((path) {
        String filename = path.split('/').last;
        String nameWithoutExtension = filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
        nameWithoutExtension = nameWithoutExtension.replaceAll('_', ' ').trim();
        if (nameWithoutExtension.isNotEmpty) {
          nameWithoutExtension = nameWithoutExtension[0].toUpperCase() +
              nameWithoutExtension.substring(1);
        }
        return RandomImageInfo(path, nameWithoutExtension);
      }).toList();
      debugPrint(
          "Loaded ${_objectImageInfos.length} image infos from $objectsFolderPath");
      if (_objectImageInfos.isEmpty) {
        debugPrint(
            "Warning: No images found in $objectsFolderPath. Ensure they are declared in pubspec.yaml and the path is correct.");
      }
    } catch (e) {
      debugPrint("Error loading object image infos: $e");
    }
  }

  void _selectRandomObjectImageInfo() {
    if (_objectImageInfos.isNotEmpty) {
      final random = Random();
      _randomImageInfo =
          _objectImageInfos[random.nextInt(_objectImageInfos.length)];
      debugPrint(
          "Selected random object: Path=${_randomImageInfo!.path}, Name=${_randomImageInfo!.name}");
    } else {
      debugPrint("Warning: Cannot select random image, info list is empty.");
      _randomImageInfo = null;
    }
  }

  String _normalizeAssetPath(String path) {
    String cleanPath = path.trim();
    cleanPath = cleanPath.replaceAll('\\', '/');

    if (!cleanPath.startsWith('assets/')) {
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      cleanPath = 'assets/$cleanPath';
    }
    cleanPath = cleanPath.replaceAll(RegExp(r'/+'), '/');
    // debugPrint("Original path: '$path' -> Normalized path: '$cleanPath'"); // Kept for brevity
    return cleanPath;
  }

  Future<bool> _checkVideoAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      debugPrint("Asset check: Found '$assetPath'");
      return true;
    } catch (e) {
      debugPrint("Asset check: Not found '$assetPath' - Error: $e");
      return false;
    }
  }

  Future<String?> _findValidVideoPath(String originalPath) async {
    String normalizedOriginalPath = _normalizeAssetPath(originalPath);
    List<String> pathsToTry = [normalizedOriginalPath];

    String basePathWithoutExtension = normalizedOriginalPath;
    if (normalizedOriginalPath.contains('.')) {
      int lastDot = normalizedOriginalPath.lastIndexOf('.');
      String extension = normalizedOriginalPath.substring(lastDot);
      if (!['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp']
          .contains(extension.toLowerCase())) {
      } else {
        basePathWithoutExtension = normalizedOriginalPath.substring(0, lastDot);
      }
    }

    if (basePathWithoutExtension != normalizedOriginalPath || !normalizedOriginalPath.contains('.')) {
      pathsToTry.addAll([
        '$basePathWithoutExtension.mp4',
        '$basePathWithoutExtension.mov',
        '$basePathWithoutExtension.avi',
        '$basePathWithoutExtension.mkv',
        '$basePathWithoutExtension.webm',
        '$basePathWithoutExtension.3gp',
      ]);
    }

    pathsToTry = pathsToTry.toSet().toList();
    debugPrint("Trying video paths for '$originalPath': $pathsToTry");

    for (String path in pathsToTry) {
      if (await _checkVideoAssetExists(path)) {
        debugPrint("Found valid video asset path: '$path'");
        return path;
      }
    }
    debugPrint("No valid video asset path found for: '$originalPath'");
    return null;
  }


  void _prepareStepContent() async {
    _videoController?.dispose();
    _videoController = null;
    _initializeVideoPlayerFuture = null;
    _errorMessage = null;

    if (_currentSession.details.isEmpty || _currentStepIndex >= _currentSession.details.length) {
      debugPrint("Invalid step index in _prepareStepContent: $_currentStepIndex or details empty.");
      setStateIfMounted(() => _errorMessage = "خطأ في تحميل بيانات التمرين.");
      return;
    }

    final currentDetail = _currentSession.details[_currentStepIndex];

    if (currentDetail.hasVideo && currentDetail.video != null && currentDetail.video!.isNotEmpty) {
      debugPrint("--- Preparing Video Content for: ${currentDetail.video} ---");
      String? validVideoPath = await _findValidVideoPath(currentDetail.video!);

      if (validVideoPath != null) {
        debugPrint("Video asset '$validVideoPath' found. Proceeding to initialize.");
        _videoController = VideoPlayerController.asset(validVideoPath);
        _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
          debugPrint("Video controller initialized successfully for: $validVideoPath");
          if (mounted) {
            setStateIfMounted(() { _errorMessage = null; });
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        }).catchError((error) {
          debugPrint("Error initializing video player: $error for video: $validVideoPath");
          if (mounted) {
            String errorMsg = "خطأ في تحميل الفيديو: $validVideoPath";
            if (error.toString().toLowerCase().contains('source error') || error.toString().toLowerCase().contains('exoplaybackexception')) {
              errorMsg = "تنسيق الفيديو غير مدعوم أو الملف تالف: ${validVideoPath.split('/').last}";
            } else if (error.toString().toLowerCase().contains('filenotfoundexception')) {
              errorMsg = "ملف الفيديو غير موجود بالحزمة: ${validVideoPath.split('/').last}";
            }
            setStateIfMounted(() => _errorMessage = errorMsg);
          }
        });
      } else {
        debugPrint("Valid video asset NOT FOUND for: ${currentDetail.video}. Ensure it's in pubspec.yaml and the path is correct.");
        if (mounted) {
          setStateIfMounted(() {
            _errorMessage = "ملف الفيديو '${currentDetail.video}' غير موجود. تأكد من إضافته للمشروع وتحديث pubspec.yaml.";
          });
        }
      }
    } else {
       debugPrint("No video for current step, or video path is null/empty.");
    }

    if (mounted) {
      setStateIfMounted(() {});
    }
  }


  void _startStepTimer() {
    _stepTimer?.cancel();
    if (_currentSession.details.isEmpty ||
        _currentStepIndex >= _currentSession.details.length) {
      return;
    }

    final currentDetail = _currentSession.details[_currentStepIndex];
    Duration currentStepDuration;
    final bool isLastStep =
        _currentStepIndex == _currentSession.details.length - 1;

    if (currentDetail.hasVideo) {
      currentStepDuration = videoDisplayDuration;
    } else if (currentDetail.hasImage) {
      currentStepDuration = imageDisplayDuration;
    } else {
      currentStepDuration = textDisplayDuration;
    }

    debugPrint(
        "Starting step timer for Step Index: $_currentStepIndex (ID: ${currentDetail.id}) - Type: ${currentDetail.datatypeOfContent} - Duration: ${currentStepDuration.inSeconds} sec");

    if (isLastStep) {
      _selectRandomObjectImageInfo();
    }

    _stepTimer = Timer(currentStepDuration, () {
      debugPrint("Step Timer Finished for Step Index: $_currentStepIndex.");
      if (mounted) {
        _goToNextStep();
      }
    });
  }

  Future<bool> _completeDetailApiCall(int detailId) async {
    if (!_completedDetailIds.contains(detailId)) {
      _completedDetailIds.add(detailId);
    }
    debugPrint("Added detail ID $detailId to session completed list. Current list: $_completedDetailIds");

    setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint("Attempting to complete session detail ID: $detailId");
      bool success = await ApiService.completeDetail(widget.jwtToken, detailId);
      if (!mounted) return false;
      if (success) {
        debugPrint("Successfully completed session detail ID: $detailId");
      } else {
        debugPrint("Failed to complete session detail ID: $detailId via API.");
        if (_errorMessage == null || !_errorMessage!.contains("الفيديو")) {
          setStateIfMounted(() => _errorMessage = "فشل حفظ التقدم.");
        }
      }
      return success;
    } catch (e) {
      debugPrint("Error completing session detail $detailId: $e");
      if (mounted) {
        if (_errorMessage == null || !_errorMessage!.contains("الفيديو")) {
          setStateIfMounted(() => _errorMessage = "خطأ في الاتصال بالخادم.");
        }
      }
      return false;
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToNextStep() async {
    if (_isLoading || _currentSession.details.isEmpty) return;
    if (_currentStepIndex >= _currentSession.details.length) {
      debugPrint("Attempted to go to next step, but already past the end or no details.");
      if (mounted && _currentSession.details.isNotEmpty) {
        _navigateToTestScreen();
      }
      return;
    }

    _stepTimer?.cancel();
    _stepTimer = null;
    _videoController?.pause();

    final currentDetailId = _currentSession.details[_currentStepIndex].id;
    bool success = await _completeDetailApiCall(currentDetailId);

    if (!mounted) return;

    if (success) {
      final nextIndex = _currentStepIndex + 1;
      final bool isSessionFinished = nextIndex >= _currentSession.details.length;

      debugPrint("API call for session detail $currentDetailId successful. Starting break.");
      await _startBreakAndWait();
      if (!mounted) return;

      if (isSessionFinished) {
        _navigateToTestScreen();
      } else {
        debugPrint("Break finished. Moving to session exercise index $nextIndex.");
        setStateIfMounted(() {
          _currentStepIndex = nextIndex;
          _errorMessage = null;
        });
        _prepareStepContent();
        _startStepTimer();
      }
    } else {
      debugPrint("API call for session detail $currentDetailId failed. Staying on current step. Error: $_errorMessage");
      _startStepTimer();
      if (mounted && (_errorMessage != null && _errorMessage!.isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToTestScreen() {
    debugPrint("All session exercises completed or end of session reached! Navigating to StartTest screen.");
    debugPrint("Final list of completed session detail IDs to pass: $_completedDetailIds");
    if (mounted) {
      Navigator.pop(context, true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StartTest(
            previousSessionDetailIds: List<int>.from(_completedDetailIds),
          ),
        ),
      );
    }
  }

  Future<void> _startBreakAndWait() async {
    debugPrint("Navigating to BreakScreen for $breakDuration...");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreakScreen(duration: breakDuration),
        fullscreenDialog: true,
      ),
    );
    debugPrint("Returned from BreakScreen.");
  }

  Widget _buildStepContent() {
    if (_currentSession.details.isEmpty || _currentStepIndex >= _currentSession.details.length) {
      return _buildGenericErrorWidget("اكتملت التمارين أو لا يمكن عرض التمرين الحالي.");
    }

    final currentDetail = _currentSession.details[_currentStepIndex];
    final int totalSteps = _currentSession.details.length;
    final bool isLastStep = _currentStepIndex == totalSteps - 1;
    final bool isSecondToLastStep = (totalSteps > 1) && (_currentStepIndex == totalSteps - 2);

    debugPrint("--- Building Content for Step Index: $_currentStepIndex (ID: ${currentDetail.id}), Type: ${currentDetail.datatypeOfContent} ---");

    bool displayDoubleImage = false;
    String? imagePath1;
    String? imagePath2;
    String? text1 = currentDetail.text;
    String? text2;
    String? desc1 = currentDetail.desc;
    String? desc2;
    String? randomImageCaption;

    bool showAdditionalContentForNonTypeId2 = _currentSession.typeId != 2;

    if (showAdditionalContentForNonTypeId2) {
      if (isSecondToLastStep &&
          currentDetail.hasImage &&
          currentDetail.image != null &&
          _currentSession.newDetail?.hasImage == true &&
          _currentSession.newDetail?.image != null) {
        displayDoubleImage = true;
        imagePath1 = localImagePathBase + currentDetail.image!;
        imagePath2 = localImagePathBase + _currentSession.newDetail!.image!;
        text2 = _currentSession.newDetail!.text;
        desc2 = _currentSession.newDetail!.desc;
      } else if (isLastStep &&
          currentDetail.hasImage &&
          currentDetail.image != null &&
          _randomImageInfo != null &&
          _randomImageInfo!.path.isNotEmpty) {
        displayDoubleImage = true;
        imagePath1 = localImagePathBase + currentDetail.image!;
        imagePath2 = _randomImageInfo!.path;
        randomImageCaption = _randomImageInfo!.name;
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentDetail.hasImage && currentDetail.image != null && currentDetail.image!.isNotEmpty) ...[
                    if (displayDoubleImage && imagePath1 != null && imagePath2 != null) ...[
                      _buildDoubleImageDisplay(imagePath1, imagePath2, text1, text2, desc1, desc2, randomImageCaption),
                    ] else ...[
                      _buildSingleImageDisplay(
                        localImagePathBase + currentDetail.image!,
                        text1,
                        showAdditionalContentForNonTypeId2 ? desc1 : null,
                      ),
                    ],
                  ] else if (currentDetail.hasVideo && currentDetail.video != null && currentDetail.video!.isNotEmpty) ...[
                    _buildVideoDisplay(currentDetail.video!),
                  ] else if (currentDetail.hasText && currentDetail.text != null && currentDetail.text!.isNotEmpty) ...[
                    _buildTextDisplay(currentDetail.text!),
                  ] else if (!currentDetail.hasImage && !currentDetail.hasVideo && !currentDetail.hasText && _errorMessage == null) ...[
                    _buildGenericErrorWidget("لا يوجد محتوى لهذا التمرين."),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImageDisplay(String imagePath, String? text, String? desc) {
    debugPrint("Building single image display for: $imagePath");
    bool hasText = text != null && text.isNotEmpty;
    bool hasDesc = desc != null && desc.isNotEmpty;

    // Adjusted image height
    double imageHeight = spacingUnit * 42; // 336.0 (was 304.0) - Adjust as needed

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
      elevation: spacingSmall,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingLarge)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                spacingMedium,
                spacingMedium,
                spacingMedium,
                (hasText || hasDesc) ? spacingSmall : spacingMedium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(spacingMedium),
              child: Image.asset(
                _normalizeAssetPath(imagePath),
                fit: BoxFit.contain,
                height: imageHeight, // Using the new height
                errorBuilder: (context, error, stackTrace) =>
                    _buildImageErrorWidget(context, error, stackTrace, imagePath),
              ),
            ),
          ),
          if (hasText)
            Padding(
              padding: EdgeInsets.only(
                  bottom: hasDesc ? spacingSmall : spacingMedium,
                  left: spacingMedium,
                  right: spacingMedium),
              child: Text(
                text!,
                style: const TextStyle(
                  fontSize: 22, // Kept as per your previous request
                  color: cardTextColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'cairo',
                  height: 2, // Kept as per your previous request
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (hasDesc)
            Padding(
              padding: const EdgeInsets.only(
                  bottom: spacingMedium,
                  left: spacingMedium,
                  right: spacingMedium,
                  top: spacingSmall / 2),
              child: Text(
                desc!,
                style: TextStyle(
                  fontSize: 22, // Kept as per your previous request
                  color: cardTextColor.withOpacity(0.9),
                  fontFamily: 'cairo',
                  height: 1.3, // Kept as per your previous request
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoDisplay(String videoPathOriginalData) {
    debugPrint("Building video display. Controller initialized: ${_videoController?.value.isInitialized}, Error: $_errorMessage");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
      elevation: spacingSmall,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingLarge)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(spacingMedium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(spacingMedium),
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (_videoController == null) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: spacingUnit * 6),
                              const SizedBox(height: spacingSmall),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: spacingSmall),
                                child: Text(
                                  _errorMessage ?? "فشل في تهيئة مشغل الفيديو.",
                                  style: const TextStyle(color: Colors.white, fontSize: spacingMedium),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !_videoController!.value.isInitialized && snapshot.connectionState != ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: loadingIndicatorColor),
                              SizedBox(height: spacingSmall),
                              Text("جاري تحميل الفيديو...",
                                  style: TextStyle(color: Colors.white, fontSize: spacingMedium),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !_videoController!.value.isInitialized) {
                     String errorToShow = _errorMessage ?? "لا يمكن تشغيل الفيديو.";
                    if (snapshot.hasError) {
                      debugPrint("FutureBuilder snapshot error for video: ${snapshot.error}");
                    }
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: spacingUnit * 6),
                              const SizedBox(height: spacingSmall),
                              Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: spacingSmall),
                                  child: Text(errorToShow,
                                      style: const TextStyle(color: Colors.white, fontSize: spacingMedium),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (_videoController!.value.isInitialized) {
                    return AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          VideoPlayer(_videoController!),
                          _ControlsOverlay(
                              controller: _videoController!,
                              key: ValueKey(_videoController.hashCode)),
                        ],
                      ),
                    );
                  }

                  return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                          decoration: const BoxDecoration(color: videoPlaceholderColor),
                          child: Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Icon(Icons.hourglass_empty, color: Colors.white, size: spacingUnit * 6),
                                const SizedBox(height: spacingSmall),
                                Text("حالة غير معروفة للفيديو",
                                    style: TextStyle(color: Colors.white, fontSize: spacingMedium))
                              ]))));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDisplay(String text) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
      elevation: spacingSmall,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingLarge)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: spacingXXLarge, horizontal: spacingLarge),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: spacingLarge,
                color: cardTextColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'cairo',
                height: 1.6)),
      ),
    );
  }

  Widget _buildDoubleImageDisplay(
      String imagePath1,
      String imagePath2,
      String? text1,
      String? text2,
      String? desc1,
      String? desc2,
      String? randomImageCaption) {
    bool isSecondImageRandom = randomImageCaption != null &&
        _randomImageInfo != null &&
        imagePath2 == _randomImageInfo!.path;

    bool hasText1 = text1 != null && text1.isNotEmpty;
    bool hasDesc1 = desc1 != null && desc1.isNotEmpty;
    bool hasText2 = text2 != null && text2.isNotEmpty;
    bool hasDesc2 = desc2 != null && desc2.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall),
          elevation: spacingSmall,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingMedium)),
          clipBehavior: Clip.antiAlias,
          color: cardBgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    spacingMedium,
                    spacingMedium,
                    spacingMedium,
                    (hasText1 || hasDesc1) ? spacingSmall : spacingMedium),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(spacingSmall),
                    child: Image.asset(
                        _normalizeAssetPath(imagePath1),
                        fit: BoxFit.contain,
                        height: spacingUnit * 25,
                        errorBuilder: (ctx, e, s) => _buildImageErrorWidget(ctx, e, s, imagePath1))),
              ),
              if (hasText1)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: hasDesc1 ? spacingSmall : spacingMedium,
                      left: spacingMedium,
                      right: spacingMedium),
                  child: Text(text1!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: spacingMedium,
                          color: cardTextColor,
                          fontFamily: 'cairo',
                          height: 1.3)),
                ),
              if (hasDesc1)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: spacingMedium,
                      left: spacingMedium,
                      right: spacingMedium,
                      top: spacingSmall / 2),
                  child: Text(desc1!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: spacingMedium,
                          color: cardTextColor.withOpacity(0.85),
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.normal,
                          height: 1.2)),
                ),
            ],
          ),
        ),
        const SizedBox(height: spacingMedium),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingSmall),
          elevation: spacingSmall,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingMedium)),
          clipBehavior: Clip.antiAlias,
          color: cardBgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    spacingMedium,
                    spacingMedium,
                    spacingMedium,
                    (hasText2 || hasDesc2 || isSecondImageRandom) ? spacingSmall : spacingMedium),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(spacingSmall),
                  child: Image.asset(
                      _normalizeAssetPath(imagePath2),
                      fit: BoxFit.contain,
                      height: spacingUnit * 25,
                      errorBuilder: (ctx, e, s) => _buildImageErrorWidget(
                          ctx, e, s, isSecondImageRandom ? "صورة عشوائية ($imagePath2)" : imagePath2)),
                ),
              ),
              if (hasText2)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: (hasDesc2 || isSecondImageRandom) ? spacingSmall : spacingMedium,
                      left: spacingMedium,
                      right: spacingMedium),
                  child: Text(text2!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: spacingMedium,
                          color: cardTextColor,
                          fontFamily: 'cairo',
                          height: 1.3)),
                ),
              if (hasDesc2)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: isSecondImageRandom ? spacingSmall : spacingMedium,
                      left: spacingMedium,
                      right: spacingMedium,
                      top: spacingSmall / 2),
                  child: Text(desc2!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: spacingMedium,
                          color: cardTextColor.withOpacity(0.85),
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.normal,
                          height: 1.2)),
                ),
              if (isSecondImageRandom && randomImageCaption != null)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: spacingMedium,
                      left: spacingMedium,
                      right: spacingMedium,
                      top: spacingSmall),
                  child: Text(randomImageCaption,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: spacingMedium,
                          color: cardTextColor.withOpacity(0.9),
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.w500,
                          height: 1.3)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericErrorWidget(String message) {
    return Container(
      margin: const EdgeInsets.all(spacingLarge),
      padding: const EdgeInsets.symmetric(vertical: spacingXLarge, horizontal: spacingLarge),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(spacingMedium),
          border: Border.all(color: Colors.orange.shade100)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.warning_amber_rounded, size: spacingUnit * 6, color: Colors.orangeAccent),
        const SizedBox(height: spacingMedium),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: spacingMedium,
                color: Colors.orange)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    bool isVideoLoading = _videoController != null &&
        _initializeVideoPlayerFuture != null &&
        ModalRoute.of(context)?.isCurrent == true &&
        !_videoController!.value.isInitialized;

    if ((_isLoading && !isVideoLoading) || (_isLoading && _videoController == null)) {
      bodyContent = const Center(child: CircularProgressIndicator(color: loadingIndicatorColor));
    } else if (_errorMessage != null && _currentSession.details.isEmpty) {
      bodyContent = Center(child: _buildGenericErrorWidget(_errorMessage!));
    } else if (_currentSession.details.isEmpty) {
      bodyContent = Center(child: _buildGenericErrorWidget("لا توجد تمارين متاحة في هذه الجلسة حاليًا."));
    } else if (_currentStepIndex >= _currentSession.details.length) {
      bodyContent = Center(child: _buildGenericErrorWidget("اكتملت التمارين أو حدث خطأ غير متوقع في تدفق الجلسة."));
    } else {
      bodyContent = Column(
        children: [
          if (_currentSession.details.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(spacingLarge, spacingMedium, spacingLarge, spacingSmall),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(spacingSmall),
                child: LinearProgressIndicator(
                    value: (_currentStepIndex + 1) / _currentSession.details.length,
                    minHeight: spacingSmall,
                    backgroundColor: progressBarBgColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(progressBarColor)),
              ),
            ),
          Expanded(child: _buildStepContent()),
          if (_errorMessage != null &&
                  !_errorMessage!.contains("الفيديو") &&
                  !_errorMessage!.contains("ملف الفيديو")
              )
            Padding(
                padding: const EdgeInsets.all(spacingMedium),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: errorTextColor, fontWeight: FontWeight.bold, fontSize: spacingMedium - 2),
                    textAlign: TextAlign.center))
          else
            const SizedBox(height: spacingMedium), // Changed from 20.0 to 16.0 for 8-grid consistency

          Padding(
            padding: const EdgeInsets.fromLTRB(spacingLarge, spacingSmall, spacingLarge, spacingLarge),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || isVideoLoading)
                    ? null
                    : () {
                        debugPrint("Next button pressed. Current step timer will be cancelled by _goToNextStep.");
                        _goToNextStep();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBgColor,
                  foregroundColor: buttonFgColor,
                  padding: const EdgeInsets.symmetric(vertical: spacingMedium),
                  textStyle: const TextStyle(
                      fontSize: spacingMedium + 2, // 18.0, or make 16
                      fontWeight: FontWeight.bold,
                      fontFamily: 'cairo'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacingXLarge)),
                  elevation: spacingSmall,
                  shadowColor: Colors.black.withOpacity(0.2),
                  disabledBackgroundColor: buttonBgColor.withOpacity(0.7),
                  disabledForegroundColor: buttonFgColor.withOpacity(0.5),
                ),
                child: (_isLoading && !isVideoLoading)
                    ? const SizedBox(
                        height: spacingLarge,
                        width: spacingLarge,
                        child: CircularProgressIndicator(
                            strokeWidth: spacingSmall / 2,
                            valueColor: AlwaysStoppedAnimation<Color>(buttonFgColor)))
                    : const Text('التالي'),
              ),
            ),
          ),
        ],
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: screenBgColor,
        appBar: AppBar(
          title: Text(
            _currentSession.title ?? 'تمارين الجلسة',
            style: const TextStyle(
                color: appBarElementsColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'cairo',
                fontSize: spacingMedium + 2), // 18.0
          ),
          backgroundColor: screenBgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: appBarElementsColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: spacingLarge, color: appBarElementsColor),
            tooltip: 'العودة',
            onPressed: () {
              debugPrint("Back button pressed. Popping context with 'false'.");
              Navigator.pop(context, false);
            },
          ),
        ),
        body: bodyContent,
      ),
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller, super.key});
  final VideoPlayerController controller;
  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: widget.controller.value.isPlaying
              ? const SizedBox.shrink()
              : DecoratedBox(
                  key: const ValueKey<String>('playButton'),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(_SessionDetailsScreenState.spacingXLarge)),
                  child: const Center(
                      child: Icon(Icons.play_arrow,
                          color: Colors.white,
                          size: _SessionDetailsScreenState.spacingUnit * 9,
                          semanticLabel: 'Play'))),
        ),
        GestureDetector(
          onTap: () {
            if (widget.controller.value.isInitialized) {
              if (widget.controller.value.isPlaying) {
                widget.controller.pause();
              } else {
                widget.controller.play();
              }
            }
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: _SessionDetailsScreenState.spacingSmall,
                vertical: _SessionDetailsScreenState.spacingSmall / 2), // Halved vertical padding for progress bar
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: _SessionDetailsScreenState.buttonFgColor.withOpacity(0.8),
                bufferedColor: Colors.white.withOpacity(0.4),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}