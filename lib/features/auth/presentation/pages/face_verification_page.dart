// // lib/features/auth/presentation/pages/face_verification_page.dart
//
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lms/features/auth/presentation/cubit/auth_cubit.dart';
// import 'package:lms/features/auth/presentation/cubit/auth_state.dart';
// import 'package:lms/routes/app_router.dart';
//
// // یک کلاس کمکی برای شبیه‌سازی تشخیص چهره مناسب
// // در یک پروژه واقعی، از ML Kit یا یک پکیج تشخیص چهره استفاده می‌کنید
// class FaceQualityDetector {
//   // شبیه سازی: هر 4 بار از 5 بار، چهره مناسب است
//   static bool isFaceQualityGood() {
//     return DateTime.now().millisecond % 5 != 0;
//   }
// }
//
// class FaceVerificationPage extends StatefulWidget {
//   const FaceVerificationPage({super.key});
//
//   @override
//   State<FaceVerificationPage> createState() => _FaceVerificationPageState();
// }
//
// class _FaceVerificationPageState extends State<FaceVerificationPage> {
//   CameraController? _cameraController;
//   Future<void>? _initializeControllerFuture;
//
//   String _message = 'لطفاً برای تایید هویت، چهره خود را در کادر قرار دهید.';
//   bool _isFrameReady = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         setState(() => _message = 'دوربینی در دسترس نیست.');
//         return;
//       }
//
//       // انتخاب دوربین سلفی
//       final frontCamera = cameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => cameras.first,
//       );
//
//       _cameraController = CameraController(
//         frontCamera,
//         ResolutionPreset.medium,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.jpeg, // تنظیم فرمت
//       );
//
//       _initializeControllerFuture = _cameraController!.initialize().then((_) {
//         // شروع دریافت فریم‌ها برای بررسی کیفیت (شبیه سازی)
//         _cameraController!.startImageStream((CameraImage image) {
//           // در اینجا باید منطق واقعی تشخیص چهره، زاویه و نور اجرا شود
//           if (FaceQualityDetector.isFaceQualityGood()) {
//             if (!_isFrameReady) {
//               setState(() {
//                 _isFrameReady = true;
//                 _message = 'آماده عکسبرداری. کیفیت خوب.';
//               });
//             }
//           } else {
//             if (_isFrameReady) {
//               setState(() {
//                 _isFrameReady = false;
//                 _message =
//                     'زاویه یا نور مناسب نیست. لطفا چهره را صاف نگه دارید.';
//               });
//             }
//           }
//         });
//       });
//
//       setState(() {});
//     } on CameraException catch (e) {
//       setState(() => _message = 'خطا در دسترسی به دوربین: ${e.description}');
//     } catch (e) {
//       setState(() => _message = 'خطای نامشخص در راه‌اندازی دوربین: $e');
//     }
//   }
//
//   Future<void> _takePictureAndSend(BuildContext context) async {
//     final AuthCubit authCubit = BlocProvider.of<AuthCubit>(context);
//
//     if (_cameraController == null ||
//         !_cameraController!.value.isInitialized ||
//         !_isFrameReady) {
//       setState(
//         () =>
//             _message =
//                 _isFrameReady
//                     ? 'دوربین آماده نیست.'
//                     : 'لطفا منتظر تایید کیفیت چهره باشید.',
//       );
//       return;
//     }
//
//     try {
//       // توقف دریافت فریم‌ها
//       await _cameraController!.stopImageStream();
//
//       final XFile imageFile = await _cameraController!.takePicture();
//
//       setState(() {
//         _message = 'عکس گرفته شد. در حال ارسال برای تایید...';
//       });
//
//       // فراخوانی Use Case مقایسه چهره
//       authCubit.compareFace(imageFile.path);
//     } on CameraException catch (e) {
//       setState(() => _message = 'خطا در گرفتن عکس: ${e.description}');
//       // بعد از خطا، دوباره ImageStream را شروع کنید
//       _cameraController?.startImageStream((_) {});
//     } catch (e) {
//       setState(() => _message = 'خطای نامشخص در گرفتن عکس: $e');
//       _cameraController?.startImageStream((_) {});
//     }
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('تایید چهره'),
//         backgroundColor: Colors.teal,
//       ),
//       body: BlocConsumer<AuthCubit, AuthState>(
//         listener: (context, state) {
//           if (state is FaceVerificationSuccess) {
//             if (context.mounted) {
//               _cameraController?.startImageStream(
//                 (_) {},
//               ); // شروع مجدد جریان دوربین
//               if (state.isMatch) {
//                 context.go(AppRoutes.successPage); // مطابقت داشت
//               } else {
//                 setState(
//                   () => _message = 'چهره مطابقت ندارد. لطفاً دوباره تلاش کنید.',
//                 );
//               }
//             }
//           } else if (state is FaceVerificationError) {
//             _cameraController?.startImageStream((_) {});
//             setState(() => _message = 'خطا در تایید چهره: ${state.message}');
//           }
//         },
//         builder: (context, state) {
//           bool isLoading = state is FaceVerificationLoading;
//           bool isCameraReady =
//               _cameraController != null &&
//               _cameraController!.value.isInitialized;
//
//           Color indicatorColor =
//               _isFrameReady && !isLoading ? Colors.green : Colors.red;
//
//           return Column(
//             children: [
//               Expanded(
//                 child: FutureBuilder<void>(
//                   future: _initializeControllerFuture,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.done &&
//                         isCameraReady) {
//                       return Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           CameraPreview(_cameraController!),
//                           // کادر راهنما
//                           Container(
//                             width: 280,
//                             height: 350,
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: indicatorColor,
//                                 width: 4,
//                               ),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           // نمایش وضعیت کیفیت چهره
//                           Positioned(
//                             top: 20,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 5,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: indicatorColor,
//                                 borderRadius: BorderRadius.circular(5),
//                               ),
//                               child: Text(
//                                 _message.contains('لطفاً') ||
//                                         _message.contains('مناسب نیست')
//                                     ? 'ناآماده'
//                                     : 'آماده',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       );
//                     } else if (snapshot.hasError) {
//                       return Center(
//                         child: Text(
//                           'خطا: ${snapshot.error}',
//                           textDirection: TextDirection.rtl,
//                         ),
//                       );
//                     }
//                     return const Center(child: CircularProgressIndicator());
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Text(
//                       _message,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color:
//                             isLoading
//                                 ? Colors.blue
//                                 : (state is FaceVerificationError ||
//                                         !_isFrameReady
//                                     ? Colors.red
//                                     : Colors.black87),
//                       ),
//                       textDirection: TextDirection.rtl,
//                     ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed:
//                             isLoading || !_isFrameReady || !isCameraReady
//                                 ? null
//                                 : () => _takePictureAndSend(context),
//                         child:
//                             isLoading
//                                 ? const CircularProgressIndicator(
//                                   color: Colors.white,
//                                 )
//                                 : const Text('گرفتن عکس و تایید هویت'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
