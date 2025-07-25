# Flutter Painter V2 - Arrow Anchor Point System Engineering Documentation

## Overview

Replace the existing arrow rectangle selection box system with a two-draggable anchor point system, allowing users to directly drag the start and end points of arrows for precise editing.

## Goals

1. **Replace Selection Box**: Replace the 8-control-point rectangle selection box with 2 anchor points
2. **Intuitive Editing**: Users can directly drag anchor points to modify arrow start/end points
3. **Translation Function**: Retain arrow body drag translation functionality
4. **Coordinate Conversion**: Provide global coordinates relative to background image
5. **Configurability**: Anchor point appearance configurable through ObjectSettings
6. **Double Arrow Support**: System supports both single and double arrows

## Progressive Implementation Stages

### Stage 0: Setup Testing Environment
**Objective**: Create a proper testing app with background image to facilitate development and testing

**Implementation Steps**:
1. ✅ Modify `example/lib/main.dart` to include background image (5.jpg)
2. ✅ Set up proper canvas with background for testing
3. ✅ Add debugging information display (arrow positions with future anchor points note)
4. ✅ Ensure proper aspect ratio and image display (BoxFit.contain with letterboxing)
5. ✅ Fix drawOnce setting to allow multiple arrows
6. ✅ Add arrow head size control (15-40 range)
7. ✅ Update stroke width range (5-20)
8. ✅ Change clear button icon to trash can

**Testing Method**:
- App should load with background image visible
- Can draw multiple arrows on the background image
- All existing arrow functionality should work with background
- Debug information shows arrow positions in real-time

**Acceptance Criteria**:
- ✅ Background image loads correctly with proper aspect ratio
- ✅ Can draw multiple arrows on background image
- ✅ Proper canvas scaling and positioning with letterboxing
- ✅ All existing controls work normally
- ✅ Debug information displays arrow start/end positions
- ✅ Arrow head size and stroke width are configurable
- ✅ Clear button uses trash can icon

---

### Stage 1: Basic Anchor Point Display System
**Objective**: Display two anchor points when arrow is selected, replacing rectangle selection box

**Implementation Steps**:
1. ✅ Create `AnchorPointSettings` class (`lib/src/controllers/settings/anchor_point_settings.dart`)
   - Size (diameter): 15px default
   - Color: White default
   - Border color: Grey default
   - Border width: 2px default
   - Immutable design with copyWith() method

2. ✅ Modify `ObjectSettings` to include anchor point settings
   - Added `AnchorPointSettings anchorPoint` field
   - Updated constructor and copyWith() method
   - Added to settings export

3. ✅ Create anchor point rendering component (`_AnchorPoint` widget)
   - Circular design with configurable appearance
   - Shadow effect for better visibility
   - Consistent with existing control styling

4. ✅ Modify selection state display logic in `object_widget.dart`
   - Hide rectangle selection box for arrows
   - Hide scale/rotation controls for arrows
   - Prevent background gesture handling for selected arrows

5. ✅ Implement anchor points in top layer rendering
   - Render all anchor points after all drawables (rendering order B)
   - Calculate correct positions with rotation transformation
   - Apply proper coordinate transformation

6. ✅ Fix gesture conflicts
   - Disable shape creation when arrow is selected
   - Prevent double-tap zoom conflicts
   - Maintain proper interaction hierarchy

7. ✅ Add debug information display
   - Show arrow coordinates in image coordinate system
   - Display anchor point positions for selected arrows
   - Include rotation angle information

**Testing Method**:
- Two circular anchor points should appear when arrow is selected
- Anchor point positions should be at arrow start and end points
- Anchor points should disappear when deselected
- No gesture conflicts with background image zoom/pan
- Debug info shows correct coordinate mapping

**Acceptance Criteria**:
- ✅ Arrow displays 2 anchor points when selected
- ✅ Anchor point positions are correct (start/end points with rotation)
- ✅ Anchor point appearance matches settings (15px white circles with grey border)
- ✅ Does not affect other drawable selection behavior
- ✅ Proper rendering order (anchor points on top)
- ✅ No gesture conflicts during zoom/pan operations
- ✅ Debug information displays image-relative coordinates
- ✅ Supports both single and double arrows

---

### Stage 2: Basic Anchor Point Dragging Functionality
**Objective**: Implement basic functionality for dragging anchor points to modify arrow start/end points

