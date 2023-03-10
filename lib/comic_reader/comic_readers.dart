import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:simple_mangadex_api/api_types.dart';
import 'package:v_2_all_media/util/computations.dart';
import 'package:v_2_all_media/util/custom_scroll_physics.dart';
import 'package:pixel_snap/material.dart' as snap;
import 'package:extended_image/extended_image.dart' as ext_img;
import 'package:v_2_all_media/util/futures.dart';

class VerticalContinuousReader extends StatefulWidget {
  final List<ComicPage> pages;
  final ValueNotifier<int> currentPage;
  final ItemScrollController verticalContinuousScrollController;
  final BoxConstraints constraints;
  final FilterQuality filterQuality;
  final void Function(int index) animateOverlayListViewToPage;
  final void Function(BuildContext context) showToNextVolumeOverlay;
  final void Function(List<int> pages) setDisplayedPages;
  final void Function() removeToNextVolumeOverlay;

  const VerticalContinuousReader({
    Key? key,
    required this.pages,
    required this.currentPage,
    required this.constraints,
    required this.filterQuality,
    required this.verticalContinuousScrollController,
    required this.animateOverlayListViewToPage,
    required this.showToNextVolumeOverlay,
    required this.removeToNextVolumeOverlay,
    required this.setDisplayedPages,
  }) : super(key: key);

  @override
  State<VerticalContinuousReader> createState() =>
      _VerticalContinuousReaderState();
}

class _VerticalContinuousReaderState extends State<VerticalContinuousReader> {
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int previousFirst = -1;

    Future.delayed(
      Duration.zero,
      () {
        itemPositionsListener.itemPositions.addListener(() {
          final visibleElements =
              itemPositionsListener.itemPositions.value.toList();
          visibleElements.sort((a, b) => a.index.compareTo(b.index));

          final first = visibleElements.first;
          final last = visibleElements.last;

          // TODO: Add update on change of visibleElements.first
          if (last.index != widget.currentPage.value ||
              first.index != previousFirst) {
            previousFirst = first.index;
            widget.currentPage.value = last.index;
            widget.setDisplayedPages(visibleElements
                .map((element) => element.index)
                .toList()
                .sublist(0, visibleElements.length - 1));
            widget.animateOverlayListViewToPage(last.index);
          }

          if (last.index == widget.pages.length - 1) {
            widget.showToNextVolumeOverlay(context);
          } else {
            widget.removeToNextVolumeOverlay();
          }
        });
      },
    );

    Future.delayed(Duration.zero, () {
      widget.verticalContinuousScrollController.scrollTo(
          index: widget.currentPage.value,
          duration: const Duration(milliseconds: 1),
          alignment: 0.5);
    });

    return ScrollablePositionedList.builder(
      physics: const HeavyScrollPhysics(),
      itemScrollController: widget.verticalContinuousScrollController,
      itemPositionsListener: itemPositionsListener,
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        return snap.SizedBox(
          height: (widget.pages[index].height / widget.pages[index].width) *
              widget.constraints.maxWidth,
          child: ext_img.ExtendedImage.memory(
            widget.pages[index].file.content,
            filterQuality: widget.filterQuality,
            height: (widget.pages[index].height / widget.pages[index].width) *
                widget.constraints.maxWidth,
            clearMemoryCacheWhenDispose: true,
          ),
        );
      },
    );
  }
}

class VerticalPaginatedReader extends StatefulWidget {
  final List<ComicPage> pages;

  const VerticalPaginatedReader({Key? key, required this.pages})
      : super(key: key);

  @override
  State<VerticalPaginatedReader> createState() =>
      _VerticalPaginatedReaderState();
}

class _VerticalPaginatedReaderState extends State<VerticalPaginatedReader> {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.blueGrey);
  }
}

// ignore: must_be_immutable
class PaginatedReader extends StatefulWidget {
  List<ComicPage>? pages;
  Chapter? mangaDexPages;
  final ValueNotifier<int> currentPage;
  final FilterQuality filterQuality;
  final PageController horizontalPaginatedPageController;
  final Axis axis;
  final void Function(int index) animateOverlayListViewToPage;
  final void Function(BuildContext context) showToNextVolumeOverlay;
  final void Function(List<int> pages) setDisplayedPages;
  final void Function() removeToNextVolumeOverlay;

