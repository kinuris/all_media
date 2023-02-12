import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/util/computations.dart';

Widget tempDirectoryProvider(
    {Widget loading = const Placeholder(),
    required Widget Function(BuildContext context, Directory tempDir)
        builder}) {
  Future<Directory> tempDirectoryFuture() async {
    return await getTemporaryDirectory();
  }

  return FutureBuilder(
    future: tempDirectoryFuture(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return loading;
      }

      return builder(context, snapshot.data!);
    },
  );
}

Widget waitForFuture(
    {Widget loading = const Placeholder(),
    required Future future,
    required Widget Function(BuildContext context) builder}) {
  return FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return loading;
      }

      return builder(context);
    },
  );
}

Widget doesVolumeHaveCachedSizes(
    {Widget loading = const Placeholder(),
    required String absoluteVolumeReadPath,
    required Widget Function(BuildContext context, bool cached) builder}) {
  return tempDirectoryProvider(
    loading: loading,
    builder: (context, tempDir) {
      final seriesName =
          absoluteVolumeReadPath.split("/").reversed.skip(1).first;
      final volumeName = basenameWithoutExtension(
          absoluteVolumeReadPath.split("/").reversed.first);

      final cachedSizes =
          File("${tempDir.path}/$seriesName/$volumeName/sizes.json");

      return FutureBuilder(
        future: cachedSizes.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return loading;
          }

          return builder(context, snapshot.data!);
        },
      );
    },
  );
}

Future<void> provideTempDirectoryForGenThumbnailFolderResource(
    String folderResource) async {
  await compute(
      genThumbnailFolderResource,
      GenFolderResourceThumbnailArgs(
          folderResource: folderResource,
          tempDir: await getTemporaryDirectory()));
  // await compute(calculateImageSizesForSeries, folderResource);
}
