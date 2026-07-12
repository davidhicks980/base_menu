# Aim Assist

Menu aim assist tracks the user's pointer trajectory to detect when the pointer
is moving toward a submenu. By calculating a triangular movement trajectory
between the cursor and the target submenu, it prevents premature closure when
the pointer passes over sibling menu items.

| Disabled | Enabled |
| :---: | :---: |
| <video src="../assets/videos/aim_assist_disabled.gif" width="100%" autoplay loop muted></video> | <video src="../assets/videos/aim_assist_enabled.gif" width="100%" autoplay loop muted></video> |

## Usage

### With BaseMenu or BaseSubmenu

Aim assist is **disabled** by default. 

To enable aim assist for a single menu, set the `enableAimAssist` property of
the menu's positioning delegate to `true`. 

To control the behavior of aim assist for a subtree, wrap the subtree with
`MenuAimScope` and set the `enable` property to `true`. All descendant menus
will inherit the `enable` value unless a descendant menu's positioning delegate
overrides it.

If a custom `MenuPositioningDelegate` is used with `BaseMenu`, the delegate is
responsible for implementing aim assist behavior. See the
[Standalone](#standalone) section for an example of how to implement aim assist
in a custom delegate.

```dart
// Enable aim assist for a subtree of menus.
MenuAimScope(
  enable: true,
  child: Column(
    children: [
      // Aim assist is enabled for this menu and its descendants.
      BaseSubmenu(
        controller: controllerOne,
        menu: ExamplePanel(),
        child: Text('File'),
      ),
      BaseSubmenu(
        controller: controllerTwo,
        // Aim assist is disabled for this menu, but not its descendants.
        positionDelegate: DefaultMenuPositioningDelegate(
          enableAimAssist: false,
        ),
        menu: ExamplePanel(),
        child: Text('Edit'),
      ),
    ],
  ),
)
```

### Standalone

Menu aim assist can also be used as an independent module:

1. Place a `MenuAimInterceptor` in front of the widget tree that contains the
   menu and its anchor.
2. Pass a `MenuAimGeometry` instance to the `MenuAimInterceptor`.
3. Update the `MenuAimGeometry.anchorRect` and `MenuAimGeometry.targetRect`
   properties when the anchor and target positions are updated. **The `anchorRect`
   and `targetRect` should be in the same coordinate space as the
   `MenuAimInterceptor`.**

Because `MenuAimInterceptor` only captures pointer events within its bounds, it
is best to size the `MenuAimInterceptor` to cover the entire screen area.

```dart
class ExampleState extends State<Example> {
  final geometry = MenuAimGeometry();

  @override
  Widget build(BuildContext context) {
    final isEnabled = MenuAimScope.maybeOf(context)?.enable ?? false;;

    // Don't include the interceptor if aim assist is disabled.
    if (!isEnabled) {
      return CustomSingleChildLayout(
        delegate: ExampleDelegate(),
        child: ExampleMenuPanel()
      );
    }

    geometry.anchorRect = widget.anchorRect;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        CustomSingleChildLayout(
          delegate: ExampleDelegate(
            onTargetPositioned: (targetRect) { 
              // setState is not required since the pointer trajectory is only
              // calculated in response to pointer events.
              geometry.targetRect = targetRect; 
            },
          ),
          child: ExampleMenuPanel()
        )
        MenuAimInterceptor(geometry: geometry),
      ],
    );
  }
}
```

## Debugging

To visualize the aim trajectory in **debug builds**, set the static property
`MenuAimInterceptor.visualizeAim` to true:

```dart
MenuAimInterceptor.visualizeAim = true;
``` 

This renders the safe triangle (magenta), current trajectory (green), and the
nearest target point (blue).

By default, the aim trajectory visualizer is compiled out of release builds.
Setting the `VISUALIZE_MENU_AIM` environmental variable to `true` allows the
visualizer to be used in production builds.

```bash
flutter run --dart-define=VISUALIZE_MENU_AIM=true
```