**Implementation Steps**:
1. Add GestureDetector to anchor points
2. Implement anchor point dragging logic
3. Recalculate arrow properties based on anchor point positions
4. Update ArrowDrawable position and length

**Testing Method**:
- Dragging start point anchor should move arrow start point
- Dragging end point anchor should move arrow end point
- Arrow length and angle should update correctly

**Acceptance Criteria**:
- ✅ Can drag anchor points to modify arrow
- ✅ Arrow properties update correctly (position, length, angle)
- ✅ Smooth visual feedback during dragging
- ✅ Correct arrow state after dragging ends

---

### Stage 3: Arrow Body Translation Functionality
**Objective**: ~~Implement dragging arrow body for overall translation~~ **SKIPPED - Existing system sufficient**

**Decision**: The existing bounding box dragging system already provides adequate arrow body translation functionality. Users can drag the arrow body to translate the entire arrow without affecting its length or rotation. The anchor point system works seamlessly with the existing translation mechanism.

**Existing Functionality**:
- Arrow body can be dragged using the standard object selection and drag system
- Bounding box appears when arrow is selected (outside of anchor points)
- Translation preserves arrow length and rotation angle
- Anchor points correctly follow during translation

**Implementation Steps**:
~~1. Distinguish between anchor point dragging and arrow body dragging~~ **Not needed - existing system handles this**
~~2. Implement arrow body translation logic~~ **Already exists**
~~3. Ensure anchor point positions sync during translation~~ **Already working**
~~4. Handle drag area detection~~ **Already implemented**

**Testing Method**:
- Dragging arrow body should translate entire arrow
- Anchor point positions should follow during dragging
- Translation should not change arrow length and angle

**Acceptance Criteria**:
- ✅ Can drag arrow body for translation (via existing bounding box system)
- ✅ Anchor point positions sync correctly during translation
- ✅ Translation does not affect arrow length and angle
- ✅ Drag area detection correct (distinguish anchor points from body)

---

### Stage 4: Minimum Length Constraint System
**Objective**: Implement arrow minimum length constraint functionality

**Implementation Steps**:
1. ✅ Create `ArrowSettings` class (`lib/src/controllers/settings/arrow_settings.dart`)
   - Add `minimumLength` property (default: 32.0px)
   - Immutable design with copyWith() method
   - Documentation explaining anchor action area relationship

2. ✅ Integrate into settings system
   - Add `ArrowSettings arrow` field to `PainterSettings`
   - Update constructor and copyWith() method
   - Export in settings.dart

3. ✅ Modify creation logic (`lib/src/views/widgets/shape_widget.dart`)
   - Check minimum length during shape creation (onScaleUpdate)
   - Apply constraint to ArrowDrawable and DoubleArrowDrawable
   - Use choice A: adjust length during creation to avoid visual jumps

4. ✅ Modify anchor dragging logic (`lib/src/views/widgets/object_widget.dart`)
   - Update `_calculateArrowFromAnchorDrag` to use helper method
   - Add `arrowSettings` getter for easy access
   - Maintain fixed anchor position while enforcing minimum length

5. ✅ Extend helper methods (`lib/src/helpers/arrow_anchor_drag_helper.dart`)
   - Add `enforceMinimumLength` static method
   - Handle minimum length constraint calculations
   - Support both start/end anchor drag scenarios
   - Recalculate positions based on fixed anchor and minimum length

**Testing Method**:
- Drag anchor points to make arrow shorter than minimum length
- Arrow should maintain minimum length
- Anchor point positions should follow dragging (visual separation)
- Factory creation should respect minimum length constraint

**Acceptance Criteria**:
- ✅ Minimum length constraint is effective (32px default)
- ✅ Arrow maintains minimum length when limit is reached
- ✅ Anchor point positions still follow dragging visually
- ✅ Minimum length can be adjusted through settings
- ✅ Factory creation respects minimum length constraint
- ✅ Both ArrowDrawable and DoubleArrowDrawable support constraint
- ✅ Helper method provides clean separation of concerns

---

### Stage 5: Anchor Point Settings System
**Objective**: Complete anchor point appearance configuration functionality

**Implementation Steps**:
1. Complete `AnchorPointSettings` class
2. Implement anchor point size, color, border configuration
3. Modify anchor point rendering logic to use settings
4. Add dynamic updates for setting changes

**Testing Method**:
- Modify anchor point size setting, anchor points should grow/shrink
- Modify anchor point color setting, anchor points should change color
- Modify border setting, anchor point borders should change

