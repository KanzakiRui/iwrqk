import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:iwrqk/i18n/strings.g.dart';

import '../../../../components/network_image.dart';
import '../../../../data/enums/types.dart';
import '../../../../data/models/download_task.dart';
import '../../../../data/models/media/video.dart';
import '../../../../data/models/offline/download_task_media.dart';
import '../../../../data/services/download_service.dart';
import '../../../../utils/display_util.dart';
import '../controller.dart';

class DownloadMediaPreview extends StatelessWidget {
  final DownloadsController? downloadsController;
  final bool checked;

  final MediaDownloadTask taskData;
  final bool isPlaying;
  final bool isPlaylist;
  final void Function()? onTap;
  final void Function()? gotoPlayer;
  final void Function()? gotoDetail;
  final void Function()? onLongPress;
  final void Function()? onDoubleTap;

  DownloadMediaPreview({
    super.key,
    this.downloadsController,
    this.checked = false,
    required this.taskData,
    this.isPlaying = false,
    this.isPlaylist = false,
    this.onTap,
    this.gotoPlayer,
    this.gotoDetail,
    this.onLongPress,
    this.onDoubleTap,
  });

  final DownloadService _downloadService = Get.find();

  DownloadTaskMediaModel get media => taskData.offlineMedia;

  String get taskId => taskData.taskId;

  Widget _buildStateMessageWithProgress(
      BuildContext context, String message, double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: AutoSizeText(
            message,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.outline,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        LinearProgressIndicator(value: progress)
      ],
    );
  }

  Widget _buildCompleteWidget(BuildContext context) {
    String totalSize = DisplayUtil.getDisplayFileSizeWithUnit(media.size);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2, right: 2),
                      child: Text(
                        media.uploader.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        if (isPlaylist) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalSize,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.outline,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 20,
                width: 20,
                child: PopupMenuButton(
                  padding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  icon: Icon(
                    Icons.more_horiz,
                    color: Theme.of(context).colorScheme.outline,
                    size: 20,
                  ),
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: "toMediaDetail",
                        onTap: gotoDetail,
                        child: Text(
                          t.download.jump_to_detail,
                        ),
                      ),
                    ];
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.download,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 2),
                  child: Text(
                    DisplayUtil.getDisplayDate(taskData.createTime),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.outline,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              AutoSizeText(
                totalSize,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.outline,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStateWidget(BuildContext context) {
    final taskStatus = _downloadService.downloadTasksStatus[taskId];

    return Obx(() {
      if (taskStatus != null) {
        int downloadedSize = media.size * taskStatus.value.progress ~/ 100;
        int totalSize = media.size;
        switch (taskStatus.value.status) {
          case DownloadTaskStatus.enqueued:
            return _buildStateMessageWithProgress(
              context,
              t.download.enqueued,
              0,
            );
          case DownloadTaskStatus.running:
            return _buildStateMessageWithProgress(
              context,
              "${t.download.downloading} ${DisplayUtil.getDownloadFileSizeProgress(downloadedSize, totalSize)}",
              taskStatus.value.progress / 100,
            );
          case DownloadTaskStatus.paused:
            return _buildStateMessageWithProgress(
              context,
              "${t.download.paused} ${DisplayUtil.getDownloadFileSizeProgress(downloadedSize, totalSize)}",
              taskStatus.value.progress / 100,
            );
          case DownloadTaskStatus.failed:
            return _buildStateMessageWithProgress(
              context,
              t.download.failed,
              0,
            );
          default:
            return AutoSizeText(
              t.download.unknown,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.red,
                overflow: TextOverflow.ellipsis,
              ),
            );
        }
      } else {
        return AutoSizeText(
          t.download.unknown,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.red,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    });
  }

  Widget _buildBottomBadges(BuildContext context) {
    Duration? duration;

    if ((media is VideoModel)) {
      int? seconds = (media as VideoModel).file?.duration;
      if (seconds != null) duration = Duration(seconds: seconds);
    }

    return Row(
      mainAxisAlignment: media.ratingType == RatingType.ecchi.value
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: [
        if (media.ratingType == RatingType.ecchi.value)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.red.withAlpha(160),
            ),
            child: const Center(
                child: Text(
              "R-18",
              style: TextStyle(fontSize: 12, color: Colors.white),
            )),
          ),
        if (duration != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.black.withAlpha(126),
            ),
            child: Text(
              "${duration.inMinutes}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.black.withAlpha(126),
      ),
      child: Row(
        children: [
          const Icon(Icons.hd, size: 16, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            (taskData as VideoDownloadTask).resolutionName,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: media.coverUrl != null
                  ? NetworkImg(
                      imageUrl: media.coverUrl!,
                      aspectRatio: 16 / 9,
                      fit: BoxFit.cover,
                      isAdult: media.ratingType == RatingType.ecchi.value,
                    )
                  : const AspectRatio(aspectRatio: 16 / 9),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 6,
            left: 6,
            child: _buildBottomBadges(context),
          ),
          Positioned(
            top: 4,
            right: 6,
            child: _buildTopBadge(context),
          ),
          if (downloadsController != null) ...[
            Obx(
              () => Positioned.fill(
                child: AnimatedOpacity(
                  opacity: downloadsController!.enableMultipleSelection ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withValues(
                          alpha: downloadsController!.enableMultipleSelection &&
                                  checked
                              ? 0.6
                              : 0),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: AnimatedScale(
                          scale: checked ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: (Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.white
                                      : Colors.black)
                                  .withValues(alpha: 0.8),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskStatus = _downloadService.downloadTasksStatus[taskId];

    Widget left = Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AutoSizeText(
              media.title,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
                color: isPlaying ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
          if (!isPlaylist) ...[
            (taskStatus?.value.status) == DownloadTaskStatus.complete
                ? _buildCompleteWidget(context)
                : _buildStateWidget(context),
          ] else ...[
            _buildCompleteWidget(context)
          ]
        ],
      ),
    );

    return InkWell(
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      onTap: onTap ?? gotoPlayer,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 116),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: Get.mediaQuery.orientation == Orientation.portrait
              ? [
                  Flexible(
                    flex: 5,
                    child: _buildCover(context),
                  ),
                  Flexible(flex: 6, child: left)
                ]
              : [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 168),
                    child: _buildCover(context),
                  ),
                  Expanded(child: left),
                ],
        ),
      ),
    );
  }
}
