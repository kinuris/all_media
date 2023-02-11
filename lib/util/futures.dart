import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

Future<void> provideTempDirectoryForGenThumbnailFolderResource(
    String folderResource) async {
  await compute(
      genThumbnailFolderResource,
      GenFolderResourceThumbnailArgs(
          folderResource: folderResource,
          tempDir: await getTemporaryDirectory()));
  // await compute(calculateImageSizesForSeries, folderResource);
}
