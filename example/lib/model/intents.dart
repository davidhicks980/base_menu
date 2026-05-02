import 'package:flutter/widgets.dart';

import 'enum.dart';

sealed class FloogleIntent extends Intent {
  const FloogleIntent();
}

sealed class FloogleSelectableIntent<V> extends FloogleIntent {
  const FloogleSelectableIntent({required this.key, required this.value});
  final SelectionKey key;
  final V value;
}

abstract class FloogleSelectableBooleanIntent extends FloogleSelectableIntent<bool> {
  const FloogleSelectableBooleanIntent(SelectionKey key) : super(key: key, value: true);
}

class NewDocumentIntent extends FloogleIntent {
  const NewDocumentIntent();
}

class NewSpreadsheetIntent extends FloogleIntent {
  const NewSpreadsheetIntent();
}

class NewPresentationIntent extends FloogleIntent {
  const NewPresentationIntent();
}

class OpenFileIntent extends FloogleIntent {
  const OpenFileIntent();
}

class MakeCopyIntent extends FloogleIntent {
  const MakeCopyIntent();
}

class ShareWithPeopleIntent extends FloogleIntent {
  const ShareWithPeopleIntent();
}

class GetLinkIntent extends FloogleIntent {
  const GetLinkIntent();
}

class EmailFileIntent extends FloogleIntent {
  const EmailFileIntent();
}

class EmailCollaboratorsIntent extends FloogleIntent {
  const EmailCollaboratorsIntent();
}

class DownloadDocXIntent extends FloogleIntent {
  const DownloadDocXIntent();
}

class DownloadPdfIntent extends FloogleIntent {
  const DownloadPdfIntent();
}

class DownloadTextIntent extends FloogleIntent {
  const DownloadTextIntent();
}

class DownloadOdtIntent extends FloogleIntent {
  const DownloadOdtIntent();
}

class RenameFileIntent extends FloogleIntent {
  const RenameFileIntent();
}

class MoveFileIntent extends FloogleIntent {
  const MoveFileIntent();
}

class AddDriveShortcutIntent extends FloogleIntent {
  const AddDriveShortcutIntent();
}

class MoveToTrashIntent extends FloogleIntent {
  const MoveToTrashIntent();
}

class SeeVersionHistoryIntent extends FloogleIntent {
  const SeeVersionHistoryIntent();
}

class NameCurrentVersionIntent extends FloogleIntent {
  const NameCurrentVersionIntent();
}

class MakeAvailableOfflineIntent extends FloogleIntent {
  const MakeAvailableOfflineIntent();
}

class ViewDetailsIntent extends FloogleIntent {
  const ViewDetailsIntent();
}

class SetLanguageIntent extends FloogleIntent {
  const SetLanguageIntent();
}

class PageSetupIntent extends FloogleIntent {
  const PageSetupIntent();
}

class PrintIntent extends FloogleIntent {
  const PrintIntent();
}

// Edit Menu Intents
class UndoIntent extends FloogleIntent {
  const UndoIntent();
}

class RedoIntent extends FloogleIntent {
  const RedoIntent();
}

class CutIntent extends FloogleIntent {
  const CutIntent();
}

class CopyIntent extends FloogleIntent {
  const CopyIntent();
}

class CopyAsMarkdownIntent extends FloogleIntent {
  const CopyAsMarkdownIntent();
}

class PasteIntent extends FloogleIntent {
  const PasteIntent();
}

class PasteWithoutFormattingIntent extends FloogleIntent {
  const PasteWithoutFormattingIntent();
}

class PasteFromMarkdownIntent extends FloogleIntent {
  const PasteFromMarkdownIntent();
}

class SelectAllIntent extends FloogleIntent {
  const SelectAllIntent();
}

class DeleteIntent extends FloogleIntent {
  const DeleteIntent();
}

class FindAndReplaceIntent extends FloogleIntent {
  const FindAndReplaceIntent();
}

