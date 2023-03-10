import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/comic_reader/comic_volume_settings.dart';
import 'package:v_2_all_media/util/computations.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:extended_image/extended_image.dart' as ext_img;

class VolumesDisplay extends StatelessWidget {
  final String folderResourcePath;

  const VolumesDisplay({Key? key, required this.folderResourcePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: tempDirectoryProvider(
        loading: Container(),
        builder: (context, tempDir) {
          return FutureBuilder(
            future: compute(
                buildVolumes,
                BuildVolumesArgs(
                    absoluteSeriesPath: folderResourcePath, tempDir: tempDir)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SpinKitFadingCube(
                  color: Colors.orange,
                  size: 100,
                );
              }

              final gridData =
                  snapshot.data!.thumbnails.mapIndexed((index, thumbnail) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/comic-volume-reader',
                      arguments: ComicVolumeReaderArgs(
                          sortedVolumePaths: snapshot.data!.sortedVolumePaths,
                          absoluteVolumePath:
                              snapshot.data!.sortedVolumePaths[index],
                          indexInSortedVolumes: index),
                    );
                  },
                  child: Image(
                    fit: BoxFit.cover,
                    image: ext_img.ExtendedFileImageProvider(thumbnail),
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }

                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 500),
                        child: child,
                      );
                    },
                  ),
                );
              }).toList();

              return SizedBox(
                height: MediaQuery.of(context).size.height - 60,
                child: GridView.count(
                  childAspectRatio: 1 / 1.5,
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 5,
                  children: gridData,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: FORGET ABOUT IT

class ComicVolumesDisplay extends StatefulWidget {
  final ComicVolumeDisplayArgs arguments;

  const ComicVolumesDisplay({Key? key, required this.arguments})
      : super(key: key);

  @override
  State<ComicVolumesDisplay> createState() => _ComicVolumesDisplayState();
}

class _ComicVolumesDisplayState extends State<ComicVolumesDisplay> {
  int _currentPageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 60,
        onDestinationSelected: (value) {
          if (_currentPageIndex != value) {
            setState(() {
              _currentPageIndex = value;
            });
          }
        },
        selectedIndex: _currentPageIndex,
        backgroundColor: Colors.grey[850],
        destinations: const [
          NavigationDestination(
              selectedIcon: Icon(
                Icons.settings,
                color: Colors.orange,
                size: 30,
              ),
              icon: Icon(
                Icons.settings,
                color: Colors.white,
                size: 35,
              ),
              label: "Settings"),
          NavigationDestination(
              selectedIcon: Icon(
                Icons.pages,
                color: Colors.orange,
                size: 30,
              ),
              icon: Icon(
                Icons.pages,
                color: Colors.white,
                size: 35,
              ),
              label: "Volumes")
        ],
      ),
      body: AnimatedCrossFade(
          firstChild: const VolumeDisplaySettings(),
          secondChild:
              VolumesDisplay(folderResourcePath: widget.arguments.folderPath),
          crossFadeState: _currentPageIndex == 0
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300)),
    );
  }
}
