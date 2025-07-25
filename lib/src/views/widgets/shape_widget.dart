part of 'flutter_painter.dart';

/// Flutter widget to draw shapes.
class _ShapeWidget extends StatefulWidget {
  /// Child widget.
  final Widget child;

  /// Creates a [_ShapeWidget] with the given [controller], [child] widget.
  const _ShapeWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _ShapeWidgetState createState() => _ShapeWidgetState();
}

class _ShapeWidgetState extends State<_ShapeWidget> {
  /// The shape that is being currently drawn.
  ShapeDrawable? currentShapeDrawable;

  /// Getter for shape settings to simplify code.
  ShapeSettings get settings =>
      PainterController.of(context).value.settings.shape;

  /// Getter for arrow settings to simplify code.
  ArrowSettings get arrowSettings =>
      PainterController.of(context).value.settings.arrow;

  @override
  Widget build(BuildContext context) {
    final controller = PainterController.of(context);
    final selectedDrawable = controller.selectedObjectDrawable;
    
    // Disable shape creation when factory is null or when an arrow is selected
    if (settings.factory == null || 
        (selectedDrawable != null && 
         (selectedDrawable is ArrowDrawable || selectedDrawable is DoubleArrowDrawable))) {
      return widget.child;
    }

    return GestureDetector(
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      child: widget.child,
    );
  }

  void onScaleStart(ScaleStartDetails details) {
    final factory = settings.factory;
    if (factory == null || details.pointerCount > 1) return;

    var shapeDrawable =
        factory.create(details.localFocalPoint, settings.paint);

    // Apply arrow settings if this is an arrow drawable
    if (shapeDrawable is ArrowDrawable) {
      shapeDrawable = shapeDrawable.copyWith(arrowSettings: arrowSettings);
    } else if (shapeDrawable is DoubleArrowDrawable) {
      shapeDrawable = shapeDrawable.copyWith(arrowSettings: arrowSettings);
    }

    setState(() {
      PainterController.of(context).addDrawables([shapeDrawable]);
      currentShapeDrawable = shapeDrawable;
    });
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    final shapeDrawable = currentShapeDrawable;

    if (shapeDrawable == null) return;

    if (shapeDrawable is Sized1DDrawable) {
      final sized1DDrawable = (shapeDrawable as Sized1DDrawable);
      final length = sized1DDrawable.length;
      final startingPosition = shapeDrawable.position -
          Offset.fromDirection(sized1DDrawable.rotationAngle, length / 2);
      final newLine = (details.localFocalPoint - startingPosition);
      final newPosition = startingPosition +
          Offset.fromDirection(newLine.direction, newLine.distance / 2);
      // Apply minimum length constraint for arrows
      double finalLength = newLine.distance.abs();
      if (sized1DDrawable is ArrowDrawable || sized1DDrawable is DoubleArrowDrawable) {
        finalLength = finalLength < arrowSettings.minimumLength 
            ? arrowSettings.minimumLength 
            : finalLength;
      }
      
      ObjectDrawable newDrawable;
      if (sized1DDrawable is ArrowDrawable) {
        newDrawable = sized1DDrawable.copyWith(
          position: newPosition,
          length: finalLength,
          rotation: newLine.direction,
          arrowSettings: arrowSettings,
        );
      } else if (sized1DDrawable is DoubleArrowDrawable) {
        newDrawable = sized1DDrawable.copyWith(
          position: newPosition,
          length: finalLength,
          rotation: newLine.direction,
          arrowSettings: arrowSettings,
        );
      } else {
        newDrawable = sized1DDrawable.copyWith(
          position: newPosition,
          length: finalLength,
          rotation: newLine.direction,
        );
      }
      currentShapeDrawable = (newDrawable as ShapeDrawable);
      updateDrawable(sized1DDrawable, newDrawable);
    } else if (shapeDrawable is Sized2DDrawable) {
      final sized2DDrawable = (shapeDrawable as Sized2DDrawable);
      final size = sized2DDrawable.size;
      final startingPosition =
          shapeDrawable.position - Offset(size.width / 2, size.height / 2);

      final newSize = Size((details.localFocalPoint.dx - startingPosition.dx),
          (details.localFocalPoint.dy - startingPosition.dy));
      final newPosition =
          startingPosition + Offset(newSize.width / 2, newSize.height / 2);
      final newDrawable = sized2DDrawable.copyWith(
        position: newPosition,
        size: newSize,
      );
      currentShapeDrawable = (newDrawable as ShapeDrawable);
      updateDrawable(sized2DDrawable, newDrawable);
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    final shapeDrawable = currentShapeDrawable;
    if (shapeDrawable is Sized2DDrawable) {
      final sized2DDrawable = (shapeDrawable as Sized2DDrawable);
      final newDrawable = sized2DDrawable.copyWith(
        size: Size(
          sized2DDrawable.size.width.abs(),
          sized2DDrawable.size.height.abs(),
        ),
      );
      updateDrawable(sized2DDrawable as ShapeDrawable, newDrawable);
    }
    if (settings.drawOnce) {
      PainterController.of(context).settings =
          PainterController.of(context).settings.copyWith(
                  shape: settings.copyWith(
                factory: null,
              ));
      SettingsUpdatedNotification(PainterController.of(context).value.settings)
          .dispatch(context);
    }

    DrawableCreatedNotification(currentShapeDrawable).dispatch(context);

    setState(() {
      currentShapeDrawable = null;
    });
  }

  /// Replaces a drawable with a new one.
  void updateDrawable(ObjectDrawable oldDrawable, ObjectDrawable newDrawable) {
    setState(() {
      PainterController.of(context)
          .replaceDrawable(oldDrawable, newDrawable, newAction: false);
    });
  }
}
