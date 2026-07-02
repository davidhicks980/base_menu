import 'package:flutter/widgets.dart';

import '../app_state_manager.dart';
import '../../model/enum.dart';
import '../tooltip.dart';
import '../adapters/menu_entry_view_mode_panel.dart';
import '../select.dart';

class ViewModeMenu extends StatelessWidget {
  const ViewModeMenu({super.key, required this.breakpoint});
  final double breakpoint;

  Widget _buildTransition(BuildContext context, double value, Widget? child) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: 80 * value),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ViewMode(
      child: Builder(
        builder: (BuildContext context) {
          final selected =
              AppStateManager.documentStateOf(context)[SelectionKey.viewMode]! as ViewModeOption;
          return TweenAnimationBuilder(
            tween: MediaQuery.widthOf(context) < breakpoint
                ? Tween<double>(begin: 1.0, end: 0.0)
                : Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: _buildTransition,
            child: Text(selected.label),
          );
        },
      ),
    );
  }
}

class _ViewMode extends StatefulWidget {
  const _ViewMode({required this.child});
  final Widget child;

  @override
  State<_ViewMode> createState() => _ViewModeState();
}

class _ViewModeState extends State<_ViewMode> {
  final FocusNode _focusNode = FocusNode();
  final MenuController controller = MenuController();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Select(
      menuController: controller,
      focusNode: _focusNode,
      panel: ViewModePanel(
        onSurfaceExit: (event) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
      ),
      buttonRadius: const BorderRadiusGeometry.all(Radius.circular(100)),
      buttonPadding: const EdgeInsetsGeometry.symmetric(vertical: 4, horizontal: 12),
      child: Builder(
        builder: (BuildContext context) {
          final selected =
              AppStateManager.documentStateOf(context)[SelectionKey.viewMode]! as ViewModeOption;
          return ExcludeSemantics(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 3, right: 8, bottom: 2),
                  child: Icon(selected.icon, size: 18, color: const Color(0xFF444746)),
                ),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Color(0xFF444746),
                    overflow: TextOverflow.ellipsis,
                    fontSize: 14,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          );
        },
      ),
    );
    return Builder(
      builder: (BuildContext context) {
        final selected =
            AppStateManager.documentStateOf(context)[SelectionKey.viewMode]! as ViewModeOption;
        return MergeSemantics(
          child: Semantics(
            container: true,
            label: '${selected.label} mode',
            child: MenuTooltip(
              enableSemantics: false,
              message: TextSpan(text: '${selected.label} mode'),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
