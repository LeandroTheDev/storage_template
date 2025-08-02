import 'dart:async';

//Dependencies
import 'package:dio/dio.dart';
import 'package:drive/components/auth.dart';
import 'package:drive/components/cryptography.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/drive.dart';

//Packages
import 'package:flutter/material.dart';
import 'package:drive/main.dart';
import 'package:drive/components/storage.dart';
import 'package:provider/provider.dart';

class WebServer {
  static String serverAddress = "127.0.0.1:7979";

  ///Comunicates the server via http request and return a Map with the server response
  ///
  ///Example Post:
  ///```dart
  ///sendServerMessage(context, address: "/login", "drive", body: { "username": "test", "password": "123" } );
  ///```
  ///
  ///Example Get:
  ///```dart
  //////sendServerMessage(context, address: "/status", "drive", body: { "query": "test" } );
  ///```
  static Future<Response> sendMessage(
    BuildContext context, {
    required String address,
    required String api,
    Map<String, dynamic>? body,
    String requestType = "post",
  }) async {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? auth = authProvider.auth != "" ? await Cryptography.encryptText("${authProvider.auth}-${DateTime.now().millisecondsSinceEpoch}") : null;
    body ??= {};

    Future<Response> getRequest() async {
      Dio sender = Dio();
      sender.options.headers = {
        "username": authProvider.username,
        "auth": auth,
      };
      sender.options.validateStatus = (status) {
        status ??= 504;
        return status < 500;
      };
      return await sender.get("http://$serverAddress$address", queryParameters: body).catchError(
            (error) => Response(
              statusCode: 504,
              data: {
                "message": error == DioException
                    ? error.message
                    : isDebug
                        ? error.toString()
                        : "No connection"
              },
              requestOptions: RequestOptions(),
            ),
          );
    }

    Future<Response> postRequest() async {
      Dio sender = Dio();
      final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

      sender.options.headers = {
        "content-type": 'application/json',
        "username": authProvider.username,
        "auth": auth,
      };
      sender.options.validateStatus = (status) {
        status ??= 504;
        return status < 500;
      };
      return await sender.post("http://$serverAddress$address", data: body).catchError(
            (error) => Response(
              statusCode: 504,
              data: {
                "message": error == DioException
                    ? error.message
                    : isDebug
                        ? error.toString()
                        : "No connection"
              },
              requestOptions: RequestOptions(),
            ),
          );
    }

    Future<Response> deleteRequest() async {
      Dio sender = Dio();
      final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

      sender.options.headers = {
        "content-type": 'application/json',
        "username": authProvider.username,
        "auth": auth,
      };
      sender.options.validateStatus = (status) {
        status ??= 504;
        return status < 500;
      };

      return await sender.delete("http://$serverAddress$address", data: body).catchError(
            (error) => Response(
              statusCode: 504,
              data: {
                "message": error == DioException
                    ? error.message
                    : isDebug
                        ? error.toString()
                        : "No connection"
              },
              requestOptions: RequestOptions(),
            ),
          );
    }

    switch (requestType) {
      case "get":
        return await getRequest();
      case "post":
        return await postRequest();
      case "delete":
        return await deleteRequest();
      default:
        return Response(
            statusCode: 504,
            requestOptions: RequestOptions(
              data: {"message": "Invalid request type"},
            ));
    }
  }

  /// Send a file to the drive
  ///
  /// Configs accepts:
  /// saveDirectory, fileName
  static Future<Response> sendFile(
    context, {
    required String address,
    required String api,
    required Stream<List<int>> fileStream,
    required int fileSize,
    String fileName = "temp",
    Map? configs,
  }) async {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final DriveProvider driveProvider = Provider.of<DriveProvider>(context, listen: false);
    final String? auth = authProvider.auth != "" ? await Cryptography.encryptText(authProvider.getAuthWithTimetamp()) : null;
    configs ??= {};

    Dio sender = Dio();

    sender.options.headers = {"content-type": 'multipart/form-data', "username": authProvider.username, "auth": auth};
    sender.options.validateStatus = (status) {
      status ??= 504;
      return status < 500;
    };

    // Creating data
    FormData formData = FormData();
    formData.fields.add(MapEntry("saveDirectory", configs["saveDirectory"]));
    formData.files.add(
      MapEntry(
        configs["fileName"],
        MultipartFile.fromStream(
          () => fileStream,
          fileSize,
          filename: configs["fileName"],
        ),
      ),
    );

    return await sender
        .post(
          "http://$serverAddress$address",
          data: formData,
          onSendProgress: (count, total) => driveProvider.updateKeyUploadStatus(configs!["fileName"], (count / total) * 100),
        )
        .catchError(
          (error) => Response(
            statusCode: 504,
            data: {
              "message": error is DioException
                  ? error.message
                  : isDebug
                      ? error.toString()
                      : "No connection"
            },
            requestOptions: RequestOptions(),
          ),
        );
  }

  ///Returns true if no error occurs, fatal errors return to home screen
  static bool errorTreatment(BuildContext context, String api, Response response, {bool isFatal = false}) {
    Dialogs.closeLoading(context);

    Future checkFatal() async {
      AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (isFatal && authProvider.auth != "") {
        return Storage.removeData("username").then(
          (_) => Storage.removeData("auth").then(
            (_) {
              Navigator.pushNamedAndRemoveUntil(context, "home", (route) => false);
              authProvider.changeAuth("");
            },
          ),
        );
      }
    }

    switch (response.statusCode) {
      // Bad Request
      case 400:
        checkFatal();
        Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Invalid", message: response.data["message"]));
        return false;
      // Limit Overflow
      case 414:
        checkFatal();
        Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Limit Overflow", message: response.data["message"]));
        return false;
      //Temporary Banned
      case 413:
        checkFatal();
        Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Temporary Banned", message: response.data["message"]));
        return false;
      //Invalid Datas
      case 403:
        checkFatal();
        Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Invalid Types", message: response.data["message"]));
        return false;
      //Wrong Credentials
      case 401:
        isFatal = true;
        checkFatal().then((_) => Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Not Authorized", message: response.data["message"])));
        return false;
      // Not Found
      case 404:
        checkFatal();
        Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Not Found", message: response.data["message"]));
        return false;
      //Server Crashed
      case 500:
        checkFatal();
        Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "Internal Error", message: response.data["message"]));
        return false;
      //No connection with the server
      case 504:
        checkFatal().then((_) => Future.delayed(Durations.short1).then((_) => Dialogs.alert(context, title: "No connection", message: response.data["message"])));
        return false;
      //User Cancelled
      case 101:
        checkFatal();
        return false;
    }
    return true;
  }
}
