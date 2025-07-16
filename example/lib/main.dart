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
            padding: const EdgeInsets.all(16.0),
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
                    final arrowsInfo = value.drawables
                        .where((d) => d is ArrowDrawable || d is DoubleArrowDrawable)
                        .map((d) {
                      if (d is ArrowDrawable) {
                        // Calculate arrow start and end points
                        final startPoint = d.position.translate(-d.length / 2 * d.scale, 0);
                        final endPoint = d.position.translate(d.length / 2 * d.scale, 0);
                        return 'Arrow: start(${startPoint.dx.toStringAsFixed(1)}, ${startPoint.dy.toStringAsFixed(1)}) end(${endPoint.dx.toStringAsFixed(1)}, ${endPoint.dy.toStringAsFixed(1)})';
                      } else if (d is DoubleArrowDrawable) {
                        final startPoint = d.position.translate(-d.length / 2 * d.scale, 0);
                        final endPoint = d.position.translate(d.length / 2 * d.scale, 0);
                        return 'DoubleArrow: start(${startPoint.dx.toStringAsFixed(1)}, ${startPoint.dy.toStringAsFixed(1)}) end(${endPoint.dx.toStringAsFixed(1)}, ${endPoint.dy.toStringAsFixed(1)})';
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
                          '// TODO: After implementing anchor points, this will also display anchor point positions',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}