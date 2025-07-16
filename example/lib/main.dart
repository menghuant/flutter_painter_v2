import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Painter Arrow Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ArrowPainterDemo(),
    );
  }
}

class ArrowPainterDemo extends StatefulWidget {
  const ArrowPainterDemo({super.key});

  @override
  State<ArrowPainterDemo> createState() => _ArrowPainterDemoState();
}

class _ArrowPainterDemoState extends State<ArrowPainterDemo> {
  late PainterController _controller;
  bool _isDoubleArrow = false;
  Color _arrowColor = Colors.black;
  double _strokeWidth = 5.0;
  double _arrowHeadSize = 15.0;

  @override
  void initState() {
    super.initState();
    _controller = PainterController(
      settings: PainterSettings(
        object: ObjectSettings(
          layoutAssist: ObjectLayoutAssistSettings(
            enabled: false,
          ),
        ),
        shape: ShapeSettings(
          factory: ArrowFactory(arrowHeadSize: _arrowHeadSize),
          drawOnce: false,
          paint: Paint()
            ..color = _arrowColor
            ..strokeWidth = _strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateArrowSettings() {
    _controller.settings = _controller.settings.copyWith(
      shape: ShapeSettings(
        factory: _isDoubleArrow 
          ? DoubleArrowFactory(arrowHeadSize: _arrowHeadSize) 
          : ArrowFactory(arrowHeadSize: _arrowHeadSize),
        drawOnce: false,
        paint: Paint()
          ..color = _arrowColor
          ..strokeWidth = _strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      ),
    );
  }

  void _clearCanvas() {
    _controller.clearDrawables();
  }

  void _undo() {
    _controller.undo();
  }

  void _redo() {
    _controller.redo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Painter Arrow Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearCanvas,
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing Canvas
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/5.jpg',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        FlutterPainter(
                          controller: _controller,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Controls
          Container(
            height: 300, // Fixed height for the controls panel
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
              children: [
                // Arrow Type Selection
                Row(
                  children: [
                    const Text('Arrow Type: '),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Single Arrow'),
                      selected: !_isDoubleArrow,
                      onSelected: (selected) {
                        setState(() {
                          _isDoubleArrow = false;
                          _updateArrowSettings();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Double Arrow'),
                      selected: _isDoubleArrow,
                      onSelected: (selected) {
                        setState(() {
                          _isDoubleArrow = true;
                          _updateArrowSettings();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Color Selection
                Row(
                  children: [
                    const Text('Color: '),
                    const SizedBox(width: 16),
                    ...[
                      Colors.black,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ].map((color) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _arrowColor = color;
                                _updateArrowSettings();
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: _arrowColor == color
                                      ? Colors.black
                                      : Colors.grey,
                                  width: _arrowColor == color ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                // Stroke Width
                Row(
                  children: [
                    const Text('Stroke Width: '),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 5.0,
                        max: 20.0,
                        divisions: 15,
                        label: _strokeWidth.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _strokeWidth = value;
                            _updateArrowSettings();
                          });
                        },
                      ),
                    ),
                    Text(_strokeWidth.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 16),
                // Arrow Head Size
                Row(
                  children: [
                    const Text('Arrow Head Size: '),
                    Expanded(
                      child: Slider(
                        value: _arrowHeadSize,
                        min: 15.0,
                        max: 40.0,
                        divisions: 25,
                        label: _arrowHeadSize.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _arrowHeadSize = value;
                            _updateArrowSettings();
                          });
                        },
                      ),
                    ),
                    Text(_arrowHeadSize.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 16),
                // Debug Information
                ValueListenableBuilder<PainterControllerValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    // Get image dimensions - you need to replace these with actual image dimensions
                    // You can get these by loading the image asset or hardcoding if you know them
                    const imageWidth = 1024.0;  // Replace with actual 5.jpg width
                    const imageHeight = 768.0;  // Replace with actual 5.jpg height
                    
                    // Calculate the display size and offset due to AspectRatio(1.0) and BoxFit.contain
                    const containerSize = 400.0; // Approximate container size (1:1 aspect ratio)
                    final imageAspectRatio = imageWidth / imageHeight;
                    final containerAspectRatio = 1.0;
                    
                    late double displayWidth, displayHeight, offsetX, offsetY;
                    
                    if (imageAspectRatio > containerAspectRatio) {
                      // Image is wider, fit by width
                      displayWidth = containerSize;
                      displayHeight = containerSize / imageAspectRatio;
                      offsetX = 0;
                      offsetY = (containerSize - displayHeight) / 2;
                    } else {
                      // Image is taller, fit by height
                      displayWidth = containerSize * imageAspectRatio;
                      displayHeight = containerSize;
                      offsetX = (containerSize - displayWidth) / 2;
                      offsetY = 0;
                    }
                    
                    // Function to convert canvas coordinates to image coordinates
                    Offset canvasToImageCoords(Offset canvasPoint) {
                      final imageX = ((canvasPoint.dx - offsetX) / displayWidth) * imageWidth;
                      final imageY = ((canvasPoint.dy - offsetY) / displayHeight) * imageHeight;
                      return Offset(imageX, imageY);
                    }
                    
                    final arrowsInfo = value.drawables
                        .where((d) => d is ArrowDrawable || d is DoubleArrowDrawable)
                        .map((d) {
                      final isSelected = d == value.selectedObjectDrawable;
                      String anchorInfo = '';
                      
                      if (d is ArrowDrawable) {
                        // Calculate arrow start and end points
                        final startPoint = d.position.translate(-d.length / 2 * d.scale, 0);
                        final endPoint = d.position.translate(d.length / 2 * d.scale, 0);
                        
                        // Apply rotation for anchor positions
                        final cos = math.cos(d.rotationAngle);
                        final sin = math.sin(d.rotationAngle);
                        
                        final rotatedStart = Offset(
                          d.position.dx + (startPoint.dx - d.position.dx) * cos - (startPoint.dy - d.position.dy) * sin,
                          d.position.dy + (startPoint.dx - d.position.dx) * sin + (startPoint.dy - d.position.dy) * cos,
                        );
                        
                        final rotatedEnd = Offset(
                          d.position.dx + (endPoint.dx - d.position.dx) * cos - (endPoint.dy - d.position.dy) * sin,
                          d.position.dy + (endPoint.dx - d.position.dx) * sin + (endPoint.dy - d.position.dy) * cos,
                        );
                        
                        // Convert coordinates to image coordinate system
                        final imageRotatedStart = canvasToImageCoords(rotatedStart);
                        final imageRotatedEnd = canvasToImageCoords(rotatedEnd);
                        
                        if (isSelected) {
                          anchorInfo = ' | rotation: ${(d.rotationAngle * 180 / math.pi).toStringAsFixed(1)}° | anchors: start(${imageRotatedStart.dx.toStringAsFixed(1)}, ${imageRotatedStart.dy.toStringAsFixed(1)}) end(${imageRotatedEnd.dx.toStringAsFixed(1)}, ${imageRotatedEnd.dy.toStringAsFixed(1)})';
                        }
                        
                        return 'Arrow: start(${imageRotatedStart.dx.toStringAsFixed(1)}, ${imageRotatedStart.dy.toStringAsFixed(1)}) end(${imageRotatedEnd.dx.toStringAsFixed(1)}, ${imageRotatedEnd.dy.toStringAsFixed(1)})$anchorInfo';
                      } else if (d is DoubleArrowDrawable) {
                        final startPoint = d.position.translate(-d.length / 2 * d.scale, 0);
                        final endPoint = d.position.translate(d.length / 2 * d.scale, 0);
                        
                        // Apply rotation for anchor positions
                        final cos = math.cos(d.rotationAngle);
                        final sin = math.sin(d.rotationAngle);
                        
                        final rotatedStart = Offset(
                          d.position.dx + (startPoint.dx - d.position.dx) * cos - (startPoint.dy - d.position.dy) * sin,
                          d.position.dy + (startPoint.dx - d.position.dx) * sin + (startPoint.dy - d.position.dy) * cos,
                        );
                        
                        final rotatedEnd = Offset(
                          d.position.dx + (endPoint.dx - d.position.dx) * cos - (endPoint.dy - d.position.dy) * sin,
                          d.position.dy + (endPoint.dx - d.position.dx) * sin + (endPoint.dy - d.position.dy) * cos,
                        );
                        
                        // Convert coordinates to image coordinate system
                        final imageRotatedStart = canvasToImageCoords(rotatedStart);
                        final imageRotatedEnd = canvasToImageCoords(rotatedEnd);
                        
                        if (isSelected) {
                          anchorInfo = ' | rotation: ${(d.rotationAngle * 180 / math.pi).toStringAsFixed(1)}° | anchors: start(${imageRotatedStart.dx.toStringAsFixed(1)}, ${imageRotatedStart.dy.toStringAsFixed(1)}) end(${imageRotatedEnd.dx.toStringAsFixed(1)}, ${imageRotatedEnd.dy.toStringAsFixed(1)})';
                        }
                        
                        return 'DoubleArrow: start(${imageRotatedStart.dx.toStringAsFixed(1)}, ${imageRotatedStart.dy.toStringAsFixed(1)}) end(${imageRotatedEnd.dx.toStringAsFixed(1)}, ${imageRotatedEnd.dy.toStringAsFixed(1)})$anchorInfo';
                      }
                      return '';
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        if (arrowsInfo.isNotEmpty)
                          ...arrowsInfo.map((info) => Text(
                                info,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              ))
                        else
                          const Text('No arrows drawn', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text(
                          '// Selected arrows show anchor point positions',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}