class SetViewingModeIntent extends FloogleSelectableIntent<ViewModeOption> {
  const SetViewingModeIntent.viewing() : super(key: .viewMode, value: .viewing);
  const SetViewingModeIntent.editing() : super(key: .viewMode, value: .editing);
  const SetViewingModeIntent.suggesting() : super(key: .viewMode, value: .suggesting);
}

class ViewResolvedCommentsIntent extends FloogleIntent {
  const ViewResolvedCommentsIntent();
}

class CollapseSidebarIntent extends FloogleIntent {
  const CollapseSidebarIntent();
}

class TogglePrintLayoutIntent extends FloogleSelectableBooleanIntent {
  const TogglePrintLayoutIntent() : super(.showPrintLayout);
}

class ToggleRulerIntent extends FloogleSelectableBooleanIntent {
  const ToggleRulerIntent() : super(.showRuler);
}

class ToggleEquationToolbarIntent extends FloogleSelectableBooleanIntent {
  const ToggleEquationToolbarIntent() : super(.showEquationToolbar);
}

class ToggleNonPrintingCharactersIntent extends FloogleSelectableBooleanIntent {
  const ToggleNonPrintingCharactersIntent() : super(.showNonPrintingCharacters);
}

class FullScreenIntent extends FloogleIntent {
  const FullScreenIntent();
}

// Insert Menu Intents
class InsertImageIntent extends FloogleIntent {
  const InsertImageIntent();
}

class InsertTableIntent extends FloogleIntent {
  const InsertTableIntent();
}

class InsertDrawingIntent extends FloogleIntent {
  const InsertDrawingIntent();
}

sealed class InsertChartIntent extends FloogleIntent {
  const InsertChartIntent();
}

class InsertBarChartIntent extends InsertChartIntent {
  const InsertBarChartIntent();
}

class InsertColumnChartIntent extends InsertChartIntent {
  const InsertColumnChartIntent();
}

class InsertLineChartIntent extends InsertChartIntent {
  const InsertLineChartIntent();
}

class InsertPieChartIntent extends InsertChartIntent {
  const InsertPieChartIntent();
}

class InsertLinkIntent extends FloogleIntent {
  const InsertLinkIntent();
}

class InsertTabIntent extends FloogleIntent {
  const InsertTabIntent();
}

class InsertHorizontalLineIntent extends FloogleIntent {
  const InsertHorizontalLineIntent();
}

class PageBreakIntent extends FloogleIntent {
  const PageBreakIntent();
}

class ColumnBreakIntent extends FloogleIntent {
  const ColumnBreakIntent();
}

class ContinuousSectionBreakIntent extends FloogleIntent {
  const ContinuousSectionBreakIntent();
}

class NextPageSectionBreakIntent extends FloogleIntent {
  const NextPageSectionBreakIntent();
}

class InsertBookmarkIntent extends FloogleIntent {
  const InsertBookmarkIntent();
}

class InsertHeaderIntent extends FloogleIntent {
  const InsertHeaderIntent();
}

class InsertFooterIntent extends FloogleIntent {
  const InsertFooterIntent();
}

class InsertFootnoteIntent extends FloogleIntent {
  const InsertFootnoteIntent();
}

class InsertPageNumberIntent extends FloogleIntent {
  const InsertPageNumberIntent();
}

class AddCommentIntent extends FloogleIntent {
  const AddCommentIntent();
}

class FormatBoldIntent extends FloogleSelectableBooleanIntent {
  const FormatBoldIntent() : super(.textFormatBold);
}

class FormatItalicIntent extends FloogleSelectableBooleanIntent {
  const FormatItalicIntent() : super(.textFormatItalic);
}

class FormatUnderlineIntent extends FloogleSelectableBooleanIntent {
  const FormatUnderlineIntent() : super(.textFormatUnderline);
}

class FormatStrikethroughIntent extends FloogleSelectableBooleanIntent {
  const FormatStrikethroughIntent() : super(.textFormatStrikethrough);
}

class FormatSuperscriptIntent extends FloogleSelectableBooleanIntent {
  const FormatSuperscriptIntent() : super(.textFormatSuperscript);
}

