// lib/features/auth/presentation/widgets/face_verification_dialog.dart

import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';

// ===========================================
// ML KIT LOGIC SIMULATION (Stricter Checks)
// ===========================================
class MLFaceQualityChecker {
  // آستانه‌های حساس برای تشخیص چهره مناسب (بر اساس درجه و مقیاس 0-1)
  static const double MAX_YAW_ANGLE = 5.0; // حداکثر 5 درجه چرخش به چپ/راست
  static const double MAX_PITCH_ANGLE = 5.0; // حداکثر 5 درجه چرخش به بالا/پایین
  static const double MIN_BRIGHTNESS = 0.6; // حداقل روشنایی مورد نیاز
  static const double MAX_BLUR = 0.9; // شبیه‌سازی وضوح بالا

  final Random _random = Random();

  // شبیه‌سازی اندازه‌گیری‌های واقعی ML Kit
  double _simulateMeasurement(double maxError, double center) {
    // تولید یک عدد تصادفی با توزیع نزدیک به مقدار صحیح (center)
    return center + (_random.nextDouble() * 2 - 1) * maxError;
  }

  // --- شبیه‌سازی اندازه‌گیری‌های چهره ---
  bool isAngleGood() {
    // چهره باید مستقیم باشد (Yaw و Pitch نزدیک به صفر)
    final yaw = _simulateMeasurement(10.0, 0.0).abs();
    final pitch = _simulateMeasurement(10.0, 0.0).abs();

    return yaw <= MAX_YAW_ANGLE && pitch <= MAX_PITCH_ANGLE;
  }

  bool isLightingGood() {
    // شبیه‌سازی نور محیط (بیشتر مواقع نور خوب است، اما گاهی اوقات کم است)
    final brightness = _simulateMeasurement(0.6, 0.5); // تولید بین 0.1 تا 0.9
    return brightness >= MIN_BRIGHTNESS;
  }

  bool isFocusGood() {
    // شبیه‌سازی فوکوس و وضوح
    final blur = _simulateMeasurement(0.3, 0.5); // تولید تصادفی
    return blur <= MAX_BLUR;
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

  // متغیرهای وضعیت برای گزارش کیفیت
  bool _isAngleOk = false;
  bool _isLightingOk = false;
  bool _isFocusOk = false;

  bool get _isQualityOk => _isAngleOk && _isLightingOk && _isFocusOk;

  String _feedbackMessage = 'در حال راه‌اندازی دوربین...';
  final MLFaceQualityChecker _qualityChecker =
      MLFaceQualityChecker(); // نمونه ML Checker

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // ... (کد راه‌اندازی دوربین از پاسخ قبلی)
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

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _initializeControllerFuture = _cameraController!.initialize().then((_) {
        _cameraController!.startImageStream(_processCameraImage);
        _setFeedback('دوربین آماده. لطفا چهره را در کادر قرار دهید.');
      });

      setState(() {});
    } on CameraException catch (e) {
      _setFeedback('خطا در دسترسی: ${e.description}');
    } catch (e) {
      _setFeedback('خطای نامشخص در راه‌اندازی دوربین.');
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

  // --- متد پردازش فریم‌ها با منطق سختگیرانه ---
  void _processCameraImage(CameraImage image) {
    if (!mounted ||
        _cameraController == null ||
        !_cameraController!.value.isStreamingImages)
      return;

    // شبیه‌سازی ML Kit: اجرای چک‌های حساسیت بالا
    final isAngle = _qualityChecker.isAngleGood();
    final isLighting = _qualityChecker.isLightingGood();
    final isFocus = _qualityChecker.isFocusGood();

    final allGood = isAngle && isLighting && isFocus;

    if (allGood) {
      if (!_isQualityOk) {
        _setFeedback(
          'کیفیت چهره عالی. آماده ثبت.',
          angle: true,
          light: true,
          focus: true,
        );
      }
    } else {
      String status = '';
      if (!isAngle)
        status = 'زاویه چهره مناسب نیست (صاف نگه دارید).';
      else if (!isLighting)
        status = 'نور محیط کافی نیست (به سمت نور بچرخید).';
      else if (!isFocus)
        status = 'چهره تار است (فاصله را تنظیم کنید).';
      else
        status = 'در حال پردازش...';

      _setFeedback(status, angle: isAngle, light: isLighting, focus: isFocus);
    }
  }

  Future<void> _captureAndSend(BuildContext context) async {
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (!_isQualityOk) {
      // <<<--- این شرط اصلی است
      _setFeedback(
        'ارسال لغو شد. کیفیت چهره تأیید نشده است.',
        angle: false,
        light: false,
        focus: false,
      );
      return;
    }

    try {
      // 1. توقف استریم
      await _cameraController!.stopImageStream();
      _setFeedback('عکس گرفته شد. در حال ارسال...');

      // 2. گرفتن عکس
      final XFile imageFile = await _cameraController!.takePicture();

      // 3. فراخوانی Cubit برای ارسال به API
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
            if (state is FaceProcessingLoading ||
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
                // نمایش وضعیت‌های جزئی برای راهنمایی کاربر
                _buildQualityIndicator('زاویه صاف', _isAngleOk),
                _buildQualityIndicator('نور کافی', _isLightingOk),
                _buildQualityIndicator('وضوح و فوکوس', _isFocusOk),

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
                              CameraPreview(_cameraController!),
                              // کادر راهنما (رنگ بر اساس کیفیت کلی)
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
                    // دکمه فقط زمانی فعال است که: دوربین آماده، کیفیت تایید شده باشد و پردازشی در حال انجام نباشد.
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

  // ویجت کمکی برای نمایش وضعیت هر شرط
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
            color: isOk ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }
}
