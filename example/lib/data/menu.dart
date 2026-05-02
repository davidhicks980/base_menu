import 'package:material_symbols_icons/symbols.dart';

import '../model/model.dart';
import 'entry.dart';

abstract class _SubmenuLabel {
  static const spellingAndGrammar = MenuEntry('Spelling and grammar', icon: Symbols.spellcheck);
  static const addOns = MenuEntry('Add-ons', icon: Symbols.extension);
  static const extensions = MenuEntry('Extensions', icon: Symbols.extension);
  static const help = MenuEntry('Help');
  static const file = MenuEntry('File');
  static const edit = MenuEntry('Edit');
  static const comments = MenuEntry('Comments', icon: Symbols.comment);
  static const view = MenuEntry('View');
  static const format = MenuEntry('Format');
  static const insert = MenuEntry('Insert');
  static const tools = MenuEntry('Tools');
  static const formatContext = MenuEntry('Format options', icon: Symbols.text_fields);
  static const column = MenuEntry('Columns', icon: Symbols.view_column);
  static const pageElements = MenuEntry('Page elements', icon: Symbols.web_asset);
  static const text = MenuEntry('Text', icon: Symbols.text_fields);
  static const alignIndent = MenuEntry('Align & indent', icon: Symbols.format_align_left);
  static const pageBreak = MenuEntry('Break', icon: Symbols.insert_page_break);
  static const chart = MenuEntry('Chart', icon: Symbols.pie_chart_outline);
  static const drawing = MenuEntry('Drawing', icon: Symbols.brush);
  static const table = MenuEntry('Table', icon: Symbols.table_chart);
  static const image = MenuEntry('Image', icon: Symbols.image);
  static const bulletList = MenuEntry('Bulleted list menu', icon: Symbols.format_list_bulleted);
  static const checkList = MenuEntry('Checklist menu', icon: Symbols.checklist);
  static const numberList = MenuEntry('Numbered list menu', icon: Symbols.format_list_numbered);
  static const viewMode = MenuEntry('Mode', icon: Symbols.remove_red_eye);
  static const paragraphStyles = MenuEntry('Paragraph styles', icon: Symbols.format_align_left);
  static const language = MenuEntry('Language', icon: Symbols.language);
  static const versionHistory = MenuEntry('Version history', icon: Symbols.history);
  static const download = MenuEntry('Download', icon: Symbols.download);
  static const email = MenuEntry('Email', icon: Symbols.email);
  static const newDocument = MenuEntry(
    'New',
    icon: Symbols.article,
    iconConfig: IconConfiguration(fill: 1),
  );
  static const share = MenuEntry('Share', icon: Symbols.share);
  static const main = MenuEntry('Main menu');
  static const context = MenuEntry('Context menu');
  static const bulletsAndNumbering = MenuEntry(
    'Bullets & numbering',
    icon: Symbols.format_list_bulleted,
  );

  static const lineAndParagraphSpacing = MenuEntry(
    'Line & paragraph spacing',
    icon: Symbols.format_line_spacing,
  );

  static const textAlignment = MenuEntry('Text alignment', icon: Symbols.format_align_left);
}

abstract class Menu {
  static const addOns = SubmenuEntry(_SubmenuLabel.addOns, [Entry.getAddOns, Entry.manageAddOns]);
  static const extensions = SubmenuEntry(_SubmenuLabel.extensions, [addOns]);
  static const help = SubmenuEntry(_SubmenuLabel.help, [
    Entry.searchMenus,
    SeparatorMenuEntry(),
    Entry.help,
    Entry.training,
    Entry.updates,
    SeparatorMenuEntry(),
    Entry.helpFloogleDocsImprove,
    SeparatorMenuEntry(),
    Entry.privacyPolicy,
    Entry.termsOfService,
    SeparatorMenuEntry(),
    Entry.keyboardShortcuts,
  ]);

