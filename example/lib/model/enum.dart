import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

enum ViewModeOption {
  editing('Editing', Symbols.edit),
  suggesting('Suggesting', Symbols.comment),
  viewing('Viewing', Symbols.visibility);

  const ViewModeOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ChecklistType { normal, strikethrough }

enum NumberedListFormat {
  numberLowerLowerRomanPeriod,
  numberLowerLowerRomanParenthesis,
  upperLowerLowerRomanPeriod,
  upperRomanUpperNumberPeriod,
  numberPeriod,
  zeroPrefixedNumberLowerLowerRomanPeriod,
}

enum BulletedListFormat {
  circleOpenCircleSquare,
  diamondArrowSquare,
  square,
  longArrowDiamondSquare,
  starOpenCircleSquare,
  openArrowOpenCircleSquare,
}

enum ColumnLayout { one, two, three }

enum SelectionKey {
  lineHeight,
  viewMode,
  spellingGrammarCheck,
  textFormatWeight,
  textFormatItalic,
  textFormatUnderline,
  textFormatStrikethrough,
  textFormatSuperscript,
  textFormatSubscript,
  textAlign,
  numberedList,
  numberedListFormat,
  bulletedList,
  bulletedListFormat,
  checklist,
  checklistFormat,
  listOptions,
  showSpellingSuggestions,
  showGrammarSuggestions,
  showPrintLayout,
  showRuler,
  showEquationToolbar,
  showNonPrintingCharacters,
  columns,
  addSpaceAfterParagraph,
  addSpaceBeforeParagraph,
  keepLinesTogether,
  keepWithNext,
  preventSingleLines,
  underlineErrors,
  spellingSuggestions,
  grammarSuggestions,
  commentVisibility,
  textFormatColor,
  textFormatHighlight,
  zoomLevel,
  fontSize,
  fontFamily,
  textFormatBold,
  paragraphStyle,
  paintFormat,
}

enum DocumentParagraphStyle {
  normal('Normal text'),
  title('Title'),
  subtitle('Subtitle'),
  heading1('Heading 1'),
  heading2('Heading 2'),
  heading3('Heading 3');

  const DocumentParagraphStyle(this.label);
  final String label;
}

enum CommentVisibility { showAll, hide, minimize, expand }

final fontWeightToLabelMap = {
  FontWeight.w100: 'Thin',
  FontWeight.w200: 'Extra Light',
  FontWeight.w300: 'Light',
  FontWeight.w400: 'Regular',
  FontWeight.w500: 'Medium',
  FontWeight.w600: 'Semi Bold',
  FontWeight.w700: 'Bold',
  FontWeight.w800: 'Extra Bold',
  FontWeight.w900: 'Black',
};

enum FontFamily {
  amaticSc('Amatic SC'),

  caveat('Caveat', [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]),
  comfortaa('Comfortaa', [FontWeight.w300, FontWeight.w400, FontWeight.w700]),
  courierNew('Courier New'),
  ebGaramond('EB Garamond', [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]),
  inter('Inter', [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  lato('Lato', [
    FontWeight.w100,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w700,
    FontWeight.w900,
  ]),
  lexend('Lexend', [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  lora('Lora', [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]),
  libreBaskerville('Libre Baskerville', [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ]),
  merriweather('Merriweather', [
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w700,
    FontWeight.w900,
  ]),
  montserrat('Montserrat', [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  nunito('Nunito', [
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  oswald('Oswald', [
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ]),
  pacifico('Pacifico'),
  playfairDisplay('Playfair Display', [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  raleway('Raleway', [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  roboto('Roboto', [
    FontWeight.w100,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w700,
    FontWeight.w900,
  ]),
  robotoMono('Roboto Mono', [
    FontWeight.w100,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w700,
  ]),
  robotoSerif('Roboto Serif', [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  robotoSlab('Roboto Slab', [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]),
  sourceSansPro('Source Sans 3', [
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w900,
  ]),
  ubuntu('Ubuntu', [FontWeight.w300, FontWeight.w400, FontWeight.w500, FontWeight.w700]);

  const FontFamily(this.label, [this.variants = const []]);
  final String label;
  final List<FontWeight> variants;
}
