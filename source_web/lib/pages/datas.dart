import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class DriveDatas {
  static int bytesOnImageCache = 0;

  /// Save datas of type: string, bool, int and double
  static Future saveData(String dataName, dynamic dataValue) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    if (dataValue.runtimeType == String) {
      await preferences.setString(dataName, dataValue);
    } else if (dataValue.runtimeType == List<String>) {
      await preferences.setStringList(dataName, dataValue);
    } else if (dataValue.runtimeType == bool) {
      await preferences.setBool(dataName, dataValue);
    } else if (dataValue.runtimeType == int) {
      await preferences.setInt(dataName, dataValue);
    } else if (dataValue.runtimeType == double) {
      await preferences.setDouble(dataName, dataValue);
    } else {
      throw "The Type is not Compatibile";
    }
  }

  /// Read data based in name and type, the types consist in: 'string', 'int', 'bool', 'double'
  static Future<dynamic> readData(String dataName, String dataType) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    switch (dataType) {
      case "string":
        return preferences.getString(dataName);
      case "stringlist":
        return preferences.getStringList(dataName);
      case "double":
        return preferences.getDouble(dataName);
      case "int":
        return preferences.getInt(dataName);
      case "bool":
        return preferences.getBool(dataName);
    }
    throw "Invalid Data Type";
  }

  /// Remove a data based in data name
  static void removeData(String dataName) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(dataName);
  }

  /// Clean all data saved
  static Future clearData() async {
    bytesOnImageCache = 0;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  /// Stores the image bytes into localstorage
  static Future saveSingleImageOnCache(String imageName, List<int> bytes) {
    bytesOnImageCache += bytes.length;
    if (bytesOnImageCache >= 1000000) return Future.error("Image Storage Full");
    return saveData("cacheImages_$imageName", bytes.map((intItem) => intItem.toString()).toList());
  }

  /// Receives the image bytes from localstorage
  static Future<Uint8List> getSingleImageOnCache(String imageName) async {
    // Get image from storage
    List<String>? imageData = await readData("cacheImages_$imageName", "stringlist");
    // Image not found
    if (imageData == null) return Future.error("Image not found");

    // Converting to bytes
    Uint8List bytes = Uint8List.fromList(imageData.map((stringItem) => int.parse(stringItem)).toList());

    return bytes;
  }
}
