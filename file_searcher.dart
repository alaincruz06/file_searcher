// dart
import 'dart:async';
import 'dart:io';

// packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_ex/path_provider_ex.dart';

// local files

String permissionMessage = '''
    \n
    Try to add thes lines to your AndroidManifest.xml file

          `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>`
          `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>`

    and grant storage permissions to your applicaion from app settings
    \n
''';

class FileManager {
  // The start point .
  Directory root;

  FileManager({required this.root});

  /// Return list tree of directories.
  /// You may exclude some directories from the list.
  /// * [excludedPaths] will excluded paths and their subpaths from the final [list]
  Future<List<Directory>> dirsTree({
    required List<String> excludedPaths,
    bool followLinks = false,
    bool excludeHidden = false,
  }) async {
    List<Directory> dirs = [];

    try {
      var contents = root.listSync(recursive: true, followLinks: followLinks);

      for (var fileOrDir in contents) {
        if (fileOrDir is Directory) {
          for (var excludedPath in excludedPaths) {
            if (!p.isWithin(excludedPath, p.normalize(fileOrDir.path))) {
              if (!excludeHidden) {
                dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
              } else {
                if (!fileOrDir.absolute.path.contains(RegExp(r"\.[\w]+"))) {
                  dirs.add(Directory(p.normalize(fileOrDir.absolute.path)));
                }
              }
            }
          }
        }
      }
    } catch (error) {
      throw (permissionMessage + error.toString());
    }
/*     if (dirs != null) {
      return sortBy(dirs, sortedBy);
    } */

    return dirs;
  }

  /// Return tree [List] of files starting from the root of type [File]
  /// * [excludedPaths] example: '/storage/emulated/0/Android' no files will be
  ///   returned from this path, and its sub directories
  Future<List<File>> filesTree({
    required List<String> extensions,
    required List<String> excludedPaths,
    excludeHidden = false,
  }) async {
    List<File> files = [];

    List<Directory> dirs =
        await dirsTree(excludedPaths: excludedPaths, excludeHidden: excludeHidden);

    dirs.insert(0, Directory(root.path));

    for (var dir in dirs) {
      for (var file in await listFiles(dir.absolute.path, extensions: extensions)) {
        if (excludeHidden) {
          if (!file.path.startsWith(".")) {
            files.add(file);
          } else {
            debugPrint("Excluded: ${file.path}");
          }
        } else {
          files.add(file);
        }
      }
    }

    return files;
  }

  /// This function returns files' paths list only from  specific location.
  /// * You may specify the types of the files you want to get by supplying the optional
  /// [extensions].
  static Future<List<File>> listFiles(
    String path, {
    required List<String> extensions,
    followsLinks = false,
    excludeHidden = false,
  }) async {
    List<File> files = [];

    try {
      List contents = Directory(path).listSync(followLinks: followsLinks, recursive: false);

      // Future<List<String>> extensionsPatterns =
      //     RegexTools.makeExtensionPatterns(extensions);
      for (var fileOrDir in contents) {
        if (fileOrDir is File) {
          String file = p.normalize(fileOrDir.path);
          for (var extension in extensions) {
            if (p.extension(file).replaceFirst(".", "") == extension.replaceFirst('.', '')) {
              if (excludeHidden) {
                if (file.startsWith('.')) files.add(File(p.normalize(fileOrDir.absolute.path)));
              } else {
                files.add(File(p.normalize(fileOrDir.absolute.path)));
              }
            }
          }
        }
      }
    } catch (error) {
      throw (error.toString());
    }

    return files;
  }
}

class GetFilesPage extends StatefulWidget {
  const GetFilesPage({Key? key}) : super(key: key);

  @override
  State<GetFilesPage> createState() => _GetFilesPageState();
}

class _GetFilesPageState extends State<GetFilesPage> {
  List<File>? files;

  void getFiles() async {
    //asyn function to get list of files
    List<StorageInfo> storageInfo = await PathProviderEx.getStorageInfo();
    var root = storageInfo[0].rootDir; //storageInfo[1] for SD card, geting the root directory
    var fm = FileManager(
      root: Directory(root),
    );
    files = await fm.filesTree(
        //set fm.dirsTree() for directory/folder tree list
        excludedPaths: ["/storage/emulated/0/Android"],
        extensions: ["mp3"] //optional, to filter files, remove to list all,
        //remove this if your are grabbing folder list
        );
    setState(() {}); //update the UI
  }

  @override
  void initState() {
    getFiles(); //call getFiles() function on initial state.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: files == null
          ? const Text("Searching Files")
          : ListView.builder(
              //if file/folder list is grabbed, then show here
              itemCount: files?.length ?? 0,
              itemBuilder: (context, index) {
                return Card(
                    child: ListTile(
                  title: Text(files![index].path.split('/').last),
                  leading: const Icon(Icons.image),
                  trailing: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                ));
              },
            ),
    );
  }
}
