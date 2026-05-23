import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utilities/colors.dart';

// Base text editor widget

class _EditorSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  _EditorSelectionGestureDetectorBuilder({required _EditableState state})
    : _state = state,
      super(delegate: state);

  final _EditableState _state;

  @override
  bool get onUserTapAlwaysCalled => _state.widget.onTapAlwaysCalled;

  @override
  void onUserTap() {
    _state.widget.onTap?.call();
  }

  @override
  void onSecondaryTapDown(TapDownDetails details) {
    if (_state.widget.onSecondaryTapDown == null) {
      super.onSecondaryTapDown(details);
    } else {
      renderEditable.handleSecondaryTapDown(TapDownDetails(globalPosition: details.globalPosition));
      _state.widget.onSecondaryTapDown?.call(details);
    }
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (_state.widget.onSingleLongTapStart != null) {
      _state.widget.onSingleLongTapStart?.call(details);
    } else {
      super.onSingleLongTapStart(details);
    }
  }
}

class Editable extends StatefulWidget {
  const Editable({
    super.key,
    this.textController,
    this.focusNode,
    this.undoController,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.onTapAlwaysCalled = false,
    this.rendererIgnoresPointer = true,
    this.onTapOutside,
    this.mouseCursor,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const <String>[],
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardType,
    this.textInputAction,
    this.forceLine = false,
    this.onTapUpOutside,
    this.contextMenuBuilder,
    this.onSingleLongTapStart,
    this.onSecondaryTapDown,
    this.cursorWidth = 2,
    this.cursorHeight,
    this.cursorOffset,
    this.paintCursorAboveText = true,
    this.selectionColor = FloogleColors.editorSelectionColor,
    this.blurredSelectionColor = FloogleColors.editorBlurredSelectionColor,
    this.selectAllOnFocus = false,
  });

  final TextEditingController? textController;
  final FocusNode? focusNode;
  final UndoHistoryController? undoController;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final AppPrivateCommandCallback? onAppPrivateCommand;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final GestureTapCallback? onTap;
  final bool onTapAlwaysCalled;
  final TapRegionCallback? onTapOutside;
  final MouseCursor? mouseCursor;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final Clip clipBehavior;
  final String? restorationId;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool forceLine;
  final TapRegionUpCallback? onTapUpOutside;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final GestureLongPressStartCallback? onSingleLongTapStart;
  final GestureTapDownCallback? onSecondaryTapDown;
  final double cursorWidth;
  final double? cursorHeight;
  final Offset? cursorOffset;
  final bool paintCursorAboveText;
  final bool rendererIgnoresPointer;
  final Color selectionColor;
  final Color blurredSelectionColor;
  final bool selectAllOnFocus;

  bool get selectionEnabled => enableInteractiveSelection ?? true;

  @override
  State<Editable> createState() => _EditableState();
}

