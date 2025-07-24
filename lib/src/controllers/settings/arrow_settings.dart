import 'package:flutter/material.dart';

/// Represents settings that control the behavior of arrow drawables.
///
/// This includes constraints on arrow properties such as minimum length
/// to ensure proper functionality and user experience, as well as outline
/// appearance settings.
@immutable
class ArrowSettings {
  /// The minimum length for arrows in logical pixels.
  ///
  /// This constraint ensures that arrows maintain a minimum size for proper
  /// interaction and visual clarity. The default value of 40.0 is designed
  /// to prevent anchor action areas from overlapping during interaction.
  /// The action area diameter is calculated as: anchor size + actionAreaPadding.
  ///
  /// Defaults to 40.0.
  final double minimumLength;

  /// Whether to enable outline rendering for arrows.
  ///
  /// When enabled, arrows will be drawn with an outline using the specified
  /// [outlineColor] and [outlineWidth].
  ///
  /// Defaults to true.
  final bool outlineEnabled;

  /// The color of the arrow outline.
  ///
  /// Only used when [outlineEnabled] is true.
  ///
  /// Defaults to white.
  final Color outlineColor;

  /// The width of the arrow outline in logical pixels.
  ///
  /// Only used when [outlineEnabled] is true.
  ///
  /// Defaults to 2.0.
  final double outlineWidth;

  /// The size of the arrow head in logical pixels.
  ///
  /// If null, the arrow head size will be automatically calculated as 3 times
  /// the stroke width of the arrow's paint.
  ///
  /// Defaults to null (auto-calculated).
  final double? arrowHeadSize;

  /// Creates an [ArrowSettings] with the given parameters.
  const ArrowSettings({
    this.minimumLength = 32.0,
    this.outlineEnabled = true,
    this.outlineColor = Colors.white,
    this.outlineWidth = 2.0,
    this.arrowHeadSize,
  });

  /// Creates a copy of this but with the given fields replaced with the new values.
  ArrowSettings copyWith({
    double? minimumLength,
    bool? outlineEnabled,
    Color? outlineColor,
    double? outlineWidth,
    double? arrowHeadSize,
  }) {
    return ArrowSettings(
      minimumLength: minimumLength ?? this.minimumLength,
      outlineEnabled: outlineEnabled ?? this.outlineEnabled,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      arrowHeadSize: arrowHeadSize ?? this.arrowHeadSize,
    );
  }

  /// Compares two [ArrowSettings] for equality.
  @override
  bool operator ==(Object other) {
    return other is ArrowSettings &&
        other.minimumLength == minimumLength &&
        other.outlineEnabled == outlineEnabled &&
        other.outlineColor == outlineColor &&
        other.outlineWidth == outlineWidth &&
        other.arrowHeadSize == arrowHeadSize;
  }

  @override
  int get hashCode => Object.hash(
    minimumLength,
    outlineEnabled,
    outlineColor,
    outlineWidth,
    arrowHeadSize,
  );
}