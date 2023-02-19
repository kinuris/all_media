import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v_2_all_media/util/futures.dart';
import 'package:v_2_all_media/util/helpers.dart';
import 'package:v_2_all_media/util/local_storage_init.dart';
import 'package:v_2_all_media/comic_reader/root_folder_display.dart';

class Root extends StatefulWidget {
  const Root({Key? key}) : super(key: key);

  @override
  State<Root> createState() => _RootState();
}

enum RootAction {
  addFolderResource,
  removeFolderResource,
  addMangaDexChapter,
  initialize
}

class _RootState extends State<Root> {
  final List<String> _folderResources = getLocalStorageFolderResources() ?? [];
  String? addedFolderResource;
  var action = RootAction.initialize;

  addFolderResource(String folderResource) {
    final previousLength = _folderResources.length;
    var tempList = [..._folderResources, folderResource];

    tempList = tempList.toSet().toList();
    final currentLength = tempList.length;

    if (currentLength > previousLength) {
      setState(() {
        action = RootAction.addFolderResource;
        addedFolderResource = folderResource;
        _folderResources.add(folderResource);

        setLocalStorageFolderResources(_folderResources);
      });
    }
  }

  void removeFolderResource(String folderResource) {
    if (_folderResources.contains(folderResource)) {
      setState(() {
        action = RootAction.removeFolderResource;
        _folderResources.remove(folderResource);

        setLocalStorageFolderResources(_folderResources);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      floatingActionButton: AddResourceFloatingActionButton(
        addFolderResource: addFolderResource,
      ),
      body: Stack(
        alignment:
            _folderResources.isEmpty ? Alignment.center : Alignment.topCenter,
        children: [
          const BackgroundImage(),
          const BackgroundGradient(),
          FolderDisplay(
            removeFolderResource: removeFolderResource,
            folders: _folderResources,
            parentAction: action,
          ),
        ],
      ),
    );

    if (action == RootAction.addFolderResource) {
      return FutureBuilder(
        future: provideTempDirectoryForGenThumbnailFolderResource(
            addedFolderResource!),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SpinKitFadingCube(
              color: Colors.orange,
              size: 100,
            );
          }

          return scaffold;
        },
      );
    }

    return scaffold;
  }

  static Future<void> setLocalStorageFolderResources(
      List<String> folderResources) async {
    return await localStorage.setItem("folder-resources", folderResources);
  }

  static List<String>? getLocalStorageFolderResources() {
    List<dynamic>? result = localStorage.getItem("folder-resources");

    return result?.map((dyn) => dyn.toString()).toList();
  }
}

// TODO: FORGET ABOUT IT

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xba0a0a00), Color(0xF0000000)],
          stops: [
            0.1,
            0.35,
            0.9,
          ],
        ),
      ),
    );
  }
}

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/comics_bg.webp"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class AddResourceFloatingActionButton extends StatefulWidget {
  final void Function(String folderResource) addFolderResource;

  const AddResourceFloatingActionButton({
    Key? key,
    required this.addFolderResource,
  }) : super(key: key);

  @override
  State<AddResourceFloatingActionButton> createState() =>
      _AddResourceFloatingActionButtonState();
}

class _AddResourceFloatingActionButtonState
    extends State<AddResourceFloatingActionButton> {
  final _isDialOpen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.orange,
      activeBackgroundColor: Colors.orange.withOpacity(0.5),
      openCloseDial: _isDialOpen,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.6,
      spaceBetweenChildren: 2,
      spacing: 20,
      direction: SpeedDialDirection.up,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.folder),
          backgroundColor: Colors.orange.withOpacity(0.3),
          foregroundColor: Colors.white,
          label: 'Folder Resource',
          labelBackgroundColor: Colors.orange,
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () async {
            await Permission.manageExternalStorage.request();
            final result = await FilePicker.platform.getDirectoryPath();

            if (result != null) {
              final cbzCount = Directory(result)
                  .listSync()
                  .where((file) => extension(file.path) == ".cbz")
                  .whereType<File>()
                  .toList()
                  .length;

              if (cbzCount < 1) {
                if (context.mounted) {
                  showSnackBarMessage(
                      context, "Folder resource must contain .cbz files",
                      millis: 1000);
                }

                return;
              }

              widget.addFolderResource(result);
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(
            Icons.settings_system_daydream,
            size: 25,
          ),
          backgroundColor: Colors.orange.withOpacity(0.3),
          foregroundColor: Colors.white,
          label: 'MangaDex Series',
          labelBackgroundColor: Colors.orange,
          labelStyle: const TextStyle(fontSize: 18.0),
        ),
        SpeedDialChild(
          child: const Icon(
            Icons.settings_system_daydream,
            size: 25,
          ),
          backgroundColor: Colors.orange.withOpacity(0.3),
          foregroundColor: Colors.white,
          label: 'MangaDex Chapter',
          labelBackgroundColor: Colors.orange,
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () {
            Navigator.pushNamed(context, '/mangadex-chapter-selector');
          },
        ),
      ],
    );
  }
}
