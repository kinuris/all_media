import 'package:flutter/material.dart';
import 'package:v_2_all_media/util/arguments.dart';
import 'package:v_2_all_media/util/computations.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:v_2_all_media/util/helpers.dart';
import 'package:v_2_all_media/comic_reader/root.dart';

class FolderDisplay extends StatelessWidget {
  final List<String> folders;
  final RootAction parentAction;
  final void Function(String folderResource) removeFolderResource;

  const FolderDisplay(
      {Key? key,
      required this.folders,
      required this.parentAction,
      required this.removeFolderResource})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final noFolderDisplay = Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade600.withOpacity(0.3),
            const Color(0xFF444444).withOpacity(0.9)
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade900.withOpacity(0.1),
            offset: Offset.fromDirection(10, -5),
          )
        ],
      ),
      child: Center(
        child: Text(
          "No Folders Added",
          style: TextStyle(
            color: Colors.black.withOpacity(0.4),
            fontSize: 27,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final hasFolderDisplay = LayoutBuilder(
      builder: (innerContext, constraints) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(6),
            width: constraints.maxWidth * 0.90,
            height: constraints.maxHeight * 0.85,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(16),
              ),
              color: Colors.black.withOpacity(0.7),
            ),
            child: GridView.count(
              childAspectRatio: 1 / 1.5,
              crossAxisCount: 3,
              padding: EdgeInsets.zero,
              crossAxisSpacing: 5,
              mainAxisSpacing: 6,
              children: folders
                  .map((folder) => FolderEntry(
                        folderPath: folder,
                        removeFolderResource: removeFolderResource,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );

    return folders.isEmpty ? noFolderDisplay : hasFolderDisplay;
  }
}

class FolderEntry extends StatelessWidget {
  final String folderPath;
  final void Function(String folder) removeFolderResource;

  const FolderEntry(
      {Key? key, required this.folderPath, required this.removeFolderResource})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return tempDirectoryProvider(
      loading: Container(),
      builder: (context, tempDir) {
        return FutureBuilder(
          future: resolveThumbnails(
              ResolveThumbnailArgs(folderPath: folderPath, tempDir: tempDir)),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Container(
                  color: Colors.transparent,
                );
              }

              return Container(
                color: Colors.transparent,
                child: IconButton(
                    icon: const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      removeFolderResource(folderPath);
                      showSnackBarMessage(context,
                          "Removed Bad Directory: ${folderPath.split("/").last}");
                    }),
              );
            }

            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                  child: Image.file(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  ),
                ),
                Material(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                    overlayColor: MaterialStatePropertyAll(
                      Colors.orange.withOpacity(0.2),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/comic-volumes-display',
                          arguments:
                              ComicVolumeDisplayArgs(folderPath: folderPath));
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Delete?"),
                            content:
                                const Text("Do you want to delete resource?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () {
                                  removeFolderResource(folderPath);
                                  showSnackBarMessage(context,
                                      "Removed Folder Resource: ${folderPath.split("/").last}");

                                  Navigator.pop(context);
                                },
                                child: const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
