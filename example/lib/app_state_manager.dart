import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/entry.dart';
import 'data/menu.dart';
import 'extensions/string.dart';
import 'model/enum.dart';
import 'model/intents.dart';
import 'model/model.dart';
import 'utilities/editor_controller.dart';
import 'utilities/style_segment_tree.dart';
import 'widgets/action_reflector.dart';

abstract interface class AppStateInterface {
  void toggleTitle();
}

class AppStateManager extends StatefulWidget {
  const AppStateManager({super.key, required this.child});
  final Widget child;

  static bool hasSelectionOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.hasSelection,
    )!.hasSelection;
  }

  static String? selectedTextOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.selectionText,
    )!.selectedText;
  }

  static SegmentTextStyle? selectedTextStyleOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.selectedTextStyle,
    )!.selectedTextStyle;
  }

  static DocumentParagraphStyle selectedParagraphStyleOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.selectedParagraphStyle,
    )!.selectedParagraphStyle;
  }

  static Map<DocumentParagraphStyle, SegmentTextStyle> paragraphStylesOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.paragraphStyles,
    )!.paragraphStyles;
  }

  static FocusNode editorFocusNodeOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.editorFocusNode,
    )!.editorFocusNode;
  }

  static MenuController searchMenuControllerOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.searchMenuController,
    )!.searchMenuController;
  }

  static EditorController controllerOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.controller,
    )!.controller;
  }

  static Map<SelectionKey, Object> documentStateOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.documentFlags,
    )!.documentFlags;
  }

  static AppStateInterface of(BuildContext context) {
    return context.findAncestorStateOfType<_AppStateManagerState>()!;
  }

  static bool isHeaderShownOf(BuildContext context) {
    return InheritedModel.inheritFrom<_EditorModel>(
      context,
      aspect: _EditorModelAspect.isHeaderShown,
    )!.isHeaderShown;
  }

  @override
  State<AppStateManager> createState() => _AppStateManagerState();
}

class _AppStateManagerState extends State<AppStateManager> implements AppStateInterface {
  final controller = EditorController(
    text:
        'This application demonstrates a menu system built using menu_utilities.\n\n'
        'The editor itself is only a demonstration, and has limited functionality.\n\n'
        'No Material or Cupertino widgets are used in this example.',
  );

  final FocusNode editorFocusNode = FocusNode();
  final MenuController searchMenuController = MenuController();
  Map<SelectionKey, Object> documentFlags = <SelectionKey, Object>{
    .viewMode: ViewModeOption.editing,
    .showRuler: true,
    .showPrintLayout: true,
    .zoomLevel: '100%',
    .menuAimAssist: false,
    .menuAimAssistDebugPaint: false,
    .topMargin: 96.0,
    .bottomMargin: 96.0,
    .leftMargin: 96.0,
    .rightMargin: 96.0,
    .leftIndent: 0.0,
    .rightIndent: 0.0,
    .firstLineIndent: 0.0,
  };
  late final shortcuts = _buildShortcuts();
  bool _isHeaderShown = true;
  SegmentTextStyle? _lastTextStyle;

  @override
  void dispose() {
    controller.dispose();
    editorFocusNode.dispose();
    super.dispose();
  }

  void toggleFlag(SelectionKey key) {
    setState(() {
      documentFlags = {...documentFlags, key: !((documentFlags[key] as bool?) ?? false)};
    });
  }

  void setFlag<T extends Object>(SelectionKey key, T value) {
    setState(() {
      documentFlags = {...documentFlags, key: value};
    });
  }