  static const file = SubmenuEntry(_SubmenuLabel.file, [
    _SubmenuLabel.newDocument,
    Entry.openFile,
    Entry.makeCopy,
    SeparatorMenuEntry(),
    _SubmenuLabel.share,
    _SubmenuLabel.email,
    _SubmenuLabel.download,
    SeparatorMenuEntry(),
    Entry.renameFile,
    Entry.moveFile,
    Entry.addDriveShortcut,
    Entry.moveToTrash,
    SeparatorMenuEntry(),
    _SubmenuLabel.versionHistory,
    Entry.makeAvailableOffline,
    SeparatorMenuEntry(),
    Entry.viewDetails,
    _SubmenuLabel.language,
    Entry.pageSetup,
    Entry.print,
  ]);
  static const edit = SubmenuEntry(_SubmenuLabel.edit, [
    Entry.undo,
    Entry.redo,
    SeparatorMenuEntry(),
    Entry.cut,
    Entry.copy,
    Entry.copyAsMarkdown,
    Entry.paste,
    Entry.pasteWithoutFormatting,
    Entry.pasteFromMarkdown,
    SeparatorMenuEntry(),
    Entry.selectAll,
    Entry.delete,
    Entry.findAndReplace,
  ]);

  static const comments = SubmenuEntry(_SubmenuLabel.comments, [
    Entry.hideComments,
    Entry.minimizeComments,
    Entry.expandComments,
    SeparatorMenuEntry(),
    Entry.showAllComments,
  ]);

  static const view = SubmenuEntry(_SubmenuLabel.view, [
    viewMode,
    comments,
    Entry.collapseSidebar,
    SeparatorMenuEntry(),
    Entry.showPrintLayout,
    Entry.showRuler,
    Entry.showEquationToolbar,
    Entry.showNonPrintingCharacters,
    SeparatorMenuEntry(),
    Entry.fullScreen,
  ]);

  static const insert = SubmenuEntry(_SubmenuLabel.insert, [
    image,
    table,
    drawing,
    chart,
    Entry.insertLinkMenu,
    SeparatorMenuEntry(),
    Entry.insertTab,
    Entry.horizontalLine,
    pageBreak,
    Entry.bookmark,
    pageElements,
    SeparatorMenuEntry(),
    Entry.addComment,
  ]);

  static const format = SubmenuEntry(_SubmenuLabel.format, [
    textFormat,
    paragraphStyles,
    alignIndent,
    lineAndParagraphSpacing,
    column,
    bulletsAndNumbering,
    SeparatorMenuEntry(),
    Entry.headersAndFooters,
    Entry.pageNumbers,
    Entry.pageOrientation,
    Entry.switchToPageless,
    SeparatorMenuEntry(),
    Entry.clearFormatting,
  ]);

  static const tools = SubmenuEntry(_SubmenuLabel.tools, [
    _SubmenuLabel.spellingAndGrammar,
    Entry.wordCount,
    Entry.reviewSuggestedEdits,
    Entry.compareDocuments,
    Entry.citations,
    Entry.lineNumbers,
    Entry.linkedObjects,
    Entry.dictionary,
    SeparatorMenuEntry(),
    Entry.translateDocument,
    Entry.voiceTyping,
    SeparatorMenuEntry(),
    Entry.notificationSettings,
    Entry.preferences,
    Entry.accessibility,
  ]);

  static const formatOptions = SubmenuEntry(_SubmenuLabel.formatContext, [
    textFormat,
    alignIndent,
    lineAndParagraphSpacing,
  ]);
  static const spellingAndGrammar = SubmenuEntry(_SubmenuLabel.spellingAndGrammar, [
    Entry.spellingAndGrammarOption,
    Entry.showSpellingSuggestions,
    Entry.showGrammarSuggestions,
    Entry.underlineErrors,
  ]);

  static const bulletsAndNumbering = SubmenuEntry(_SubmenuLabel.bulletsAndNumbering, [
    bulletList,
    numberList,
  ]);

  static const column = SubmenuEntry(_SubmenuLabel.column, [
    Entry.columnGroup,
    SeparatorMenuEntry(),
    Entry.moreColumnsOptions,
  ]);

  static const pageElements = SubmenuEntry(_SubmenuLabel.pageElements, [
    Entry.header,
    Entry.footer,
    Entry.footnote,
    Entry.pageNumber,
    Entry.pageCount,
  ]);

  // Format menu entries
  static const textFormat = SubmenuEntry(_SubmenuLabel.text, [
    Entry.boldFormat,
    Entry.italicFormat,
    Entry.underlineFormat,
    Entry.strikethroughFormat,
    Entry.superscriptFormat,
    Entry.subscriptFormat,
  ]);

  static const alignIndent = SubmenuEntry(_SubmenuLabel.alignIndent, [
    Entry.alignLeft,
    Entry.alignCenter,
    Entry.alignRight,
    Entry.alignJustified,
    Entry.increaseIndent,
    Entry.decreaseIndent,
  ]);

