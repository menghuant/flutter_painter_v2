part of 'flutter_painter.dart';

/// Flutter widget to move, scale and rotate [ObjectDrawable]s.
class _ObjectWidget extends StatefulWidget {
  /// Child widget.
  final Widget child;

  /// Whether scaling is enabled or not.
  ///
  /// If `false`, objects won't be movable, scalable or rotatable.
  final bool interactionEnabled;

  /// Creates a [_ObjectWidget] with the given [controller], [child] widget.
  const _ObjectWidget({
    Key? key,
    required this.child,
    this.interactionEnabled = true,
  }) : super(key: key);

  @override
  _ObjectWidgetState createState() => _ObjectWidgetState();
}

class _ObjectWidgetState extends State<_ObjectWidget> {
  static Set<double> assistAngles = <double>{
    0,
    pi / 4,
    pi / 2,
    3 * pi / 4,
    pi,
    5 * pi / 4,
    3 * pi / 2,
    7 * pi / 4,
    2 * pi
  };

  /// The last controller value in the widget tree.
  /// Updated by [didChangeDependencies] and used in [dispose].
  PainterController? controller;

  /// Calculates the scale for the [InteractiveViewer] in the widget tree, and scales
  double transformationScale = 1;

  /// Getter for extra amount of padding added around each object to make it easier to interact with.
  double get objectPadding => 25 / transformationScale;

  /// Getter for the duration of fade-in and out animations for the object controls.
  static Duration get controlsTransitionDuration =>
      const Duration(milliseconds: 100);

  /// Getter for the size of the controls of the selected object.
  double get controlsSize =>
      (settings.enlargeControlsResolver() ? 20 : 10) / transformationScale;

  /// Getter for the blur radius of the selected object highlighting.
  double get selectedBlurRadius => 2 / transformationScale;

  /// Getter for the border width of the selected object highlighting.
  double get selectedBorderWidth => 1 / transformationScale;

  /// Keeps track of the initial local focal point when scaling starts.
  ///
  /// This is used to offset the movement of the drawable correctly.
  Map<int, Offset> drawableInitialLocalFocalPoints = {};

  /// Keeps track of the initial drawable when scaling starts.
  ///
  /// This is used to calculate the new rotation angle and
  /// degree relative to the initial drawable.
  Map<int, ObjectDrawable> initialScaleDrawables = {};

  /// Keeps track of widgets that have assist lines assigned to them.
  ///
  /// This is used to provide haptic feedback when the assist line appears.
  Map<ObjectDrawableAssist, Set<int>> assistDrawables = {
    for (var e in ObjectDrawableAssist.values) e: <int>{}
  };

  /// Keeps track of which controls are being used.
  ///
  /// Used to highlight the controls when they are in use.
  Map<int, bool> controlsAreActive = {
    for (var e in List.generate(8, (index) => index)) e: false
  };

  /// Subscription to the events coming from the controller.
  StreamSubscription<PainterEvent>? controllerEventSubscription;

  /// Keeps track of anchor dragging state.
  bool _isDraggingAnchor = false;

  /// Which anchor is being dragged ('start' or 'end').
  String? _draggingAnchorType;

  /// The arrow being dragged by its anchor.
  MapEntry<int, ArrowDrawable>? _draggingArrow;

  /// The fixed anchor position during dragging (the one that shouldn't move).
  Offset? _fixedAnchorPosition;
  
  /// The initial anchor position of the dragged anchor when drag started.
  Offset? _initialDraggedAnchorPosition;

  /// Getter for the list of [ObjectDrawable]s in the controller
  /// to make code more readable.
  List<ObjectDrawable> get drawables => PainterController.of(context)
      .value
      .drawables
      .whereType<ObjectDrawable>()
      .toList();

  /// A flag on whether to cancel controls animation or not.
  /// This is used to cancel the animation after the selected object
  /// drawable is deleted.
  bool cancelControlsAnimation = false;

  @override
  void initState() {
    super.initState();

    // Listen to the stream of events from the paint controller
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      controllerEventSubscription =
          PainterController.of(context).events.listen((event) {
        // When an [RemoveDrawableEvent] event is received and removed drawable is the selected object
        // cancel the animation.
        if (event is SelectedObjectDrawableRemovedEvent) {
          setState(() {
            cancelControlsAnimation = true;
          });
        }
      });

      // Listen to transformation changes of [InteractiveViewer].
      PainterController.of(context)
          .transformationController
          .addListener(onTransformUpdated);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = PainterController.of(context);
  }

