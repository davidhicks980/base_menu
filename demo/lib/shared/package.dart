const String? kPackage = bool.hasEnvironment('FONT_PACKAGE')
    ? String.fromEnvironment('FONT_PACKAGE', defaultValue: 'base_menu_demo')
    : null;