class FormatSubscriptIntent extends FloogleSelectableBooleanIntent {
  const FormatSubscriptIntent() : super(.textFormatSubscript);
}

class ApplyParagraphStyleIntent extends FloogleSelectableIntent<DocumentParagraphStyle> {
  const ApplyParagraphStyleIntent(DocumentParagraphStyle value)
    : super(key: SelectionKey.paragraphStyle, value: value);
}

class UpdateParagraphStyleToMatchIntent extends FloogleIntent {
  const UpdateParagraphStyleToMatchIntent(this.style);
  final DocumentParagraphStyle style;
}

class SetBlockAlignIntent extends FloogleSelectableIntent<TextAlign> {
  const SetBlockAlignIntent.left() : super(key: .textAlign, value: .left);
  const SetBlockAlignIntent.center() : super(key: .textAlign, value: .center);
  const SetBlockAlignIntent.right() : super(key: .textAlign, value: .right);
  const SetBlockAlignIntent.justify() : super(key: .textAlign, value: .justify);
}

class IncreaseIndentIntent extends FloogleIntent {
  const IncreaseIndentIntent();
}

class DecreaseIndentIntent extends FloogleIntent {
  const DecreaseIndentIntent();
}

class SetLineSpacingIntent extends FloogleSelectableIntent<double> {
  const SetLineSpacingIntent({required super.value}) : super(key: SelectionKey.lineHeight);
}

class CustomLineSpacingIntent extends FloogleIntent {
  const CustomLineSpacingIntent();
}

class AddSpaceBeforeParagraphIntent extends FloogleSelectableBooleanIntent {
  const AddSpaceBeforeParagraphIntent() : super(SelectionKey.addSpaceBeforeParagraph);
}

class KeepLinesTogetherIntent extends FloogleSelectableBooleanIntent {
  const KeepLinesTogetherIntent() : super(SelectionKey.keepLinesTogether);
}

class KeepWithNextIntent extends FloogleSelectableBooleanIntent {
  const KeepWithNextIntent() : super(SelectionKey.keepWithNext);
}

class PreventSingleLinesIntent extends FloogleSelectableBooleanIntent {
  const PreventSingleLinesIntent() : super(SelectionKey.preventSingleLines);
}

class AddSpaceAfterParagraphIntent extends FloogleSelectableBooleanIntent {
  const AddSpaceAfterParagraphIntent() : super(SelectionKey.addSpaceAfterParagraph);
}

class ClearFormattingIntent extends FloogleIntent {
  const ClearFormattingIntent();
}

// Tools Menu Intents
class CheckSpellingGrammarIntent extends FloogleSelectableBooleanIntent {
  const CheckSpellingGrammarIntent() : super(SelectionKey.spellingGrammarCheck);
}

class WordCountIntent extends FloogleIntent {
  const WordCountIntent();
}

class ReviewSuggestedEditsIntent extends FloogleIntent {
  const ReviewSuggestedEditsIntent();
}

class TranslateDocumentIntent extends FloogleIntent {
  const TranslateDocumentIntent();
}

class VoiceTypingIntent extends FloogleIntent {
  const VoiceTypingIntent();
}

class FindInDocumentIntent extends FloogleIntent {
  const FindInDocumentIntent();
}

// Help Menu Intents
class SearchMenusIntent extends FloogleIntent {
  const SearchMenusIntent();
}

class KeyboardShortcutsIntent extends FloogleIntent {
  const KeyboardShortcutsIntent();
}

// New intents for previously missing options
class InsertPageCountIntent extends FloogleIntent {
  const InsertPageCountIntent();
}

class SetBulletedListIntent extends FloogleSelectableBooleanIntent {
  const SetBulletedListIntent() : super(SelectionKey.bulletedList);
}

class SetNumberedListIntent extends FloogleSelectableBooleanIntent {
  const SetNumberedListIntent() : super(SelectionKey.numberedList);
}

