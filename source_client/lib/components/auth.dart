import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _username = "anonymous";
  String get username => _username;
  void changeUsername(value) => _username = value;

  String _auth = "";
  String get auth => _auth;
  void changeAuth(value) => _auth = value;
  String getAuthWithTimetamp() => "$auth-${DateTime.now().millisecondsSinceEpoch}";
}
