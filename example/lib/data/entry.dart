// File menu entries
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../model/intents.dart';
import '../model/model.dart';

abstract class Entry {
  static const newDocument = MenuEntryWithIntent(
    'Document',
    icon: Symbols.docs_rounded,
    intent: NewDocumentIntent(),
  );

  static const newSpreadsheet = MenuEntryWithIntent(
    'Spreadsheet',
    icon: Symbols.grid_on,
    intent: NewSpreadsheetIntent(),
  );

  static const newPresentation = MenuEntryWithIntent(
    'Presentation',
    icon: Symbols.slideshow,
    intent: NewPresentationIntent(),
  );

  static const openFile = MenuEntryWithIntent(
    'Open',
    icon: Symbols.folder_open,
    shortcut: SingleActivator(LogicalKeyboardKey.keyO, meta: true),
    intent: OpenFileIntent(),
  );
  static const makeCopy = MenuEntryWithIntent(
    'Make a copy',
    icon: Symbols.content_copy,
    intent: MakeCopyIntent(),
  );

  static const shareWithPeople = MenuEntryWithIntent(
    'Share with people',
    icon: Symbols.person_add,
    intent: ShareWithPeopleIntent(),
  );
  static const getLink = MenuEntryWithIntent(
    'Get link',
    icon: Symbols.link,
    intent: GetLinkIntent(),
  );

  static const emailThisFile = MenuEntryWithIntent(
    'Email this file',
    icon: Symbols.email,
    intent: EmailFileIntent(),
  );
  static const emailCollaborators = MenuEntryWithIntent(
    'Email collaborators',
    icon: Symbols.group,
    intent: EmailCollaboratorsIntent(),
  );

  static const downloadDocX = MenuEntryWithIntent(
    'Microsoft Word (.docx)',
    icon: Symbols.description,
    intent: DownloadDocXIntent(),
  );
  static const downloadPdf = MenuEntryWithIntent(
    'PDF Document (.pdf)',
    icon: Symbols.picture_as_pdf,
    intent: DownloadPdfIntent(),
  );
  static const downloadText = MenuEntryWithIntent(
    'Plain Text (.txt)',
    icon: Symbols.text_snippet,
    intent: DownloadTextIntent(),
  );
  static const downloadOdt = MenuEntryWithIntent(
    'OpenDocument Format (.odt)',
    icon: Symbols.document_scanner,
    intent: DownloadOdtIntent(),
  );

  static const renameFile = MenuEntryWithIntent(
    'Rename',
    icon: Symbols.edit,
    intent: RenameFileIntent(),
  );
  static const moveFile = MenuEntryWithIntent(
    'Move',
    icon: Symbols.drive_file_move,
    intent: MoveFileIntent(),
  );
  static const addDriveShortcut = MenuEntryWithIntent(
    'Add shortcut to Drive',
    icon: Symbols.add_box,
    intent: AddDriveShortcutIntent(),
  );
  static const moveToTrash = MenuEntryWithIntent(
    'Move to trash',
    icon: Symbols.delete,
    intent: MoveToTrashIntent(),
  );