**Acceptance Criteria**:
- ✅ Anchor point size is configurable
- ✅ Anchor point color is configurable
- ✅ Anchor point border is configurable
- ✅ Setting changes take effect immediately

---

### Stage 6: Coordinate Conversion System
**Objective**: Implement calculation and conversion of coordinates relative to background image

**Implementation Steps**:
1. Analyze existing coordinate systems
2. Implement conversion from canvas coordinates to background image coordinates
3. Modify arrow property storage to include global coordinates
4. Implement real-time coordinate conversion and updates

**Testing Method**:
- Edit arrows at different zoom levels
- Check if global coordinates are calculated correctly
- Verify coordinate conversion accuracy

**Acceptance Criteria**:
- ✅ Coordinate conversion logic is correct
- ✅ Global coordinates are unaffected by canvas zoom
- ✅ Coordinate conversion performance is good
- ✅ Provides correct API to get global coordinates

---

### Stage 7: Drag Range Restriction
**Objective**: Restrict anchor point dragging range within background image

**Implementation Steps**:
1. Get background image boundary information
2. Implement drag range detection logic
3. Modify anchor point dragging logic to include range restriction
4. Add visual feedback for boundary collision

**Testing Method**:
- Try to drag anchor points outside image boundaries
- Anchor points should be restricted within image range
- Appropriate feedback should be provided at boundaries

**Acceptance Criteria**:
- ✅ Anchor points cannot be dragged outside image range
- ✅ Boundary restriction behavior is natural and smooth
- ✅ Has appropriate visual feedback
- ✅ Does not affect normal dragging within image

---

### Stage 8: Double Arrow Support
**Objective**: Extend anchor point system to double arrows

**Implementation Steps**:
1. Analyze `DoubleArrowDrawable` structure
2. Modify anchor point system to support double arrows
3. Implement double arrow anchor point dragging logic
4. Ensure consistent behavior between single and double arrows

**Testing Method**:
- Select double arrow, should display two anchor points
- Drag anchor points to modify double arrow start/end points
- All double arrow functionality should be consistent with single arrow

**Acceptance Criteria**:
- ✅ Double arrow displays correct anchor points
- ✅ Double arrow anchor point dragging works normally
- ✅ Double arrow supports all anchor point functionality
- ✅ Single and double arrow behavior is consistent

---

### Stage 9: Testing and Optimization
**Objective**: Complete testing of all functionality and performance optimization

**Implementation Steps**:
1. Create comprehensive test cases
2. Conduct performance testing and optimization
3. Fix discovered issues
4. Complete documentation and usage instructions

**Testing Method**:
- Full functionality testing of all implemented stages
- Performance testing (drag response speed, memory usage)
- Edge case testing
- User experience testing

**Acceptance Criteria**:
- ✅ All functionality works correctly
- ✅ Performance meets requirements
- ✅ No obvious bugs
- ✅ Good user experience

---

## Testing Strategy for Each Stage

1. **Unit Testing**: Classes and methods implemented in each stage
2. **Integration Testing**: Interactions between components
3. **Manual Testing**: Actual operation testing for user experience
4. **Regression Testing**: Ensure existing functionality is not affected

## Risks and Considerations

1. **Coordinate Conversion Complexity**: Need to carefully handle multiple coordinate systems
2. **Performance Impact**: Real-time calculations during dragging
3. **Existing Function Compatibility**: Cannot break existing arrow functionality
4. **User Experience**: Balance between anchor point size and response area

## Technical Details

### Requirements Summary
- **Anchor Point Count**: 2 (start and end points)
- **Anchor Point Shape**: Circular
- **Anchor Point Layer**: Display above arrow
- **Drag Behavior**: Anchor point dragging modifies start/end points, body dragging translates
- **Minimum Length**: Configurable, arrow maintains minimum length when reached but anchor points continue following
- **Coordinate System**: Provides global coordinates relative to background image
- **Drag Range**: Restricted within background image range
- **Supported Types**: Single arrow and double arrow

### Configuration Settings
Settings are organized across multiple classes:

**ObjectSettings** (for anchor point appearance):
- Anchor point size (diameter): 16px default
- Anchor point color: White default
- Anchor point border color and width: Grey, 2px default

**ArrowSettings** (for arrow behavior):
- Arrow minimum length: 32px default (= anchor action area diameter)
- Configurable through PainterController settings