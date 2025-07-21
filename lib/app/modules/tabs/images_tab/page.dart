import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/enums/types.dart';
import '../media_grid_tab/page.dart';
import 'controller.dart';

class ImagesTabPage extends GetView<ImagesTabController> {
  final String tabTag;

  const ImagesTabPage({
    super.key,
    required this.tabTag,
  });

  @override
  Widget build(BuildContext context) {
    controller.init(tabTag);
    return MediaGridTabPage(
      tag: controller.tag,
      tabNameList: controller.tabNameList,
      tabTagList: controller.tabTagList,
      sourceType: MediaSourceType.images,
      orderTypeList: controller.orderTypeList,
    );
  }
}
