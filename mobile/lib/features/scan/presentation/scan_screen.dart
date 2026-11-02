import 'dart:io';
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

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _repo = ScanRepository();
  bool _isLoading = false;

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showPermissionDenied('kamera');
      return;
    }
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file != null) _analyzeImage(File(file.path));
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 90,
    );
    if (file != null) _analyzeImage(File(file.path));
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
                'Skinly membutuhkan izin akses $type agar dapat memotret wajahmu untuk dianalisis jenis kulitnya.',
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
              const SizedBox(height: 24),
              SkinlyButton(
                text: 'Ambil Foto Ulang',
                variant: SkinlyButtonVariant.primaryPink,
                width: double.infinity,
                height: 48,
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _repo.analyze(imageFile);
      if (mounted) {
        context.push(AppRoutes.result, extra: {
          'result': result,
          'imageFile': imageFile,
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
                      IconButton(
                        onPressed: () => context.push(AppRoutes.scanExample),
                        icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                        tooltip: 'Panduan Contoh Foto',
                      ),
                    ],
                  ),
                ),

                // Area Viewfinder Bingkai Oval
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder Container
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.face_retouching_natural_rounded,
                                    size: 90,
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Posisikan wajah di dalam bingkai oval',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              // Oval Overlay Painter
                              CustomPaint(
                                size: const Size(double.infinity, double.infinity),
                                painter: _FigmaOvalOverlayPainter(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

                      // Tombol Shutter Kamera Utama
                      GestureDetector(
                        onTap: _isLoading ? null : _pickFromCamera,
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
