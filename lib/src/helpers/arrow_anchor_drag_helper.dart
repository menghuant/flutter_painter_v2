import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../controllers/drawables/shape/arrow_drawable.dart';

/// Helper class for arrow anchor point calculations.
class ArrowAnchorDragHelper {
  /// Checks if a point is within the anchor action area.
  ///
  /// The action area is defined as anchorSize + 16 logical pixels.
  static bool isPointInAnchorArea({
    required Offset point,
    required Offset anchorCenter,
    required double anchorSize,
  }) {
    final actionRadius = (anchorSize + 16) / 2;
    final distance = (point - anchorCenter).distance;
    return distance <= actionRadius;
  }


  /// Enforces minimum length constraint on arrow calculations.
  ///
  /// When the calculated length is below the minimum, adjusts the arrow properties
  /// to maintain the minimum length while keeping the fixed anchor position.
  ///
  /// Returns adjusted arrow properties: (position, length, rotation).
  static ({Offset position, double length, double rotation}) enforceMinimumLength({
    required String anchorType,
    required Offset draggedPosition,
    required Offset fixedAnchorPosition,
    required double minimumLength,
  }) {
    // Determine start and end positions
    final newStart = anchorType == 'start' ? draggedPosition : fixedAnchorPosition;
    final newEnd = anchorType == 'start' ? fixedAnchorPosition : draggedPosition;
    
    // Calculate arrow properties
    final dx = newEnd.dx - newStart.dx;
    final dy = newEnd.dy - newStart.dy;
    double length = math.sqrt(dx * dx + dy * dy);
    final rotation = math.atan2(dy, dx);
    
    // Apply minimum length constraint
    if (length < minimumLength) {
      length = minimumLength;
      
      // Recalculate end position based on minimum length and fixed anchor
      final adjustedEnd = Offset(
        fixedAnchorPosition.dx + length * math.cos(rotation),
        fixedAnchorPosition.dy + length * math.sin(rotation),
      );
      
      // Update positions based on which anchor is being dragged
      final finalStart = anchorType == 'start' ? 
          Offset(fixedAnchorPosition.dx - length * math.cos(rotation),
                 fixedAnchorPosition.dy - length * math.sin(rotation)) : 
          fixedAnchorPosition;
      final finalEnd = anchorType == 'start' ? 
          fixedAnchorPosition : 
          adjustedEnd;
      
      final position = Offset((finalStart.dx + finalEnd.dx) / 2, (finalStart.dy + finalEnd.dy) / 2);
      return (position: position, length: length, rotation: rotation);
    }
    
    final position = Offset((newStart.dx + newEnd.dx) / 2, (newStart.dy + newEnd.dy) / 2);
    return (position: position, length: length, rotation: rotation);
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