class HeadersAndFootersIntent extends FloogleIntent {
  const HeadersAndFootersIntent();
}

class PageNumbersIntent extends FloogleIntent {
  const PageNumbersIntent();
}

class PageOrientationIntent extends FloogleIntent {
  const PageOrientationIntent();
}

class SwitchToPagelessIntent extends FloogleIntent {
  const SwitchToPagelessIntent();
}

class ToggleUnderlineErrorsIntent extends FloogleSelectableBooleanIntent {
  const ToggleUnderlineErrorsIntent() : super(SelectionKey.underlineErrors);
}

class ToggleSpellingSuggestionsIntent extends FloogleSelectableBooleanIntent {
  const ToggleSpellingSuggestionsIntent() : super(SelectionKey.spellingSuggestions);
}

class ToggleGrammarSuggestionsIntent extends FloogleSelectableBooleanIntent {
  const ToggleGrammarSuggestionsIntent() : super(SelectionKey.grammarSuggestions);
}

class CompareDocumentsIntent extends FloogleIntent {
  const CompareDocumentsIntent();
}

class CitationsIntent extends FloogleIntent {
  const CitationsIntent();
}

class LineNumbersIntent extends FloogleIntent {
  const LineNumbersIntent();
}

class LinkedObjectsIntent extends FloogleIntent {
  const LinkedObjectsIntent();
}

class DictionaryIntent extends FloogleIntent {
  const DictionaryIntent();
}

class NotificationSettingsIntent extends FloogleIntent {
  const NotificationSettingsIntent();
}

class PreferencesIntent extends FloogleIntent {
  const PreferencesIntent();
}

class AccessibilityIntent extends FloogleIntent {
  const AccessibilityIntent();
}

class GetAddOnsIntent extends FloogleIntent {
  const GetAddOnsIntent();
}

class ManageAddOnsIntent extends FloogleIntent {
  const ManageAddOnsIntent();
}

class AppsScriptIntent extends FloogleIntent {
  const AppsScriptIntent();
}

class HelpIntent extends FloogleIntent {
  const HelpIntent();
}

class TrainingIntent extends FloogleIntent {
  const TrainingIntent();
}

class UpdatesIntent extends FloogleIntent {
  const UpdatesIntent();
}

class HelpFloogleDocsImproveIntent extends FloogleIntent {
  const HelpFloogleDocsImproveIntent();
}

class PrivacyPolicyIntent extends FloogleIntent {
  const PrivacyPolicyIntent();
}

class TermsOfServiceIntent extends FloogleIntent {
  const TermsOfServiceIntent();
}

class MoreColumnsOptionsIntent extends FloogleIntent {
  const MoreColumnsOptionsIntent();
}

class SetColumnsIntent extends FloogleSelectableIntent<ColumnLayout> {
  const SetColumnsIntent.one() : super(key: .columns, value: .one);
  const SetColumnsIntent.two() : super(key: .columns, value: .two);
  const SetColumnsIntent.three() : super(key: .columns, value: .three);
}

class FormatNumberedListIntent extends FloogleSelectableIntent<NumberedListFormat> {
  const FormatNumberedListIntent.numberLowerLowerRomanPeriod()
    : super(key: .numberedListFormat, value: .numberLowerLowerRomanPeriod);
  const FormatNumberedListIntent.numberLowerLowerRomanParenthesis()
    : super(key: .numberedListFormat, value: .numberLowerLowerRomanParenthesis);
  const FormatNumberedListIntent.upperLowerLowerRomanPeriod()
    : super(key: .numberedListFormat, value: .upperLowerLowerRomanPeriod);
  const FormatNumberedListIntent.upperRomanUpperNumberPeriod()
    : super(key: .numberedListFormat, value: .upperRomanUpperNumberPeriod);
  const FormatNumberedListIntent.numberPeriod()
    : super(key: .numberedListFormat, value: .numberPeriod);
  const FormatNumberedListIntent.zeroPrefixedNumberLowerLowerRomanPeriod()
    : super(key: .numberedListFormat, value: .zeroPrefixedNumberLowerLowerRomanPeriod);
}

