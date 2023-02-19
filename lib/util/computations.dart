import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:image/image.dart' as img;
import 'package:v_2_all_media/util/local_storage_init.dart';

Future<void> genThumbnailFolderResource(
    GenFolderResourceThumbnailArgs args) async {
  final volumes = Directory(args.folderResource)
      .listSync()
      .where((file) => extension(file.path) == ".cbz")
      .whereType<File>()
      .toList();

  await Future.wait(volumes.map((file) async {
    var destinationDirectory = Directory(
        "${args.tempDir.path}/${args.folderResource.split("/").last}/${basenameWithoutExtension(file.path)}");

    if (!await destinationDirectory.exists()) {
      destinationDirectory = await destinationDirectory.create(recursive: true);
    }

    final zipStream = InputFileStream(file.path);
    final decodedArchive = ZipDecoder().decodeBuffer(zipStream);

    final archiveFiles = decodedArchive.files
        .where((file) => lookupMimeType(file.name)?.split("/").first == "image")
        .toList();
    archiveFiles.sort(
      (a, b) => a.name.compareTo(b.name),
    );

    final firstArchiveFile = archiveFiles.first;

    final thumbnailFile = await File(
            "${destinationDirectory.path}/thumbnail${extension(firstArchiveFile.name.split("/").last)}")
        .create();
    await thumbnailFile.writeAsBytes(firstArchiveFile.content);
  }).toList());
}

Future<File?> resolveThumbnails(ResolveThumbnailArgs args) async {
  final seriesDirectory =
      Directory("${args.tempDir.path}/${args.folderPath.split("/").last}");

  if (!await seriesDirectory.exists()) {
    return null;
  }

  final fileSystemEntities = seriesDirectory.listSync();

  fileSystemEntities.sort((a, b) => a.path.compareTo(b.path));

  var potentialThumbnailJpg =
      File("${fileSystemEntities.first.path}/thumbnail.jpg");

  if (!await potentialThumbnailJpg.exists()) {
    potentialThumbnailJpg =
        File("${fileSystemEntities.first.path}/thumbnail.jpeg");
  }

  if (await potentialThumbnailJpg.exists()) {
    return potentialThumbnailJpg;
  }

  final potentialThumbnailPng =
      File("${fileSystemEntities.first.path}/thumbnail.png");

  if (await potentialThumbnailPng.exists()) {
    return potentialThumbnailPng;
  }

  return null;
}

class BuildVolumesData {
  final List<String> sortedVolumePaths;
  final List<File> thumbnails;

  const BuildVolumesData(
      {required this.sortedVolumePaths, required this.thumbnails});
}

Future<BuildVolumesData?> buildVolumes(BuildVolumesArgs args) async {
  final tempSeriesDirectory = Directory(
      "${args.tempDir.path}/${args.absoluteSeriesPath.split("/").last}");

  if (!await tempSeriesDirectory.exists()) {
    return null;
  }

  final volumesInTempDir = await tempSeriesDirectory.list().toList();
  final thumbnails = await Future.wait(
      volumesInTempDir.whereType<Directory>().map((dir) async {
    var thumbnailJpg = File("${dir.path}/thumbnail.jpg");

    if (!await thumbnailJpg.exists()) {
      thumbnailJpg = File("${dir.path}/thumbnail.jpeg");
    }

    if (await thumbnailJpg.exists()) {
      return thumbnailJpg;
    }

    var thumbnailPng = File("${dir.path}/thumbnail.png");

    return thumbnailPng;
  }).toList());

  thumbnails.sort((a, b) => a.path.compareTo(b.path));

  // TODO: Construct sortVolumes

  final volumesInActualSeriesDir =
      await Directory(args.absoluteSeriesPath).list().toList();
  final sortedVolumePaths = volumesInActualSeriesDir
      .whereType<File>()
      .map((file) => file.path)
      .toList();

  sortedVolumePaths.sort((a, b) => a.compareTo(b));

  return BuildVolumesData(
      sortedVolumePaths: sortedVolumePaths, thumbnails: thumbnails);
}

class ComicPage {
  final ArchiveFile file;
  final int width;
  final int height;

  const ComicPage(
      {required this.file, required this.height, required this.width});
}

class ComicImageSize {
  final int width;
  final int height;

  const ComicImageSize({required this.width, required this.height});

  operator [](String key) {
    switch (key) {
      case 'width':
        return width;
      case 'height':
        return height;
      default:
        throw Exception("key must only be 'width' or 'height'");
    }
  }

  Map<String, dynamic> toJson() => {'width': width, 'height': height};
}

