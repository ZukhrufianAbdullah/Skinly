import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../data/scan_repository.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String? _cameraErrorMessage;

  final _picker = ImagePicker();
  final _repo = ScanRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        _startCamera(_cameras[_cameraIndex]);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isCameraError = false;
      _cameraErrorMessage = null;
    });

    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _cameraErrorMessage = 'Izin kamera diperlukan untuk memindai wajah.';
          });
        }
        _showPermissionDenied('kamera');
        return;
      }
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraError = true;
            _cameraErrorMessage = 'Kamera tidak ditemukan di perangkat ini.';
          });
        }
        return;
      }

      // Utamakan kamera depan untuk scan wajah
      int frontIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIndex != -1 ? frontIndex : 0;

      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMessage = 'Gagal mengakses kamera: $e';
        });
      }
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraError = true;
          _cameraErrorMessage = 'Gagal memulai preview kamera: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isCameraInitialized = false);
    await _cameraController?.dispose();
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _takePhoto() async {
    if (_isLoading) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      // Fallback jika kamera in-app belum siap
      await _pickFromCamera();
      return;
    }

    if (controller.value.isTakingPicture) return;

    try {
      final XFile photo = await controller.takePicture();
      await _analyzeImage(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal mengambil gambar: $e'),
          ),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showPermissionDenied('kamera');
        return;
      }
    }
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file != null) _analyzeImage(file);
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 90,
    );
    if (file != null) _analyzeImage(file);
  }

  void _showPermissionDenied(String type) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkinlyMascot(
                width: 80,
                height: 80,
                variant: SkinlyMascotVariant.standard,
              ),
              const SizedBox(height: 16),
              Text(
                'Izin $type Diperlukan',
                style: AppTextStyles.h2.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Skinly membutuhkan izin akses $type agar dapat memotret wajahmu langsung di aplikasi untuk dianalisis jenis kulitnya.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SkinlyButton(
                      text: 'Batal',
                      variant: SkinlyButtonVariant.ghost,
                      height: 46,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SkinlyButton(
                      text: 'Pengaturan',
                      variant: SkinlyButtonVariant.primaryTeal,
                      height: 46,
                      onPressed: () {
                        Navigator.pop(ctx);
                        openAppSettings();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoRejectedDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkinlyMascot(
                width: 80,
                height: 80,
                variant: SkinlyMascotVariant.standard,
              ),
              const SizedBox(height: 16),
              Text(
                'Foto Perlu Diperbaiki',
                style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips agar foto diterima:',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Hadapkan wajah lurus ke kamera\n'
                      '• Pastikan cahaya cukup, hindari backlight\n'
                      '• Lepas masker/kacamata hitam\n'
                      '• Pegang kamera stabil dan tunggu fokus',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SkinlyButton(
                text: 'Ambil Foto Ulang',
                variant: SkinlyButtonVariant.primaryPink,
                width: double.infinity,
                height: 48,
                onPressed: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeImage(XFile imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final result = await _repo.analyze(bytes, filename: imageFile.name);
      if (mounted) {
        context.push(AppRoutes.result, extra: {
          'result': result,
          'imageBytes': bytes,
        });
      }
    } catch (e) {
      if (mounted) {
        _showPhotoRejectedDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        'Periksa Wajahmu',
                        style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20),
                      ),
                      const Spacer(),
                      if (_cameras.length > 1)
                        IconButton(
                          onPressed: _switchCamera,
                          icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                          tooltip: 'Ganti Kamera',
                        ),
                      IconButton(
                        onPressed: () => context.push(AppRoutes.scanExample),
                        icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                        tooltip: 'Panduan Contoh Foto',
                      ),
                    ],
                  ),
                ),

                // Area Viewfinder Bingkai Oval dengan Kamera Langsung
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          // 1. Live Camera Preview Feed
                          if (_isCameraInitialized && _cameraController != null)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final previewSize = _cameraController!.value.previewSize;
                                final double width = previewSize != null ? previewSize.height : constraints.maxWidth;
                                final double height = previewSize != null ? previewSize.width : constraints.maxHeight;

                                return SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: width,
                                      height: height,
                                      child: CameraPreview(_cameraController!),
                                    ),
                                  ),
                                );
                              },
                            )
                          else if (_isCameraError)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.videocam_off_rounded, size: 54, color: Colors.white54),
                                    const SizedBox(height: 12),
                                    Text(
                                      _cameraErrorMessage ?? 'Kamera tidak dapat diakses',
                                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    SkinlyButton(
                                      text: 'Coba Lagi',
                                      variant: SkinlyButtonVariant.primaryTeal,
                                      height: 42,
                                      onPressed: _initCamera,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: AppColors.primary),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Menyiapkan kamera...',
                                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),

                          // 2. Oval Overlay Painter di atas preview kamera
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                size: const Size(double.infinity, double.infinity),
                                painter: _FigmaOvalOverlayPainter(),
                              ),
                            ),
                          ),

                          // 3. Panduan Posisi Wajah
                          Positioned(
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Posisikan wajahmu di dalam oval',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Panduan Singkat
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScanTip(Icons.wb_sunny_outlined, 'Cahaya Terang'),
                      _buildScanTip(Icons.accessibility_new_rounded, 'Wajah Lurus'),
                      _buildScanTip(Icons.auto_fix_off_rounded, 'Tanpa Filter'),
                    ],
                  ),
                ),

                // Tombol Kontrol Bawah
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Tombol Galeri
                      GestureDetector(
                        onTap: _isLoading ? null : _pickFromGallery,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Galeri',
                              style: AppTextStyles.caption.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      // Tombol Shutter Kamera Utama (Pink)
                      GestureDetector(
                        onTap: _isLoading ? null : _takePhoto,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentButton,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentButton.withOpacity(0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      // Tombol Contoh Foto
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.scanExample),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Contoh',
                              style: AppTextStyles.caption.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay Beranimasi
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanTip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _FigmaOvalOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.48)
      ..style = PaintingStyle.fill;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.74,
      height: size.height * 0.66,
    );

    // Lubang oval
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect),
      Path()..addOval(ovalRect),
    );
    canvas.drawPath(path, overlayPaint);

    // Border oval teal
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawOval(ovalRect, borderPaint);

    // Sudut panduan putih
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 22.0;
    final corners = [
      [ovalRect.topLeft, const Offset(cornerLen, 0), const Offset(0, cornerLen)],
      [ovalRect.topRight, const Offset(-cornerLen, 0), const Offset(0, cornerLen)],
      [ovalRect.bottomLeft, const Offset(cornerLen, 0), const Offset(0, -cornerLen)],
      [ovalRect.bottomRight, const Offset(-cornerLen, 0), const Offset(0, -cornerLen)],
    ];

    for (final c in corners) {
      final pt = c[0];
      final d1 = c[1];
      final d2 = c[2];
      canvas.drawLine(pt, pt + d1, cornerPaint);
      canvas.drawLine(pt, pt + d2, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
