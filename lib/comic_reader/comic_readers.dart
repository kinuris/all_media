import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:v_2_all_media/util/computations.dart';
import 'package:v_2_all_media/util/custom_scroll_physics.dart';
import 'package:pixel_snap/material.dart' as snap;
import 'package:extended_image/extended_image.dart' as ext_img;

// TODO: VERTICAL CONTINUOUS READER

class VerticalContinuousReader extends StatefulWidget {
  final List<ComicPage> pages;
  final ValueNotifier<int> currentPage;
  final ItemScrollController verticalContinuousScrollController;
  final BoxConstraints constraints;
  final void Function(int index) animateOverlayListViewToPage;
  final void Function(BuildContext context) showToNextVolumeOverlay;
  final void Function(List<int> pages) setDisplayedPages;
  final void Function() removeToNextVolumeOverlay;

  const VerticalContinuousReader({
    Key? key,
    required this.pages,
    required this.currentPage,
    required this.constraints,
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
    Future.delayed(
      Duration.zero,
      () {
        itemPositionsListener.itemPositions.addListener(() {
          final visibleElements =
              itemPositionsListener.itemPositions.value.toList();
          visibleElements.sort((a, b) => a.index.compareTo(b.index));

          final last = visibleElements.last;

          if (last.index != widget.currentPage.value) {
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
            filterQuality: FilterQuality.medium,
            height: (widget.pages[index].height / widget.pages[index].width) *
                widget.constraints.maxWidth,
            clearMemoryCacheWhenDispose: true,
          ),
        );
      },
    );
  }
}

// TODO: VERTICAL PAGINATED READER

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

// TODO: HORIZONTAL PAGINATED READER

class PaginatedReader extends StatefulWidget {
  final List<ComicPage> pages;
  final ValueNotifier<int> currentPage;
  final PageController horizontalPaginatedPageController;
  final Axis axis;
  final void Function(int index) animateOverlayListViewToPage;
  final void Function(BuildContext context) showToNextVolumeOverlay;
  final void Function(List<int> pages) setDisplayedPages;
  final void Function() removeToNextVolumeOverlay;

  const PaginatedReader({
    Key? key,
    required this.pages,
    required this.currentPage,
    required this.animateOverlayListViewToPage,
    required this.axis,
    required this.horizontalPaginatedPageController,
    required this.showToNextVolumeOverlay,
    required this.removeToNextVolumeOverlay,
    required this.setDisplayedPages,
  }) : super(key: key);

  @override
  State<PaginatedReader> createState() =>
      _PaginatedReaderState();
}

class _PaginatedReaderState extends State<PaginatedReader> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Defer to next tick
    Future.delayed(Duration.zero, () {
      widget.horizontalPaginatedPageController
          .jumpToPage(widget.currentPage.value);
      widget.setDisplayedPages([]);
    });

    return PhotoViewGallery.builder(
      pageController: widget.horizontalPaginatedPageController,
      itemCount: widget.pages.length,
      scrollDirection: widget.axis,
      allowImplicitScrolling: true,
      gaplessPlayback: true,
      scrollPhysics: const HeavyScrollPhysics(),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
            imageProvider: ext_img.ExtendedImage.memory(
          widget.pages[index].file.content,
          filterQuality: FilterQuality.medium,
          clearMemoryCacheWhenDispose: true,
        ).image);
      },
      onPageChanged: (index) {
        widget.currentPage.value = index;
        widget.animateOverlayListViewToPage(index);
        evaluateShowNextVolumeOverlayEntry(index);
      },
    );
  }

  evaluateShowNextVolumeOverlayEntry(index) {
    if (index == widget.pages.length - 1) {
      widget.showToNextVolumeOverlay(context);
    } else {
      widget.removeToNextVolumeOverlay();
    }
  }
}

// TODO: HORIZONTAL CONTINUOUS READER

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
