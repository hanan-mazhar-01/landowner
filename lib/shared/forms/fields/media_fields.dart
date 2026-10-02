import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/sheets.dart';

/// Dashed upload box with thumbnails. Images are picked at ≤1600px and
/// 82% quality so uploads stay small; single-file fields also accept PDFs.
class UploadField extends StatelessWidget {
  const UploadField({super.key, required this.files, required this.onChanged, this.multi = false});
  final List<String> files;
  final ValueChanged<List<String>> onChanged;
  final bool multi;

  static const _library = 'Photo library';
  static const _camera = 'Take a photo';
  static const _file = 'Choose a file (PDF or image)';

  static bool isImage(String path) {
    final ext = path.split('?').first.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'heic', 'heif', 'webp', 'gif'}.contains(ext);
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showChoiceSheet(
      context,
      title: multi ? 'Add photos' : 'Attach',
      options: [_library, _camera, if (!multi) _file],
    );
    if (source == null) return;
    final picker = ImagePicker();
    try {
      if (source == _file) {
        final picked = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
        );
        if (picked.isEmpty) return;
        final f = picked.first;
        var path = f.path;
        if (path == null) {
          // Content URIs (Android) are copied into the app's temp folder.
          final dir = await getTemporaryDirectory();
          final copy = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}_${f.name}');
          await copy.writeAsBytes(await f.readAsBytes(), flush: true);
          path = copy.path;
        }
        onChanged([path]);
      } else if (source == _camera) {
        final x = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 82);
        if (x != null) onChanged(multi ? [...files, x.path] : [x.path]);
      } else if (multi) {
        final picked = await picker.pickMultiImage(maxWidth: 1600, imageQuality: 82, limit: 12);
        if (picked.isNotEmpty) onChanged([...files, ...picked.map((x) => x.path)]);
      } else {
        final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 82);
        if (x != null) onChanged([x.path]);
      }
    } catch (_) {
      // Picker unavailable (simulator without camera, denied permission) — keep state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = files.length;
    final label = n > 0
        ? '$n ${multi ? 'photo${n > 1 ? 's' : ''}' : 'file'} added · tap to ${multi ? 'add more' : 'replace'}'
        : (multi ? 'Tap to add photos' : 'Tap to attach a PDF or photo');
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => _pick(context),
        scale: .99,
        child: CustomPaint(
          painter: _DashedBorder(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.blue25, borderRadius: BorderRadius.circular(AppRadius.cta)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (n > 0) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final f in files.take(8))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox.square(dimension: 62, child: isImage(f) ? NetImage(f) : _FileTile(f)),
                    ),
                ]),
                const SizedBox(height: 12),
              ],
              Row(children: [
                const HomelyIcon(HomelyIcons.upload, size: 20, color: AppColors.primary, strokeWidth: 1.9),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Thumbnail for a non-image attachment (e.g. a PDF).
class _FileTile extends StatelessWidget {
  const _FileTile(this.path);
  final String path;

  @override
  Widget build(BuildContext context) {
    final ext = path.split('?').first.split('.').last.toUpperCase();
    return ColoredBox(
      color: AppColors.blue100,
      child: Center(
        child: Text(ext.length > 4 ? 'FILE' : ext,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.cta));
    final path = Path()..addRRect(rr.deflate(.75));
    final paint = Paint()
      ..color = AppColors.blue300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
}

/// Stylised location preview with a draggable pin (design `isMap`).
class MapPinField extends StatefulWidget {
  const MapPinField({super.key});

  @override
  State<MapPinField> createState() => _MapPinFieldState();
}

class _MapPinFieldState extends State<MapPinField> {
  Offset _pin = Offset.zero;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.cta),
        child: SizedBox(
          height: 150,
          child: LayoutBuilder(builder: (context, c) {
            return GestureDetector(
              onPanUpdate: (d) => setState(() {
                final n = _pin + d.delta;
                _pin = Offset(n.dx.clamp(-c.maxWidth / 2 + 24, c.maxWidth / 2 - 24), n.dy.clamp(-50, 50));
              }),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                Center(
                  child: Transform.translate(
                    offset: _pin + const Offset(0, -14),
                    child: Transform.rotate(
                      angle: -0.785,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(4),
                          ),
                          boxShadow: AppShadows.pin,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Drag the pin to adjust',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                ),
              ]),
            );
          }),
        ),
      );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapGround);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-12 * 3.14159 / 180);
    canvas.scale(1.3);
    canvas.translate(-size.width / 2, -size.height / 2);
    final grid = Paint()
      ..color = AppColors.mapGrid
      ..strokeWidth = 2;
    for (var x = -size.width; x < size.width * 2; x += 46) {
      canvas.drawLine(Offset(x, -size.height), Offset(x, size.height * 2), grid);
    }
    for (var y = -size.height; y < size.height * 2; y += 38) {
      canvas.drawLine(Offset(-size.width, y), Offset(size.width * 2, y), grid);
    }
    canvas.drawRect(Rect.fromLTWH(-size.width, 62, size.width * 3, 14), Paint()..color = AppColors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => false;
}
