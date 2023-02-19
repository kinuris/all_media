import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class MangaDexChapterSelector extends StatefulWidget {
  const MangaDexChapterSelector({super.key});

  @override
  State<MangaDexChapterSelector> createState() =>
      _MangaDexChapterSelectorState();
}

class _MangaDexChapterSelectorState extends State<MangaDexChapterSelector> {
  final List<String> _chapterIds = [
    "Sample",
    "Life",
    "Is World",
    "Hello",
    "I am Here"
  ];

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
                                "MangaDex Chapter ID",
                                textAlign: TextAlign.center,
                              ),
                              content: const TextField(),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Submit"),
                                ),
                                TextButton(
                                  onPressed: () {
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
                )),
            Expanded(
              child: ListView.builder(
                itemCount: _chapterIds.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Dismissible(
                    onDismissed: (direction) {
                      setState(() {
                        debugPrint("Removed: ${_chapterIds.removeAt(index)}");
                      });
                    },
                    key: ValueKey("$index+${_chapterIds[index]}"),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        height: 50,
                        width: 50,
                      ),
                      title: Text(
                        _chapterIds[index],
                        style: const TextStyle(color: Colors.white),
                      ),
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
