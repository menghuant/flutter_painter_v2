
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../object_drawable.dart';
import 'shape_drawable.dart';
import '../sized1ddrawable.dart';
import '../../../extensions/paint_copy_extension.dart';
import '../../settings/arrow_settings.dart';

/// A drawable of a simple arrow shape.
class ArrowDrawable extends Sized1DDrawable implements ShapeDrawable {
  /// The paint to be used for the line drawable.
  @override
  Paint paint;

  /// Arrow-specific settings for outline and behavior.
  ArrowSettings arrowSettings;

  /// Creates a new [ArrowDrawable] with the given [length], [paint] and [arrowSettings].
  ArrowDrawable({
    Paint? paint,
    this.arrowSettings = const ArrowSettings(),
    required double length,
    required Offset position,
    double rotationAngle = 0,
    double scale = 1,
    Set<ObjectDrawableAssist> assists = const <ObjectDrawableAssist>{},
    Map<ObjectDrawableAssist, Paint> assistPaints =
        const <ObjectDrawableAssist, Paint>{},
    bool locked = false,
    bool hidden = false,
  })  : paint = paint ?? ShapeDrawable.defaultPaint,
        super(
            length: length,
            position: position,
            rotationAngle: rotationAngle,
            scale: scale,
            assists: assists,
            assistPaints: assistPaints,
            locked: locked,
            hidden: hidden);

  /// The actual arrow head size used in drawing.
  double get _arrowHeadSize => arrowSettings.arrowHeadSize ?? paint.strokeWidth * 3;

  /// Getter for padding of drawable.
  ///
  /// Add padding equal to the stroke width of the line and the size of the arrow head.
  /// Also accounts for outline width if enabled.
  @protected
  @override
  EdgeInsets get padding {
    final outlinePadding = arrowSettings.outlineEnabled ? arrowSettings.outlineWidth / 2 : 0.0;
    return EdgeInsets.symmetric(
        horizontal: paint.strokeWidth / 2 + outlinePadding,
        vertical: paint.strokeWidth / 2 + (_arrowHeadSize / 2) + outlinePadding);
  }

  /// Draws the arrow on the provided [canvas] of size [size].
  @override
  void drawObject(Canvas canvas, Size size) {
    final arrowHeadSize = _arrowHeadSize;

    final dx = length / 2 * scale - arrowHeadSize;

    final start = position.translate(-length / 2 * scale, 0);
    final end = position.translate(dx, 0);

    final pathDx = dx /*.clamp(-arrowHeadSize/2, double.infinity)*/;

    // Create arrow head path
    final path = Path();
    path.moveTo(position.dx + pathDx + arrowHeadSize, position.dy);
    path.lineTo(position.dx + pathDx, position.dy - (arrowHeadSize / 2));
    path.lineTo(position.dx + pathDx, position.dy + (arrowHeadSize / 2));
    path.lineTo(position.dx + pathDx + arrowHeadSize, position.dy);

    // Draw outline if enabled
    if (arrowSettings.outlineEnabled) {
      final outlinePaint = Paint()
        ..color = arrowSettings.outlineColor
        ..strokeWidth = paint.strokeWidth + (arrowSettings.outlineWidth * 2)
        ..style = PaintingStyle.stroke
        ..strokeCap = paint.strokeCap;

      final outlineHeadPaint = Paint()
        ..color = arrowSettings.outlineColor
        ..strokeWidth = arrowSettings.outlineWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      // Draw outline for line shaft
      if ((end - start).dx > 0) {
        canvas.drawLine(start, end, outlinePaint);
      }

      // Draw outline for arrow head
      canvas.drawPath(path, outlineHeadPaint);
    }

    // Draw the main arrow shaft
    if ((end - start).dx > 0) {
      canvas.drawLine(start, end, paint);
    }

    final headPaint = paint.copyWith(
      style: PaintingStyle.fill,
    );

    // Draw arrow head
    canvas.drawPath(path, headPaint);
  }

  /// Creates a copy of this but with the given fields replaced with the new values.
  @override
  ArrowDrawable copyWith({
    bool? hidden,
    Set<ObjectDrawableAssist>? assists,
    Offset? position,
    double? rotation,
    double? scale,
    double? length,
    Paint? paint,
    bool? locked,
    ArrowSettings? arrowSettings,
  }) {
    return ArrowDrawable(
      hidden: hidden ?? this.hidden,
      assists: assists ?? this.assists,
      position: position ?? this.position,
      rotationAngle: rotation ?? rotationAngle,
      scale: scale ?? this.scale,
      length: length ?? this.length,
      paint: paint ?? this.paint,
      locked: locked ?? this.locked,
      arrowSettings: arrowSettings ?? this.arrowSettings,
    );
  }

  /// Calculates the size of the rendered object.
  @override
  Size getSize({double minWidth = 0.0, double maxWidth = double.infinity}) {
    final size = super.getSize();
    return Size(size.width, size.height);
  }

  /// Compares two [ArrowDrawable]s for equality.
  // @override
  // bool operator ==(Object other) {
  //   return other is ArrowDrawable &&
  //       super == other &&
  //       other.paint == paint &&
  //       other.length == length &&
  //       other.arrowHeadSize == arrowHeadSize;
  // }
  //
  // @override
  // int get hashCode => hashValues(
  //     hidden,
  //     locked,
  //     hashList(assists),
  //     hashList(assistPaints.entries),
  //     position,
  //     rotationAngle,
  //     scale,
  //     paint,
  //     length,
  //     arrowHeadSize);
}
