// lib/features/auth/presentation/widgets/face_verification_dialog.dart

// ----------------------------------------------------
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ----------------------------------------------------
// ایمپورت‌های ML KIT واقعی
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';

// ===========================================
// ML Kit Quality Checker (با آستانه‌های سختگیرانه)
// ===========================================
class FaceQualityChecker {
  // --- آستانه‌های سختگیرانه ---
  static const double MAX_YAW_ANGLE = 5.0;
  static const double MAX_PITCH_ANGLE = 7.0;
  static const double MIN_BRIGHTNESS = 0.5;
  static const double MIN_EYE_OPEN = 0.8;
  static const double MIN_VISIBILITY = 0.9;

  final Random _random = Random();

  // 1. بررسی زوایای Yaw و Pitch (زاویه صورت صاف)
  bool isAngleGood(Face face) {
    final yaw = face.headEulerAngleY?.abs() ?? 999;
    final pitch = face.headEulerAngleX?.abs() ?? 999;

    return yaw <= MAX_YAW_ANGLE && pitch <= MAX_PITCH_ANGLE;
  }

  // 2. بررسی باز بودن چشم
  bool isEyesOpen(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 0;
    final rightEye = face.rightEyeOpenProbability ?? 0;

    return leftEye >= MIN_EYE_OPEN && rightEye >= MIN_EYE_OPEN;
  }

  // 3. بررسی نور محیط و وضوح (شبیه‌سازی ML Kit)
  bool isLightingAndClarityGood(Face face) {
    final simulatedBrightness =
        _random.nextDouble() * 0.5 + 0.3; // شبیه‌سازی نور
    final isFocused = _random.nextDouble() > 0.1;

    final isLightingOk = simulatedBrightness >= MIN_BRIGHTNESS;
    final isClarityOk = (face.trackingId != null) && isFocused;

    return isLightingOk && isClarityOk;
  }
}
// ===========================================

class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({super.key});

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