class FormatBulletedListIntent extends FloogleSelectableIntent<BulletedListFormat> {
  const FormatBulletedListIntent.circleOpenCircleSquare()
    : super(key: .bulletedListFormat, value: .circleOpenCircleSquare);
  const FormatBulletedListIntent.diamondArrowSquare()
    : super(key: .bulletedListFormat, value: .diamondArrowSquare);
  const FormatBulletedListIntent.square() : super(key: .bulletedListFormat, value: .square);
  const FormatBulletedListIntent.longArrowDiamondSquare()
    : super(key: .bulletedListFormat, value: .longArrowDiamondSquare);
  const FormatBulletedListIntent.starOpenCircleSquare()
    : super(key: .bulletedListFormat, value: .starOpenCircleSquare);
  const FormatBulletedListIntent.openArrowOpenCircleSquare()
    : super(key: .bulletedListFormat, value: .openArrowOpenCircleSquare);
}

class CommentIntent extends FloogleIntent {
  const CommentIntent();
}

class SuggestEditsIntent extends FloogleIntent {
  const SuggestEditsIntent();
}

class DefineIntent extends FloogleIntent {
  const DefineIntent();
}

class SelectAllMatchingTextIntent extends FloogleIntent {
  const SelectAllMatchingTextIntent();
}

class UpdateStyleToMatchIntent extends FloogleIntent {
  const UpdateStyleToMatchIntent();
}

class FormatIncrementFontSizeIntent extends Intent {
  const FormatIncrementFontSizeIntent();
}

class FormatDecrementFontSizeIntent extends Intent {
  const FormatDecrementFontSizeIntent();
}

class PaintFormatIntent extends FloogleSelectableBooleanIntent {
  const PaintFormatIntent() : super(SelectionKey.paintFormat);
}

class SetCommentVisibilityIntent extends FloogleSelectableIntent<CommentVisibility> {
  const SetCommentVisibilityIntent.hide() : super(key: .commentVisibility, value: .hide);
  const SetCommentVisibilityIntent.minimize() : super(key: .commentVisibility, value: .minimize);
  const SetCommentVisibilityIntent.expand() : super(key: .commentVisibility, value: .expand);
  const SetCommentVisibilityIntent.showAll() : super(key: .commentVisibility, value: .showAll);
}

class SetChecklistIntent extends FloogleIntent {
  const SetChecklistIntent();
}

class FormatChecklistIntent extends FloogleSelectableIntent<ChecklistType> {
  const FormatChecklistIntent.normal() : super(key: .checklistFormat, value: .normal);
  const FormatChecklistIntent.strikethrough() : super(key: .checklistFormat, value: .strikethrough);
}

// Intents with dynamic values

class FormatTextColorIntent extends FloogleSelectableIntent<Color> {
  const FormatTextColorIntent(Color color) : super(key: SelectionKey.textFormatColor, value: color);
}

class FormatTextHighlightIntent extends FloogleSelectableIntent<Color> {
  const FormatTextHighlightIntent(Color color)
    : super(key: SelectionKey.textFormatHighlight, value: color);
}

class SetZoomLevelIntent extends FloogleSelectableIntent<double> {
  const SetZoomLevelIntent(double zoomLevel)
    : assert(zoomLevel > 0.1 && zoomLevel <= 2.0),
      super(key: SelectionKey.zoomLevel, value: zoomLevel);
}

class FormatFontSizeIntent extends FloogleSelectableIntent<double> {
  const FormatFontSizeIntent(double fontSize)
    : assert(fontSize > 0 && fontSize <= 96),
      super(key: SelectionKey.fontSize, value: fontSize);
}

typedef FontFamilyWeightPair = ({FontFamily family, FontWeight weight});

class SetFontFamilyIntent extends FloogleSelectableIntent<FontFamilyWeightPair> {
  const SetFontFamilyIntent(FontFamilyWeightPair value)
    : super(key: SelectionKey.fontFamily, value: value);
}
