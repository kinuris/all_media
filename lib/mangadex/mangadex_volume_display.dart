import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:v_2_all_media/mangadex/api_types.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/util/exceptions.dart';
import 'package:v_2_all_media/util/futures.dart';

class MangaDexVolumeDisplay extends StatefulWidget {
  final MangaDexMangaAggregateResult args;

  const MangaDexVolumeDisplay({
    super.key,
    required this.args,
  });

  @override
  State<MangaDexVolumeDisplay> createState() => _MangaDexVolumeDisplayState();
}

class _MangaDexVolumeDisplayState extends State<MangaDexVolumeDisplay> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: ListView.separated(
            itemBuilder: (context, index) {
              return Container(
                color: Colors.grey[850],
                child: GestureDetector(
                  onTapUp: (details) {
                    Navigator.pushNamed(context, '/mangadex-volume-reader',
                        arguments: MangaDexChapterReaderArgs(
                            currentIndex: index, result: widget.args));
                  },
                  child: ListTile(
                    title: waitForFuture(
                      loading: const SpinKitRing(
                        color: Colors.orange,
                        size: 30,
                        lineWidth: 1,
                      ),
                      future: Future(() async {
                        try {
                          return await widget.args.sortedChapters[index]
                              .getChapterData();
                        } on InvalidChapterException {
                          return MangaDexGetChapterResult.errState();
                        }
                      }),
                      builder: (context, data) {
                        return AutoSizeText(
                          "Chapter ${data.data.attributes.chapter} ${data.data.attributes.title == "" || data.data.attributes.title == "Chapter ${data.data.attributes.chapter}" ? "" : "- ${data.data.attributes.title}"}",
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 3),
            itemCount: widget.args.totalChapterCount),
      ),
    );
  }
}