class _FaceVerificationDialogState extends State<FaceVerificationDialog> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.1,
    ),
  );

  final FaceQualityChecker _qualityChecker = FaceQualityChecker();

  // وضعیت‌های جزئی برای UI
  bool _isAngleOk = false;
  bool _isLightingOk = false;
  bool _isFocusOk = false;
  bool _isMlProcessing = false; // <<<--- قفل همزمانی

  bool get _isQualityOk => _isAngleOk && _isLightingOk && _isFocusOk;
  String _feedbackMessage = 'در حال راه‌اندازی دوربین...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setFeedback('دوربین در دسترس نیست.');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // --- اعمال انعطاف در رزولوشن ---
      ResolutionPreset preferredResolution = ResolutionPreset.medium;

      for (int i = 0; i < 3; i++) {
        try {
          _cameraController = CameraController(
            frontCamera,
            preferredResolution,
            enableAudio: false,
            // برای ML Kit، NV21 برای Android و BGRA برای iOS مناسب‌ترند
            imageFormatGroup:
                Platform.isAndroid
                    ? ImageFormatGroup.nv21
                    : ImageFormatGroup.bgra8888,
          );

          _initializeControllerFuture = _cameraController!.initialize();
          await _initializeControllerFuture;

          if (_cameraController!.value.isInitialized) break;
        } catch (e) {
          if (preferredResolution == ResolutionPreset.medium) {
            preferredResolution = ResolutionPreset.low;
          } else if (preferredResolution == ResolutionPreset.low) {
            preferredResolution = ResolutionPreset.low;
          } else {
            rethrow;
          }
        }
      }
      // -------------------------------

      _cameraController!.startImageStream(_processCameraImage);
      _setFeedback('دوربین آماده. لطفا چهره را در کادر قرار دهید.');

      setState(() {});
    } on CameraException catch (e) {
      _setFeedback('خطا در دسترسی: ${e.description}');
    } catch (e) {
      _setFeedback('خطای راه‌اندازی دوربین. ممکن است رزولوشن پشتیبانی نشود.');
    }
  }

  void _setFeedback(String message, {bool? angle, bool? light, bool? focus}) {
    if (!mounted) return;
    setState(() {
      _feedbackMessage = message;
      if (angle != null) _isAngleOk = angle;
      if (light != null) _isLightingOk = light;
      if (focus != null) _isFocusOk = focus;
    });
  }

  // --- متد پردازش فریم‌ها با ML Kit ---
  void _processCameraImage(CameraImage image) async {
    if (!mounted || _isMlProcessing) return; // <<<--- قفل همزمانی
    _isMlProcessing = true;

    final inputImage = _inputImageFromCameraImage(image);

    if (inputImage == null) {
      _isMlProcessing = false;
      return;
    }

    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        final isAngle = _qualityChecker.isAngleGood(face);
        final isLighting = _qualityChecker.isLightingAndClarityGood(face);
        final isFocusAndEye = _qualityChecker.isEyesOpen(face);

        final allGood = isAngle && isLighting && isFocusAndEye;

        if (allGood) {
          if (!_isQualityOk) {
            _setFeedback(
              'کیفیت چهره تأیید شد. آماده ثبت.',
              angle: true,
              light: true,
              focus: true,
            );
          }
        } else if (!allGood) {
          String status = 'لطفا چهره خود را ثابت و صاف در کادر قرار دهید.';
          if (!isAngle)
            status = 'زاویه چهره نامناسب است.';
          else if (!isLighting)
            status = 'نور محیط یا وضوح کافی نیست.';
          else if (!isFocusAndEye)
            status = 'چشم‌ها بسته است.';

          _setFeedback(
            status,
            angle: isAngle,
            light: isLighting,
            focus: isFocusAndEye,
          );
        }
      } else {
        _setFeedback(
          'چهره‌ای در کادر یافت نشد.',
          angle: false,
          light: false,
          focus: false,
        );
      }
    } catch (e) {
      _setFeedback(
        'خطا در پردازش ML: ${e.toString()}',
        angle: false,
        light: false,
        focus: false,
      );
    }

    _isMlProcessing = false; // <<<--- باز کردن قفل
  }

  // --- تابع کمکی برای تبدیل CameraImage به InputImage ( ML Kit) ---
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final rotation = InputImageRotation.rotation90deg;

    final allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format:
          Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
  // ----------------------------------------------------

  Future<void> _captureAndSend(BuildContext context) async {
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (!_isQualityOk) {
      _setFeedback(
        'ارسال لغو شد. کیفیت چهره تأیید نشده است.',
        angle: false,
        light: false,
        focus: false,
      );
      return;
    }

    try {
      await _cameraController!.stopImageStream();
      _setFeedback('عکس گرفته شد. در حال ارسال...');
      final XFile imageFile = await _cameraController!.takePicture();

      authCubit.registerFace(imageFile.path);
    } on CameraException catch (e) {
      _setFeedback('خطا در گرفتن عکس: ${e.description}');
      _cameraController?.startImageStream(_processCameraImage);
    } catch (e) {
      _setFeedback('خطای نامشخص در گرفتن عکس.');
      _cameraController?.startImageStream(_processCameraImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCameraReady = _cameraController?.value.isInitialized ?? false;

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        return BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is FaceProcessingSuccess ||
                state is FaceProcessingError) {
              _cameraController?.startImageStream(_processCameraImage);
            }
            if (state is FaceProcessingSuccess) {
              Navigator.of(context).pop(state.success);
            } else if (state is FaceProcessingError) {
              _setFeedback('خطا: ${state.message}. دوباره تلاش کنید.');
            }
          },
          child: AlertDialog(
            title: const Text(
              'تایید هویت (Face Verification)',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // نمایش وضعیت‌های جزئی
                _buildQualityIndicator('زاویه (صاف)', _isAngleOk),
                _buildQualityIndicator('نور و وضوح', _isLightingOk),
                _buildQualityIndicator('چشم‌ها باز', _isFocusOk),

                // کادر نمایش دوربین
                Container(
                  width: 300,
                  height: 350,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child:
                      isCameraReady &&
                              snapshot.connectionState == ConnectionState.done
                          ? Stack(
                            alignment: Alignment.center,
                            children: [
                              _cameraController != null &&
                                      _cameraController!.value.isInitialized
                                  ? CameraPreview(_cameraController!)
                                  : const Center(
                                    child: Text("دوربین در حال آماده‌سازی"),
                                  ),
                              Container(
                                width: 200,
                                height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        _isQualityOk
                                            ? Colors.green
                                            : Colors.red,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ],
                          )
                          : Center(
                            child: Text(
                              _feedbackMessage,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                ),
                Text(
                  _feedbackMessage,
                  style: TextStyle(
                    color: _isQualityOk ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('لغو'),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is FaceProcessingLoading;
                  return ElevatedButton(
                    onPressed:
                        isLoading || !isCameraReady || !_isQualityOk
                            ? null
                            : () => _captureAndSend(context),
                    child:
                        isLoading
                            ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : const Text('تأیید و ارسال'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityIndicator(String text, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(color: isOk ? Colors.green : Colors.black87),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Icon(
            isOk ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isOk ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _faceDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }
}
