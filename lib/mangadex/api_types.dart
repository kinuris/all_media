import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class MangaDexMangaAggregateResult {
  final String result;
  final String coverLink;
  final MangaDexGetMangaResult manga;
  final List<MangaDexMangaAggregateVolumes> volumes;

  static Future<MangaDexMangaAggregateResult?> id(String mangaId) async {
    final res = await http.get(
      Uri.parse(
          "https://api.mangadex.org/manga/$mangaId/aggregate?translatedLanguage%5B%5D=en"),
      headers: {
        HttpHeaders.userAgentHeader: 'all_media/1.0',
      },
    );

    if (res.statusCode >= 400) {
      debugPrint(
          "Failed: ${"https://api.mangadex.org/manga/$mangaId/aggregate"} -- ${res.reasonPhrase}");
      return null;
    }

    final Map decodedBody = jsonDecode(res.body);

    final result = decodedBody['result'];
    final volumes =
        MangaDexMangaAggregateVolumes.fromJson(decodedBody['volumes']);


    // for (var volume in volumes) {
    //   for (var chapter in volume.chapters) {
    //     debugPrint(chapter.chapter);
    //   }
    // }

    // volumes.sort(
    //     (a, b) => double.parse(a.volume).compareTo(double.parse(b.volume)));


    final chapterId = volumes.reversed.first.chapters.reversed.first.id;

    final coverResult = await http.get(
      Uri.parse("https://api.mangadex.org/at-home/server/$chapterId"),
      headers: {
        HttpHeaders.userAgentHeader: 'all_media/1.0',
      },
    );

    final decodedCoverResultBody = jsonDecode(coverResult.body);
    final chapterHash = decodedCoverResultBody['chapter']['hash'];
    final coverEndpoint = decodedCoverResultBody['chapter']['data'][0];

    final coverLink =
        "${decodedCoverResultBody['baseUrl']}/data/$chapterHash/$coverEndpoint?scale=0.1";

    final mangaResult = await MangaDexGetMangaResult.id(mangaId);

    if (mangaResult == null) {
      return null;
    }

    return MangaDexMangaAggregateResult(
        result: result, volumes: volumes, coverLink: coverLink, manga: mangaResult);
  }

  int get totalChapterCount {
    int total = 0;
    for (var volume in volumes) {
      total += volume.chapters.length;
    }

    return total;
  }

  const MangaDexMangaAggregateResult({
    required this.result,
    required this.volumes,
    required this.coverLink,
    required this.manga,
  });
}

class MangaDexMangaAggregateVolumes {
  final String volume;
  final int count;
  final List<MangaDexMangaAggregateChapter> chapters;

  static List<MangaDexMangaAggregateVolumes> fromJson(
      Map<dynamic, dynamic> map) {
    return map.keys.map((key) {
      var volume = map[key];

      String volumeNumber = volume['volume'];
      int volumeCount = volume['count'];
      List<MangaDexMangaAggregateChapter> volumeChapters =
          MangaDexMangaAggregateChapter.fromJson(volume['chapters']);

      return MangaDexMangaAggregateVolumes(
          count: volumeCount, chapters: volumeChapters, volume: volumeNumber);
    }).toList();
  }

  const MangaDexMangaAggregateVolumes({
    required this.count,
    required this.chapters,
    required this.volume,
  });
}

class MangaDexMangaAggregateChapter {
  final String chapter;
  final String id;
  final List<String> others;
  final int count;

  static List<MangaDexMangaAggregateChapter> fromJson(
      Map<dynamic, dynamic> map) {
    return map.keys.map((key) {
      var chapter = map[key];

      String chapterNumber = chapter['chapter'];
      String chapterId = chapter['id'];
      int chapterCount = chapter['count'];
      List<String> others = (chapter['others'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      return MangaDexMangaAggregateChapter(
        chapter: chapterNumber,
        count: chapterCount,
        id: chapterId,
        others: others,
      );
    }).toList();
  }

  const MangaDexMangaAggregateChapter({
    required this.chapter,
    required this.count,
    required this.id,
    required this.others,
  });
}

class MangaDexGetMangaResult {
  final String result;
  final String response;
  final MangaDexGetMangaData data;

  static Future<MangaDexGetMangaResult?> id(String mangaId) async {
    final res = await http.get(
        Uri.parse("https://api.mangadex.org/manga/$mangaId"),
        headers: {HttpHeaders.userAgentHeader: 'all_media/1.0'});

    if (res.statusCode >= 400) {
      return null;
    }

    final decodedData = jsonDecode(res.body);
    final result = decodedData['result'];
    final response = decodedData['response'];
    final data = MangaDexGetMangaData.fromJson(decodedData['data']);

    return MangaDexGetMangaResult(result: result, data: data, response: response);
  }

  const MangaDexGetMangaResult({
    required this.result,
    required this.data,
    required this.response,
  });
}

class MangaDexGetMangaData {
  final String id;
  final String type;
  final MangaDexGetMangaDataAttrib attributes;

  static MangaDexGetMangaData fromJson(Map<String, dynamic> map) {
    final id = map['id'];
    final type = map['type'];

    final attributes = MangaDexGetMangaDataAttrib.fromJson(map['attributes']);

    return MangaDexGetMangaData(id: id, attributes: attributes, type: type);
  }

  const MangaDexGetMangaData({
    required this.id,
    required this.attributes,
    required this.type,
  });
}

class MangaDexGetMangaDataAttrib {
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String publicationDemographic;

  static MangaDexGetMangaDataAttrib fromJson(Map<String, dynamic> map) {

    final Map<String, String> descriptions = (map['description'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value.toString()));
    final String publicationDemographic = map['publicationDemographic'];
    final Map<String, String> titles = {};

    titles.addEntries((map['altTitles'] as List<dynamic>).cast<Map<String, dynamic>>().map(
            (titleObj) => MapEntry(titleObj.keys.first, titleObj.values.first)));

    return MangaDexGetMangaDataAttrib(
        titles: titles,
        descriptions: descriptions,
        publicationDemographic: publicationDemographic);
  }

  const MangaDexGetMangaDataAttrib({
    required this.titles,
    required this.descriptions,
    required this.publicationDemographic,
  });
}
