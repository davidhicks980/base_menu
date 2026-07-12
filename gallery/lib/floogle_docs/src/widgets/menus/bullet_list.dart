import 'package:flutter/widgets.dart';

import '../../data/entry.dart';
import '../../data/menu.dart';
import '../adapters/menu_entry_segmented_popup_button.dart';

class BulletedListToolbarMenu extends StatelessWidget {
  const BulletedListToolbarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return const SegmentedPopupButton(entry: Menu.bulletList, child: Entry.bulletList);
  }
}
