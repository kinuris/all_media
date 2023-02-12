import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/comic_reader/comic_readers.dart';
import 'package:v_2_all_media/util/computations.dart';
import 'package:v_2_all_media/util/custom_scroll_physics.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:v_2_all_media/util/helpers.dart';
import 'package:v_2_all_media/util/local_storage_init.dart';
import 'package:extended_image/extended_image.dart' as ext_img;

enum ReaderMode {
  horizontalPaginated,
  horizontalContinuous,
  verticalPaginated,
  verticalContinuous
}

class ComicVolumeReader extends StatefulWidget {
  final ComicVolumeReaderArgs arguments;

  const ComicVolumeReader({Key? key, required this.arguments})
      : super(key: key);

  @override
  State<ComicVolumeReader> createState() => _ComicVolumeReaderState();
}

class _ComicVolumeReaderState extends State<ComicVolumeReader>
    with SingleTickerProviderStateMixin {
  final _isOverlayOpen = ValueNotifier(false);

  late AnimationController _overlayOpacityAnimationController;
  late Animation<double> _overlayOpacityAnimation;
  late ScrollController _overlayScrollController;
  late ValueNotifier<ReaderMode> _readerMode;
  late ValueNotifier<int> _currentPage;

  final ValueNotifier<List<int>> _displayedPages = ValueNotifier([]);

  late PageController _horizontalPaginatedPageController;
  late ItemScrollController _verticalContinuousScrollController;

  OverlayEntry? volumeSummaryOverlayEntry;
  late OverlayEntry nextVolumeOverlayEntry;
  ListView? overlayPagesListView;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _overlayOpacityAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _overlayOpacityAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_overlayOpacityAnimationController);

    _readerMode = ValueNotifier(widget.arguments.assumeReaderMode ??
        (getLocalStorageReaderMode() ?? ReaderMode.horizontalPaginated));
    _currentPage = ValueNotifier(getLocalStorageCurrentPage() ?? 0);
    _overlayScrollController = ScrollController(
        initialScrollOffset: 104 * _currentPage.value.toDouble());

    _horizontalPaginatedPageController = PageController();
    _verticalContinuousScrollController = ItemScrollController();

    nextVolumeOverlayEntry =
        OverlayEntry(builder: (context) => getToNextVolumeOverlay(context));

    super.initState();
  }

  @override
  void dispose() {
    if (volumeSummaryOverlayEntry != null &&
        volumeSummaryOverlayEntry!.mounted) {
      volumeSummaryOverlayEntry!.remove();
    }

    if (nextVolumeOverlayEntry.mounted) {
      nextVolumeOverlayEntry.remove();
    }

    nextVolumeOverlayEntry.dispose();
    volumeSummaryOverlayEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: tempDirectoryProvider(
        loading: Container(),
        builder: (context, tempDir) {
          return doesVolumeHaveCachedSizes(
            absoluteVolumeReadPath: widget.arguments.absoluteVolumePath,
            loading: Container(),
            builder: (context, cached) {
              return FutureBuilder(
                future: !cached
                    ? Future.delayed(
                        const Duration(milliseconds: 100),
                        () => buildReadableVolumeOfMemoryImagesTempCached(
                            BuildReadableVolumeArgs(
                                absoluteVolumeReadPath:
                                    widget.arguments.absoluteVolumePath,
                                tempDir: tempDir)))
                    : buildReadableVolumeOfMemoryImagesTempCached(
                        BuildReadableVolumeArgs(
                            absoluteVolumeReadPath:
                                widget.arguments.absoluteVolumePath,
                            tempDir: tempDir)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      debugPrint(snapshot.error.toString());

                      return const Icon(
                        Icons.error,
                        size: 100,
                        color: Colors.red,
                      );
                    }

                    if (!cached) {
                      return const Center(
                        child: Padding(padding: EdgeInsets.all(32),
                        child: Text(
                            "First Time Opening... Depending on the file size this may take a while",
                            style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
                      ));
                    }

                    return const SpinKitFadingCube(
                      color: Colors.orange,
                      size: 100,
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return WillPopScope(
                        child: GestureDetector(
                          child: ValueListenableBuilder(
                            valueListenable: _readerMode,
                            builder: (context, value, child) {
                              switch (_readerMode.value) {
                                case ReaderMode.horizontalPaginated:
                                  return HorizontalPaginatedReader(
                                    pages: snapshot.data!,
                                    currentPage: _currentPage,
                                    animateOverlayListViewToPage:
                                        animateOverlayListViewToPage,
                                    horizontalPaginatedPageController:
                                        _horizontalPaginatedPageController,
                                    showToNextVolumeOverlay:
                                        showToNextVolumeOverlay,
                                    removeToNextVolumeOverlay:
                                        removeToNextVolumeOverlay,
                                    setDisplayedPages: setDisplayedPages,
                                  );
                                case ReaderMode.horizontalContinuous:
                                  return HorizontalContinuousReader(
                                      pages: snapshot.data!);
                                case ReaderMode.verticalPaginated:
                                  return VerticalPaginatedReader(
                                      pages: snapshot.data!);
                                case ReaderMode.verticalContinuous:
                                  return VerticalContinuousReader(
                                    pages: snapshot.data!,
                                    currentPage: _currentPage,
                                    verticalContinuousScrollController:
                                        _verticalContinuousScrollController,
                                    constraints: constraints,
                                    animateOverlayListViewToPage:
                                        animateOverlayListViewToPage,
                                    showToNextVolumeOverlay:
                                        showToNextVolumeOverlay,
                                    removeToNextVolumeOverlay:
                                        removeToNextVolumeOverlay,
                                    setDisplayedPages: setDisplayedPages,
                                  );
                              }
                            },
                          ),
                          onTapUp: (details) {
                            overlayOnTapUpHandler(
                                context, constraints, details, snapshot.data!);
                          },
                        ),
                        onWillPop: () async {
                          if (volumeSummaryOverlayEntry != null &&
                              volumeSummaryOverlayEntry!.mounted) {
                            volumeSummaryOverlayEntry!.remove();
                          }

                          if (nextVolumeOverlayEntry.mounted) {
                            nextVolumeOverlayEntry.remove();
                          }

                          // TODO: Save ReaderMode
                          await setLocalStorageReaderMode(_readerMode.value);
                          await setLocalStorageCurrentPage(_currentPage.value);

                          SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.manual,
                              overlays: SystemUiOverlay.values);

                          return true;
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  overlayOnTapUpHandler(BuildContext context, BoxConstraints constraints,
      TapUpDetails details, List<ComicPage> pages) {
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
          _isOverlayOpen.value = false;

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
        _isOverlayOpen.value = true;
      }
    }
  }

  Widget getMangaOverlayWidget(
      BoxConstraints constraints, List<ComicPage> pages) {
    if (_overlayScrollController.hasClients) {
      if (_currentPage.value * 104 >=
          _overlayScrollController.position.maxScrollExtent) {
        _overlayScrollController
            .jumpTo(_overlayScrollController.position.maxScrollExtent);
      } else {
        _overlayScrollController.jumpTo(_currentPage.value * 104);
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
                  basenameWithoutExtension(
                      widget.arguments.absoluteVolumePath.split("/").last),
                  style: const TextStyle(
                      color: Colors.white, decoration: TextDecoration.none),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            width: constraints.maxWidth,
            height: clampDouble(constraints.maxHeight * 0.25, 150, 200),
            child: ValueListenableBuilder(
              valueListenable: _readerMode,
              builder: (context, value, child) {
                return ValueListenableBuilder(
                  valueListenable: _currentPage,
                  builder: (context, value, child) {
                    return Container(
                      color: Colors.grey.shade900,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          PageIndicatorAndReaderModeMenu(
                            displayedPages: _displayedPages,
                            currentPage: _currentPage,
                            readerMode: _readerMode,
                            pageCount: pages.length,
                            constraints: constraints,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight * 0.15,
                            child: overlayPagesListView ??
                                (overlayPagesListView = ListView.builder(
                                  controller: _overlayScrollController,
                                  physics: const HeavyScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: pages.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        width: 100,
                                        height: constraints.maxHeight * 0.15,
                                        child: ext_img.ExtendedImage.memory(
                                          pages[index].file.content,
                                          clearMemoryCacheWhenDispose: true,
                                          fit: BoxFit.cover,
                                        ),
                                        // child: Image.memory(
                                        //     pages[index].file.content,
                                        //     fit: BoxFit.cover),
                                      ),
                                      onTapUp: (details) {
                                        if (_readerMode.value ==
                                            ReaderMode.horizontalPaginated) {
                                          _horizontalPaginatedPageController
                                              .jumpToPage(index);
                                        } else if (_readerMode.value ==
                                            ReaderMode.verticalContinuous) {
                                          _verticalContinuousScrollController
                                              .jumpTo(
                                                  index: index, alignment: 0.5);
                                        }
                                      },
                                    );
                                  },
                                )),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  animateOverlayListViewToPage(int index) {
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
      _overlayScrollController.animateTo(_currentPage.value * 104,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInExpo);
    }
  }

  showToNextVolumeOverlay(BuildContext context) {
    if (!nextVolumeOverlayEntry.mounted &&
        widget.arguments.indexInSortedVolumes <
            widget.arguments.sortedVolumePaths.length - 1) {
      final overlayState = Overlay.of(context);

      try {
        overlayState.insert(nextVolumeOverlayEntry);
      } catch (err) {
        return;
      }
    }
  }

  removeToNextVolumeOverlay() {
    if (nextVolumeOverlayEntry.mounted) {
      try {
        nextVolumeOverlayEntry.remove();
      } catch (err) {
        return;
      }
    }
  }

  setDisplayedPages(List<int> pages) {
    _displayedPages.value = [...pages];
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
                Navigator.popAndPushNamed(context, '/comic-volume-reader',
                    arguments: ComicVolumeReaderArgs(
                        sortedVolumePaths: widget.arguments.sortedVolumePaths,
                        absoluteVolumePath: widget.arguments.sortedVolumePaths[
                            widget.arguments.indexInSortedVolumes + 1],
                        indexInSortedVolumes:
                            widget.arguments.indexInSortedVolumes + 1,
                        assumeReaderMode: _readerMode.value));
              },
            ),
          ),
        ),
      ],
    );
  }

  // TODO: BELOW ARE LOCAL STORAGE METHODS
  // TODO: Put Hash of content in key
  Future<void> setLocalStorageCurrentPage(int page) async {
    await localStorage.setItem(
        "${widget.arguments.absoluteVolumePath.split("/").last}-current-page",
        page);
  }

  int? getLocalStorageCurrentPage() {
    return localStorage.getItem(
        "${widget.arguments.absoluteVolumePath.split("/").last}-current-page");
  }

  Future<void> setLocalStorageContinuousVerticalOffset(double offset) async {
    await localStorage.setItem(
        "${widget.arguments.absoluteVolumePath.split("/").last}-current-offset",
        offset);
  }

  double? getLocalStorageContinuousVerticalOffset() {
    return localStorage.getItem(
        "${widget.arguments.absoluteVolumePath.split("/").last}-current-offset");
  }

  Future<void> setLocalStorageReaderMode(ReaderMode readerMode) async {
    await localStorage.setItem(
        "${widget.arguments.absoluteVolumePath.split("/").last}-reader-mode",
        readerMode.toEncodedState());
  }

  ReaderMode? getLocalStorageReaderMode() {
    return (localStorage.getItem(
                "${widget.arguments.absoluteVolumePath.split("/").last}-reader-mode")
            as String?)
        ?.toReaderMode();
  }
}

class PageIndicatorAndReaderModeMenu extends StatelessWidget {
  const PageIndicatorAndReaderModeMenu({
    super.key,
    required ValueNotifier<int> currentPage,
    required ValueNotifier<ReaderMode> readerMode,
    required int pageCount,
    required this.constraints,
    required displayedPages,
  })  : _currentPage = currentPage,
        _readerMode = readerMode,
        _displayedPages = displayedPages,
        _pageCount = pageCount;

  final BoxConstraints constraints;
  final ValueNotifier<List<int>> _displayedPages;

  final ValueNotifier<int> _currentPage;
  final ValueNotifier<ReaderMode> _readerMode;
  final int _pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ValueListenableBuilder(
          valueListenable: _displayedPages,
          builder: (context, value, child) {
            return SizedBox(
              width: constraints.maxWidth * 0.4,
              child: AutoSizeText(
                "${value.isNotEmpty ? "${value.first + 1}-" : ""}${_currentPage.value + 1}/$_pageCount",
                maxLines: 1,
                style: const TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.none,
                    fontSize: 24),
              ),
            );
          },
        ),
        SizedBox(width: constraints.maxWidth * 0.1),
        Row(
          children: [
            GestureDetector(
              child: Icon(
                Icons.panorama_horizontal,
                color: _readerMode.value == ReaderMode.horizontalContinuous
                    ? Colors.orange
                    : Colors.white,
                size: 30,
              ),
              onTapUp: (details) {
                _readerMode.value = ReaderMode.horizontalContinuous;
              },
            ),
            const SizedBox(
              width: 10,
            ),
            GestureDetector(
              child: Icon(
                Icons.panorama_vertical,
                color: _readerMode.value == ReaderMode.verticalContinuous
                    ? Colors.orange
                    : Colors.white,
                size: 30,
              ),
              onTapUp: (details) {
                _readerMode.value = ReaderMode.verticalContinuous;
              },
            ),
            const SizedBox(
              width: 10,
            ),
            GestureDetector(
              child: Icon(
                Icons.arrow_forward,
                color: _readerMode.value == ReaderMode.horizontalPaginated
                    ? Colors.orange
                    : Colors.white,
                size: 30,
              ),
              onTapUp: (details) {
                _readerMode.value = ReaderMode.horizontalPaginated;
              },
            ),
            const SizedBox(
              width: 10,
            ),
            GestureDetector(
              child: Icon(
                Icons.arrow_downward,
                color: _readerMode.value == ReaderMode.verticalPaginated
                    ? Colors.orange
                    : Colors.white,
                size: 30,
              ),
              onTapUp: (details) {
                _readerMode.value = ReaderMode.verticalPaginated;
              },
            ),
          ],
        ),
      ],
    );
  }
}