class _EditableState extends State<Editable>
    with RestorationMixin
    implements TextSelectionGestureDetectorBuilderDelegate, AutofillClient {
  VoidCallback? handleDidGainAccessibilityFocus;
  VoidCallback? handleDidLoseAccessibilityFocus;
  bool _showSelectionHandles = false;
  late _EditorSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;
  bool get _isEnabled => widget.enabled ?? true;

  RestorableTextEditingController? _internalTextEditingController;
  TextEditingController get _effectiveController =>
      widget.textController ?? _internalTextEditingController!.value;

  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => widget.selectionEnabled && _isEnabled;

  @override
  String? get restorationId => widget.restorationId;

  @override
  String get autofillId => editableTextKey.currentState!.autofillId;

  @override
  TextInputConfiguration get textInputConfiguration {
    final List<String>? autofillHints = widget.autofillHints?.toList(growable: false);
    final AutofillConfiguration autofillConfiguration = autofillHints != null
        ? AutofillConfiguration(
            uniqueIdentifier: autofillId,
            autofillHints: autofillHints,
            currentEditingValue: _effectiveController.value,
          )
        : AutofillConfiguration.disabled;

    return editableTextKey.currentState!.textInputConfiguration.copyWith(
      autofillConfiguration: autofillConfiguration,
    );
  }

  @override
  bool get forcePressEnabled {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => false,
      TargetPlatform.android => false,
      TargetPlatform.fuchsia => false,
      TargetPlatform.linux => false,
      TargetPlatform.windows => false,
    };
  }

  @override
  void initState() {
    super.initState();
    _setupAccessibilityActions();
    _selectionGestureDetectorBuilder = _EditorSelectionGestureDetectorBuilder(state: this);
    if (widget.textController == null) {
      _createLocalTextEditingController();
    }
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(covariant Editable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textController != oldWidget.textController) {
      if (oldWidget.textController == null) {
        _internalTextEditingController!.dispose();
        _internalTextEditingController = null;
      }
      if (widget.textController == null) {
        _createLocalTextEditingController(oldWidget.textController?.value);
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode != null) {
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      } else {
        _internalFocusNode = FocusNode();
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _internalTextEditingController?.dispose();
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_internalTextEditingController != null) {
      registerForRestoration(_internalTextEditingController!, 'controller');
    }
  }

  @override
  void autofill(TextEditingValue newEditingValue) {
    editableTextKey.currentState!.autofill(newEditingValue);
  }

  void _createLocalTextEditingController([TextEditingValue? value]) {
    assert(_internalTextEditingController == null);
    _internalTextEditingController = value == null
        ? RestorableTextEditingController()
        : RestorableTextEditingController.fromValue(value);
    if (!restorePending) {
      registerForRestoration(_internalTextEditingController!, 'controller');
    }
  }

  void _requestKeyboard() {
    editableTextKey.currentState?.requestKeyboard();
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
    if (cause == SelectionChangedCause.longPress || cause == SelectionChangedCause.drag) {
      editableTextKey.currentState?.bringIntoView(selection.extent);
    }
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionHandles) {
      return false;
    }

    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    if (widget.readOnly && _effectiveController.selection.isCollapsed) {
      return false;
    }

    if (!_isEnabled) {
      return false;
    }

    if (cause == SelectionChangedCause.longPress) {
      return true;
    }

    if (_effectiveController.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  void _setupAccessibilityActions() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS || TargetPlatform.android || TargetPlatform.fuchsia:
        break;
      case TargetPlatform.linux || TargetPlatform.windows || TargetPlatform.macOS:
        handleDidGainAccessibilityFocus ??= () {
          if (!_effectiveFocusNode.hasFocus && _effectiveFocusNode.canRequestFocus) {
            _effectiveFocusNode.requestFocus();
          }
        };
        handleDidLoseAccessibilityFocus ??= () {
          _effectiveFocusNode.unfocus();
        };
    }
  }

  void _handleTap() {
    if (!_effectiveController.selection.isValid) {
      _effectiveController.selection = TextSelection.collapsed(
        offset: _effectiveController.text.length,
      );
    }
    _requestKeyboard();
  }

  void _handleFocus() {
    assert(
      _effectiveFocusNode.canRequestFocus,
      'Received SemanticsAction.focus from the engine. However, the FocusNode '
      'of this text field cannot gain focus. This likely indicates a bug. '
      'If this text field cannot be focused (e.g. because it is not '
      'enabled), then its corresponding semantics node must be configured '
      'such that the assistive technology cannot request focus on it.',
    );

    if (_effectiveFocusNode.canRequestFocus && !_effectiveFocusNode.hasFocus) {
      _effectiveFocusNode.requestFocus();
    } else if (!widget.readOnly) {
      // If the platform requested focus, that means that previously the
      // platform believed that the text field did not have focus (even
      // though Flutter's widget system believed otherwise). This likely
      // means that the on-screen keyboard is hidden, or more generally,
      // there is no current editing session in this field. To correct
      // that, keyboard must be requested.
      //
      // A concrete scenario where this can happen is when the user
      // dismisses the keyboard on the web. The editing session is
      // closed by the engine, but the text field widget stays focused
      // in the framework.
      _requestKeyboard();
    }
  }

  Widget _buildSemantics(BuildContext context, Widget? child) {
    return Semantics(
      enabled: _isEnabled,
      maxValueLength: widget.maxLength,
      currentValueLength: _effectiveController.text.length,
      onTap: widget.readOnly ? null : _handleTap,
      onDidGainAccessibilityFocus: handleDidGainAccessibilityFocus,
      onDidLoseAccessibilityFocus: handleDidLoseAccessibilityFocus,
      onFocus: _isEnabled ? _handleFocus : null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
    ];

    final Widget child = RepaintBoundary(
      child: UnmanagedRestorationScope(
        bucket: bucket,
        child: ListenableBuilder(
          listenable: _effectiveFocusNode,
          builder: (context, _) {
            final defaultTextStyle = DefaultTextStyle.of(context);
            return EditableText(
              key: editableTextKey,
              forceLine: widget.forceLine,
              readOnly: widget.readOnly || !_isEnabled,
              showSelectionHandles: _showSelectionHandles,
              controller: _effectiveController,
              focusNode: _effectiveFocusNode,
              undoController: widget.undoController,
              keyboardType: widget.keyboardType ?? TextInputType.text,
              textInputAction: widget.textInputAction,
              style: defaultTextStyle.style.merge(widget.style),
              strutStyle: widget.strutStyle ?? StrutStyle.fromTextStyle(defaultTextStyle.style),
              textAlign: widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
              textDirection: widget.textDirection,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              expands: widget.expands,
              cursorWidth: widget.cursorWidth,
              cursorHeight: widget.cursorHeight,
              cursorOffset: widget.cursorOffset,
              selectAllOnFocus: widget.selectAllOnFocus,
              paintCursorAboveText: widget.paintCursorAboveText,
              selectionColor: _effectiveFocusNode.hasFocus
                  ? widget.selectionColor
                  : widget.blurredSelectionColor,
              selectionControls: widget.selectionEnabled ? widget.selectionControls : null,
              onChanged: widget.onChanged,
              onSelectionChanged: _handleSelectionChanged,
              onEditingComplete: widget.onEditingComplete,
              onSubmitted: widget.onSubmitted,
              onAppPrivateCommand: widget.onAppPrivateCommand,
              onTapOutside: widget.onTapOutside,
              onTapUpOutside: widget.onTapUpOutside,
              inputFormatters: formatters,
              scrollPadding: widget.scrollPadding,
              enableInteractiveSelection: widget.enableInteractiveSelection ?? true,
              dragStartBehavior: widget.dragStartBehavior,
              scrollController: widget.scrollController,
              scrollPhysics: widget.scrollPhysics,
              rendererIgnoresPointer: widget.rendererIgnoresPointer,
              selectionWidthStyle: .max,
              autofillHints: widget.autofillHints,
              autofillClient: this,
              backgroundCursorColor: FloogleColors.white,
              clipBehavior: widget.clipBehavior,
              restorationId: 'editable',
              cursorColor: FloogleColors.black,
              contextMenuBuilder: widget.contextMenuBuilder,
            );
          },
        ),
      ),
    );

    return MouseRegion(
      cursor: widget.mouseCursor ?? SystemMouseCursors.text,
      child: TextFieldTapRegion(
        child: IgnorePointer(
          ignoring: !_isEnabled,
          child: AnimatedBuilder(
            animation: _effectiveController,
            builder: _buildSemantics,
            child: _selectionGestureDetectorBuilder.buildGestureDetector(
              behavior: HitTestBehavior.opaque,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
