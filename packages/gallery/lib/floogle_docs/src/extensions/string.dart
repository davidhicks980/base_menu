extension StringExtensions on String {
  String get withSpaceAfterCapitals {
    final result = StringBuffer();
    final it = runes.iterator;
    var wasLowercase = false;
    while (it.moveNext()) {
      final current = it.current;
      switch (current) {
        case >= 65 && <= 90:
          if (wasLowercase) {
            result.write(' ');
          }

          wasLowercase = false;
        case >= 97 && <= 122:
          wasLowercase = true;
        default:
          wasLowercase = false;
      }

      result.writeCharCode(current);
    }

    return result.toString();
  }
}
