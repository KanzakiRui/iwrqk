import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:iwrqk/i18n/strings.g.dart';

import '../../../../components/iwr_markdown.dart';
import '../../../../components/network_image.dart';
import '../../../../components/translated_content.dart';
import '../../../../data/models/forum/post.dart';
import '../../../../data/providers/translate_provider.dart';
import '../../../../data/services/user_service.dart';
import '../../../../utils/display_util.dart';
import 'edit_post_bottom_sheet/widget.dart';

class Post extends StatefulWidget {
  final PostModel post;
  final int index;
  final bool showDivider;
  final String starterUserName;
  final bool isMyComment;
  final void Function(Map)? onUpdated;

  const Post({
    super.key,
    required this.post,
    required this.index,
    this.showDivider = true,
    required this.starterUserName,
    this.isMyComment = false,
    this.onUpdated,
  });

  @override
  State<StatefulWidget> createState() => _PostState();
}

class _PostState extends State<Post> with AutomaticKeepAliveClientMixin {
  String? translatedContent;

  Widget _buildStarterBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "OP",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUserWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed("/profile?userName=${widget.post.user.username}");
      },
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: NetworkImg(
                    imageUrl: widget.post.user.avatarUrl,
                    width: 40,
                    height: 40,
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      widget.post.user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                if (widget.starterUserName == widget.post.user.username)
                  _buildStarterBadge(context)
              ],
            ),
          ),
          PopupMenuButton(
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            icon: Icon(
              Icons.more_horiz,
              color: Theme.of(context).colorScheme.outline,
            ),
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: "translate",
                  onTap: _getTranslatedContent,
                  child: Text(
                    t.common.translate,
                  ),
                ),
                if (widget.isMyComment) ...[
                  PopupMenuItem<String>(
                    value: "edit",
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: EditPostBottomSheet(
                            isEdit: true,
                            editId: widget.post.id,
                            editInitialContent: widget.post.body,
                            onChanged: (String content) => widget.onUpdated
                                ?.call({"state": "edit", "content": content}),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      t.comment.edit_comment,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: "delete",
                    onTap: () {
                      final UserService userService = Get.find();
                      userService.deletePost(
                        id: widget.post.id,
                      );
                      widget.onUpdated?.call({"state": "delete"});
                    },
                    child: Text(
                      t.comment.delete_comment,
                    ),
                  ),
                ]
              ];
            },
          ),
        ],
      ),
    );
  }

  void _getTranslatedContent() async {
    if (translatedContent != null) return;

    TranslateProvider.google(
      text: widget.post.body,
    ).then((value) {
      if (value.success) {
        setState(() {
          translatedContent = value.data;
        });
      } else {
        SmartDialog.showToast(value.message!);
      }
    });
  }

  Widget _buildBottomWidget(BuildContext context) {
    String text =
        DisplayUtil.getDisplayTime(DateTime.parse(widget.post.createAt));
    if (widget.post.createAt != widget.post.updateAt) {
      text +=
          "\n${t.media.updated_at(time: DisplayUtil.getDisplayTime(DateTime.parse(widget.post.updateAt)))}";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "#${widget.index} ",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IwrMarkdown(
            selectable: true,
            data: widget.post.body,
          ),
          if (translatedContent != null)
            TranslatedContent(
              padding: const EdgeInsets.only(top: 12),
              translatedContent: translatedContent!,
            ),
          _buildBottomWidget(context),
          if (widget.showDivider) const SizedBox(height: 12),
          if (widget.showDivider) const Divider(height: 0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildUserWidget(context), _buildContent(context)],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
