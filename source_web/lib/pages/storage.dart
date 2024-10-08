import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static final _storageInstance = SharedPreferences.getInstance();

  static Future saveData(String dataId, dynamic data) async {
    final SharedPreferences storageInstance = await _storageInstance;
    switch (data.runtimeType.toString()) {
      case "String":
        await storageInstance.setString(dataId, data);
        break;
      case "bool":
        await storageInstance.setBool(dataId, data);
        break;
      case "int":
        await storageInstance.setInt(dataId, data);
        break;
    }
  }

  static Future<Object?> getData(String dataId) async {
    final SharedPreferences storageInstance = await _storageInstance;
    return storageInstance.get(dataId);
  }

  static Future removeData(String dataId) async {
    final SharedPreferences storageInstace = await _storageInstance;
    return storageInstace.remove(dataId);
  }
}