  @override
  void dispose() {
    // Cancel subscription to events from painter controller
    controllerEventSubscription?.cancel();
    controller?.transformationController.removeListener(onTransformUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawables = this.drawables;
    final selectedDrawable = controller?.selectedObjectDrawable;
    final drawableAirTransformable = selectedDrawable != null &&
        controller?.shapeSettings.factory == null &&
        !(selectedDrawable is ArrowDrawable ||
            selectedDrawable is DoubleArrowDrawable);
    final selectedDrawableEntry = drawableAirTransformable
        ? MapEntry<int, ObjectDrawable>(
            drawables.indexOf(controller!.selectedObjectDrawable!),
            controller!.selectedObjectDrawable!)
        : MapEntry<int, ObjectDrawable>(
            0,
            TextDrawable(
              position: Offset(0, 0),
              text: '',
            ));
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned.fill(
              child: GestureDetector(
                  onTap: onBackgroundTapped,
                  onScaleStart: drawableAirTransformable
                      ? (details) =>
                          onDrawableScaleStart(selectedDrawableEntry, details)
                      : null,
                  onScaleUpdate: drawableAirTransformable
                      ? (details) =>
                          onDrawableScaleUpdate(selectedDrawableEntry, details)
                      : null,
                  onScaleEnd: drawableAirTransformable
                      ? (_) => onDrawableScaleEnd(selectedDrawableEntry)
                      : null,
                  child: widget.child)),
          ...drawables.asMap().entries.map((entry) {
            final drawable = entry.value;
            final selected = drawable == controller?.selectedObjectDrawable;
            final size = drawable.getSize(maxWidth: constraints.maxWidth);
            final widget = Padding(
              padding: EdgeInsets.all(objectPadding),
              child: SizedBox(
                width: size.width,
                height: size.height,
              ),
            );
            return Positioned(
              // Offset the position by half the size of the drawable so that
              // the object is in the center point
              top: drawable.position.dy - objectPadding - size.height / 2,
              left: drawable.position.dx - objectPadding - size.width / 2,
              child: Transform.rotate(
                angle: drawable.rotationAngle,
                transformHitTests: true,
                child: Container(
                  child: freeStyleSettings.mode != FreeStyleMode.none
                      ? widget
                      : MouseRegion(
                          cursor: drawable.locked
                              ? MouseCursor.defer
                              : SystemMouseCursors.allScroll,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => tapDrawable(drawable),
                            onScaleStart: (details) =>
                                onDrawableScaleStart(entry, details),
                            onScaleUpdate: (details) =>
                                onDrawableScaleUpdate(entry, details),
                            onScaleEnd: (_) => onDrawableScaleEnd(entry),
                            child: AnimatedSwitcher(
                              duration: controlsTransitionDuration,
                              child: selected
                                  ? Stack(
                                      children: [
                                        widget,
                                        // Show selection box for non-arrow drawables
                                        if (!(drawable is ArrowDrawable ||
                                            drawable is DoubleArrowDrawable))
                                          Positioned(
                                            top: objectPadding -
                                                (controlsSize / 2),
                                            bottom: objectPadding -
                                                (controlsSize / 2),
                                            left: objectPadding -
                                                (controlsSize / 2),
                                            right: objectPadding -
                                                (controlsSize / 2),
                                            child: Builder(
                                              builder: (context) {
                                                if (usingHtmlRenderer) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.black,
                                                          width:
                                                              selectedBorderWidth),
                                                    ),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors.white,
                                                            width:
                                                                selectedBorderWidth),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return Container(
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.white,
                                                          width:
                                                              selectedBorderWidth),
                                                      boxShadow: [
                                                        BorderBoxShadow(
                                                          color: Colors.black,
                                                          blurRadius:
                                                              selectedBlurRadius,
                                                        )
                                                      ]),
                                                );
                                              },
                                            ),
                                          ),
                                        if (settings
                                                .showScaleRotationControlsResolver() &&
                                            !(drawable is ArrowDrawable ||
                                                drawable
                                                    is DoubleArrowDrawable)) ...[
                                          Positioned(
                                            top: objectPadding - (controlsSize),
                                            left:
                                                objectPadding - (controlsSize),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors
                                                  .resizeUpLeft,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onScaleControlPanStart(
                                                        0, entry, details),
                                                onPanUpdate: (details) =>
                                                    onScaleControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        true),
                                                onPanEnd: (details) =>
                                                    onScaleControlPanEnd(
                                                        0, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[0] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom:
                                                objectPadding - (controlsSize),
                                            left:
                                                objectPadding - (controlsSize),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors
                                                  .resizeDownLeft,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onScaleControlPanStart(
                                                        1, entry, details),
                                                onPanUpdate: (details) =>
                                                    onScaleControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        true),
                                                onPanEnd: (details) =>
                                                    onScaleControlPanEnd(
                                                        1, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[1] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: objectPadding - (controlsSize),
                                            right:
                                                objectPadding - (controlsSize),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor: initialScaleDrawables
                                                      .containsKey(entry.key)
                                                  ? SystemMouseCursors.grabbing
                                                  : SystemMouseCursors.grab,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onRotationControlPanStart(
                                                        2, entry, details),
                                                onPanUpdate: (details) =>
                                                    onRotationControlPanUpdate(
                                                        entry, details, size),
                                                onPanEnd: (details) =>
                                                    onRotationControlPanEnd(
                                                        2, entry, details),
                                                child: _ObjectControlBox(
                                                  shape: BoxShape.circle,
                                                  active:
                                                      controlsAreActive[2] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom:
                                                objectPadding - (controlsSize),
                                            right:
                                                objectPadding - (controlsSize),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors
                                                  .resizeDownRight,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onScaleControlPanStart(
                                                        3, entry, details),
                                                onPanUpdate: (details) =>
                                                    onScaleControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        false),
                                                onPanEnd: (details) =>
                                                    onScaleControlPanEnd(
                                                        3, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[3] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (entry.value is Sized2DDrawable &&
                                            !(drawable is ArrowDrawable ||
                                                drawable
                                                    is DoubleArrowDrawable)) ...[
                                          Positioned(
                                            top: objectPadding - (controlsSize),
                                            left: (size.width / 2) +
                                                objectPadding -
                                                (controlsSize / 2),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor:
                                                  SystemMouseCursors.resizeUp,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onResizeControlPanStart(
                                                        4, entry, details),
                                                onPanUpdate: (details) =>
                                                    onResizeControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        Axis.vertical,
                                                        true),
                                                onPanEnd: (details) =>
                                                    onResizeControlPanEnd(
                                                        4, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[4] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom:
                                                objectPadding - (controlsSize),
                                            left: (size.width / 2) +
                                                objectPadding -
                                                (controlsSize / 2),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor:
                                                  SystemMouseCursors.resizeDown,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onResizeControlPanStart(
                                                        5, entry, details),
                                                onPanUpdate: (details) =>
                                                    onResizeControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        Axis.vertical,
                                                        false),
                                                onPanEnd: (details) =>
                                                    onResizeControlPanEnd(
                                                        5, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[5] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left:
                                                objectPadding - (controlsSize),
                                            top: (size.height / 2) +
                                                objectPadding -
                                                (controlsSize / 2),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor:
                                                  SystemMouseCursors.resizeLeft,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onResizeControlPanStart(
                                                        6, entry, details),
                                                onPanUpdate: (details) =>
                                                    onResizeControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        Axis.horizontal,
                                                        true),
                                                onPanEnd: (details) =>
                                                    onResizeControlPanEnd(
                                                        6, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[6] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right:
                                                objectPadding - (controlsSize),
                                            top: (size.height / 2) +
                                                objectPadding -
                                                (controlsSize / 2),
                                            width: controlsSize,
                                            height: controlsSize,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors
                                                  .resizeRight,
                                              child: GestureDetector(
                                                onPanStart: (details) =>
                                                    onResizeControlPanStart(
                                                        7, entry, details),
                                                onPanUpdate: (details) =>
                                                    onResizeControlPanUpdate(
                                                        entry,
                                                        details,
                                                        constraints,
                                                        Axis.horizontal,
                                                        false),
                                                onPanEnd: (details) =>
                                                    onResizeControlPanEnd(
                                                        7, entry, details),
                                                child: _ObjectControlBox(
                                                  active:
                                                      controlsAreActive[7] ??
                                                          false,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    )
                                  : widget,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              layoutBuilder: (child, previousChildren) {
                                if (cancelControlsAnimation) {
                                  cancelControlsAnimation = false;
                                  return child ?? const SizedBox();
                                }
                                return AnimatedSwitcher.defaultLayoutBuilder(
                                    child, previousChildren);
                              },
                            ),
                          ),
                        ),
                ),
              ),
            );
          }),
          // Render anchor points for selected arrows on top layer
          ...drawables.asMap().entries.where((entry) {
            final drawable = entry.value;
            final selected = drawable == controller?.selectedObjectDrawable;
            return selected &&
                (drawable is ArrowDrawable || drawable is DoubleArrowDrawable);
          }).map((entry) {
            final drawable = entry.value as ArrowDrawable;
            final anchorSettings = settings.anchorPoint;

            // Calculate anchor positions using the helper
            final anchorPositions =
                ArrowAnchorDragHelper.calculateAnchorPositions(drawable);
            final startPosition = anchorPositions['start']!;
            final endPosition = anchorPositions['end']!;

            return [
              // Start point anchor with GestureDetector
              Positioned(
                left: startPosition.dx - (anchorSettings.size + anchorSettings.actionAreaPadding) / 2,
                top: startPosition.dy - (anchorSettings.size + anchorSettings.actionAreaPadding) / 2,
                child: GestureDetector(
                  onPanStart: (details) => _onAnchorPanStart(
                      MapEntry(entry.key, drawable), 'start', details),
                  onPanUpdate: (details) => _onAnchorPanUpdate(
                      MapEntry(entry.key, drawable), 'start', details),
                  onPanEnd: (details) => _onAnchorPanEnd(
                      MapEntry(entry.key, drawable), 'start', details),
                  child: Container(
                    width: anchorSettings.size + anchorSettings.actionAreaPadding, // Action area
                    height: anchorSettings.size + anchorSettings.actionAreaPadding,
                    alignment: Alignment.center,
                    child: _AnchorPoint(settings: anchorSettings),
                  ),
                ),
              ),
              // End point anchor with GestureDetector
              Positioned(
                left: endPosition.dx - (anchorSettings.size + anchorSettings.actionAreaPadding) / 2,
                top: endPosition.dy - (anchorSettings.size + anchorSettings.actionAreaPadding) / 2,
                child: GestureDetector(
                  onPanStart: (details) => _onAnchorPanStart(
                      MapEntry(entry.key, drawable), 'end', details),
                  onPanUpdate: (details) => _onAnchorPanUpdate(
                      MapEntry(entry.key, drawable), 'end', details),
                  onPanEnd: (details) => _onAnchorPanEnd(
                      MapEntry(entry.key, drawable), 'end', details),
                  child: Container(
                    width: anchorSettings.size + anchorSettings.actionAreaPadding, // Action area
                    height: anchorSettings.size + anchorSettings.actionAreaPadding,
                    alignment: Alignment.center,
                    child: _AnchorPoint(settings: anchorSettings),
                  ),
                ),
              ),
            ];
          }).expand((anchors) => anchors),
        ],
      );
    });
  }

  /// Getter for the [ObjectSettings] from the controller to make code more readable.
  ObjectSettings get settings =>
      PainterController.of(context).value.settings.object;

  /// Getter for the [FreeStyleSettings] from the controller to make code more readable.
  ///
  /// This is used to disable object movement, scaling and rotation
  /// when free-style drawing is enabled.
  FreeStyleSettings get freeStyleSettings =>
      PainterController.of(context).value.settings.freeStyle;

  /// Getter for the [ArrowSettings] from the controller to make code more readable.
  ArrowSettings get arrowSettings =>
      PainterController.of(context).value.settings.arrow;

  /// Triggers when the user taps an empty space.
  ///
  /// Deselects the selected object drawable.
  void onBackgroundTapped() {
    SelectedObjectDrawableUpdatedNotification(null).dispatch(context);

    setState(() {
      // selectedDrawableIndex = null;
      controller?.deselectObjectDrawable();
    });
  }

  /// Callback when an object is tapped.
  ///
  /// Dispatches an [ObjectDrawableNotification] that the object was tapped.
  void tapDrawable(ObjectDrawable drawable) {
    if (drawable.locked) return;

    if (controller?.selectedObjectDrawable == drawable) {
      ObjectDrawableReselectedNotification(drawable).dispatch(context);
    } else {
      SelectedObjectDrawableUpdatedNotification(drawable).dispatch(context);
    }

    setState(() {
      // selectedDrawableIndex = drawables.indexOf(drawable);
      controller?.selectObjectDrawable(drawable);
    });
  }

  /// Callback when the object drawable starts being moved, scaled and/or rotated.
  ///
  /// Saves the initial point of interaction and drawable to be used on update events.
  void onDrawableScaleStart(
      MapEntry<int, ObjectDrawable> entry, ScaleStartDetails details) {
    if (!widget.interactionEnabled) return;

    final index = entry.key;
    final drawable = entry.value;

    if (index < 0 || drawable.locked) return;

    // For arrows, check if the user is clicking on an anchor point
    if (drawable is ArrowDrawable) {
      final anchorPositions =
          ArrowAnchorDragHelper.calculateAnchorPositions(drawable);
      final localPosition = details.localFocalPoint;
      final anchorSize = settings.anchorPoint.size;

      // Check if clicking on start anchor
      if (ArrowAnchorDragHelper.isPointInAnchorArea(
        point: localPosition,
        anchorCenter: anchorPositions['start']!,
        anchorSize: anchorSize,
        actionAreaPadding: settings.anchorPoint.actionAreaPadding,
      )) {
        // Don't start body dragging, anchor drag will handle it
        return;
      }

      // Check if clicking on end anchor
      if (ArrowAnchorDragHelper.isPointInAnchorArea(
        point: localPosition,
        anchorCenter: anchorPositions['end']!,
        anchorSize: anchorSize,
        actionAreaPadding: settings.anchorPoint.actionAreaPadding,
      )) {
        // Don't start body dragging, anchor drag will handle it
        return;
      }
    }

    setState(() {
      // selectedDrawableIndex = index;
      controller?.selectObjectDrawable(entry.value);
    });

    initialScaleDrawables[index] = drawable;

    // When the gesture detector is rotated, the hit test details are not transformed with it
    // This causes events from rotated objects to behave incorrectly
    // So, a [Matrix4] is used to transform the needed event details to be consistent with
    // the current rotation of the object
    final rotateOffset = Matrix4.rotationZ(drawable.rotationAngle)
      ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
      ..rotateZ(-drawable.rotationAngle);
    drawableInitialLocalFocalPoints[index] =
        Offset(rotateOffset[12], rotateOffset[13]);

    updateDrawable(drawable, drawable, newAction: true);
  }

  /// Callback when the object drawable finishes movement, scaling and rotation.
  ///
  /// Cleans up the object information.
  void onDrawableScaleEnd(MapEntry<int, ObjectDrawable> entry) {
    if (!widget.interactionEnabled) return;

    final index = entry.key;

    // Using the index instead of [entry.value] is to prevent an issue
    // when an update and end events happen before the UI is updated,
    // the [entry.value] is the old drawable before it was updated
    // This causes updating the entry in this method to sometimes fail
    // To get around it, the object is fetched directly from the drawables
    // in the controller
    final drawable = drawables[index];

    // Clean up
    drawableInitialLocalFocalPoints.remove(index);
    initialScaleDrawables.remove(index);
    for (final assistSet in assistDrawables.values) {
      assistSet.remove(index);
    }

    // Remove any assist lines the object has
    final newDrawable = drawable.copyWith(assists: {});

    updateDrawable(drawable, newDrawable);
  }

  /// Callback when the object drawable is moved, scaled and/or rotated.
  ///
  /// Calculates the next position, scale and rotation of the object depending on the event details.
  void onDrawableScaleUpdate(
      MapEntry<int, ObjectDrawable> entry, ScaleUpdateDetails details) {
    if (!widget.interactionEnabled) return;

    final index = entry.key;
    final drawable = entry.value;
    if (index < 0) return;

    final initialDrawable = initialScaleDrawables[index];
    // When the gesture detector is rotated, the hit test details are not transformed with it
    // This causes events from rotated objects to behave incorrectly
    // So, a [Matrix4] is used to transform the needed event details to be consistent with
    // the current rotation of the object
    final initialLocalFocalPoint =
        drawableInitialLocalFocalPoints[index] ?? Offset.zero;

    if (initialDrawable == null) return;

    final initialPosition = initialDrawable.position - initialLocalFocalPoint;
    final initialRotation = initialDrawable.rotationAngle;

    // When the gesture detector is rotated, the hit test details are not transformed with it
    // This causes events from rotated objects to behave incorrectly
    // So, a [Matrix4] is used to transform the needed event details to be consistent with
    // the current rotation of the object
    final rotateOffset = Matrix4.identity()
      ..rotateZ(initialRotation)
      ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
      ..rotateZ(-initialRotation);
    final position =
        initialPosition + Offset(rotateOffset[12], rotateOffset[13]);

    // Calculate scale of object reference to the initial object scale
    final scale = initialDrawable.scale * details.scale;

    // Calculate the rotation of the object reference to the initial object rotation
    // and normalize it so that its between 0 and 2*pi
    var rotation = (initialRotation + details.rotation).remainder(pi * 2);
    if (rotation < 0) rotation += pi * 2;

    // The center point of the widget
    final center = this.center;

    // The angle from [assistAngles] the object's current rotation is close
    final double? closestAssistAngle;

    // If layout assist is enabled, calculate the positional and rotational assists
    if (settings.layoutAssist.enabled) {
      calculatePositionalAssists(
        settings.layoutAssist,
        index,
        position,
        center,
      );
      closestAssistAngle = calculateRotationalAssist(
        settings.layoutAssist,
        index,
        rotation,
      );
    } else {
      closestAssistAngle = null;
    }

    // The set of assists for the object
    // If layout assist is disabled, it is empty
    final assists = settings.layoutAssist.enabled
        ? assistDrawables.entries
            .where((element) => element.value.contains(index))
            .map((e) => e.key)
            .toSet()
        : <ObjectDrawableAssist>{};

    // Do not display the rotational assist if the user is using less that 2 pointers
    // So, rotational assist lines won't show if the user is only moving the object
    if (details.pointerCount < 2) assists.remove(ObjectDrawableAssist.rotation);

    // Snap the object to the horizontal/vertical center if its is near it
    // and layout assist is enabled
    final assistedPosition = Offset(
      assists.contains(ObjectDrawableAssist.vertical) ? center.dx : position.dx,
      assists.contains(ObjectDrawableAssist.horizontal)
          ? center.dy
          : position.dy,
    );

    // Snap the object rotation to the nearest angle from [assistAngles] if its near it
    // and layout assist is enabled
    final assistedRotation = assists.contains(ObjectDrawableAssist.rotation) &&
            closestAssistAngle != null
        ? closestAssistAngle.remainder(pi * 2)
        : rotation;

    final newDrawable = drawable.copyWith(
      position: assistedPosition,
      scale: scale,
      rotation: assistedRotation,
      assists: assists,
    );

    updateDrawable(drawable, newDrawable);
  }

  /// Calculates whether the object entered or exited the horizontal and vertical assist areas.
  void calculatePositionalAssists(ObjectLayoutAssistSettings settings,
      int index, Offset position, Offset center) {
    // Horizontal
    //
    // If the object is within the enter distance from the center dy and isn't marked
    // as a drawable with a horizontal assist, mark it
    if ((position.dy - center.dy).abs() < settings.positionalEnterDistance &&
        !(assistDrawables[ObjectDrawableAssist.horizontal]?.contains(index) ??
            false)) {
      assistDrawables[ObjectDrawableAssist.horizontal]?.add(index);
      settings.hapticFeedback.impact();
    }
    // Otherwise, if the object is outside the exit distance from the center dy and is marked as
    // as a drawable with a horizontal assist, un-mark it
    else if ((position.dy - center.dy).abs() >
            settings.positionalExitDistance &&
        (assistDrawables[ObjectDrawableAssist.horizontal]?.contains(index) ??
            false)) {
      assistDrawables[ObjectDrawableAssist.horizontal]?.remove(index);
    }

    // Vertical
    //
    // If the object is within the enter distance from the center dx and isn't marked
    // as a drawable with a vertical assist, mark it
    if ((position.dx - center.dx).abs() < settings.positionalEnterDistance &&
        !(assistDrawables[ObjectDrawableAssist.vertical]?.contains(index) ??
            false)) {
      assistDrawables[ObjectDrawableAssist.vertical]?.add(index);
      settings.hapticFeedback.impact();
    }
    // Otherwise, if the object is outside the exit distance from the center dx and is marked as
    // as a drawable with a vertical assist, un-mark it
    else if ((position.dx - center.dx).abs() >
            settings.positionalExitDistance &&
        (assistDrawables[ObjectDrawableAssist.vertical]?.contains(index) ??
            false)) {
      assistDrawables[ObjectDrawableAssist.vertical]?.remove(index);
    }
  }

  /// Calculates whether the object entered or exited the rotational assist range.
  ///
  /// Returns the angle the object is closest to if it is inside the assist range.
  double? calculateRotationalAssist(
      ObjectLayoutAssistSettings settings, int index, double rotation) {
    // Calculates all angles from [assistAngles] in the exit range of rotational assist
    final closeAngles = assistAngles
        .where(
            (angle) => (rotation - angle).abs() < settings.rotationalExitAngle)
        .toList();

    // If the object is close to at least one assist angle
    if (closeAngles.isNotEmpty) {
      // If the object is also in the enter range of rotational assist and isn't marked
      // as a drawable with a rotational assist, mark it
      if (closeAngles.any((angle) =>
              (rotation - angle).abs() < settings.rotationalEnterAngle) &&
          !(assistDrawables[ObjectDrawableAssist.rotation]?.contains(index) ??
              false)) {
        assistDrawables[ObjectDrawableAssist.rotation]?.add(index);
        settings.hapticFeedback.impact();
      }
      // Return the angle the object is close to
      return closeAngles[0];
    }

    // Otherwise, if the object is not in the exit range of any assist angles,
    // but is marked as a drawable with rotational assist, un-mark it
    if (closeAngles.isEmpty &&
        (assistDrawables[ObjectDrawableAssist.rotation]?.contains(index) ??
            false)) {
      assistDrawables[ObjectDrawableAssist.rotation]?.remove(index);
    }

    return null;
  }

  /// Returns the center point of the painter widget.
  ///
  /// Uses the [GlobalKey] for the painter from [controller].
  Offset get center {
    final renderBox = PainterController.of(context)
        .painterKey
        .currentContext
        ?.findRenderObject() as RenderBox?;
    final center = renderBox == null
        ? Offset.zero
        : Offset(
            renderBox.size.width / 2,
            renderBox.size.height / 2,
          );
    return center;
  }

  /// Replaces a drawable with a new one.
  void updateDrawable(ObjectDrawable oldDrawable, ObjectDrawable newDrawable,
      {bool newAction = false}) {
    setState(() {
      PainterController.of(context)
          .replaceDrawable(oldDrawable, newDrawable, newAction: newAction);
    });
  }

  void onRotationControlPanStart(int controlIndex,
      MapEntry<int, ObjectDrawable> entry, DragStartDetails details) {
    setState(() {
      controlsAreActive[controlIndex] = true;
    });
    onDrawableScaleStart(
        entry,
        ScaleStartDetails(
          pointerCount: 2,
          localFocalPoint: entry.value.position,
        ));
  }

  void onRotationControlPanUpdate(MapEntry<int, ObjectDrawable> entry,
      DragUpdateDetails details, Size size) {
    final index = entry.key;
    final initial = initialScaleDrawables[index];
    if (initial == null) return;
    final initialOffset = Offset((size.width / 2), (-size.height / 2));
    final initialAngle = atan2(initialOffset.dx, initialOffset.dy);
    final angle = atan2((details.localPosition.dx + initialOffset.dx),
        (details.localPosition.dy + initialOffset.dy));
    final rotation = initialAngle - angle;
    onDrawableScaleUpdate(
        entry,
        ScaleUpdateDetails(
          pointerCount: 2,
          rotation: rotation,
          scale: 1,
          localFocalPoint: entry.value.position,
        ));
  }

  void onRotationControlPanEnd(int controlIndex,
      MapEntry<int, ObjectDrawable> entry, DragEndDetails details) {
    setState(() {
      controlsAreActive[controlIndex] = false;
    });
    onDrawableScaleEnd(entry);
  }

  void onScaleControlPanStart(int controlIndex,
      MapEntry<int, ObjectDrawable> entry, DragStartDetails details) {
    setState(() {
      controlsAreActive[controlIndex] = true;
    });
    onDrawableScaleStart(
        entry,
        ScaleStartDetails(
          pointerCount: 1,
          localFocalPoint: entry.value.position,
        ));
  }

  void onScaleControlPanUpdate(MapEntry<int, ObjectDrawable> entry,
      DragUpdateDetails details, BoxConstraints constraints,
      [bool isReversed = true]) {
    final index = entry.key;
    final initial = initialScaleDrawables[index];
    if (initial == null) return;
    final length = details.localPosition.dx * (isReversed ? -1 : 1);
    final initialSize = initial.getSize(maxWidth: constraints.maxWidth);
    final initialLength = initialSize.width / 2;
    final double scale = initialLength == 0
        ? (length * 2)
        : ((length + initialLength) / initialLength);
    onDrawableScaleUpdate(
        entry,
        ScaleUpdateDetails(
          pointerCount: 1,
          rotation: 0,
          scale: scale.clamp(ObjectDrawable.minScale, double.infinity),
          localFocalPoint: entry.value.position,
        ));
  }

  void onScaleControlPanEnd(int controlIndex,
      MapEntry<int, ObjectDrawable> entry, DragEndDetails details) {
    setState(() {
      controlsAreActive[controlIndex] = false;
    });
    onDrawableScaleEnd(entry);
  }

  void onResizeControlPanStart(int controlIndex,
      MapEntry<int, ObjectDrawable> entry, DragStartDetails details) {
    setState(() {
      controlsAreActive[controlIndex] = true;
    });
    onDrawableScaleStart(
        entry,
        ScaleStartDetails(
          pointerCount: 1,
          localFocalPoint: entry.value.position,
        ));
  }

  void onResizeControlPanUpdate(MapEntry<int, ObjectDrawable> entry,
      DragUpdateDetails details, BoxConstraints constraints, Axis axis,
      [bool isReversed = true]) {
    final index = entry.key;

    final drawable = entry.value;

    if (drawable is! Sized2DDrawable) return;

    final initial = initialScaleDrawables[index];
    if (initial is! Sized2DDrawable?) return;

    if (initial == null) return;
    final vertical = axis == Axis.vertical;
    final length =
        ((vertical ? details.localPosition.dy : details.localPosition.dx) *
            (isReversed ? -1 : 1));
    final initialLength = vertical ? initial.size.height : initial.size.width;

    final totalLength = (length / initial.scale + initialLength)
        .clamp(0, double.infinity) as double;

    // final double scale = initialLength == 0 ?
    //   (length*2).clamp(0.001, double.infinity) :
    //   ((length + initialLength) / initialLength).clamp(0.001, double.infinity);

    // When the gesture detector is rotated, the hit test details are not transformed with it
    // This causes events from rotated objects to behave incorrectly
    // So, a [Matrix4] is used to transform the needed event details to be consistent with
    // the current rotation of the object

    final offsetPosition = Offset(
      vertical ? 0 : (isReversed ? -1 : 1) * length / 2,
      vertical ? (isReversed ? -1 : 1) * length / 2 : 0,
    );

    final rotateOffset = Matrix4.identity()
      ..rotateZ(initial.rotationAngle)
      ..translate(offsetPosition.dx, offsetPosition.dy)
      ..rotateZ(-initial.rotationAngle);
    final position = Offset(rotateOffset[12], rotateOffset[13]);

    final newDrawable = drawable.copyWith(
      size: Size(
        vertical ? drawable.size.width : totalLength,
        vertical ? totalLength : drawable.size.height,
      ),
      position: initial.position + position,
      // scale: scale,
      // rotation: assistedRotation,
      // assists: assists,
    );

    updateDrawable(drawable, newDrawable);
  }

  void onResizeControlPanEnd(int controlIndex,
      MapEntry<int, ObjectDrawable> entry, DragEndDetails details) {
    setState(() {
      controlsAreActive[controlIndex] = false;
    });
    onDrawableScaleEnd(entry);
  }

  /// Handles the start of anchor point dragging.
  void _onAnchorPanStart(MapEntry<int, ArrowDrawable> entry, String anchorType,
      DragStartDetails details) {
    if (!widget.interactionEnabled) return;

    // Calculate the current anchor positions and remember both fixed and initial dragged positions
    final arrow = entry.value;
    final anchorPositions = ArrowAnchorDragHelper.calculateAnchorPositions(arrow);
    
    // The fixed anchor is the opposite of the one being dragged
    final fixedAnchorType = anchorType == 'start' ? 'end' : 'start';
    _fixedAnchorPosition = anchorPositions[fixedAnchorType]!;
    _initialDraggedAnchorPosition = anchorPositions[anchorType]!;

    setState(() {
      _isDraggingAnchor = true;
      _draggingAnchorType = anchorType;
      _draggingArrow = entry;
    });
  }

  /// Handles anchor point dragging updates.
  void _onAnchorPanUpdate(MapEntry<int, ArrowDrawable> entry, String anchorType,
      DragUpdateDetails details) {
    if (!widget.interactionEnabled || !_isDraggingAnchor) return;

    final index = entry.key;
    final currentArrow = drawables[index] as ArrowDrawable;

    try {
      // Convert local gesture position to canvas coordinates
      final canvasPosition = _convertLocalToCanvasPosition(details.localPosition);
      
      // Calculate new arrow properties from anchor positions
      final arrowUpdate = _calculateArrowFromAnchorDrag(
        anchorType: anchorType,
        draggedPosition: canvasPosition,
      );

      // Apply the update to the arrow
      final updatedArrow = currentArrow.copyWith(
        position: arrowUpdate.position,
        length: arrowUpdate.length,
        rotation: arrowUpdate.rotation,
      );

      updateDrawable(currentArrow, updatedArrow, newAction: false);
    } catch (e) {
      debugPrint('Error updating arrow anchor: $e');
    }
  }

  /// Handles the end of anchor point dragging.
  void _onAnchorPanEnd(MapEntry<int, ArrowDrawable> entry, String anchorType,
      DragEndDetails details) {
    if (!widget.interactionEnabled || !_isDraggingAnchor) return;

    // Create a final action for undo/redo support
    final index = entry.key;
    final currentArrow = drawables[index] as ArrowDrawable;
    updateDrawable(currentArrow, currentArrow, newAction: true);

    setState(() {
      _isDraggingAnchor = false;
      _draggingAnchorType = null;
      _draggingArrow = null;
      _fixedAnchorPosition = null;
      _initialDraggedAnchorPosition = null;
    });
  }

  /// Converts local gesture position to canvas coordinates using the initial anchor position.
  Offset _convertLocalToCanvasPosition(Offset localPosition) {
    final initialAnchorPosition = _initialDraggedAnchorPosition!;
    final anchorSettings = settings.anchorPoint;
    
    return Offset(
      initialAnchorPosition.dx - anchorSettings.size + localPosition.dx,
      initialAnchorPosition.dy - anchorSettings.size + localPosition.dy,
    );
  }

  /// Calculates new arrow properties from anchor drag positions.
  ({Offset position, double length, double rotation}) _calculateArrowFromAnchorDrag({
    required String anchorType,
    required Offset draggedPosition,
  }) {
    return ArrowAnchorDragHelper.enforceMinimumLength(
      anchorType: anchorType,
      draggedPosition: draggedPosition,
      fixedAnchorPosition: _fixedAnchorPosition!,
      minimumLength: arrowSettings.minimumLength,
    );
  }

  /// A callback that is called when a transformation occurs in the [InteractiveViewer] in the widget tree.
  void onTransformUpdated() {
    setState(() {
      final _m4storage =
          PainterController.of(context).transformationController.value;
      transformationScale = math.sqrt(_m4storage[8] * _m4storage[8] +
          _m4storage[9] * _m4storage[9] +
          _m4storage[10] * _m4storage[10]);
    });
  }
}

