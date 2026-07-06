const String? kPackage = bool.hasEnvironment('FONT_PACKAGE')
    ? String.fromEnvironment('FONT_PACKAGE', defaultValue: 'example')
    : null;
