import 'package:flutter/material.dart';
import 'package:v_2_all_media/comic_reader/comic_volume_reader.dart';
import 'package:v_2_all_media/util/computations.dart';

showSnackBarMessage(BuildContext context, String content, {int millis = 400}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(milliseconds: millis), content: Text(content)));
}

extension CustomEncodeReaderMode on ReaderMode {
  String toEncodedState() {
    switch (this) {
      case ReaderMode.verticalContinuous:
        return "vertical-continuous";
      case ReaderMode.horizontalPaginated:
        return "horizontal-paginated";
      case ReaderMode.verticalPaginated:
        return "vertical-paginated";
      case ReaderMode.horizontalContinuous:
        return "horizontal-continuous";
    }
  }
}

extension CustomDecodeReaderMode on String? {
  ReaderMode? toReaderMode() {
    if (this == "vertical-continuous") {
      return ReaderMode.verticalContinuous;
    } else if (this == "horizontal-paginated") {
      return ReaderMode.horizontalPaginated;
    } else if (this == "vertical-paginated") {
      return ReaderMode.verticalPaginated;
    } else if (this == "horizontal-continuous") {
      return ReaderMode.horizontalContinuous;
    }

    return null;
  }
}

class StaticDecompressArgs {
  final int index;
  final List<ComicPage> pages;

  const StaticDecompressArgs({required this.index, required this.pages});
}

extension DecompressSurroundings on List<ComicPage> {
  static staticDecompressSurroundings(StaticDecompressArgs args) {
    final leftSide =
        args.pages.take(args.index).toList().reversed.take(2).toList();
    final rightSide =
        args.pages.take(args.index + 4).toList().reversed.take(1).toList();

    for (var page in leftSide) {
      page.file.content;
    }

    for (var page in rightSide) {
      page.file.content;
    }
  }

  decompressSurroundings(int index) {
    staticDecompressSurroundings(
        StaticDecompressArgs(index: index, pages: this));
  }
}