  static const seeVersionHistory = MenuEntryWithIntent(
    'See version history',
    icon: Symbols.history,
    shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, alt: true, shift: true),
    intent: SeeVersionHistoryIntent(),
  );

  static const nameCurrentVersion = MenuEntryWithIntent(
    'Name current version',
    icon: Symbols.edit_note,
    intent: NameCurrentVersionIntent(),
  );

  static const makeAvailableOffline = MenuEntryWithIntent(
    'Make available offline',
    icon: Symbols.offline_pin,
    intent: MakeAvailableOfflineIntent(),
  );

  static const viewDetails = MenuEntryWithIntent(
    'Details',
    icon: Symbols.info,
    intent: ViewDetailsIntent(),
  );

  static const setLanguage = MenuEntryWithIntent(
    'English (United States)',
    icon: Symbols.language,
    intent: SetLanguageIntent(),
  );

  static const pageSetup = MenuEntryWithIntent(
    'Page setup',
    icon: Symbols.settings,
    intent: PageSetupIntent(),
  );

  static const print = MenuEntryWithIntent(
    'Print',
    icon: Symbols.print,
    iconConfig: IconConfiguration(fill: 1),
    shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true),
    intent: PrintIntent(),
  );

  static const spellingAndGrammar = MenuEntryWithIntent(
    'Spelling & grammar check',
    icon: Symbols.spellcheck,
    shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true, alt: true),
    intent: CheckSpellingGrammarIntent(),
  );

  static const paintFormat = MenuEntryWithIntent(
    'Paint format',
    icon: Symbols.format_paint,
    intent: PaintFormatIntent(),
  );

  static const insertLink = MenuEntryWithIntent(
    'Insert link',
    shortcut: SingleActivator(LogicalKeyboardKey.keyK, meta: true),
    icon: Symbols.link,
    intent: InsertLinkIntent(),
  );

  static const addComment = MenuEntryWithIntent(
    'Comment',
    shortcut: SingleActivator(LogicalKeyboardKey.keyM, meta: true, alt: true),
    icon: Symbols.add_comment,
    intent: AddCommentIntent(),
  );

  static const increaseIndent = MenuEntryWithIntent(
    'Increase indent',
    icon: Symbols.format_indent_increase,
    shortcut: SingleActivator(LogicalKeyboardKey.bracketRight, meta: true),
    intent: IncreaseIndentIntent(),
  );

  static const decreaseIndent = MenuEntryWithIntent(
    'Decrease indent',
    icon: Symbols.format_indent_decrease,
    shortcut: SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true),
    intent: DecreaseIndentIntent(),
  );

  static const clearFormatting = MenuEntryWithIntent(
    'Clear formatting',
    icon: Symbols.format_clear,
    shortcut: SingleActivator(LogicalKeyboardKey.backslash, meta: true),
    intent: ClearFormattingIntent(),
  );

  static const cut = MenuEntryWithIntent(
    'Cut',
    icon: Symbols.content_cut,
    shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true),
    intent: CutIntent(),
  );

  static const copy = MenuEntryWithIntent(
    'Copy',
    icon: Symbols.content_copy,
    shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true),
    intent: CopyIntent(),
  );

  static const copyAsMarkdown = MenuEntryWithIntent(
    'Copy as Markdown',
    icon: Symbols.code,
    intent: CopyAsMarkdownIntent(),
  );

  static const paste = MenuEntryWithIntent(
    'Paste',
    icon: Symbols.content_paste,
    shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true),
    intent: PasteIntent(),
  );

  static const pasteWithoutFormatting = MenuEntryWithIntent(
    'Paste without formatting',
    icon: Symbols.content_paste_off,
    shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true, shift: true),
    intent: PasteWithoutFormattingIntent(),
  );

  static const pasteFromMarkdown = MenuEntryWithIntent(
    'Paste from Markdown',
    icon: Symbols.code,
    intent: PasteFromMarkdownIntent(),
  );

  static const lineHeightSingle = SelectableMenuEntry(
    'Single',
    intent: SetLineSpacingIntent(value: 1),
  );
  static const lineHeightOnePointOneFive = SelectableMenuEntry(
    '1.15',
    intent: SetLineSpacingIntent(value: 1.15),
  );
  static const lineHeightOnePointFive = SelectableMenuEntry(
    '1.5',
    intent: SetLineSpacingIntent(value: 1.5),
  );
  static const lineHeightDouble = SelectableMenuEntry(
    'Double',
    intent: SetLineSpacingIntent(value: 2),
  );
  static const addSpaceBeforeParagraph = SelectableMenuEntry(
    'Add space before paragraph',
    intent: AddSpaceBeforeParagraphIntent(),
  );
  static const addSpaceAfterParagraph = SelectableMenuEntry(
    'Add space after paragraph',
    intent: AddSpaceAfterParagraphIntent(),
  );
  static const keepLinesTogether = SelectableMenuEntry(
    'Keep lines together',
    intent: KeepLinesTogetherIntent(),
  );
  static const keepWithNext = SelectableMenuEntry('Keep with next', intent: KeepWithNextIntent());
  static const preventSingleLines = SelectableMenuEntry(
    'Prevent single lines',
    intent: PreventSingleLinesIntent(),
  );

  static const editingMode = SelectableMenuEntry(
    'Editing',
    subtitle: 'Edit documents directly',
    icon: Symbols.edit,
    iconConfig: IconConfiguration(weight: 500),
    intent: SetViewingModeIntent.editing(),
  );

  static const suggestingMode = SelectableMenuEntry(
    'Suggesting',
    subtitle: 'Edits become suggestions',
    icon: Symbols.rate_review,
    iconConfig: IconConfiguration(weight: 500),
    intent: SetViewingModeIntent.suggesting(),
  );

  static const viewingMode = SelectableMenuEntry(
    'Viewing',
    subtitle: 'Read or print final document',
    icon: Symbols.visibility,
    iconConfig: IconConfiguration(weight: 500),
    intent: SetViewingModeIntent.viewing(),
  );

  static const undo = MenuEntryWithIntent(
    'Undo',
    icon: Symbols.undo,
    shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
    intent: UndoIntent(),
  );

  static const redo = MenuEntryWithIntent(
    'Redo',
    icon: Symbols.redo,
    shortcut: SingleActivator(LogicalKeyboardKey.keyY, meta: true),
    intent: RedoIntent(),
  );

  static const spellingAndGrammarOption = SelectableMenuEntry(
    'Spelling and grammar check',
    icon: Symbols.spellcheck,
    shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true, alt: true),
    intent: CheckSpellingGrammarIntent(),
  );

  static const boldFormat = MenuEntryWithIntent(
    'Bold',
    icon: Symbols.format_bold,
    shortcut: SingleActivator(LogicalKeyboardKey.keyB, meta: true),
    intent: FormatBoldIntent(),
  );

  static const italicFormat = MenuEntryWithIntent(
    'Italic',
    icon: Symbols.format_italic,
    shortcut: SingleActivator(LogicalKeyboardKey.keyI, meta: true),
    intent: FormatItalicIntent(),
  );

  static const underlineFormat = MenuEntryWithIntent(
    'Underline',
    icon: Symbols.format_underlined,
    shortcut: SingleActivator(LogicalKeyboardKey.keyU, meta: true),
    intent: FormatUnderlineIntent(),
  );

  static const strikethroughFormat = MenuEntryWithIntent(
    'Strikethrough',
    icon: Symbols.strikethrough_s,
    shortcut: SingleActivator(LogicalKeyboardKey.digit5, meta: true, alt: true, shift: true),
    intent: FormatStrikethroughIntent(),
  );

  static const superscriptFormat = MenuEntryWithIntent(
    'Superscript',
    icon: Symbols.superscript,
    shortcut: SingleActivator(LogicalKeyboardKey.period, meta: true),
    intent: FormatSuperscriptIntent(),
  );

  static const subscriptFormat = MenuEntryWithIntent(
    'Subscript',
    icon: Symbols.subscript,
    shortcut: SingleActivator(LogicalKeyboardKey.comma, meta: true),
    intent: FormatSubscriptIntent(),
  );

  static const alignLeft = MenuEntryWithIntent(
    'Left',
    icon: Symbols.format_align_left,
    shortcut: SingleActivator(LogicalKeyboardKey.keyL, meta: true, shift: true),
    intent: SetBlockAlignIntent.left(),
  );

  static const alignCenter = MenuEntryWithIntent(
    'Center',
    icon: Symbols.format_align_center,
    shortcut: SingleActivator(LogicalKeyboardKey.keyE, meta: true, shift: true),
    intent: SetBlockAlignIntent.center(),
  );

  static const alignRight = MenuEntryWithIntent(
    'Right',
    icon: Symbols.format_align_right,
    shortcut: SingleActivator(LogicalKeyboardKey.keyR, meta: true, shift: true),
    intent: SetBlockAlignIntent.right(),
  );

  static const alignJustified = MenuEntryWithIntent(
    'Justified',
    icon: Symbols.format_align_justify,
    shortcut: SingleActivator(LogicalKeyboardKey.keyJ, meta: true, shift: true),
    intent: SetBlockAlignIntent.justify(),
  );

  static const numberList = MenuEntryWithIntent(
    'Number list',
    icon: Symbols.format_list_numbered,
    intent: SetNumberedListIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.digit7, meta: true, shift: true),
  );

  static const bulletList = MenuEntryWithIntent(
    'Bullet list',
    icon: Symbols.format_list_bulleted,
    intent: SetBulletedListIntent(),
    shortcut: SingleActivator(LogicalKeyboardKey.digit8, meta: true, shift: true),
  );

  static const paragraphStyleNormalText = MenuEntryWithIntent(
    'Normal text',
    icon: Symbols.text_fields,
    shortcut: SingleActivator(LogicalKeyboardKey.digit0, meta: true, alt: true),
    intent: ApplyParagraphStyleIntent(.normal),
  );

  static const paragraphStyleTitle = MenuEntryWithIntent(
    'Title',
    icon: Symbols.text_fields,
    intent: ApplyParagraphStyleIntent(.title),
  );

  static const paragraphStyleSubtitle = MenuEntryWithIntent(
    'Subtitle',
    icon: Symbols.text_fields,
    intent: ApplyParagraphStyleIntent(.subtitle),
  );

  static const paragraphStyleHeading1 = MenuEntryWithIntent(
    'Heading 1',
    icon: Symbols.format_h1,
    shortcut: SingleActivator(LogicalKeyboardKey.digit1, meta: true, alt: true),
    intent: ApplyParagraphStyleIntent(.heading1),
  );

  static const paragraphStyleHeading2 = MenuEntryWithIntent(
    'Heading 2',
    icon: Symbols.format_h2,
    shortcut: SingleActivator(LogicalKeyboardKey.digit2, meta: true, alt: true),
    intent: ApplyParagraphStyleIntent(.heading2),
  );

  static const paragraphStyleHeading3 = MenuEntryWithIntent(
    'Heading 3',
    icon: Symbols.format_h3,
    shortcut: SingleActivator(LogicalKeyboardKey.digit3, meta: true, alt: true),
    intent: ApplyParagraphStyleIntent(.heading3),
  );

  // Insert menu entries
  static const uploadImage = MenuEntryWithIntent(
    'Upload from computer',
    icon: Symbols.upload_file,
    intent: InsertImageIntent(),
  );
  static const searchImage = MenuEntryWithIntent(
    'Search the web',
    icon: Symbols.search,
    intent: InsertImageIntent(),
  );
  static const driveImage = MenuEntryWithIntent(
    'Drive',
    icon: Symbols.drive_folder_upload,
    intent: InsertImageIntent(),
  );
  static const photosImage = MenuEntryWithIntent(
    'Photos',
    icon: Symbols.photo_library,
    intent: InsertImageIntent(),
  );
  static const urlImage = MenuEntryWithIntent(
    'By URL',
    icon: Symbols.link,
    intent: InsertImageIntent(),
  );
  static const cameraImage = MenuEntryWithIntent(
    'Camera',
    icon: Symbols.camera_alt,
    intent: InsertImageIntent(),
  );

  static const newDrawing = MenuEntryWithIntent(
    'New',
    icon: Symbols.add,
    intent: InsertDrawingIntent(),
  );
  static const driveDrawing = MenuEntryWithIntent(
    'From Drive',
    icon: Symbols.drive_folder_upload,
    intent: InsertDrawingIntent(),
  );

  static const barChart = MenuEntryWithIntent(
    'Bar',
    icon: Symbols.bar_chart,
    intent: InsertBarChartIntent(),
  );

  static const columnChart = MenuEntryWithIntent(
    'Column',
    icon: Symbols.bar_chart,
    intent: InsertColumnChartIntent(),
  );

  static const lineChart = MenuEntryWithIntent(
    'Line',
    icon: Symbols.show_chart,
    intent: InsertLineChartIntent(),
  );

  static const pieChart = MenuEntryWithIntent(
    'Pie',
    icon: Symbols.pie_chart_outline,
    intent: InsertPieChartIntent(),
  );

  static const insertLinkMenu = MenuEntryWithIntent(
    'Link',
    icon: Symbols.link,
    shortcut: SingleActivator(LogicalKeyboardKey.keyK, meta: true),
    intent: InsertLinkIntent(),
  );

  static const insertTab = MenuEntryWithIntent(
    'Tab',
    icon: Symbols.article,
    shortcut: SingleActivator(LogicalKeyboardKey.f11),
    intent: InsertTabIntent(),
  );

  static const horizontalLine = MenuEntryWithIntent(
    'Horizontal line',
    icon: Symbols.horizontal_rule,
    intent: InsertHorizontalLineIntent(),
  );

  static const pageBreak = MenuEntryWithIntent(
    'Page break',
    icon: Symbols.insert_page_break,
    intent: PageBreakIntent(),
  );
  static const columnBreak = MenuEntryWithIntent(
    'Column break',
    icon: Symbols.view_column,
    intent: ColumnBreakIntent(),
  );
  static const continuousSectionBreak = MenuEntryWithIntent(
    'Section break (continuous)',
    icon: Symbols.horizontal_rule,
    intent: ContinuousSectionBreakIntent(),
  );
  static const nextPageSectionBreak = MenuEntryWithIntent(
    'Section break (next page)',
    icon: Symbols.horizontal_rule,
    intent: NextPageSectionBreakIntent(),
  );

  static const bookmark = MenuEntryWithIntent(
    'Bookmark',
    icon: Symbols.bookmark,
    intent: InsertBookmarkIntent(),
  );

  static const header = MenuEntryWithIntent(
    'Header',
    icon: Symbols.border_top,
    intent: InsertHeaderIntent(),
  );
  static const footer = MenuEntryWithIntent(
    'Footer',
    icon: Symbols.border_bottom,
    intent: InsertFooterIntent(),
  );
  static const footnote = MenuEntryWithIntent(
    'Footnote',
    icon: Symbols.format_quote,
    intent: InsertFootnoteIntent(),
  );
  static const pageNumber = MenuEntryWithIntent(
    'Page number',
    icon: Symbols.tag,
    intent: InsertPageNumberIntent(),
  );
  static const pageCount = MenuEntryWithIntent(
    'Page count',
    icon: Symbols.tag,
    intent: InsertPageCountIntent(),
  );

  static const moreColumnsOptions = MenuEntryWithIntent(
    'More options',
    icon: Symbols.more_horiz,
    intent: MoreColumnsOptionsIntent(),
  );

  static const numberedListMenu = SelectableMenuEntry(
    'Numbered list',
    icon: Symbols.format_list_numbered,
    intent: SetNumberedListIntent(),
  );

  static const headersAndFooters = MenuEntryWithIntent(
    'Headers & footers',
    icon: Symbols.border_top,
    intent: HeadersAndFootersIntent(),
  );

  static const pageNumbers = MenuEntryWithIntent(
    'Page numbers',
    icon: Symbols.tag,
    intent: PageNumbersIntent(),
  );

  static const pageOrientation = MenuEntryWithIntent(
    'Page orientation',
    icon: Symbols.screen_rotation,
    intent: PageOrientationIntent(),
  );

  static const switchToPageless = MenuEntryWithIntent(
    'Switch to Pageless format',
    icon: Symbols.crop_free,
    intent: SwitchToPagelessIntent(),
  );

  // Tools menu entries
  static const showSpellingSuggestions = SelectableMenuEntry(
    'Show spelling suggestions',
    intent: ToggleSpellingSuggestionsIntent(),
  );

  static const showGrammarSuggestions = SelectableMenuEntry(
    'Show grammar suggestions',
    intent: ToggleGrammarSuggestionsIntent(),
  );

  static const underlineErrors = MenuEntryWithIntent(
    'Underline errors',
    icon: Symbols.format_underlined_squiggle,
    intent: ToggleUnderlineErrorsIntent(),
  );

  static const wordCount = MenuEntryWithIntent(
    'Word count',
    icon: Symbols.article,
    shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true),
    intent: WordCountIntent(),
  );

  static const reviewSuggestedEdits = MenuEntryWithIntent(
    'Review suggested edits',
    icon: Symbols.rate_review,
    shortcut: SingleActivator(LogicalKeyboardKey.keyU, meta: true, control: true),
    intent: ReviewSuggestedEditsIntent(),
  );

  static const compareDocuments = MenuEntryWithIntent(
    'Compare documents',
    icon: Symbols.compare_arrows,
    intent: CompareDocumentsIntent(),
  );

  static const citations = MenuEntryWithIntent(
    'Citations',
    icon: Symbols.format_quote,
    intent: CitationsIntent(),
  );

  static const lineNumbers = MenuEntryWithIntent(
    'Line numbers',
    icon: Symbols.format_list_numbered,
    intent: LineNumbersIntent(),
  );

  static const linkedObjects = MenuEntryWithIntent(
    'Linked objects',
    icon: Symbols.link,
    intent: LinkedObjectsIntent(),
  );

  static const dictionary = MenuEntryWithIntent(
    'Dictionary',
    icon: Symbols.menu_book,
    shortcut: SingleActivator(LogicalKeyboardKey.keyY, meta: true, shift: true),
    intent: DictionaryIntent(),
  );

  static const translateDocument = MenuEntryWithIntent(
    'Translate document',
    icon: Symbols.translate,
    intent: TranslateDocumentIntent(),
  );

  static const voiceTyping = MenuEntryWithIntent(
    'Voice typing',
    icon: Symbols.keyboard_voice,
    shortcut: SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
    intent: VoiceTypingIntent(),
  );

  static const notificationSettings = MenuEntryWithIntent(
    'Notification settings',
    icon: Symbols.notifications_none,
    intent: NotificationSettingsIntent(),
  );

  static const preferences = MenuEntryWithIntent(
    'Preferences',
    icon: Symbols.settings,
    intent: PreferencesIntent(),
  );

  static const accessibility = MenuEntryWithIntent(
    'Accessibility',
    icon: Symbols.accessibility,
    intent: AccessibilityIntent(),
  );

  static const findInDocument = MenuEntryWithIntent(
    'Find in document',
    icon: Symbols.find_in_page,
    shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, shift: true),
    intent: FindInDocumentIntent(),
  );

  // Help menu entries
  static const searchMenus = MenuEntryWithIntent(
    'Search the menus',
    icon: Symbols.search,
    shortcut: SingleActivator(LogicalKeyboardKey.slash, alt: true),
    intent: SearchMenusIntent(),
  );

  static const help = MenuEntryWithIntent('Help', icon: Symbols.help_outline, intent: HelpIntent());
  static const training = MenuEntryWithIntent(
    'Training',
    icon: Symbols.school,
    intent: TrainingIntent(),
  );
  static const updates = MenuEntryWithIntent(
    'Updates',
    icon: Symbols.update,
    intent: UpdatesIntent(),
  );

  static const helpFloogleDocsImprove = MenuEntryWithIntent(
    'Help Floogle Docs improve',
    icon: Symbols.feedback,
    intent: HelpFloogleDocsImproveIntent(),
  );

  static const privacyPolicy = MenuEntryWithIntent(
    'Privacy Policy',
    icon: Symbols.privacy_tip,
    intent: PrivacyPolicyIntent(),
  );

  static const termsOfService = MenuEntryWithIntent(
    'Terms of Service',
    icon: Symbols.rule,
    intent: TermsOfServiceIntent(),
  );

  static const keyboardShortcuts = MenuEntryWithIntent(
    'Keyboard shortcuts',
    icon: Symbols.keyboard,
    shortcut: SingleActivator(LogicalKeyboardKey.slash, meta: true),
    intent: KeyboardShortcutsIntent(),
  );

  static const menuAimAssist = SelectableMenuEntry(
    'Use aim assistance to open submenus',
    intent: ToggleMenuAimAssistIntent(),
  );

  static const menuAimAssistDebugPaint = SelectableMenuEntry(
    'Show cursor trajectory',
    intent: ToggleMenuAimDebugPaintIntent(),
  );

  static const selectAll = MenuEntryWithIntent(
    'Select all',
    icon: Symbols.select_all,
    shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true),
    intent: SelectAllIntent(),
  );
  static const delete = MenuEntry('Delete', icon: Symbols.delete_outline);
  static const findAndReplace = MenuEntryWithIntent(
    'Find and replace',
    icon: Symbols.find_replace,
    shortcut: SingleActivator(LogicalKeyboardKey.keyH, meta: true, shift: true),
    intent: FindAndReplaceIntent(),
  );

  static const hideComments = SelectableMenuEntry(
    'Hide comments',
    intent: SetCommentVisibilityIntent.hide(),
  );

  static const minimizeComments = SelectableMenuEntry(
    'Minimize comments',
    intent: SetCommentVisibilityIntent.minimize(),
  );

  static const expandComments = SelectableMenuEntry(
    'Expand comments',
    intent: SetCommentVisibilityIntent.expand(),
  );

  static const showAllComments = SelectableMenuEntry(
    'Show all comments',
    intent: SetCommentVisibilityIntent.showAll(),
  );

  static const collapseSidebar = MenuEntryWithIntent(
    'Collapse tabs & outlines sidebar',
    icon: Symbols.list,
    shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true, control: true),
    intent: CollapseSidebarIntent(),
  );

  static const showPrintLayout = SelectableMenuEntry(
    'Show print layout',
    intent: TogglePrintLayoutIntent(),
  );

  static const showRuler = SelectableMenuEntry('Show ruler', intent: ToggleRulerIntent());

  static const showEquationToolbar = SelectableMenuEntry(
    'Show equation toolbar',
    intent: ToggleEquationToolbarIntent(),
  );

  static const showNonPrintingCharacters = SelectableMenuEntry(
    'Show non-printing characters',
    shortcut: SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
    intent: ToggleNonPrintingCharactersIntent(),
  );

  static const fullScreen = MenuEntryWithIntent(
    'Full screen',
    icon: Symbols.fullscreen,
    intent: FullScreenIntent(),
  );

  static const getAddOns = MenuEntryWithIntent(
    'Get add-ons',
    icon: Symbols.add_box,
    intent: GetAddOnsIntent(),
  );
  static const manageAddOns = MenuEntryWithIntent(
    'Manage add-ons',
    icon: Symbols.build,
    intent: ManageAddOnsIntent(),
  );

  // Context menu entries
  static const selectAllMatchingText = MenuEntryWithIntent(
    'Select all matching text',
    icon: Symbols.text_fields,
    intent: SelectAllMatchingTextIntent(),
  );

  static const updateStyleToMatch = MenuEntryWithIntent(
    'Update style to match',
    icon: Symbols.text_fields,
    intent: UpdateStyleToMatchIntent(),
  );

  static const clearFormattingContext = MenuEntryWithIntent(
    'Clear formatting',
    icon: Symbols.format_clear,
    shortcut: SingleActivator(LogicalKeyboardKey.backslash, meta: true),
    intent: ClearFormattingIntent(),
  );

  static const suggestEdits = MenuEntryWithIntent(
    'Suggest edits',
    icon: Symbols.rate_review,
    intent: SuggestEditsIntent(),
  );

  static const define = MenuEntryWithIntent(
    'Define',
    icon: Symbols.menu_book,
    shortcut: SingleActivator(LogicalKeyboardKey.keyY, meta: true, shift: true),
    intent: DefineIntent(),
  );

  static const insertTable = DimensionalPickerMenuEntry(
    'Insert table',
    intent: InsertTableIntent(1, 1),
  );

  static const checkList = MenuEntryWithIntent(
    'Checklist',
    icon: Symbols.checklist,
    shortcut: SingleActivator(LogicalKeyboardKey.digit9, meta: true, shift: true),
    intent: SetChecklistIntent(),
  );

  // Columns entries
  static const oneColumnTile = TileMenuEntry(
    '1 column',
    tileLines: [
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
      TileLineMenuEntry(0),
    ],
    intent: SetColumnsIntent.one(),
  );

  static const twoColumnTile = TileMenuEntry(
    '2 columns',
    tileLines: [
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
      TileLineMenuEntry(0, columns: 2),
    ],
    intent: SetColumnsIntent.two(),
  );

  static const threeColumnTile = TileMenuEntry(
    '3 columns',
    tileLines: [
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
      TileLineMenuEntry(0, columns: 3),
    ],
    intent: SetColumnsIntent.three(),
  );

  static const columnGroup = TileGroupMenuEntry(
    [Entry.oneColumnTile, Entry.twoColumnTile, Entry.threeColumnTile],
    size: Size(76, 82.0),
    columns: 3,
    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
  );

  // Bullet list

  static const formatBulletListOne = TileMenuEntry(
    'Bullet list: ●, ○, ◾',
    tileLines: [
      TileLineMenuEntry(1, prefix: '●'),
      TileLineMenuEntry(2, prefix: '○'),
      TileLineMenuEntry(2, prefix: '○'),
      TileLineMenuEntry(3, prefix: '◾'),
      TileLineMenuEntry(1, prefix: '●'),
    ],
    intent: FormatBulletedListIntent.circleOpenCircleSquare(),
  );

  static const formatBulletListTwo = TileMenuEntry(
    'Bullet list: ◆, ⮚, ◾',
    tileLines: [
      TileLineMenuEntry(1, prefix: '❖'),
      TileLineMenuEntry(2, prefix: '⮚'),
      TileLineMenuEntry(2, prefix: '⮚'),
      TileLineMenuEntry(3, prefix: '◾'),
      TileLineMenuEntry(1, prefix: '❖'),
    ],
    intent: FormatBulletedListIntent.diamondArrowSquare(),
  );

  static const formatBulletListThree = TileMenuEntry(
    'Bullet list: ☐, ☐, ☐',
    tileLines: [
      TileLineMenuEntry(1, prefix: '☐'),
      TileLineMenuEntry(2, prefix: '☐'),
      TileLineMenuEntry(2, prefix: '☐'),
      TileLineMenuEntry(3, prefix: '☐'),
      TileLineMenuEntry(1, prefix: '☐'),
    ],
    intent: FormatBulletedListIntent.square(),
  );

  static const formatBulletListFour = TileMenuEntry(
    'Bullet list: ➜, ◆, ◾',
    tileLines: [
      TileLineMenuEntry(1, prefix: '➜'),
      TileLineMenuEntry(2, prefix: '◆'),
      TileLineMenuEntry(2, prefix: '◆'),
      TileLineMenuEntry(3, prefix: '●'),
      TileLineMenuEntry(1, prefix: '➜'),
    ],
    intent: FormatBulletedListIntent.longArrowDiamondSquare(),
  );

  static const formatBulletListFive = TileMenuEntry(
    'Bullet list: ★, ○, ◾',
    tileLines: [
      TileLineMenuEntry(1, prefix: '★'),
      TileLineMenuEntry(2, prefix: '○'),
      TileLineMenuEntry(2, prefix: '○'),
      TileLineMenuEntry(3, prefix: '◾'),
      TileLineMenuEntry(1, prefix: '★'),
    ],
    intent: FormatBulletedListIntent.starOpenCircleSquare(),
  );

  static const formatBulletListSix = TileMenuEntry(
    'Bullet list: ⮚, ○, ◾',
    tileLines: [
      TileLineMenuEntry(1, prefix: '⮚'),
      TileLineMenuEntry(2, prefix: '○'),
      TileLineMenuEntry(2, prefix: '○'),
      TileLineMenuEntry(3, prefix: '◾'),
      TileLineMenuEntry(1, prefix: '⮚'),
    ],
    intent: FormatBulletedListIntent.openArrowOpenCircleSquare(),
  );

  static const bulletListTileGroup = TileGroupMenuEntry(
    [
      Entry.formatBulletListOne,
      Entry.formatBulletListTwo,
      Entry.formatBulletListThree,
      Entry.formatBulletListFour,
      Entry.formatBulletListFive,
      Entry.formatBulletListSix,
    ],
    size: Size(76, 82.0),
    columns: 3,
  );

  // Number list

  static const formatNumberListOne = TileMenuEntry(
    'Number list: 1., a., i.',
    tileLines: [
      TileLineMenuEntry(1, prefix: '1.'),
      TileLineMenuEntry(2, prefix: 'a.'),
      TileLineMenuEntry(2, prefix: 'b.'),
      TileLineMenuEntry(3, prefix: 'i.'),
      TileLineMenuEntry(1, prefix: '2.'),
    ],
    intent: FormatNumberedListIntent.numberLowerLowerRomanPeriod(),
  );

  static const formatNumberListTwo = TileMenuEntry(
    'Number list: 1), a), i)',
    tileLines: [
      TileLineMenuEntry(1, prefix: '1)'),
      TileLineMenuEntry(2, prefix: 'a)'),
      TileLineMenuEntry(2, prefix: 'b)'),
      TileLineMenuEntry(3, prefix: 'i)'),
      TileLineMenuEntry(1, prefix: '2)'),
    ],
    intent: FormatNumberedListIntent.numberLowerLowerRomanParenthesis(),
  );

  static const formatNumberListThree = TileMenuEntry(
    'Number list: 1., 1.1, 1.1.1',
    tileLines: [
      TileLineMenuEntry(1, prefix: '1'),
      TileLineMenuEntry(2, prefix: '1.1'),
      TileLineMenuEntry(2, prefix: '1.2'),
      TileLineMenuEntry(3, prefix: '1.2.1'),
      TileLineMenuEntry(1, prefix: '2'),
    ],
    intent: FormatNumberedListIntent.numberPeriod(),
  );

  static const formatNumberListFour = TileMenuEntry(
    'Number list: A., a., i.',
    tileLines: [
      TileLineMenuEntry(1, prefix: 'A.'),
      TileLineMenuEntry(2, prefix: 'a.'),
      TileLineMenuEntry(2, prefix: 'b.'),
      TileLineMenuEntry(3, prefix: 'i.'),
      TileLineMenuEntry(1, prefix: 'B.'),
    ],
    intent: FormatNumberedListIntent.upperLowerLowerRomanPeriod(),
  );

  static const formatNumberListFive = TileMenuEntry(
    'Number list: I., A., 1.',
    tileLines: [
      TileLineMenuEntry(1, prefix: 'I.'),
      TileLineMenuEntry(2, prefix: 'A.'),
      TileLineMenuEntry(2, prefix: 'B.'),
      TileLineMenuEntry(3, prefix: '1.'),
      TileLineMenuEntry(1, prefix: 'II.'),
    ],
    intent: FormatNumberedListIntent.upperRomanUpperNumberPeriod(),
  );

  static const formatNumberListSix = TileMenuEntry(
    'Number list: 01., a., i.',
    tileLines: [
      TileLineMenuEntry(1, prefix: '01.'),
      TileLineMenuEntry(2, prefix: 'a.'),
      TileLineMenuEntry(2, prefix: 'b.'),
      TileLineMenuEntry(3, prefix: 'i.'),
      TileLineMenuEntry(1, prefix: '02.'),
    ],
    intent: FormatNumberedListIntent.zeroPrefixedNumberLowerLowerRomanPeriod(),
  );

  static const numberListTileGroup = TileGroupMenuEntry(
    [
      Entry.formatNumberListOne,
      Entry.formatNumberListTwo,
      Entry.formatNumberListThree,
      Entry.formatNumberListFour,
      Entry.formatNumberListFive,
      Entry.formatNumberListSix,
    ],
    size: Size(76, 82.0),
    columns: 3,
  );

  // Checklist

  static const formatChecklistTwo = TileMenuEntry(
    'Do not strikethrough text when checked',
    tileLines: [
      TileLineMenuEntry(1, prefix: '☐'),
      TileLineMenuEntry(1, prefix: '☑'),
    ],
    intent: FormatChecklistIntent.normal(),
  );

  static const formatChecklistOne = TileMenuEntry(
    'Strikethrough text when checked',
    tileLines: [
      TileLineMenuEntry(1, prefix: '☐'),
      TileLineMenuEntry(1, prefix: '☑', strikeThrough: true),
    ],
    intent: FormatChecklistIntent.strikethrough(),
  );

  static const checkListTileGroup = TileGroupMenuEntry(
    [formatChecklistOne, formatChecklistTwo],
    size: Size(85.0, 50.0),
    columns: 2,
  );

  static const e_1 = MenuEntry('1', icon: Symbols.ac_unit);
  static const e_1_1 = MenuEntry('1.1', icon: Symbols.access_alarm);
  static const e_1_1_1 = MenuEntry('1.1.1', icon: Symbols.accessibility_new);
  static const e_1_2 = MenuEntry('1.2', icon: Symbols.access_time);
  static const e_1_2_1 = MenuEntry('1.2.1', icon: Symbols.account_balance);
  static const e_1_2_2 = MenuEntry('1.2.2', icon: Symbols.ad_units);
  static const e_1_3 = MenuEntry('1.3', icon: Symbols.accessibility);
  static const e_1_3_1 = MenuEntry('1.3.1', icon: Symbols.account_balance_wallet);
  static const e_1_3_2 = MenuEntry('1.3.2', icon: Symbols.account_balance);
  static const e_1_3_3 = MenuEntry('1.3.3', icon: Symbols.account_box);
  static const e_1_4 = MenuEntry('1.4', icon: Symbols.account_circle);
  static const e_1_4_1 = MenuEntry('1.4.1', icon: Symbols.account_tree);
  static const e_1_4_2 = MenuEntry('1.4.2', icon: Symbols.adb);
  static const e_2 = MenuEntry('2', icon: Symbols.access_alarm);
  static const e_2_1 = MenuEntry('2.1', icon: Symbols.accessibility_new);
  static const e_3 = MenuEntry('3', icon: Symbols.access_time);
  static const e_3_1 = MenuEntry('3.1', icon: Symbols.account_balance_wallet);
  static const e_4 = MenuEntry('4', icon: Symbols.accessibility);
  static const e_4_1 = MenuEntry('4.1', icon: Symbols.account_box);
  static const e_5 = MenuEntry('5', icon: Symbols.account_balance);
  static const e_5_1 = MenuEntry('5.1', icon: Symbols.account_circle);
  static const e_1_1_1_1 = MenuEntry('1.1.1.1', icon: Symbols.account_circle);
  static const e_1_1_1_2 = MenuEntry('1.1.1.2', icon: Symbols.account_tree);
  static const e_1_1_2 = MenuEntry('1.1.2', icon: Symbols.account_box);
  static const e_1_1_2_1 = MenuEntry('1.1.2.1', icon: Symbols.adb);
  static const e_1_1_2_2 = MenuEntry('1.1.2.2', icon: Symbols.add_box);
  static const e_1_2_1_1 = MenuEntry('1.2.1.1', icon: Symbols.add_comment);
  static const e_1_2_1_2 = MenuEntry('1.2.1.2', icon: Symbols.add_to_drive);
  static const e_1_3_3_1 = MenuEntry('1.3.3.1', icon: Symbols.add_alert);
  static const e_1_3_3_2 = MenuEntry('1.3.3.2', icon: Symbols.add_a_photo);
  static const e_2_1_1 = MenuEntry('2.1.1', icon: Symbols.add_alarm);
  static const e_2_1_2 = MenuEntry('2.1.2', icon: Symbols.add_business);
  static const e_3_1_1 = MenuEntry('3.1.1', icon: Symbols.add_card);
  static const e_3_1_2 = MenuEntry('3.1.2', icon: Symbols.add_chart);
  static const e_4_1_1 = MenuEntry('4.1.1', icon: Symbols.add_circle);
  static const e_4_1_2 = MenuEntry('4.1.2', icon: Symbols.add_circle_outline);
  static const e_5_1_1 = MenuEntry('5.1.1', icon: Symbols.add_home);
  static const e_5_1_2 = MenuEntry('5.1.2', icon: Symbols.add_link);
}
