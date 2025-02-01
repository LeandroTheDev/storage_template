import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

//Dependencies
import 'package:dio/dio.dart';
import 'package:drive/components/crypto.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/pages/provider.dart';

//Packages
import 'package:flutter/material.dart';
import 'package:drive/main.dart';
import 'package:drive/pages/storage.dart';
import 'package:provider/provider.dart';

class WebServer {
  static final serverAddress = html.window.location.host.split(":").first;

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
    body ??= {};

    Future<Response> getRequest() async {
      Dio sender = Dio();
      final DriveProvider apiProvider = Provider.of<DriveProvider>(context, listen: false);

      sender.options.headers = {
        "username": Crypto.encryptText(apiProvider.username),
        "token": Crypto.encryptText(apiProvider.token),
        "handshake": Crypto.encryptText(apiProvider.handshake),
      };
      sender.options.validateStatus = (status) {
        status ??= 504;
        return status < 500;
      };
      return await sender.get("http://$serverAddress:${apiProvider.apiPorts}$address", queryParameters: body).catchError(
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
      final DriveProvider apiProvider = Provider.of<DriveProvider>(context, listen: false);

      sender.options.headers = {
        "content-type": 'application/json',
        "username": Crypto.encryptText(apiProvider.username),
        "token": Crypto.encryptText(apiProvider.token),
        "handshake": Crypto.encryptText(apiProvider.handshake),
      };
      sender.options.validateStatus = (status) {
        status ??= 504;
        return status < 500;
      };
      return await sender.post("http://$serverAddress:${apiProvider.apiPorts}$address", data: body).catchError(
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
      final DriveProvider apiProvider = Provider.of<DriveProvider>(context, listen: false);

      sender.options.headers = {
        "content-type": 'application/json',
        "username": Crypto.encryptText(apiProvider.username),
        "token": Crypto.encryptText(apiProvider.token),
        "handshake": Crypto.encryptText(apiProvider.handshake),
      };
      sender.options.validateStatus = (status) {
        status ??= 504;
        return status < 500;
      };

      return await sender.delete("http://$serverAddress:${apiProvider.apiPorts}$address", data: body).catchError(
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

  ///Download a file from the server via get stream
  ///
  ///Example:
  ///```dart
  ///downloadFile(context, address: "/getFile", api: "drive", body: { "fileDirectory": "myFile.txt" } );
  ///```
  static Future<Response> downloadFile(
    BuildContext context, {
    required String address,
    required String api,
    Map<String, dynamic>? body,
  }) async {
    Dio receiver = Dio();
    final DriveProvider apiProvider = Provider.of<DriveProvider>(context, listen: false);

    receiver.options.headers = {"username": apiProvider.username, "token": apiProvider.token};
    receiver.options.validateStatus = (status) {
      status ??= 504;
      return status < 500;
    };
    receiver.options.responseType = ResponseType.stream;

    try {
      // Request stream download from the server
      Response response = await receiver.get("http://$serverAddress:${apiProvider.apiPorts}$address", queryParameters: body).catchError(
            (error) => Response(
              statusCode: 504,
              data: {"message": isDebug ? "Cannot download file, reason: $error" : "Cannot connect to the server"},
              requestOptions: RequestOptions(),
            ),
          );

      // Request success
      if (response.statusCode == 200 && response.data is ResponseBody) {
        Completer<Response> completer = Completer<Response>();
        // Receive stream
        Stream<Uint8List> fileStream = response.data!.stream;

        // Bytes from the file
        List<int> fileBytes = [];

        // Process the stream
        fileStream.listen(
          // Saving in memory
          (data) => fileBytes.addAll(data),
          onDone: () async {
            try {
              // Saving image from memory to cache
              await apiProvider.addFileToCache(body!["fileName"], fileBytes);
              // Finish
              completer.complete(
                Response(
                  statusCode: 200,
                  data: {"message": "Success"},
                  requestOptions: RequestOptions(),
                ),
              );
            } catch (error) {
              // Error
              completer.complete(
                Response(
                  statusCode: 504,
                  data: {"message": "Cannot save image on cache, reason: $error"},
                  requestOptions: RequestOptions(),
                ),
              );
            }
          },
          onError: (error) => completer.complete(
            Response(
              statusCode: 504,
              data: {"message": isDebug ? "$error" : "Any error occurs when receiving the file"},
              requestOptions: RequestOptions(),
            ),
          ),
        );
        return completer.future;
      } else if (response.data is! ResponseBody)
        return Response(
          statusCode: 504,
          data: {"message": isDebug ? "The server returned a invalid stream to get file: ${response.data?.runtimeType}, value: ${response.data}" : "Cannot connect to the server"},
          requestOptions: RequestOptions(),
        );
      else
        return response;
    } catch (error) {
      return Response(
        statusCode: 504,
        data: {"message": isDebug ? "$error" : "Cannot connect to the server"},
        requestOptions: RequestOptions(),
      );
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
    configs ??= {};

    Dio sender = Dio();
    final DriveProvider apiProvider = Provider.of<DriveProvider>(context, listen: false);

    sender.options.headers = {
      "content-type": 'multipart/form-data',
      "username": Crypto.encryptText(apiProvider.username),
      "token": Crypto.encryptText(apiProvider.token),
      "handshake": Crypto.encryptText(apiProvider.handshake),
    };
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

    print(formData);

    return await sender
        .post(
          "http://$serverAddress:${apiProvider.apiPorts}$address",
          data: formData,
          onSendProgress: (count, total) => apiProvider.updateKeyUploadStatus(configs!["fileName"], (count / total) * 100),
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

  ///Returns true if no error occurs, fatal erros return to home screen
  static bool errorTreatment(BuildContext context, String api, Response response, {bool isFatal = false}) {
    Future checkFatal() async {
      DriveProvider provider = Provider.of<DriveProvider>(context, listen: false);
      if (isFatal && provider.token != "") {
        return Storage.removeData("username").then(
          (_) => Storage.removeData("handshake").then(
            (_) => Storage.removeData("token").then(
              (_) => Storage.removeData("token_timestamp").then((_) {
                Navigator.pushNamedAndRemoveUntil(context, "home", (route) => false);
                provider.changeToken("");
              }),
            ),
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