  void syncFlagsToTextStyle(SegmentTextStyle textStyle) {
    if (_lastTextStyle == textStyle) {
      return;
    }

    final TextStyle(:fontWeight, :fontStyle, :decoration, :height, :fontFamily, :fontSize) =
        textStyle.textStyle ?? const TextStyle();

    documentFlags = {
      ...documentFlags,
      .textFormatBold: fontWeight == FontWeight.bold,
      .textFormatItalic: fontStyle == FontStyle.italic,
      .textFormatUnderline: decoration == TextDecoration.underline,
      .textFormatStrikethrough: decoration == TextDecoration.lineThrough,
      .textFormatSuperscript: textStyle.isSuperscript == true,
      .textFormatSubscript: textStyle.isSubscript == true,
      .textAlign: textStyle.textAlign ?? TextAlign.left,
      .lineHeight: height ?? 1.5,
    };
    _lastTextStyle = textStyle;
  }

  @override
  void toggleTitle() {
    setState(() {
      _isHeaderShown = !_isHeaderShown;
    });
  }

  void _handlePaste(Intent intent) {
    Actions.invoke(editorFocusNode.context!, const PasteTextIntent(.keyboard));
    Actions.invoke(
      editorFocusNode.context!,
      const ShowSnackbarTextIntent('Paste with formatting is not implemented'),
    );
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DoNothingAndStopPropagationIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): const DoNothingAndStopPropagationIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): const DoNothingAndStopPropagationIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowDown): const DoNothingAndStopPropagationIntent(),
    };

    void walkEntries(List<BaseMenuEntry> entries) {
      for (final entry in entries) {
        switch (entry) {
          case TileGroupMenuEntry():
            walkEntries(entry.children);
          case SubmenuEntry():
            walkEntries(entry.children);
          case MenuEntryWithIntent():
            if (entry.shortcut != null) {
              shortcuts[entry.shortcut!] = entry.intent;
            }
          case MenuEntry():
          case SeparatorMenuEntry():
            continue;
        }
      }
    }

    walkEntries(Menu.main.children);
    walkEntries(Menu.context.children);
    walkEntries([
      Entry.paintFormat,
      Entry.increaseFontSize,
      Entry.decreaseFontSize,
      Entry.showHideMenus,
    ]);

    return shortcuts;
  }

  late final Map<Type, Action<Intent>> _actions = {
    // Edit
    CutIntent: CallbackAction<CutIntent>(
      onInvoke: (intent) {
        Actions.invoke(editorFocusNode.context!, const CopySelectionTextIntent.cut(.keyboard));
        return null;
      },
    ),
    CopyIntent: CallbackAction<CopyIntent>(
      onInvoke: (intent) {
        Actions.invoke(editorFocusNode.context!, CopySelectionTextIntent.copy);
        return null;
      },
    ),
    CopyAsMarkdownIntent: ReflectAction('Copy as Markdown'),
    PasteIntent: CallbackAction(onInvoke: _handlePaste),
    PasteWithoutFormattingIntent: CallbackAction(onInvoke: _handlePaste),
    PasteFromMarkdownIntent: CallbackAction(onInvoke: _handlePaste),
    UndoIntent: CallbackAction<UndoIntent>(
      onInvoke: (intent) {
        Actions.invoke(editorFocusNode.context!, const UndoTextIntent(.keyboard));
        return null;
      },
    ),
    RedoIntent: CallbackAction<RedoIntent>(
      onInvoke: (intent) {
        Actions.invoke(editorFocusNode.context!, const RedoTextIntent(.keyboard));
        return null;
      },
    ),
    SelectAllIntent: CallbackAction<SelectAllIntent>(
      onInvoke: (intent) {
        Actions.invoke(editorFocusNode.context!, const SelectAllTextIntent(.keyboard));
        return null;
      },
    ),
    FindAndReplaceIntent: ReflectAction('Find and Replace'),
    PaintFormatIntent: _ToggleEntryAction(this),

    // File
    NewDocumentIntent: ReflectAction('New Document'),
    NewSpreadsheetIntent: ReflectAction('New Spreadsheet'),
    NewPresentationIntent: ReflectAction('New Presentation'),
    OpenFileIntent: ReflectAction('Open File'),
    MakeCopyIntent: ReflectAction('Make Copy'),
    ShareWithPeopleIntent: ReflectAction('Share With People'),
    GetLinkIntent: ReflectAction('Get Link'),
    EmailFileIntent: ReflectAction('Email File'),
    EmailCollaboratorsIntent: ReflectAction('Email Collaborators'),
    DownloadDocXIntent: ReflectAction('Download DocX'),
    DownloadPdfIntent: ReflectAction('Download PDF'),
    DownloadTextIntent: ReflectAction('Download Text'),
    DownloadOdtIntent: ReflectAction('Download ODT'),
    RenameFileIntent: ReflectAction('Rename File'),
    MoveFileIntent: ReflectAction('Move File'),
    AddDriveShortcutIntent: ReflectAction('Add Drive Shortcut'),
    MoveToTrashIntent: ReflectAction('Move to Trash'),
    SeeVersionHistoryIntent: ReflectAction('See Version History'),
    NameCurrentVersionIntent: ReflectAction('Name Current Version'),
    MakeAvailableOfflineIntent: ReflectAction('Make Available Offline'),
    ViewDetailsIntent: ReflectAction('View Details'),
    SetLanguageIntent: ReflectAction('Set Language'),
    SetZoomLevelIntent: CallbackAction<SetZoomLevelIntent>(
      onInvoke: (intent) {
        setFlag(SelectionKey.zoomLevel, intent.value);
        return null;
      },
    ),
    PageSetupIntent: ReflectAction('Page Setup'),
    PrintIntent: ReflectAction('Print'),
    SetCommentVisibilityIntent: CallbackAction<SetCommentVisibilityIntent>(
      onInvoke: (intent) {
        setFlag(intent.key, intent.value);
        return null;
      },
    ),

    // View
    SetViewingModeIntent: CallbackAction<SetViewingModeIntent>(
      onInvoke: (intent) {
        setFlag(intent.key, intent.value);
        return null;
      },
    ),
    ViewResolvedCommentsIntent: ReflectAction('View Resolved Comments'),
    CollapseSidebarIntent: ReflectAction('Collapse Sidebar'),
    TogglePrintLayoutIntent: _ToggleEntryAction(this),
    ToggleRulerIntent: _ToggleEntryAction(this),
    ToggleEquationToolbarIntent: _ToggleEntryAction(this),
    ToggleNonPrintingCharactersIntent: _ToggleEntryAction(this),
    FullScreenIntent: ReflectAction('Full Screen'),

    // Insert
    InsertImageIntent: ReflectAction('Insert Image'),
    InsertTableIntent: CallbackAction<InsertTableIntent>(
      onInvoke: (intent) {
        Actions.invoke(
          editorFocusNode.context!,
          ShowSnackbarTextIntent(
            'Pretending to insert a ${intent.rows}x${intent.columns} table...',
          ),
        );
        return null;
      },
    ),
    InsertDrawingIntent: ReflectAction('Insert Drawing'),
    InsertBarChartIntent: ReflectAction('Insert Bar Chart'),
    InsertColumnChartIntent: ReflectAction('Insert Column Chart'),
    InsertLineChartIntent: ReflectAction('Insert Line Chart'),
    InsertPieChartIntent: ReflectAction('Insert Pie Chart'),
    InsertLinkIntent: ReflectAction('Insert Link'),
    InsertTabIntent: ReflectAction('Insert Tab'),
    InsertHorizontalLineIntent: ReflectAction('Insert Horizontal Line'),
    PageBreakIntent: ReflectAction('Page Break'),
    ColumnBreakIntent: ReflectAction('Column Break'),
    ContinuousSectionBreakIntent: ReflectAction('Continuous Section Break'),
    NextPageSectionBreakIntent: ReflectAction('Next Page Section Break'),
    InsertBookmarkIntent: ReflectAction('Insert Bookmark'),
    InsertHeaderIntent: ReflectAction('Insert Header'),
    InsertFooterIntent: ReflectAction('Insert Footer'),
    InsertFootnoteIntent: ReflectAction('Insert Footnote'),
    InsertPageNumberIntent: ReflectAction('Insert Page Number'),
    InsertPageCountIntent: ReflectAction('Insert Page Count'),
    AddCommentIntent: ReflectAction('Add Comment'),

    // Format
    FormatBoldIntent: CallbackAction<FormatBoldIntent>(
      onInvoke: (intent) {
        final isBold = controller.selectionHasAttributes(
          (s) =>
              s.textStyle?.fontWeight?.value != null &&
              s.textStyle!.fontWeight!.value > FontWeight.normal.value,
        );

        final fontWeight = isBold ? FontWeight.normal : FontWeight.bold;

        final textStyle =
            controller.selectedTextStyle?.textStyle ??
            TextStyle(fontWeight: FontWeight.normal, fontFamily: FontFamily.roboto.label);

        controller.applyStyle(
          SegmentTextStyle(
            textStyle: GoogleFonts.getFont(
              textStyle.fontFamily?.withSpaceAfterCapitals.split('_')[0] ?? FontFamily.roboto.label,
              fontWeight: fontWeight,
              textStyle: textStyle,
            ),
          ),
        );
        editorFocusNode.requestFocus();
        return null;
      },
    ),

    FormatItalicIntent: CallbackAction<FormatItalicIntent>(
      onInvoke: (intent) {
        final isItalic = !controller.selectionHasAttributes(
          (s) => s.textStyle?.fontStyle != FontStyle.italic,
        );
        final fontStyle = isItalic ? FontStyle.normal : FontStyle.italic;
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(fontStyle: fontStyle)));
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    FormatUnderlineIntent: CallbackAction<FormatUnderlineIntent>(
      onInvoke: (intent) {
        final isUnderlined = !controller.selectionHasAttributes(
          (s) => s.textStyle?.decoration != TextDecoration.underline,
        );
        final decoration = isUnderlined ? TextDecoration.none : TextDecoration.underline;
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(decoration: decoration)));
        editorFocusNode.requestFocus();

        return null;
      },
    ),
    FormatStrikethroughIntent: CallbackAction<FormatStrikethroughIntent>(
      onInvoke: (intent) {
        final isStruckThrough = !controller.selectionHasAttributes(
          (s) => s.textStyle?.decoration != TextDecoration.lineThrough,
        );
        final decoration = isStruckThrough ? TextDecoration.none : TextDecoration.lineThrough;
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(decoration: decoration)));
        editorFocusNode.requestFocus();

        return null;
      },
    ),
    FormatSuperscriptIntent: CallbackAction<FormatSuperscriptIntent>(
      onInvoke: (intent) {
        controller.applyStyle(
          SegmentTextStyle(
            isSuperscript: !(controller.selectedTextStyle?.isSuperscript == true),
            isSubscript: false,
          ),
        );
        return null;
      },
    ),
    FormatSubscriptIntent: CallbackAction<FormatSubscriptIntent>(
      onInvoke: (intent) {
        controller.applyStyle(
          SegmentTextStyle(
            isSubscript: !(controller.selectedTextStyle?.isSubscript == true),
            isSuperscript: false,
          ),
        );
        return null;
      },
    ),
    FormatTextHighlightIntent: CallbackAction<FormatTextHighlightIntent>(
      onInvoke: (intent) {
        controller.applyStyle(
          SegmentTextStyle(textStyle: TextStyle(backgroundColor: intent.value)),
        );
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    FormatTextColorIntent: CallbackAction<FormatTextColorIntent>(
      onInvoke: (intent) {
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(color: intent.value)));
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    FormatFontSizeIntent: CallbackAction<FormatFontSizeIntent>(
      onInvoke: (intent) {
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(fontSize: intent.value)));
        return null;
      },
    ),
    FormatIncreaseFontSizeIntent: CallbackAction<FormatIncreaseFontSizeIntent>(
      onInvoke: (intent) {
        final currentSize = controller.selectedTextStyle?.textStyle?.fontSize ?? 14;
        final newSize = math.min(94.0, currentSize + 1);
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(fontSize: newSize)));
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    FormatDecreaseFontSizeIntent: CallbackAction<FormatDecreaseFontSizeIntent>(
      onInvoke: (intent) {
        final currentSize = controller.selectedTextStyle?.textStyle?.fontSize ?? 14;
        final newSize = math.max(1.0, currentSize - 1);
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(fontSize: newSize)));
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    ApplyParagraphStyleIntent: CallbackAction<ApplyParagraphStyleIntent>(
      onInvoke: (intent) {
        controller.applyParagraphStyle(intent.value);
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    SetFontFamilyIntent: CallbackAction<SetFontFamilyIntent>(
      onInvoke: (intent) {
        controller.applyStyle(
          SegmentTextStyle(
            textStyle: GoogleFonts.getFont(
              intent.value.family.label,
              textStyle: controller.selectedTextStyle?.textStyle,
              fontWeight: intent.value.weight,
            ),
          ),
        );
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    UpdateParagraphStyleToMatchIntent: CallbackAction<UpdateParagraphStyleToMatchIntent>(
      onInvoke: (intent) {
        final textStyle = controller.selectedTextStyle;
        if (textStyle == null) {
          Actions.invoke(
            context,
            const ShowSnackbarTextIntent('No text selected to update style from'),
          );
          return;
        }

        controller.updateParagraphStyle(intent.style, textStyle);
        editorFocusNode.requestFocus();
        return;
      },
    ),
    ClearFormattingIntent: CallbackAction<ClearFormattingIntent>(
      onInvoke: (intent) {
        final controller = AppStateManager.controllerOf(primaryFocus!.context!);
        controller.applyStyle(
          const SegmentTextStyle(isSubscript: false, isSuperscript: false, textStyle: TextStyle()),
        );
        controller.applyParagraphStyle(.normal);
        editorFocusNode.requestFocus();
        return;
      },
    ),
    IncreaseIndentIntent: ReflectAction('Increase Indent'),
    DecreaseIndentIntent: ReflectAction('Decrease Indent'),
    SetLineSpacingIntent: CallbackAction<SetLineSpacingIntent>(
      onInvoke: (intent) {
        controller.applyStyle(SegmentTextStyle(textStyle: TextStyle(height: intent.value)));
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    SetBlockAlignIntent: CallbackAction<SetBlockAlignIntent>(
      onInvoke: (intent) {
        controller.applyStyle(SegmentTextStyle(textAlign: intent.value));
        editorFocusNode.requestFocus();
        return null;
      },
    ),
    AddSpaceBeforeParagraphIntent: _ToggleEntryAction(this),
    AddSpaceAfterParagraphIntent: _ToggleEntryAction(this),
    KeepLinesTogetherIntent: _ToggleEntryAction(this),
    KeepWithNextIntent: _ToggleEntryAction(this),
    PreventSingleLinesIntent: _ToggleEntryAction(this),
    SetColumnsIntent: ReflectAction<SetColumnsIntent>('Set Columns'),
    InsertBulletedListIntent: ReflectAction<InsertBulletedListIntent>('Set Bulleted List'),
    InsertNumberedListIntent: ReflectAction<InsertNumberedListIntent>('Set Numbered List'),
    FormatNumberedListIntent: ReflectAction<FormatNumberedListIntent>('Format Numbered List'),
    FormatBulletedListIntent: ReflectAction<FormatBulletedListIntent>('Format Bulleted List'),
    FormatChecklistIntent: ReflectAction<FormatChecklistIntent>('Format Checklist'),
    MoreColumnsOptionsIntent: ReflectAction<MoreColumnsOptionsIntent>('More Columns Options'),
    HeadersAndFootersIntent: ReflectAction<HeadersAndFootersIntent>('Headers and Footers'),
    PageNumbersIntent: ReflectAction('Page Numbers'),
    PageOrientationIntent: ReflectAction('Page Orientation'),
    SwitchToPagelessIntent: ReflectAction('Switch to Pageless'),

    // Tools
    CheckSpellingGrammarIntent: _ToggleEntryAction(this),
    ToggleSpellingSuggestionsIntent: _ToggleEntryAction(this),
    ToggleGrammarSuggestionsIntent: _ToggleEntryAction(this),
    ToggleUnderlineErrorsIntent: _ToggleEntryAction(this),
    WordCountIntent: ReflectAction('Word Count'),
    ReviewSuggestedEditsIntent: ReflectAction('Review Suggested Edits'),
    CompareDocumentsIntent: ReflectAction('Compare Documents'),
    CitationsIntent: ReflectAction('Citations'),
    LineNumbersIntent: ReflectAction('Line Numbers'),
    LinkedObjectsIntent: ReflectAction('Linked Objects'),
    DictionaryIntent: ReflectAction('Dictionary'),
    TranslateDocumentIntent: ReflectAction('Translate Document'),
    VoiceTypingIntent: ReflectAction('Voice Typing'),
    NotificationSettingsIntent: ReflectAction('Notification Settings'),
    PreferencesIntent: ReflectAction('Preferences'),
    AccessibilityIntent: ReflectAction('Accessibility'),

    // Extensions
    GetAddOnsIntent: ReflectAction('Get Add-Ons'),
    ManageAddOnsIntent: ReflectAction('Manage Add-Ons'),

    // Help
    SearchMenusIntent: CallbackAction<SearchMenusIntent>(
      onInvoke: (intent) {
        searchMenuController.open();
        return null;
      },
    ),
    HelpIntent: ReflectAction('Help'),
    TrainingIntent: ReflectAction('Training'),
    UpdatesIntent: ReflectAction('Updates'),
    HelpFloogleDocsImproveIntent: ReflectAction('Help Floogle Docs Improve'),
    PrivacyPolicyIntent: ReflectAction('Privacy Policy'),
    TermsOfServiceIntent: ReflectAction('Terms of Service'),
    KeyboardShortcutsIntent: ReflectAction('Keyboard Shortcuts'),

    // Context menu
    CommentIntent: ReflectAction('Comment'),
    SuggestEditsIntent: ReflectAction('Suggest Edits'),
    DefineIntent: ReflectAction('Define'),
    SelectAllMatchingTextIntent: ReflectAction('Select All Matching Text'),

    SetDocumentTopMarginIntent: _SetEntryAction<double, SetDocumentTopMarginIntent>(this),
    SetDocumentBottomMarginIntent: _SetEntryAction<double, SetDocumentBottomMarginIntent>(this),
    SetDocumentLeftMarginIntent: _SetEntryAction<double, SetDocumentLeftMarginIntent>(this),
    SetDocumentRightMarginIntent: _SetEntryAction<double, SetDocumentRightMarginIntent>(this),

    SetParagraphLeftIndentIntent: _SetEntryAction<double, SetParagraphLeftIndentIntent>(this),
    SetParagraphRightIndentIntent: _SetEntryAction<double, SetParagraphRightIndentIntent>(this),
    SetParagraphFirstLineIndentIntent: _SetEntryAction<double, SetParagraphFirstLineIndentIntent>(
      this,
    ),

    ToggleMenuAimAssistIntent: _ToggleEntryAction(this),
    ToggleMenuAimDebugPaintIntent: _ToggleEntryAction(this),

    ToggleMenuVisibilityIntent: CallbackAction<ToggleMenuVisibilityIntent>(
      onInvoke: (intent) {
        toggleTitle();
        return null;
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: _actions,
      child: Shortcuts(
        shortcuts: shortcuts,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            syncFlagsToTextStyle(controller.selectedTextStyle ?? const SegmentTextStyle());
            return _EditorModel(
              controller: controller,
              hasSelection: !controller.selection.isCollapsed,
              selectedText: controller.selectedText,
              selectedTextStyle: controller.selectedTextStyle,
              selectedParagraphStyle: controller.selectedParagraphStyle,
              paragraphStyles: controller.paragraphStyles,
              editorFocusNode: editorFocusNode,
              searchMenuController: searchMenuController,
              documentFlags: documentFlags,
              isHeaderShown: _isHeaderShown,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

enum _EditorModelAspect {
  hasSelection,
  selectionText,
  selectedTextStyle,
  selectedParagraphStyle,
  paragraphStyles,
  documentFlags,
  controller,
  editorFocusNode,
  searchMenuController,
  isHeaderShown,
}

class _EditorModel extends InheritedModel<_EditorModelAspect> {
  const _EditorModel({
    required super.child,
    required this.selectedTextStyle,
    required this.selectedText,
    required this.selectedParagraphStyle,
    required this.paragraphStyles,
    required this.documentFlags,
    required this.hasSelection,
    required this.controller,
    required this.editorFocusNode,
    required this.searchMenuController,
    required this.isHeaderShown,
  });
  final String? selectedText;
  final SegmentTextStyle? selectedTextStyle;
  final DocumentParagraphStyle selectedParagraphStyle;
  final Map<DocumentParagraphStyle, SegmentTextStyle> paragraphStyles;
  final Map<SelectionKey, Object> documentFlags;
  final bool hasSelection;
  final EditorController controller;
  final FocusNode editorFocusNode;
  final MenuController searchMenuController;
  final bool isHeaderShown;

  @override
  bool updateShouldNotify(_EditorModel oldWidget) {
    return selectedTextStyle != oldWidget.selectedTextStyle ||
        selectedText != oldWidget.selectedText ||
        selectedTextStyle != oldWidget.selectedTextStyle ||
        selectedParagraphStyle != oldWidget.selectedParagraphStyle ||
        !mapEquals(paragraphStyles, oldWidget.paragraphStyles) ||
        !mapEquals(documentFlags, oldWidget.documentFlags) ||
        hasSelection != oldWidget.hasSelection ||
        controller != oldWidget.controller ||
        editorFocusNode != oldWidget.editorFocusNode ||
        searchMenuController != oldWidget.searchMenuController ||
        isHeaderShown != oldWidget.isHeaderShown;
  }

  @override
  bool updateShouldNotifyDependent(_EditorModel oldWidget, Set<_EditorModelAspect> dependencies) {
    if (dependencies.contains(_EditorModelAspect.hasSelection) &&
        hasSelection != oldWidget.hasSelection) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.selectionText) &&
        selectedText != oldWidget.selectedText) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.selectedTextStyle) &&
        selectedTextStyle != oldWidget.selectedTextStyle) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.selectedParagraphStyle) &&
        selectedParagraphStyle != oldWidget.selectedParagraphStyle) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.paragraphStyles) &&
        !mapEquals(paragraphStyles, oldWidget.paragraphStyles)) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.documentFlags) &&
        !mapEquals(documentFlags, oldWidget.documentFlags)) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.controller) &&
        controller != oldWidget.controller) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.editorFocusNode) &&
        editorFocusNode != oldWidget.editorFocusNode) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.searchMenuController) &&
        searchMenuController != oldWidget.searchMenuController) {
      return true;
    }

    if (dependencies.contains(_EditorModelAspect.isHeaderShown) &&
        isHeaderShown != oldWidget.isHeaderShown) {
      return true;
    }

    return false;
  }
}

class _ToggleEntryAction extends Action<FloogleSelectableBooleanIntent> {
  _ToggleEntryAction(this.state);
  final _AppStateManagerState state;

  @override
  Object? invoke(FloogleSelectableBooleanIntent intent) {
    state.toggleFlag(intent.key);
    return null;
  }
}

class _SetEntryAction<T extends Object, I extends FloogleSelectableIntent<T>> extends Action<I> {
  _SetEntryAction(this.state);
  final _AppStateManagerState state;

  @override
  Object? invoke(I intent) {
    state.setFlag<T>(intent.key, intent.value);
    return null;
  }
}