  PaginatedReader({
    Key? key,
    this.pages,
    this.mangaDexPages,
    this.filterQuality = FilterQuality.medium,
    required this.currentPage,
    required this.animateOverlayListViewToPage,
    required this.axis,
    required this.horizontalPaginatedPageController,
    required this.showToNextVolumeOverlay,
    required this.removeToNextVolumeOverlay,
    required this.setDisplayedPages,
  }) : super(key: key);

  @override
  State<PaginatedReader> createState() => _PaginatedReaderState();
}

class _PaginatedReaderState extends State<PaginatedReader> {
  @override
  void initState() {
    super.initState();

    assert(widget.pages != null || widget.mangaDexPages != null);

    if (widget.pages != null) {
      assert(widget.mangaDexPages == null);
    } else if (widget.mangaDexPages != null) {
      assert(widget.pages == null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages != null) {
      Future.delayed(Duration.zero, () {
        widget.horizontalPaginatedPageController
            .jumpToPage(widget.currentPage.value);
        widget.setDisplayedPages([]);
      });

      return PhotoViewGallery.builder(
        pageController: widget.horizontalPaginatedPageController,
        itemCount: widget.pages!.length,
        scrollDirection: widget.axis,
        allowImplicitScrolling: true,
        scrollPhysics: const HeavyScrollPhysics(),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
              filterQuality: widget.filterQuality,
              imageProvider: ext_img.ExtendedImage.memory(
                widget.pages![index].file.content,
                clearMemoryCacheWhenDispose: true,
              ).image);
        },
        onPageChanged: (index) {
          widget.currentPage.value = index;
          widget.animateOverlayListViewToPage(index);
          evaluateShowNextVolumeOverlayEntry(index);
        },
      );
    } else if (widget.mangaDexPages != null) {
      return waitForFuture(
        future: Future(() async {
          try {
            return await widget.mangaDexPages!.imageLinks;
          } catch (_) {
            return <String>[];
          }
        }),
        loading: const SpinKitRing(color: Colors.orange, size: 100),
        builder: (context, data) {
          if (data.isEmpty) {
            return Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 100,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Invalid MangaDex Chapter",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            );
          }

          final imageProviders =
              data.map((link) => CachedNetworkImageProvider(link)).toList();

          for (var provider in imageProviders) {
            precacheImage(provider, context);
          }

          Future.delayed(Duration.zero, () {
            widget.horizontalPaginatedPageController
                .jumpToPage(widget.currentPage.value);
            widget.setDisplayedPages([]);
          });

          return PhotoViewGallery.builder(
            scrollPhysics: const HeavyScrollPhysics(),
            pageController: widget.horizontalPaginatedPageController,
            scrollDirection: widget.axis,
            itemCount: data.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions.customChild(
                child: SizedBox(
                  child: Image(
                    image: imageProviders[index],
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }

                      return AnimatedCrossFade(
                        firstChild:
                            const SpinKitRing(color: Colors.orange, size: 100),
                        secondChild: child,
                        crossFadeState: frame == null
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (topChild, topChildKey, bottomChild,
                            bottomChildKey) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                key: bottomChildKey,
                                child: bottomChild,
                              ),
                              Positioned(
                                key: topChildKey,
                                child: topChild,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
            onPageChanged: (index) {
              widget.animateOverlayListViewToPage(index);
              widget.currentPage.value = index;
              evaluateShowNextVolumeOverlayEntry(index);
            },
          );
        },
      );
    }

    return Container();
  }

  evaluateShowNextVolumeOverlayEntry(index) {
    if (widget.pages != null) {
      if (index == widget.pages!.length - 1) {
        widget.showToNextVolumeOverlay(context);
      } else {
        widget.removeToNextVolumeOverlay();
      }
    } else if (widget.mangaDexPages != null) {
      if (index == widget.mangaDexPages!.pages! - 1) {
        widget.showToNextVolumeOverlay(context);
      } else {
        widget.removeToNextVolumeOverlay();
      }
    }
  }
}

class HorizontalContinuousReader extends StatefulWidget {
  final List<ComicPage> pages;

  const HorizontalContinuousReader({Key? key, required this.pages})
      : super(key: key);

  @override
  State<HorizontalContinuousReader> createState() =>
      _HorizontalContinuousReaderState();
}

class _HorizontalContinuousReaderState
    extends State<HorizontalContinuousReader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
    );
  }
}
