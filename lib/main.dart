import 'package:flutter/material.dart';
import 'package:simple_mangadex_api/api_types.dart';
import 'package:v_2_all_media/mangadex/chapter_selector.dart';
import 'package:v_2_all_media/mangadex/manga_selector.dart';
import 'package:v_2_all_media/mangadex/mangadex_volume_display.dart';
import 'package:v_2_all_media/mangadex/mangadex_volume_reader.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/comic_reader/comic_volume_reader.dart';
import 'package:v_2_all_media/comic_reader/comic_volumes_display.dart';
import 'package:v_2_all_media/util/local_storage_init.dart';
import 'package:v_2_all_media/comic_reader/root.dart';

void main() => runApp(const Init());

class Init extends StatelessWidget {
  const Init({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage("assets/comics_bg.webp"), context);

    return FutureBuilder(
      future: localStorage.ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
            navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                );
              }

              return null;
            })),
          ),
          title: "Idiot Watch",
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (context) => const Root(),
                  settings: const RouteSettings(name: '/'),
                );

              case '/comic-volumes-display':
                final args = settings.arguments as ComicVolumeDisplayArgs;

                return MaterialPageRoute(
                  builder: (context) => ComicVolumesDisplay(
                    arguments: args,
                  ),
                  settings: const RouteSettings(name: '/comic-volumes-display'),
                );
              case '/comic-volume-reader':
                final args = settings.arguments as ComicVolumeReaderArgs;

                return MaterialPageRoute(
                  builder: (context) => ComicVolumeReader(
                    arguments: args,
                  ),
                  settings: const RouteSettings(name: '/comic-volume-reader'),
                );
              case '/mangadex-chapter-selector':
                return MaterialPageRoute(
                    builder: (context) => const MangaDexChapterSelector(),
                    settings: const RouteSettings(
                        name: '/mangadex-chapter-selector'));
              case '/mangadex-manga-selector':
                return MaterialPageRoute(
                    builder: (context) => const MangaDexMangaSelector(),
                    settings:
                        const RouteSettings(name: '/mangadex-manga-selector'));
              case '/mangadex-volume-display':
                final args = settings.arguments as Manga;

                return MaterialPageRoute(
                    builder: (context) => MangaDexVolumeDisplay(args: args),
                    settings:
                        const RouteSettings(name: '/mangadex-volume-display'));
              case '/mangadex-volume-reader':
                final args = settings.arguments as MangaDexChapterReaderArgs;

                return MaterialPageRoute(
                    builder: (context) => MangaDexChapterReader(args: args),
                    settings:
                        const RouteSettings(name: '/mangadex-volume-reader'));
            }

            return null;
          },
        );
      },
    );
  }
}
