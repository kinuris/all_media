import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_mangadex_api/api_types.dart';
import 'package:v_2_all_media/comic_reader/comic_readers.dart';
import 'package:v_2_all_media/comic_reader/comic_volume_reader.dart';
import 'package:v_2_all_media/util/arguments.dart';
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
  late ScrollController _overlayScrollController;
  late OverlayEntry _nextVolumeOverlayEntry;
  late ValueNotifier<ReaderMode> _readerMode;
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
    _overlayScrollController =
        ScrollController(initialScrollOffset: _currentPage.value * 104);

    _readerMode = ValueNotifier(ReaderMode.horizontalPaginated);

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
        body: WillPopScope(
          onWillPop: () async {
            await setLocalStorageCurrentPage(_currentPage.value,
                widget.args.result.sortedChapters[widget.args.currentIndex].id);
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
                child: Builder(
                  builder: (context) {
                    if (_readerMode.value == ReaderMode.horizontalPaginated) {
                      return PaginatedReader(
                        currentPage: _currentPage,
                        mangaDexPages: widget.args.result
                            .sortedChapters[widget.args.currentIndex],
                        animateOverlayListViewToPage:
                            animateOverlayListViewToPage,
                        axis: Axis.horizontal,
                        horizontalPaginatedPageController:
                            _paginatedPageController,
                        showToNextVolumeOverlay: showToNextVolumeOverlay,
                        removeToNextVolumeOverlay: removeToNextVolumeOverlay,
                        setDisplayedPages: setDisplayedPages,
                      );
                    } else if (_readerMode.value ==
                        ReaderMode.verticalPaginated) {}

                    return Container();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget getMangaOverlayWidget(BoxConstraints constraints, Manga result) {
    if (_overlayScrollController.hasClients) {
      if (_currentPage.value * 104 >=
          _overlayScrollController.position.maxScrollExtent) {
        _overlayScrollController
            .jumpTo(_overlayScrollController.position.maxScrollExtent - 0.1);
        _overlayScrollController.animateTo(
            _overlayScrollController.position.maxScrollExtent + 0.1,
            duration: const Duration(milliseconds: 1),
            curve: Curves.easeInOutExpo);
      } else {
        _overlayScrollController.jumpTo((_currentPage.value * 104) - 0.1);
        _overlayScrollController.animateTo(_currentPage.value * 104 + 0.1,
            duration: const Duration(milliseconds: 1),
            curve: Curves.easeInOutExpo);
      }
    }

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
                  child: AutoSizeText(
                widget.args.result.sortedChapters[widget.args.currentIndex]
                            .title! ==
                        ""
                    ? "Chapter ${widget.args.result.sortedChapters[widget.args.currentIndex].chapterString}"
                    : widget.args.result
                        .sortedChapters[widget.args.currentIndex].title!,
                style: const TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              )),
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
                      const SizedBox(height: 10),
                      AutoSizeText(
                        "${_currentPage.value + 1}/${result.sortedChapters[widget.args.currentIndex].pages}",
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight * 0.15,
                        child: ListView.builder(
                          controller: _overlayScrollController,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(width: 1, color: Colors.white),
                              ),
                              child: GestureDetector(
                                onTapUp: (details) {
                                  if (_readerMode.value ==
                                      ReaderMode.horizontalPaginated) {
                                    _paginatedPageController.jumpToPage(index);
                                  }
                                },
                                child: CachedNetworkImage(
                                  imageUrl: widget
                                      .args
                                      .result
                                      .sortedChapters[widget.args.currentIndex]
                                      .infallibleImageLinks[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                          scrollDirection: Axis.horizontal,
                          itemCount: result
                              .sortedChapters[widget.args.currentIndex].pages,
                        ),
                      ),
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
      TapUpDetails details, Manga pages) {
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

                if (volumeSummaryOverlayEntry != null &&
                    volumeSummaryOverlayEntry!.mounted) {
                  volumeSummaryOverlayEntry!.remove();
                }

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

  animateOverlayListViewToPage(int page) {
    if (!_overlayScrollController.hasClients) {
      return;
    }

    if (_currentPage.value * 104 >=
        _overlayScrollController.position.maxScrollExtent) {
      _overlayScrollController.animateTo(
          _overlayScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInExpo);
    } else {
      _overlayScrollController.animateTo(page * 104,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInExpo);
    }
  }

  showToNextVolumeOverlay(BuildContext context) {
    if (!_nextVolumeOverlayEntry.mounted &&
        widget.args.currentIndex < widget.args.result.chapters.length - 1) {
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
