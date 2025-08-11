import 'dart:io';

class System {
  static String getOperatingSystem() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }

  static bool isLinux() {
    if (getOperatingSystem() == "Linux") return true;
    return false;
  }

  static bool isWindows() {
    if (getOperatingSystem() == "Windows") return true;
    return false;
  }

  static bool isAndroid() {
    if (getOperatingSystem() == "Android") return true;
    return false;
  }
}
