import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../controllers/drawables/shape/arrow_drawable.dart';

/// Helper class for arrow anchor point calculations.
class ArrowAnchorDragHelper {
  /// Checks if a point is within the anchor action area.
  ///
  /// The action area is defined as anchorSize + 16 pixels.
  static bool isPointInAnchorArea({
    required Offset point,
    required Offset anchorCenter,
    required double anchorSize,
  }) {
    final actionRadius = (anchorSize + 16) / 2;
    final distance = (point - anchorCenter).distance;
    return distance <= actionRadius;
  }


  /// Calculates the current anchor positions for an arrow.
  /// 
  /// Returns the actual visual endpoints of the arrow using the original calculation method.
  static Map<String, Offset> calculateAnchorPositions(ArrowDrawable arrow) {
    // Use the original calculation method that was working correctly
    final startPoint = arrow.position.translate(-arrow.length / 2 * arrow.scale, 0);
    final endPoint = arrow.position.translate(arrow.length / 2 * arrow.scale, 0);
    
    // Apply rotation transformation using the original method
    final cos = math.cos(arrow.rotationAngle);
    final sin = math.sin(arrow.rotationAngle);
    
    final rotatedStart = Offset(
      arrow.position.dx + (startPoint.dx - arrow.position.dx) * cos - (startPoint.dy - arrow.position.dy) * sin,
      arrow.position.dy + (startPoint.dx - arrow.position.dx) * sin + (startPoint.dy - arrow.position.dy) * cos,
    );
    
    final rotatedEnd = Offset(
      arrow.position.dx + (endPoint.dx - arrow.position.dx) * cos - (endPoint.dy - arrow.position.dy) * sin,
      arrow.position.dy + (endPoint.dx - arrow.position.dx) * sin + (endPoint.dy - arrow.position.dy) * cos,
    );

    return {
      'start': rotatedStart,
      'end': rotatedEnd,
    };
  }

}