import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:v_2_all_media/util/exceptions.dart';

class MangaDexMangaAggregateResult {
  final String result;
  final String coverLink;
  final MangaDexGetMangaResult manga;
  final List<MangaDexMangaAggregateVolumes> volumes;

  static Future<MangaDexMangaAggregateResult?> id(
    String mangaId, {
    String lang = 'en',
  }) async {
    final res = await http.get(
      Uri.parse(
          "https://api.mangadex.org/manga/$mangaId/aggregate?translatedLanguage%5B%5D=$lang"),
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

    var chapterId = volumes.reversed.first.chapters.reversed.first.id;

    if (!await MangaDexGetChapterResult.hasData(chapterId)) {
      chapterId = volumes.reversed.first.chapters.reversed.first.others.first;
    }

    final coverResult = await http.get(
      Uri.parse("https://api.mangadex.org/at-home/server/$chapterId"),
      headers: {
        HttpHeaders.userAgentHeader: 'all_media/1.0',
      },
    );

    final decodedCoverResultBody = jsonDecode(coverResult.body);
    final chapterHash = decodedCoverResultBody['chapter']['hash'];

    final coverEndpoint = decodedCoverResultBody['chapter']['data'].first;
    final coverLink =
        "${decodedCoverResultBody['baseUrl']}/data/$chapterHash/$coverEndpoint?scale=0.1";

    final mangaResult = await MangaDexGetMangaResult.id(mangaId);

    if (mangaResult == null) {
      return null;
    }

    return MangaDexMangaAggregateResult(
        result: result,
        volumes: volumes,
        coverLink: coverLink,
        manga: mangaResult);
  }

  int get totalChapterCount {
    int total = 0;
    for (var volume in volumes) {
      total += volume.chapters.length;
    }

    return total;
  }

  List<MangaDexMangaAggregateChapter> get sortedChapters {
    final List<MangaDexMangaAggregateChapter> result = [];

    for (var volume in volumes.reversed) {
      for (var chapter in volume.chapters.reversed) {
        result.add(chapter);
      }
    }

    return result;
  }

  getAlternativeChapter(String chapterId) {
    final chapter =
        sortedChapters.where((chapter) => chapter.id == chapterId).first;

    return chapter.others.first;
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
  final List<String> others;
  final int count;
  final String id;
  List<String>? _imageLinks;
  MangaDexGetChapterResult? _result;

  // static List<MangaDexMangaAggregateChapter> fromListDyn(List<dynamic> list) {

  // }

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

  Future<MangaDexGetChapterResult> getChapterData() async {
    if (_result != null) {
      return _result!;
    }

    if (_result == null) {
      final res =
          await MangaDexGetChapterResult.chapterIdInfallible(id, others);
      _result = res;
      return res;
    }

    return _result!;
  }

  Future<List<String>> fetchImageLinks() async {
    if (_imageLinks == null) {
      final res = await MangaDexAtHomeServerResult.chapterIdInfallible(id);
      final links = res.chapterData
          .map((dataLink) => "${res.baseUrl}/data/${res.hash}/$dataLink")
          .toList();
      _imageLinks = links;

      return links;
    }

    return _imageLinks!;
  }

  MangaDexMangaAggregateChapter({
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

  static Future<bool> isValidId(String mangaId) async {
    final res = await http.get(
        Uri.parse("https://api.mangadex.org/manga/$mangaId"),
        headers: {HttpHeaders.userAgentHeader: 'all_media/1.0'});

    if (res.statusCode >= 400) {
      return false;
    }

    return true;
  }

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

    return MangaDexGetMangaResult(
        result: result, data: data, response: response);
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

  MangaDexGetMangaData({
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
    final Map<String, String> descriptions =
        (map['description'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value.toString()));
    final String publicationDemographic =
        map['publicationDemographic'] ?? "N/A";
    final Map<String, String> titles = {};

    titles.addEntries((map['altTitles'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((titleObj) =>
            MapEntry(titleObj.keys.first, titleObj.values.first)));

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

class MangaDexGetChapterResult {
  final String result;
  final String response;
  final MangaDexGetChapterData data;
  final List<String> others;

  static Future<bool> hasData(String chapterId) async {
    final coverResult = await http.get(
      Uri.parse("https://api.mangadex.org/at-home/server/$chapterId"),
      headers: {
        HttpHeaders.userAgentHeader: 'all_media/1.0',
      },
    );

    if (coverResult.statusCode >= 400) {
      return false;
    }

    final data = jsonDecode(coverResult.body);

    if ((data['chapter']['data'] as List<dynamic>).isEmpty) {
      return false;
    }

    return true;
  }

  static Future<MangaDexGetChapterResult> chapterIdInfallible(
      String chapterId, List<String> others) async {
    final res = await http.get(
        Uri.parse("https://api.mangadex.org/chapter/$chapterId"),
        headers: {
          HttpHeaders.userAgentHeader: 'all_media/1.0',
        });

    final decodeBody = jsonDecode(res.body);
    final result = decodeBody['result'];
    final response = decodeBody['response'];
    final data = MangaDexGetChapterData.fromJson(decodeBody['data'], others);

    return MangaDexGetChapterResult(
        data: data, response: response, result: result, others: others);
  }

  static MangaDexGetChapterResult errState() {
    return MangaDexGetChapterResult(
        data: MangaDexGetChapterData(
          type: "-1",
          id: "0",
          attributes: const MangaDexGetChapterDataAttrib(
            chapter: "-1",
            pages: -1,
            title: "",
            volume: "",
          ),
          others: [],
        ),
        response: "-1",
        result: "-1",
        others: []);
  }

  isErrState() {
    return response == "-1";
  }

  const MangaDexGetChapterResult({
    required this.others,
    required this.data,
    required this.response,
    required this.result,
  });
}

class MangaDexGetChapterData {
  final String id;
  final String type;
  final List<String> others;
  final MangaDexGetChapterDataAttrib attributes;
  List<String>? _imageLinks;

  static MangaDexGetChapterData fromJson(
      Map<String, dynamic> map, List<String> others) {
    final id = map['id'];
    final type = map['type'];
    final attributes = MangaDexGetChapterDataAttrib.fromJson(map['attributes']);

    return MangaDexGetChapterData(
        attributes: attributes, id: id, type: type, others: others);
  }

  Future<List<String>> fetchImageLinks() async {
    String id = this.id;

    if (!await MangaDexGetChapterResult.hasData(this.id)) {
      if (others.isEmpty) {
        throw InvalidChapterException();
      }

      id = others.first;
    }

    if (_imageLinks == null) {
      final res = await MangaDexAtHomeServerResult.chapterIdInfallible(id);
      final links = res.chapterData
          .map((dataLink) => "${res.baseUrl}/data/${res.hash}/$dataLink")
          .toList();
      _imageLinks = links;

      return links;
    }

    return _imageLinks!;
  }

  MangaDexGetChapterData({
    required this.others,
    required this.attributes,
    required this.id,
    required this.type,
  });
}

class MangaDexGetChapterDataAttrib {
  final String title;
  final String volume;
  final String chapter;
  final int pages;

  static MangaDexGetChapterDataAttrib fromJson(Map<String, dynamic> map) {
    final String title = map['title'] ?? "";
    final String volume = map['volume'] ?? "";
    final String chapter = map['chapter'];
    final int pages = map['pages'];

    return MangaDexGetChapterDataAttrib(
        chapter: chapter, pages: pages, title: title, volume: volume);
  }

  const MangaDexGetChapterDataAttrib({
    required this.chapter,
    required this.pages,
    required this.title,
    required this.volume,
  });
}

class MangaDexAtHomeServerResult {
  final String result;
  final String baseUrl;
  final String hash;
  final List<String> chapterData;
  final List<String> chapterDataSaver;

  static Future<MangaDexAtHomeServerResult> chapterIdInfallible(
      String chapterId) async {
    final res = await http.get(
      Uri.parse("https://api.mangadex.org/at-home/server/$chapterId"),
      headers: {
        HttpHeaders.userAgentHeader: 'all_media/1.0',
      },
    );

    final decodedBody = jsonDecode(res.body);
    final result = decodedBody['result'];
    final baseUrl = decodedBody['baseUrl'];
    final hash = decodedBody['chapter']['hash'];
    final List<String> chapterData =
        (decodedBody['chapter']['data'] as List<dynamic>).cast<String>();
    final List<String> chapterDataSaver =
        (decodedBody['chapter']['dataSaver'] as List<dynamic>).cast<String>();

    return MangaDexAtHomeServerResult(
        result: result,
        baseUrl: baseUrl,
        chapterData: chapterData,
        chapterDataSaver: chapterDataSaver,
        hash: hash);
  }

  const MangaDexAtHomeServerResult({
    required this.result,
    required this.baseUrl,
    required this.chapterData,
    required this.chapterDataSaver,
    required this.hash,
  });
}
