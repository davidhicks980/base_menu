import 'package:flutter/widgets.dart';

import '../../data/entry.dart';
import '../../data/menu.dart';
import '../adapters/menu_entry_segmented_popup_button.dart';

class ChecklistToolbarMenu extends StatelessWidget {
  const ChecklistToolbarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return const SegmentedPopupButton(entry: Menu.checkList, child: Entry.checkList);
  }
}
