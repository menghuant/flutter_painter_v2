# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Commands
```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Format code
dart format .

# Check formatting without making changes
dart format --set-exit-if-changed -o none .
```

## Architecture Overview

Flutter Painter V2 is a customizable Flutter painting library with a clean MVC-like architecture:

### Core Components

1. **PainterController** (lib/src/controllers/painter_controller.dart) - Central state management
   - Extends `ValueNotifier<PainterControllerValue>`
   - Manages drawables, background, settings, and actions
   - Handles undo/redo through action system
   - Provides event streams for state changes

2. **Drawable Hierarchy** - All drawing objects inherit from `Drawable`
   - **ObjectDrawable**: Movable/scalable objects (images, text, shapes)
   - **PathDrawable**: Free-style paths and eraser strokes
   - **BackgroundDrawable**: Special drawable for background management

3. **Action System** (lib/src/controllers/actions/) - Command pattern for undo/redo
   - Each modification creates an action (AddDrawables, RemoveDrawables, etc.)
   - Actions are stored in history for undo/redo functionality

4. **Factory Pattern** (lib/src/controllers/factories/) - Shape creation
   - Separate factories for each shape type (arrow, line, oval, rectangle)
   - Handles drag-to-create behavior

### Key Design Decisions

1. **Immutable Settings**: All settings objects are immutable. Use `.copyWith()` for modifications.

2. **Extension Separation**: Core functionality in `flutter_painter_pure.dart`, convenience extensions in `flutter_painter_extensions.dart`.

3. **Platform Handling**: 
   - Web requires `canvaskit` renderer (not `html` renderer)
   - Special handling for web image rendering in painters

4. **Widget Constraints**: FlutterPainter must have size constraints from parent (use SizedBox, Expanded, etc.)

5. **Controller Isolation**: Each FlutterPainter instance needs its own PainterController.

### Common Tasks

When modifying drawables:
- Use controller methods (`addDrawables`, `removeDrawables`, etc.) for proper action tracking
- Direct list manipulation bypasses undo/redo system

When adding new drawable types:
1. Extend appropriate base class (ObjectDrawable or PathDrawable)
2. Implement required methods (draw, copyWith, etc.)
3. Update FlutterPainterPainter to handle rendering
4. Consider adding factory if drag-to-create is needed

When working with settings:
- All settings are in `lib/src/controllers/settings/`
- Use `.copyWith()` pattern for modifications
- Settings control appearance and behavior of drawing tools

### Testing Considerations

Currently minimal test coverage. When adding features:
- Test drawable serialization/deserialization
- Test controller state management
- Test action system for undo/redo
- Mock PainterController using mocktail package