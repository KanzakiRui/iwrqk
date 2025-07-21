import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iwrqk/i18n/strings.g.dart';

import 'controller.dart';

class EditPostBottomSheet extends GetWidget<EditPostBottomSheetController> {
  final String? threadId;
  final bool isEdit;
  final String? editId;
  final String? editInitialContent;
  final void Function(String)? onChanged;

  const EditPostBottomSheet({
    super.key,
    this.threadId,
    this.isEdit = false,
    this.editId,
    this.editInitialContent,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    controller.contentController.text = editInitialContent ?? '';
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: EdgeInsets.only(
        bottom: Get.mediaQuery.padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(
              maxHeight: 200,
              minHeight: 120,
            ),
            padding:
                const EdgeInsets.only(top: 12, right: 16, left: 16, bottom: 12),
            child: TextField(
              focusNode: controller.contentFocusNode,
              controller: controller.contentController,
              minLines: 1,
              maxLines: null,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: t.comment.reply,
                border: InputBorder.none,
              ),
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    FocusScope.of(context)
                        .requestFocus(controller.contentFocusNode);
                  },
                  icon: const Icon(Icons.keyboard),
                ),
                TextButton(
                  onPressed: () => controller.editPost(
                    threadId: threadId,
                    isEdit: isEdit,
                    editId: editId,
                    onChanged: onChanged,
                  ),
                  child: Text(t.comment.reply),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