/// The control box container (only the UI, no logic).
class _ObjectControlBox extends StatelessWidget {
  /// Shape of the control box.
  final BoxShape shape;

  /// Whether the box is being used or not.
  final bool active;

  /// Color of control when it is not active.
  /// Defaults to [Colors.white].
  final Color inactiveColor;

  /// Color of control when it is active.
  /// If null is provided, the theme's accent color is used. If there is no theme, [Colors.blue] is used.
  final Color? activeColor;

  /// Color of the shadow surrounding the control.
  /// Defaults to [Colors.black].
  final Color shadowColor;

  /// Creates an [_ObjectControlBox] with the given [shape] and [active].
  ///
  /// By default, it will be a [BoxShape.rectangle] shape and not active.
  const _ObjectControlBox({
    Key? key,
    this.shape = BoxShape.rectangle,
    this.active = false,
    this.inactiveColor = Colors.white,
    this.activeColor,
    this.shadowColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData? theme = Theme.of(context);
    if (theme == ThemeData.fallback()) theme = null;
    final activeColor =
        this.activeColor ?? theme?.colorScheme.secondary ?? Colors.blue;
    return AnimatedContainer(
      duration: _ObjectWidgetState.controlsTransitionDuration,
      decoration: BoxDecoration(
        color: active ? activeColor : inactiveColor,
        shape: shape,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 2,
          )
        ],
      ),
    );
  }
}

/// A circular anchor point widget for arrows.
class _AnchorPoint extends StatelessWidget {
  /// The anchor point settings that control appearance.
  final AnchorPointSettings settings;

  /// Creates an [_AnchorPoint] with the given [settings].
  const _AnchorPoint({
    Key? key,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: settings.size,
      height: settings.size,
      decoration: BoxDecoration(
        color: settings.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: settings.borderColor,
          width: settings.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
