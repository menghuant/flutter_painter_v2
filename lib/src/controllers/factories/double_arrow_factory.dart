import 'dart:ui';

import '../drawables/shape/double_arrow_drawable.dart';
import 'shape_factory.dart';

/// A [DoubleArrowDrawable] factory.
class DoubleArrowFactory extends ShapeFactory<DoubleArrowDrawable> {
  /// Creates an instance of [DoubleArrowFactory].
  DoubleArrowFactory() : super();

  /// Creates and returns a [DoubleArrowDrawable] with length of 0 and the passed [position] and [paint].
  @override
  DoubleArrowDrawable create(Offset position, [Paint? paint]) {
    return DoubleArrowDrawable(
        length: 0,
        position: position,
        paint: paint);
  }
}
