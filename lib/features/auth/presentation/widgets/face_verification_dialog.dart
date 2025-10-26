// lib/features/auth/presentation/widgets/face_verification_dialog.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:lms/features/auth/presentation/cubit/auth_state.dart';

// --- (Placeholder for ML KIT Face Quality Detector) ---
// شبیه‌سازی ML Kit: وضعیت خوب بودن چهره
class MLFaceQualityDetector {
  static bool isFaceQualityGood() {
    // در یک پروژه واقعی، منطق ML برای بررسی نور، زاویه، وضوح و وجود یک چهره واحد اینجا اجرا می‌شود.
    // شبیه‌سازی: 90% زمان‌ها را خوب فرض می‌کنیم
    return DateTime.now().millisecond % 10 != 0;
  }
}

class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({super.key});

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

class _FaceVerificationDialogState extends State<FaceVerificationDialog> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  bool _isQualityOk = false;
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

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // فرمت مناسب برای پردازش ML
      );

      _initializeControllerFuture = _cameraController!.initialize().then((_) {
        // شروع دریافت فریم‌ها برای پردازش کیفیت
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

  void _setFeedback(String message, {bool? quality}) {
    if (!mounted) return;
    setState(() {
      _feedbackMessage = message;
      if (quality != null) {
        _isQualityOk = quality;
      }
    });
  }

  void _processCameraImage(CameraImage image) {
    if (!mounted ||
        _cameraController == null ||
        !_cameraController!.value.isStreamingImages)
      return;

    final isGood = MLFaceQualityDetector.isFaceQualityGood();

    if (isGood) {
      if (!_isQualityOk) {
        _setFeedback('کیفیت چهره تأیید شد. آماده ثبت.', quality: true);
      }
    } else {
      if (_isQualityOk || _feedbackMessage.contains('آماده ثبت')) {
        _setFeedback(
          'زاویه، نور یا وضوح مناسب نیست. لطفا ثابت بمانید.',
          quality: false,
        );
      }
    }
  }

  Future<void> _captureAndSend(BuildContext context) async {
    final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _setFeedback('دوربین آماده نیست.');
      return;
    }
    if (!_isQualityOk) {
      _setFeedback('کیفیت چهره تایید نشده است. ارسال لغو شد.', quality: false);
      return;
    }

    try {
      // 1. توقف استریم
      await _cameraController!.stopImageStream();

      // 2. گرفتن عکس
      final XFile imageFile = await _cameraController!.takePicture();

      _setFeedback('عکس گرفته شد. در حال ارسال...');

      // 3. فراخوانی Cubit برای ارسال به API
      /*authCubit.compareFace(
        imageFile.path,
      );*/ // <<<--- این متد اکنون در Cubit تعریف شده است
    } on CameraException catch (e) {
      _setFeedback('خطا در گرفتن عکس: ${e.description}');
      _cameraController?.startImageStream(_processCameraImage);
    } catch (e) {
      _setFeedback('خطای نامشخص در گرفتن عکس: $e');
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
            // استفاده از FaceVerificationSuccess/Error
            if (state is FaceVerificationSuccess) {
              _cameraController?.startImageStream(_processCameraImage);
              // بستن دایالوگ و بازگشت نتیجه (true/false)
              Navigator.of(context).pop(state.isMatch);
            } else if (state is FaceVerificationError) {
              _cameraController?.startImageStream(_processCameraImage);
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
                // ... (کد نمایش دوربین و کادر راهنما)
                Container(
                  width: 300,
                  height: 350,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child:
                      isCameraReady
                          ? Stack(
                            alignment: Alignment.center,
                            children: [
                              // نمایش دوربین فقط زمانی که آماده است
                              _cameraController != null &&
                                      _cameraController!.value.isInitialized
                                  ? CameraPreview(_cameraController!)
                                  : const Center(
                                    child: Text("دوربین در حال آماده‌سازی"),
                                  ),
                              // کادر راهنما
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
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _feedbackMessage,
                    style: TextStyle(
                      color: _isQualityOk ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop(false), // خروج با نتیجه ناموفق
                child: const Text('لغو'),
              ),
              // استفاده از FaceVerificationLoading
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is FaceVerificationLoading;
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

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }
}
