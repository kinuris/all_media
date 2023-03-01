import 'dart:io';

import 'package:simple_mangadex_api/api_types.dart';
import 'package:v_2_all_media/comic_reader/comic_volume_reader.dart';

class GenFolderResourceThumbnailArgs {
  final String folderResource;
  final Directory tempDir;

  const GenFolderResourceThumbnailArgs({
    required this.folderResource,
    required this.tempDir,
  });
}

class ResolveThumbnailArgs {
  final String folderPath;
  final Directory tempDir;

  const ResolveThumbnailArgs({
    required this.folderPath,
    required this.tempDir,
  });
}

class ComicVolumeDisplayArgs {
  final String folderPath;

  const ComicVolumeDisplayArgs({required this.folderPath});
}

class BuildVolumesArgs {
  final String absoluteSeriesPath;
  final Directory tempDir;

  const BuildVolumesArgs({
    required this.absoluteSeriesPath,
    required this.tempDir,
  });
}

class ComicVolumeReaderArgs {
  final String absoluteVolumePath;
  final List<String> sortedVolumePaths;
  final int indexInSortedVolumes;
  final ReaderMode? assumeReaderMode;

  const ComicVolumeReaderArgs({
    required this.sortedVolumePaths,
    required this.absoluteVolumePath,
    required this.indexInSortedVolumes,
    this.assumeReaderMode,
  });
}

class BuildReadableVolumeArgs {
  final String absoluteVolumeReadPath;
  final Directory tempDir;

  const BuildReadableVolumeArgs({
    required this.absoluteVolumeReadPath,
    required this.tempDir,
  });
}

class BuildReadableVolumeArgsStringVersion {
  final String absoluteVolumeReadPath;
  final String tempDirPath;

  const BuildReadableVolumeArgsStringVersion({
    required this.absoluteVolumeReadPath,
    required this.tempDirPath,
  });
}

class MangaDexChapterReaderArgs {
  final Manga result;
  final int currentIndex;

  const MangaDexChapterReaderArgs({
    required this.currentIndex,
    required this.result,
  });
}
