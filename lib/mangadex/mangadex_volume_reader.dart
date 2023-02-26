import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:v_2_all_media/comic_reader/comic_readers.dart';
import 'package:v_2_all_media/mangadex/api_types.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:v_2_all_media/util/local_storage_init.dart';

class MangaDexChapterReader extends StatefulWidget {
  final MangaDexChapterReaderArgs args;

  const MangaDexChapterReader({
    super.key,
    required this.args,
  });

  @override
  State<MangaDexChapterReader> createState() => _MangaDexChapterReaderState();
}

class _MangaDexChapterReaderState extends State<MangaDexChapterReader>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<int> _currentPage;
  late PageController _paginatedPageController;
  late AnimationController _overlayOpacityAnimationController;
  late Animation<double> _overlayOpacityAnimation;
  late OverlayEntry _nextVolumeOverlayEntry;
  OverlayEntry? volumeSummaryOverlayEntry;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentPage = ValueNotifier(getLocalStorageCurrentPage(
            widget.args.result.sortedChapters[widget.args.currentIndex].id) ??
        0);
    _overlayOpacityAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _overlayOpacityAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_overlayOpacityAnimationController);
    _paginatedPageController = PageController();
    _nextVolumeOverlayEntry =
        OverlayEntry(builder: (context) => getToNextVolumeOverlay(context));

    super.initState();
  }

  @override
  void dispose() {
    if (_nextVolumeOverlayEntry.mounted) {
      _nextVolumeOverlayEntry.remove();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: waitForFuture(
          loading: const SpinKitRing(size: 100, color: Colors.orange),
          future: widget.args.result.sortedChapters[widget.args.currentIndex]
              .getChapterData(),
          builder: (context, data) {
            return WillPopScope(
              onWillPop: () async {
                await setLocalStorageCurrentPage(
                    _currentPage.value, data.data.id);
                if (_nextVolumeOverlayEntry.mounted) {
                  _nextVolumeOverlayEntry.remove();
                }

                if (volumeSummaryOverlayEntry != null &&
                    volumeSummaryOverlayEntry!.mounted) {
                  volumeSummaryOverlayEntry!.remove();
                }

                SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                    overlays: SystemUiOverlay.values);

                return true;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: (details) {
                      overlayOnTapUpHandler(
                          context, constraints, details, widget.args.result);
                    },
                    child: PaginatedReader(
                      currentPage: _currentPage,
                      mangaDexPages: data.data,
                      animateOverlayListViewToPage:
                          animateOverlayListViewToPage,
                      axis: Axis.horizontal,
                      horizontalPaginatedPageController:
                          _paginatedPageController,
                      showToNextVolumeOverlay: showToNextVolumeOverlay,
                      removeToNextVolumeOverlay: removeToNextVolumeOverlay,
                      setDisplayedPages: setDisplayedPages,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget getMangaOverlayWidget(
      BoxConstraints constraints, MangaDexMangaAggregateResult result) {
    return Opacity(
      opacity: _overlayOpacityAnimation.value,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            height: constraints.maxHeight * 0.08,
            width: constraints.maxWidth,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade900.withOpacity(0.9),
              child: Center(
                child: waitForFuture(
                  loading: Container(),
                  future: widget
                      .args.result.sortedChapters[widget.args.currentIndex]
                      .getChapterData(),
                  builder: (context, data) {
                    return AutoSizeText(
                      data.data.attributes.title == ""
                          ? "Chapter ${data.data.attributes.chapter}"
                          : data.data.attributes.title,
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            width: constraints.maxWidth,
            height: clampDouble(constraints.maxHeight * 0.25, 150, 200),
            child: Container(
              color: Colors.grey.shade900,
              child: ValueListenableBuilder(
                valueListenable: _currentPage,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      AutoSizeText(
                          "${_currentPage.value + 1}/${result.sortedChapters[widget.args.currentIndex]}"),
                    ],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  overlayOnTapUpHandler(BuildContext context, BoxConstraints constraints,
      TapUpDetails details, MangaDexMangaAggregateResult pages) {
    final upperBound = constraints.maxHeight * 0.33;
    final lowerBound = constraints.maxHeight * 0.66;

    if (details.localPosition.dy > upperBound &&
        details.localPosition.dy < lowerBound) {
      final overlayState = Overlay.of(context);

      volumeSummaryOverlayEntry ??= OverlayEntry(
          builder: (context) => getMangaOverlayWidget(constraints, pages));

      listener() {
        overlayState.setState(() {});
      }

      _overlayOpacityAnimationController.addListener(listener);

      if (volumeSummaryOverlayEntry!.mounted) {
        _overlayOpacityAnimationController.reverse().whenComplete(() {
          try {
            volumeSummaryOverlayEntry!.remove();
          } catch (err) {
            debugPrint(err.toString());
            return;
          }
        });
      } else {
        overlayState.insert(volumeSummaryOverlayEntry!);
        _overlayOpacityAnimationController.forward();
      }
    }
  }

  Widget getToNextVolumeOverlay(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        Positioned(
          width: 70,
          height: 70,
          right: 10,
          child: ClipOval(
            child: GestureDetector(
              child: Container(
                color: Colors.orange.withOpacity(0.4),
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: 50,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              onTapUp: (details) {
                removeToNextVolumeOverlay();
                Navigator.popAndPushNamed(context, '/mangadex-volume-reader',
                    arguments: MangaDexChapterReaderArgs(
                        currentIndex: widget.args.currentIndex + 1,
                        result: widget.args.result));
              },
            ),
          ),
        ),
      ],
    );
  }

  animateOverlayListViewToPage(int page) {}

  showToNextVolumeOverlay(BuildContext context) {
    if (!_nextVolumeOverlayEntry.mounted &&
        widget.args.currentIndex < widget.args.result.totalChapterCount) {
      final overlayState = Overlay.of(context);

      try {
        overlayState.insert(_nextVolumeOverlayEntry);
      } catch (err) {
        return;
      }
    }
  }

  removeToNextVolumeOverlay() {
    if (_nextVolumeOverlayEntry.mounted) {
      try {
        _nextVolumeOverlayEntry.remove();
      } catch (err) {
        return;
      }
    }
  }

  setDisplayedPages(List<int> pages) {}

  setLocalStorageCurrentPage(int page, String chapterId) async {
    await localStorage.setItem("chapter-$chapterId", page);
  }

  int? getLocalStorageCurrentPage(String chapterId) {
    return localStorage.getItem("chapter-$chapterId");
  }
}