  static const pageBreak = SubmenuEntry(_SubmenuLabel.pageBreak, [
    Entry.pageBreak,
    Entry.columnBreak,
    Entry.continuousSectionBreak,
    Entry.nextPageSectionBreak,
  ]);

  static const chart = SubmenuEntry(_SubmenuLabel.chart, [
    Entry.barChart,
    Entry.columnChart,
    Entry.lineChart,
    Entry.pieChart,
  ]);

  static const drawing = SubmenuEntry(_SubmenuLabel.drawing, [
    Entry.newDrawing,
    Entry.driveDrawing,
  ]);

  static const table = SubmenuEntry(_SubmenuLabel.table, [Entry.insertTable]);

  static const image = SubmenuEntry(_SubmenuLabel.image, [
    Entry.uploadImage,
    Entry.searchImage,
    SeparatorMenuEntry(),
    Entry.driveImage,
    Entry.photosImage,
    Entry.urlImage,
    Entry.cameraImage,
  ]);

  static const bulletList = SubmenuEntry(_SubmenuLabel.bulletList, [Entry.bulletListTileGroup]);

  static const checkList = SubmenuEntry(_SubmenuLabel.checkList, [Entry.checkListTileGroup]);

  static const numberList = SubmenuEntry(_SubmenuLabel.numberList, [Entry.numberListTileGroup]);

  static const align = SubmenuEntry(_SubmenuLabel.textAlignment, [
    Entry.alignLeft,
    Entry.alignCenter,
    Entry.alignRight,
    Entry.alignJustified,
  ]);

  static const viewMode = SubmenuEntry(_SubmenuLabel.viewMode, [
    Entry.editingMode,
    Entry.suggestingMode,
    Entry.viewingMode,
  ]);

  static const lineAndParagraphSpacing =
      SubmenuEntry(_SubmenuLabel.lineAndParagraphSpacing, <BaseMenuEntry>[
        Entry.lineHeightSingle,
        Entry.lineHeightOnePointOneFive,
        Entry.lineHeightOnePointFive,
        Entry.lineHeightDouble,
        SeparatorMenuEntry(),
        Entry.addSpaceBeforeParagraph,
        Entry.addSpaceAfterParagraph,
        SeparatorMenuEntry(),
        Entry.keepLinesTogether,
        Entry.keepWithNext,
        Entry.preventSingleLines,
      ]);

  static const paragraphStyles = SubmenuEntry(_SubmenuLabel.paragraphStyles, [
    Entry.paragraphStyleNormalText,
    Entry.paragraphStyleTitle,
    Entry.paragraphStyleSubtitle,
    Entry.paragraphStyleHeading1,
    Entry.paragraphStyleHeading2,
    Entry.paragraphStyleHeading3,
  ]);

  static const language = SubmenuEntry(_SubmenuLabel.language, [Entry.setLanguage]);

  static const versionHistory = SubmenuEntry(_SubmenuLabel.versionHistory, [
    Entry.seeVersionHistory,
    Entry.nameCurrentVersion,
  ]);

  static const download = SubmenuEntry(_SubmenuLabel.download, [
    Entry.downloadDocX,
    Entry.downloadPdf,
    Entry.downloadText,
    Entry.downloadOdt,
  ]);

  static const email = SubmenuEntry(_SubmenuLabel.email, [
    Entry.emailThisFile,
    Entry.emailCollaborators,
  ]);

  static const newDocument = SubmenuEntry(_SubmenuLabel.newDocument, [
    Entry.newDocument,
    Entry.newSpreadsheet,
    Entry.newPresentation,
  ]);

  static const share = SubmenuEntry(_SubmenuLabel.share, [Entry.shareWithPeople, Entry.getLink]);

  static const main = SubmenuEntry<SubmenuEntry>(_SubmenuLabel.main, <SubmenuEntry>[
    file,
    edit,
    view,
    insert,
    format,
    tools,
    extensions,
    help,
  ]);

  static const context = SubmenuEntry(_SubmenuLabel.context, [
    Entry.cut,
    Entry.copy,
    Entry.copyAsMarkdown,
    Entry.paste,
    Entry.pasteWithoutFormatting,
    Entry.pasteFromMarkdown,
    Entry.delete,
    SeparatorMenuEntry(),
    Entry.addComment,
    Entry.suggestEdits,
    SeparatorMenuEntry(),
    Entry.insertLink,
    SeparatorMenuEntry(),
    Entry.define,
    SeparatorMenuEntry(),
    Menu.formatOptions,
    Entry.clearFormatting,
  ]);
}
