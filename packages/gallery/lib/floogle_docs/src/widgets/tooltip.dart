import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../shared/package.dart';
import '../theme/colors.dart';

const webStyle = TextStyle(
  color: FloogleColors.onDarkGray,
  fontFamily: 'RobotoFlex',
  package: kPackage,
  fontFamilyFallback: ['InterVariable'],
  fontSize: 12.0,
  fontVariations: [FontVariation.weight(500)],
  letterSpacing: 0.1,
  height: 1,
  decoration: TextDecoration.none,
);

const defaultStyle = TextStyle(
  color: FloogleColors.onDarkGray,
  fontFamily: 'RobotoFlex',
  package: kPackage,
  fontFamilyFallback: ['InterVariable'],
  fontSize: 12.0,
  fontVariations: [FontVariation.weight(425)],
  letterSpacing: 0.1,
  height: 1,
  decoration: TextDecoration.none,
);

class MenuTooltip extends StatefulWidget {
  const MenuTooltip({
    super.key,
    required this.message,
    required this.child,
    this.hoverDelay = const Duration(milliseconds: 300),
    this.enableSemantics = true,
  });

  /// The text content to display inside the tooltip overlay.
  final InlineSpan message;

  /// The target anchor widget that triggers and aligns the tooltip.
  final Widget child;

  /// Delay duration when hovered before showing the tooltip.
  final Duration hoverDelay;

  final bool enableSemantics;

  @override
  State<MenuTooltip> createState() => _MenuTooltipState();
}

class _MenuTooltipState extends State<MenuTooltip> {
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  bool get _isTooltipVisible => MenuTooltipScope.of(context).isTooltipVisible;

  void _showTooltip() {
    MenuTooltipScope.of(context).showTooltip(layerLink: _layerLink, message: widget.message);
  }

  void _hideTooltip() {
    MenuTooltipScope.of(context).hideTooltip();
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    _isHovered = true;
    if (_isTooltipVisible) {
      _showTooltip();
      return;
    }

    Future.delayed(widget.hoverDelay, () {
      if (_isHovered && mounted) {
        _showTooltip();
      }
    });
  }

  void _handleMouseExit(PointerExitEvent event) {
    _isHovered = false;
    _hideTooltip();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      child: Semantics(
        tooltip: widget.enableSemantics ? widget.message.toPlainText() : null,
        child: CompositedTransformTarget(link: _layerLink, child: widget.child),
      ),
    );
  }
}

class _MenuTooltipScope extends InheritedWidget {
  const _MenuTooltipScope({required super.child, required this.state});
  final MenuTooltipScopeState state;

  @override
  bool updateShouldNotify(_MenuTooltipScope oldWidget) {
    return state != oldWidget.state;
  }
}

abstract class MenuTooltipScopeState {
  void showTooltip({required LayerLink layerLink, required InlineSpan message});
  void hideTooltip({bool sync = false});
  bool get isTooltipVisible;
}

class MenuTooltipScope extends StatefulWidget {
  const MenuTooltipScope({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
    this.margin,
    this.targetAnchor = Alignment.bottomCenter,
    this.followerAnchor = Alignment.topCenter,
    this.offset = const Offset(0.0, 4.0),
  });

  /// The target anchor widget that triggers and aligns the tooltip.
  final Widget child;

  /// Padding around the tooltip content.
  final EdgeInsetsGeometry padding;

  /// Margin for the tooltip.
  final EdgeInsetsGeometry? margin;

  /// The anchor alignment point relative to the target (Leader).
  final Alignment targetAnchor;

  /// The anchor alignment point on the tooltip itself (Follower) that aligns with the target anchor.
  final Alignment followerAnchor;

  /// An extra coordinate offset adjustment to space the tooltip away from the anchor.
  final Offset offset;

  static MenuTooltipScopeState of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_MenuTooltipScope>()!.state;
  }

  @override
  State<MenuTooltipScope> createState() => _MenuTooltipScopeState();
}

class _MenuTooltipScopeState extends State<MenuTooltipScope>
    with SingleTickerProviderStateMixin
    implements MenuTooltipScopeState {
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  LayerLink? _parentLayerLink;
  InlineSpan? _currentMessage;
  OverlayEntry? _overlayEntry;

  @override
  bool get isTooltipVisible =>
      _animationController.status == AnimationStatus.completed ||
      _animationController.status == AnimationStatus.reverse;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
  }

  void _insertOverlay() {
    assert(_overlayEntry == null, 'Overlay entry already exists');
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: RepaintBoundary(
          child: IgnorePointer(
            child: ExcludeFocus(
              child: ExcludeSemantics(
                child: CompositedTransformFollower(
                  link: _parentLayerLink ?? _layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: widget.targetAnchor,
                  followerAnchor: widget.followerAnchor,
                  offset: widget.offset,
                  child: Align(
                    alignment: .topCenter,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: widget.margin ?? EdgeInsets.zero,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: FloogleColors.darkGray,
                            borderRadius: BorderRadius.circular(4.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: widget.padding,
                            child: Text.rich(
                              _currentMessage ?? const TextSpan(),
                              style: kIsWeb ? webStyle : defaultStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  @override
  void showTooltip({required LayerLink layerLink, required InlineSpan message}) {
    if (_overlayEntry == null) {
      _insertOverlay();
    }

    _parentLayerLink = layerLink;
    _currentMessage = message;
    _animationController.forward();
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void hideTooltip({bool sync = false}) {
    if (sync) {
      _animationController.value = 0.0;
      _parentLayerLink = null;
      _currentMessage = null;
      _overlayEntry?.markNeedsBuild();
    } else {
      _animationController.reverse().whenComplete(() {
        _parentLayerLink = null;
        _currentMessage = null;
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _parentLayerLink = null;
    _currentMessage = null;
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MenuTooltipScope(state: this, child: widget.child);
  }
}
