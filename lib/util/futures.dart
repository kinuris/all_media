import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/util/computations.dart';
import 'package:http/http.dart' as http;

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

Widget waitForFuture<T>(
    {Widget loading = const Placeholder(),
    required Future<T> future,
    required Widget Function(BuildContext context, T data) builder}) {
  return FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return loading;
      }

      return builder(context, snapshot.data as T);
    },
  );
}

class MangaDexChapter {
  final Image coverImage;
  final String title;
  final String chapterNumber;

  const MangaDexChapter(
      {required this.coverImage,
      required this.title,
      required this.chapterNumber});
}

Future<MangaDexChapter?> getMangaDexChapterCover(String chapterId) async {
  final res = await http.get(
      Uri.parse("https://api.mangadex.org/at-home/server/$chapterId"),
      headers: {
        HttpHeaders.userAgentHeader: 'all_media/1.0',
      });

  if (res.statusCode >= 400) {
    return null;
  }

  final decodedBody = jsonDecode(res.body);
  final chapterHash = decodedBody['chapter']['hash'];
  final coverEndpoint = decodedBody['chapter']['data'][0];

  final coverLink =
      "${decodedBody['baseUrl']}/data/$chapterHash/$coverEndpoint?scale=0.1";

  final rawChapterDataResponse =
      await http.get(Uri.parse("https://api.mangadex.org/chapter/$chapterId"));
  final decodedChapterData = jsonDecode(rawChapterDataResponse.body);

  final chapterTitle = decodedChapterData['data']['attributes']['title'];
  final chapterNumber = decodedChapterData['data']['attributes']['chapter'];

  return MangaDexChapter(
    coverImage: Image.network(
      coverLink,
      fit: BoxFit.cover,
    ),
    title: chapterTitle,
    chapterNumber: chapterNumber,
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
