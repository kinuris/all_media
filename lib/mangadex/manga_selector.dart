import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:v_2_all_media/mangadex/api_types.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:v_2_all_media/util/helpers.dart';
import 'package:v_2_all_media/util/local_storage_init.dart';

enum MangaSelectorAction { initialization, addManga, deleteManga }

class MangaDexMangaSelector extends StatefulWidget {
  const MangaDexMangaSelector({Key? key}) : super(key: key);

  @override
  State<MangaDexMangaSelector> createState() => _MangaDexMangaSelectorState();
}

class _MangaDexMangaSelectorState extends State<MangaDexMangaSelector> {
  MangaSelectorAction action = MangaSelectorAction.initialization;
  final _textEditingController = TextEditingController();
  final List<String> _mangaIds =
      (localStorage.getItem("MangaDex-manga") as List<dynamic>?)
              ?.map((elem) => elem.toString())
              .toList() ??
          [];

  setMangaIds(List<String> mangaIds) {
    setState(() {
      _mangaIds.clear();
      _mangaIds.addAll(mangaIds);
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await localStorage.setItem("MangaDex-manga", _mangaIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: const EdgeInsets.all(12),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            icon: const Icon(
                              Icons.settings_system_daydream,
                              size: 30,
                            ),
                            // ignore: prefer_const_constructors
                            title: Text(
                              "MangaDex Manga ID",
                              textAlign: TextAlign.center,
                            ),
                            content: TextField(
                              controller: _textEditingController,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (_textEditingController.text == "") {
                                    return;
                                  }

                                  if (!_mangaIds
                                      .contains(_textEditingController.text)) {
                                    setMangaIds([
                                      ..._mangaIds,
                                      _textEditingController.text
                                    ]);
                                  } else {
                                    showSnackBarMessage(context,
                                        "Chapter ID Already registered");
                                  }

                                  _textEditingController.clear();
                                  Navigator.pop(context);
                                },
                                child: const Text("Submit"),
                              ),
                              TextButton(
                                onPressed: () {
                                  _textEditingController.clear();
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    splashColor: Colors.orange.withOpacity(0.3),
                    icon: const Icon(
                      Icons.playlist_add,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(12),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.download,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(
                    width: 200,
                    child: AutoSizeText(
                      "MangaDex Manga Selector",
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _mangaIds.length,
                separatorBuilder: (context, index) => const SizedBox(height: 3),
                itemBuilder: (context, index) {
                  return Dismissible(
                    background: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.download,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "X",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        _mangaIds.removeAt(index);
                      });
                    },
                    key: ValueKey("$index+${_mangaIds[index]}"),
                    child: waitForFuture(
                      loading: Container(
                        color: Colors.grey[850],
                        child: ListTile(
                          visualDensity: const VisualDensity(vertical: 4),
                          contentPadding: const EdgeInsets.all(6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: const SizedBox(
                              width: 40,
                              child: SpinKitCircle(
                                color: Colors.orange,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      future: MangaDexMangaAggregateResult.id(_mangaIds[index]),
                      builder: (context, data) {
                        if (data == null) {
                          return const Icon(
                            Icons.error,
                            size: 30,
                            color: Colors.orange,
                          );
                        }

                        return Container(
                          color: Colors.grey[850],
                          child: ListTile(
                            visualDensity: const VisualDensity(vertical: 4),
                            contentPadding: const EdgeInsets.all(6),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: SizedBox(
                                width: 60,
                                height: 150,
                                child: Image.network(
                                  data.coverLink,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: AutoSizeText(
                              data.manga.data.attributes.titles['en'] ??
                                  data.manga.data.attributes.titles['jp-ro'] ??
                                  data.manga.data.attributes.titles['jp']!,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.info,
                                color: Colors.orange,
                                size: 30,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
