import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:v_2_all_media/util/helpers.dart';
import 'package:v_2_all_media/util/local_storage_init.dart';

class MangaDexChapterSelector extends StatefulWidget {
  const MangaDexChapterSelector({super.key});

  @override
  State<MangaDexChapterSelector> createState() =>
      _MangaDexChapterSelectorState();
}

class _MangaDexChapterSelectorState extends State<MangaDexChapterSelector> {
  final _textController = TextEditingController();
  final List<String> _chapterIds =
      (localStorage.getItem("MangaDex-chapters") as List<dynamic>?)
              ?.map((elem) => elem.toString())
              .toList() ??
          [];

  setChapterIds(List<String> chapterIds) {
    setState(() {
      _chapterIds.clear();
      _chapterIds.addAll(chapterIds);
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await localStorage.setItem("MangaDex-chapters", _chapterIds);
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
                            title: const Text(
                              "MangaDex Chapter ID",
                              textAlign: TextAlign.center,
                            ),
                            content: TextField(
                              controller: _textController,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  _textController.clear();
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_textController.text == "") {
                                    return;
                                  }

                                  if (!_chapterIds
                                      .contains(_textController.text)) {
                                    setChapterIds(
                                        [..._chapterIds, _textController.text]);
                                  } else {
                                    showSnackBarMessage(context,
                                        "Chapter ID Already registered");
                                  }

                                  _textController.clear();
                                  Navigator.pop(context);
                                },
                                child: const Text("Submit"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    splashColor: Colors.orange.withOpacity(0.3),
                    icon: const Icon(
                      Icons.playlist_add_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  IconButton(
                      padding: const EdgeInsets.all(12),
                      splashColor: Colors.orange.withOpacity(0.3),
                      onPressed: () {},
                      icon: const Icon(Icons.download,
                          color: Colors.orange, size: 30)),
                  const SizedBox(
                    width: 200,
                    child: AutoSizeText(
                      "MangaDex Chapter Selector",
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chapterIds.length,
                shrinkWrap: true,
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
                        debugPrint("Removed: ${_chapterIds.removeAt(index)}");
                      });
                    },
                    key: ValueKey("$index+${_chapterIds[index]}"),
                    child: waitForFuture(
                      loading: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(12)),
                          height: 50,
                          width: 50,
                          child: const SpinKitCircle(
                            size: 30,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      future: getMangaDexChapterCover(_chapterIds[index]),
                      builder: (context, data) {
                        if (data == null) {
                          return const Icon(
                            Icons.error,
                            size: 30,
                            color: Colors.orange,
                          );
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              height: 50,
                              width: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: data.coverImage,
                              )),
                          title: AutoSizeText(
                            data.title != ""
                                ? data.title
                                : "Chapter ${data.chapterNumber}",
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            onPressed: () {},
                            splashColor: Colors.orange.withOpacity(0.3),
                            icon: const Icon(
                              Icons.info,
                              color: Colors.orange,
                              size: 30,
                            ),
                          ),
                          subtitle: const AutoSizeText(
                            "From: ",
                            maxLines: 1,
                            maxFontSize: 12,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
