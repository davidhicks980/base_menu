# Menu Positioning

Menu positioning is handled by a `MenuPositioningDelegate`. This delegate
determines the size and location of the menu panel relative to its anchor (the
widget that triggered the menu).

The default implementation, `DefaultMenuPositioningDelegate`, provides a
flexible system for alignment, offset, padding, and edge behavior.

## Core Concepts

### Attachment Points

Positioning begins with two attachment points:

1.  **`anchorAttachment`**: The point on the anchor (such as a button) that the
    menu should attach to.
2.  **`menuAttachment`**: The point on the menu panel that aligns with the
    anchor's attachment point.

By default, `BaseMenu` uses the orientation of the menu's parent to determine
the attachment points:

*   **Horizontal or No Parent**: The anchor's `AlignmentDirectional.bottomStart`
    attaches to the menu's `AlignmentDirectional.topStart` (stacked).
*   **Vertical Parent**: The anchor's `AlignmentDirectional.topEnd` attaches to
    the menu's `AlignmentDirectional.topStart` (side-by-side).

In the images below, the green point represents the anchor's attachment, and the
red point represents the menu's attachment.

![Submenu with vertical parent](../assets/images/alignment_vertical.png)
![Submenu with horizontal parent](../assets/images/alignment_horizontal.png)

Changing the anchor attachment point to `bottomCenter` and the menu attachment
point to `topCenter` for the submenu in the second example yields:

![Submenu with horizontal parent](../assets/images/alignment_center.png)


Note that the root menu's layout is unaffected by changing the submenu's
attachment points.

### Offset

The `offset` property applies a relative displacement from the calculated
attachment point. If `useDirectionalOffset` is true (default), the horizontal
component respects the ambient `Directionality`, ensuring the offset works
correctly in both LTR and RTL contexts.

The blue line in the image below represents a 10-pixel vertical offset applied
to the menu's attachment point, moving it further away from the anchor:

![Offset menu](../assets/images/offset.png)

### Padding

Menu panels often have padding that causes misalignment with their anchor. Use
the `padding` property to tell the positioner to ignore specific edges of the
menu's content for alignment purposes.

| Without padding | With padding |
| :---: | :---: |
| ![Without padding](../assets/images/padding_unadjusted.png) | ![With padding](../assets/images/padding_adjusted.png) |

The positioning algorithm will automatically adjust the menu's position to
account for padding, orientation, edge behavior, text direction, and alignment.

## Usage

### Basic Configuration

You can customize the positioning of any `BaseMenu` or `BaseSubmenu` by
providing a `positionDelegate`.

```dart
BaseMenu(
  positionDelegate: DefaultMenuPositioningDelegate(
    // Attach the bottom-center of the anchor to the top-center of the menu.
    anchorAttachment: Alignment.bottomCenter,
    menuAttachment: Alignment.topCenter,
    // Add a 4-pixel gap between the anchor and the menu.
    offset: Offset(0, 4),
    // Adjust the menu's vertical padding for a panel with 6 pixels of vertical padding.
    padding: EdgeInsets.symmetric(vertical: 6.0),
  ),
  // ...other parameters...
)
```

## Edge Behavior

When a menu would overflow the screen boundaries, the `edgeBehavior` defines how
it should react. Each axis can be configured with a combination of three
strategies:

| Strategy | Description | Example |
| :--- | :--- | :--- | 
| **`flip`** | The menu flips to the opposite side of the attachment point if it doesn't fit in its preferred position. | ![Flip edge behavior](../assets/videos/flip_edge_behavior.gif) |
| **`shift`** | The menu slides along the axis to stay within the screen bounds, potentially covering the anchor. | ![Shift edge behavior](../assets/videos/shift_edge_behavior.gif) |
| **`constrain`** | The menu is resized to fit within the available space. | ![Constrain edge behavior](../assets/videos/constrain_edge_behavior.gif) |

### Configuration Example

By default, all edge behavior strategies are enabled. You can restrict this
behavior for specific UX requirements:

```dart
DefaultMenuPositioningDelegate(
  edgeBehavior: EdgeBehavior(
    // The menu will flip to the horizontal side of the anchor that has the most space, but will not shift or resize.
    horizontal: EdgeBehaviorStrategy(flip: true, shift: false, constrain: false),
    // The menu will flip to the largest side, then shift within screen bounds, then resize if necessary. This is the default behavior.
    vertical: EdgeBehaviorStrategy(shift: true, constrain: true, flip: true),
  ),
)
```

If you disable all strategies for an axis, the menu will be clipped by the
screen edge:

![Clipping edge behavior](../assets/videos/no_horizontal_edge_behavior.gif)


## Custom Positioner

The default positioner used by `BaseMenu` and `BaseSubmenu` can be replaced with
a custom implementation of `MenuPositioningDelegate`. This allows for complete
control over the menu's size and position:


```dart
class ExamplePositioningDelegate implements MenuPositioningDelegate {
  const ExamplePositioningDelegate();

  @override
  Widget build(BuildContext context, RawMenuOverlayInfo position, Widget child) {
    return Stack(
      children: [
        Positioned(
          // The menu is positioned against the bottom left corner of the anchor.
          left: position.anchorRect.left,
          top: position.anchorRect.bottom,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ],
    );
  }
}
```

![Custom positioning delegate](../assets/images/custom_positioning_delegate.png)