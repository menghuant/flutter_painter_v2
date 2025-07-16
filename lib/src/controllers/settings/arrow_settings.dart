import 'package:flutter/material.dart';

/// Represents settings that control the behavior of arrow drawables.
///
/// This includes constraints on arrow properties such as minimum length
/// to ensure proper functionality and user experience.
@immutable
class ArrowSettings {
  /// The minimum length for arrows in logical pixels.
  ///
  /// This constraint ensures that arrows maintain a minimum size for proper
  /// interaction and visual clarity. The default value of 32.0 corresponds
  /// to the anchor action area diameter (anchor size + 16 pixels) to prevent
  /// anchor overlap during interaction.
  ///
  /// Defaults to 32.0.
  final double minimumLength;

  /// Creates an [ArrowSettings] with the given parameters.
  const ArrowSettings({
    this.minimumLength = 32.0,
  });

  /// Creates a copy of this but with the given fields replaced with the new values.
  ArrowSettings copyWith({
    double? minimumLength,
  }) {
    return ArrowSettings(
      minimumLength: minimumLength ?? this.minimumLength,
    );
  }

  /// Compares two [ArrowSettings] for equality.
  @override
  bool operator ==(Object other) {
    return other is ArrowSettings &&
        other.minimumLength == minimumLength;
  }

  @override
  int get hashCode => minimumLength.hashCode;
}