// TODO: DOES NOT WORK WITH COMPUTE, BECAUSE IT USES Local Storage
Future<List<ComicPage>> buildReadableVolumeOfMemoryImages(
    BuildReadableVolumeArgs args) async {
  final inputStream = InputFileStream(args.absoluteVolumeReadPath);
  final archive = ZipDecoder().decodeBuffer(inputStream);
  late Map<String, ComicImageSize> sizes;

  try {
    final init =
        (localStorage.getItem("${args.absoluteVolumeReadPath}-image-sizes")
                as Map<String, dynamic>?) ??
            {};

    sizes = init
        .map((key, value) => MapEntry(
            key,
            ComicImageSize(
                width: init[key]['width'], height: init[key]['height'])))
        .cast<String, ComicImageSize>();
  } catch (err) {
    debugPrint(err.toString());
  }

  final pages = await Future.wait(archive.files.where((file) {
    return lookupMimeType(file.name)?.split("/").first == "image";
  }).map((file) async {
    if (sizes.isNotEmpty) {
      final decoded = sizes[file.name];
      return ComicPage(
          file: file, height: decoded!.height, width: decoded.width);
    }

    final decoded = await decodeImageFromList(file.content);
    sizes[file.name] =
        ComicImageSize(width: decoded.width, height: decoded.height);

    return ComicPage(file: file, height: decoded.height, width: decoded.width);
  }));

  localStorage.setItem("${args.absoluteVolumeReadPath}-image-sizes", sizes);

  pages.sort((a, b) => a.file.name.compareTo(b.file.name));

  return pages;
}

// TODO: Greatly Needs Optimization
Future<List<ComicPage>> buildReadableVolumeOfMemoryImagesTempCached(
    BuildReadableVolumeArgs args) async {
  final inputStream = InputFileStream(args.absoluteVolumeReadPath);
  final archive = ZipDecoder().decodeBuffer(inputStream);
  final tempDir = Directory(args.tempDir.path);
  late Map<String, ComicImageSize> sizes;

  final seriesName =
      args.absoluteVolumeReadPath.split("/").reversed.skip(1).first;
  final volumeName = basenameWithoutExtension(
      args.absoluteVolumeReadPath.split("/").reversed.first);

  final cachedSizes =
      File("${tempDir.path}/$seriesName/$volumeName/sizes.json");
  final doesCachedSizesExist = await cachedSizes.exists();

  if (doesCachedSizesExist) {
    try {
      sizes = jsonDecode(await cachedSizes.readAsString())
          .map((key, value) => MapEntry(key,
              ComicImageSize(width: value['width'], height: value['height'])))
          .cast<String, ComicImageSize>();
    } catch (err) {
      debugPrint(err.toString());
    }
  } else {
    sizes = {};
  }

  final pages = await Future.wait(archive.files
      .where((file) => lookupMimeType(file.name)?.split("/").first == "image")
      .map((file) async {
    if (doesCachedSizesExist) {
      final decoded = sizes[file.name];
      return ComicPage(
          file: file, height: decoded!.height, width: decoded.width);
    }

    // TODO: First time calling file.content is extremely heavy
    final decoded = await decodeImageFromList(file.content);
    sizes[file.name] =
        ComicImageSize(width: decoded.width, height: decoded.height);

    return ComicPage(file: file, height: decoded.height, width: decoded.width);
  }));

  if (!doesCachedSizesExist) {
    await cachedSizes.create();
    await cachedSizes.writeAsString(json.encode(sizes));
  }

  pages.sort((a, b) => a.file.name.compareTo(b.file.name));

  return pages;
}

Future<void> calculateImageSizesForSeries(String folderResource) async {
  final volumes = Directory(folderResource)
      .listSync()
      .whereType<File>()
      .where((file) => extension(file.path) == '.cbz')
      .toList();

  await Future.wait(volumes.map(
      (volume) async => await compute(calculateImageSizesForVolume, volume)));
}

Future<void> calculateImageSizesForVolume(File cbzVolume) async {
  final inputStream = InputFileStream(cbzVolume.path);
  final archive = ZipDecoder().decodeBuffer(inputStream);

  final Map<String, ComicImageSize> sizes =
      localStorage.getItem("${cbzVolume.path}-image-sizes") ?? {};

  if (sizes.isNotEmpty) {
    return;
  }

  await Future.wait(archive.files.where((file) {
    return lookupMimeType(file.name)?.split("/").first == "image";
  }).map((file) async {
    final image = img.decodeImage(file.content);
    sizes[file.name] =
        ComicImageSize(width: image!.width, height: image.height);
  }));

  localStorage.setItem("${cbzVolume.path}-image-sizes", sizes);
}

// Future<Stream<ComicPage>> buildStreamReadableVolumeOfMemoryImages(BuildReadableVolumeArgs args) async {
//   final inputStream = InputFileStream(args.volumeReadPath);
//   final archive = ZipDecoder().decodeBuffer(inputStream);
//
//   archive.
// }
