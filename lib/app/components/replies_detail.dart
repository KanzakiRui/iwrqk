import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:iwrqk/i18n/strings.g.dart';

import '../data/enums/types.dart';
import '../data/models/comment.dart';
import '../data/services/user_service.dart';
import 'comments_list/controller.dart';
import 'comments_list/widget.dart';
import 'edit_comment_bottom_sheet/widget.dart';
import 'user_comment.dart';

class RepliesDetail extends StatefulWidget {
  final String uploaderUserName;
  final CommentModel parentComment;
  final String sourceId;
  final bool showInPage;
  final CommentsSourceType sourceType;

  const RepliesDetail({
    super.key,
    required this.uploaderUserName,
    required this.parentComment,
    required this.sourceId,
    this.showInPage = false,
    required this.sourceType,
  });

  @override
  State<RepliesDetail> createState() => _RepliesDetailState();
}

class _RepliesDetailState extends State<RepliesDetail>
    with TickerProviderStateMixin {
  final UserService userService = Get.find();
  bool _isFabVisible = true;
  final ScrollController scrollController = ScrollController();
  late AnimationController fabAnimationController;

  late String commentsListTag =
      "replies_detail_${widget.parentComment.id}_${DateTime.now().millisecondsSinceEpoch}";

  late CommentModel parentComment;

  @override
  void initState() {
    super.initState();

    Get.lazyPut(() => CommentsListController(), tag: commentsListTag);

    parentComment = widget.parentComment;

    fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fabAnimationController.forward();

    scrollController.addListener(() {
      final ScrollDirection direction =
          scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.forward) {
        if (!_isFabVisible) {
          _isFabVisible = true;
          fabAnimationController.forward();
        }
      } else if (direction == ScrollDirection.reverse) {
        if (_isFabVisible) {
          _isFabVisible = false;
          fabAnimationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(() {});
    fabAnimationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget fab = SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 2),
        end: const Offset(0, 0),
      ).animate(CurvedAnimation(
        parent: fabAnimationController,
        curve: Curves.easeInOut,
      )),
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: EditCommentBottomSheet(
                sourceId: widget.sourceId,
                sourceType: widget.sourceType,
                parentId: widget.parentComment.id,
                onChanged: (_) {
                  CommentsListController controller =
                      Get.find(tag: commentsListTag);
                  controller.updateAfterSend();
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.reply),
      ),
    );

    if (widget.showInPage) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.comment.comment_detail),
        ),
        floatingActionButton: fab,
        body: CommentsList(
          tag: commentsListTag,
          scrollController: scrollController,
          uploaderUserName: widget.uploaderUserName,
          sourceType: widget.sourceType,
          sourceId: widget.sourceId,
          parentId: widget.parentComment.id,
          canJumpToDetail: false,
          paginated: false,
          parentComment: UserComment(
            uploaderUserName: widget.uploaderUserName,
            comment: parentComment,
            showReplies: false,
            canJumpToDetail: false,
            showDivider: false,
            isMyComment: userService.user?.id == widget.uploaderUserName,
            onUpdated: (Map data) {
              if (data["state"] == "delete") {
                Get.back();
              } else if (data["state"] == "edit") {
                parentComment.body = data["content"];
                setState(() {});
              }
            },
          ),
        ),
      );
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        height: Get.height - Get.width / 16 * 9 - Get.mediaQuery.padding.top,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 46,
                  padding: const EdgeInsets.only(left: 12, right: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.comment.comment_detail),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CommentsList(
                    tag: commentsListTag,
                    scrollController: scrollController,
                    uploaderUserName: widget.uploaderUserName,
                    sourceType: widget.sourceType,
                    sourceId: widget.sourceId,
                    parentId: widget.parentComment.id,
                    canJumpToDetail: false,
                    paginated: false,
                    parentComment: UserComment(
                      uploaderUserName: widget.uploaderUserName,
                      comment: parentComment,
                      showReplies: false,
                      canJumpToDetail: false,
                      showDivider: false,
                      isMyComment:
                          userService.user?.id == widget.uploaderUserName,
                      onUpdated: (Map data) {
                        if (data["state"] == "delete") {
                          Get.back();
                        } else if (data["state"] == "edit") {
                          parentComment.body = data["content"];
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: Get.mediaQuery.padding.bottom + 16,
              right: 14,
              child: fab,
            ),
          ],
        ),
      );
    }
  }
}
