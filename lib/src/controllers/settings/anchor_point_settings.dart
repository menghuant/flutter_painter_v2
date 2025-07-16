import 'package:flutter/material.dart';

/// Represents settings that control the appearance of anchor points for arrows.
///
/// Anchor points are displayed at the start and end of arrows when selected,
/// allowing users to directly manipulate arrow endpoints.
@immutable
class AnchorPointSettings {
  /// The size (diameter) of the anchor point in logical pixels.
  ///
  /// Defaults to 16.0.
  final double size;

  /// The color of the anchor point.
  ///
  /// Defaults to [Colors.white].
  final Color color;

  /// The color of the anchor point border.
  ///
  /// Defaults to [Colors.grey].
  final Color borderColor;

  /// The width of the anchor point border in logical pixels.
  ///
  /// Defaults to 2.0.
  final double borderWidth;

  /// Creates an [AnchorPointSettings] with the given parameters.
  const AnchorPointSettings({
    this.size = 16.0,
    this.color = Colors.white,
    this.borderColor = Colors.grey,
    this.borderWidth = 2.0,
  });

  /// Creates a copy of this but with the given fields replaced with the new values.
  AnchorPointSettings copyWith({
    double? size,
    Color? color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return AnchorPointSettings(
      size: size ?? this.size,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  /// Compares two [AnchorPointSettings] for equality.
  @override
  bool operator ==(Object other) {
    return other is AnchorPointSettings &&
        other.size == size &&
        other.color == color &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth;
  }

  @override
  int get hashCode => Object.hash(size, color, borderColor, borderWidth);
}