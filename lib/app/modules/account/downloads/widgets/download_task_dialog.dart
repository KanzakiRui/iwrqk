import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';

import '../../../../../i18n/strings.g.dart';
import '../../../../components/network_image.dart';
import '../../../../data/enums/types.dart';
import '../../../../data/models/download_task.dart';
import '../../../../data/models/offline/download_task_media.dart';
import '../../../../data/services/download_service.dart';
import '../../../../utils/display_util.dart';

class DownloadTaskDialog extends StatelessWidget {
  final MediaDownloadTask taskData;
  final void Function(String)? onPaused;
  final Future<String?> Function(String)? onResumed;
  final void Function(String)? onDeleted;
  final void Function(String)? onRetry;
  final void Function(String)? onOpen;
  final void Function(String)? onShare;
  final void Function()? gotoPlayer;
  final void Function()? gotoDetail;

  DownloadTaskDialog({
    super.key,
    required this.taskData,
    this.onPaused,
    this.onResumed,
    this.onDeleted,
    this.onRetry,
    this.onOpen,
    this.onShare,
    this.gotoPlayer,
    this.gotoDetail,
  });

  final DownloadService _downloadService = Get.find();
  DownloadTaskMediaModel get media => taskData.offlineMedia;

  String get taskId => taskData.taskId;
  Rx<IwrDownloadTaskStatus>? get taskStatus =>
      _downloadService.downloadTasksStatus[taskId];

  Widget _buildStateWidget(BuildContext context) {
    return Obx(() {
      if (taskStatus != null) {
        int downloadedSize = media.size * taskStatus!.value.progress ~/ 100;
        int totalSize = media.size;
        double progress = 0;

        late Widget statusWidget;

        switch (taskStatus!.value.status) {
          case DownloadTaskStatus.enqueued:
            statusWidget = Text(
              t.download.enqueued,
            );
          case DownloadTaskStatus.running:
            statusWidget = Text(
              "${t.download.downloading} ${DisplayUtil.getDownloadFileSizeProgress(downloadedSize, totalSize)}",
            );

            progress = taskStatus!.value.progress / 100;
          case DownloadTaskStatus.paused:
            statusWidget = Text(
              "${t.download.paused} ${DisplayUtil.getDownloadFileSizeProgress(downloadedSize, totalSize)}",
            );

            progress = taskStatus!.value.progress / 100;
          case DownloadTaskStatus.failed:
            statusWidget = Text(
              t.download.failed,
            );
          case DownloadTaskStatus.complete:
            statusWidget = Text(
                "${t.download.finished} ${DisplayUtil.getDownloadFileSizeProgress(downloadedSize, totalSize)}");

            progress = 1;
          default:
            statusWidget = Text(
              t.download.unknown,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.red,
              ),
            );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: progress,
            ),
            const SizedBox(height: 12),
            statusWidget,
          ],
        );
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(
              value: 0,
            ),
            const SizedBox(height: 12),
            Text(
              t.download.unknown,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      media.title,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onInverseSurface),
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            if (taskStatus?.value.status == DownloadTaskStatus.complete) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Stack(
                    children: [
                      if (Get.mediaQuery.orientation == Orientation.portrait)
                        Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: media.coverUrl != null
                              ? NetworkImg(
                                  imageUrl: media.coverUrl!,
                                  aspectRatio: 16 / 9,
                                  fit: BoxFit.cover,
                                  isAdult: media.ratingType ==
                                      RatingType.ecchi.value,
                                )
                              : const AspectRatio(aspectRatio: 16 / 9),
                        )
                      else
                        Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: media.coverUrl != null
                              ? NetworkImg(
                                  imageUrl: media.coverUrl!,
                                  width: 300,
                                  fit: BoxFit.cover,
                                  isAdult: media.ratingType ==
                                      RatingType.ecchi.value,
                                )
                              : const SizedBox(width: 300),
                        ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: InkWell(
                            onTap: gotoPlayer,
                            child: const Icon(
                              Icons.play_arrow,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: _buildStateWidget(context),
              ),
            Obx(
              () => OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  if (taskStatus?.value.status == null ||
                      taskStatus?.value.status ==
                          DownloadTaskStatus.failed) ...[
                    IconButton(
                      onPressed: () {
                        onRetry?.call(taskId);
                        Get.back();
                      },
                      tooltip: t.download.retry,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () {
                        onDeleted?.call(taskId);
                        Get.back();
                      },
                      tooltip: t.download.delete,
                      icon: const Icon(Icons.delete),
                    ),
                  ] else if (taskStatus?.value.status ==
                      DownloadTaskStatus.complete) ...[
                    IconButton(
                      onPressed: () {
                        onDeleted?.call(taskId);
                        Get.back();
                      },
                      tooltip: t.download.delete,
                      icon: const Icon(Icons.delete),
                    ),
                    IconButton(
                      onPressed: () {
                        onOpen?.call(taskId);
                      },
                      tooltip: t.download.open_with,
                      icon: const Icon(Icons.folder),
                    ),
                    IconButton(
                      onPressed: () {
                        onShare?.call(taskId);
                      },
                      tooltip: t.media.share,
                      icon: const Icon(Icons.share),
                    ),
                  ] else ...[
                    taskStatus?.value.status == DownloadTaskStatus.paused
                        ? IconButton(
                            onPressed: () {
                              onResumed?.call(taskId).then((value) {
                                if (value != null) {
                                  taskData.taskId = value;
                                  final newTaskStatus = _downloadService
                                      .downloadTasksStatus[value];
                                  if (newTaskStatus != null) {
                                    taskStatus?.value = newTaskStatus.value;
                                  }
                                }
                              });
                            },
                            tooltip: t.download.resume,
                            icon: const Icon(Icons.play_arrow),
                          )
                        : IconButton(
                            onPressed: () {
                              onPaused?.call(taskId);
                            },
                            tooltip: t.download.pause,
                            icon: const Icon(Icons.pause),
                          ),
                    IconButton(
                      onPressed: () {
                        onDeleted?.call(taskId);
                        Get.back();
                      },
                      tooltip: t.download.delete,
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                  IconButton(
                    onPressed: gotoDetail,
                    tooltip: t.download.jump_to_detail,
                    icon: const Icon(Icons.open_in_browser),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
