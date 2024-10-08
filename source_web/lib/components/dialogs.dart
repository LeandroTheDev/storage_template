import 'dart:async';
import 'dart:math';
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:drive/components/crypto.dart';
import 'package:drive/components/web_server.dart';
import 'package:drive/pages/provider.dart';
import 'package:drive/pages/storage.dart';
import 'package:provider/provider.dart';

class Dialogs {
  ///Ask for drive credentials and update the token
  ///if the server returns the token
  static Future<Response> driveCredentials(BuildContext context) {
    DriveUtils.log("Instanciating dialog for credentials");

    DriveProvider driveProvider = Provider.of<DriveProvider>(context, listen: false);

    TextEditingController username = TextEditingController();
    TextEditingController password = TextEditingController();

    Completer<Response> completer = Completer<Response>();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Credentials",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              //Username
              TextField(
                controller: username,
                cursorColor: Theme.of(context).colorScheme.tertiary,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              //Password
              TextField(
                controller: password,
                cursorColor: Theme.of(context).colorScheme.tertiary,
                style: Theme.of(context).textTheme.titleMedium,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //Confirm Button
                  ElevatedButton(
                    onPressed: () async {
                      DriveUtils.log("Confirming credentials...");
                      loading(context);

                      // Creating the handshake
                      Random random = Random();
                      String handshake = "";
                      for (int i = 0; i < 100; i++) handshake += random.nextInt(10).toString();

                      WebServer.sendMessage(
                        context,
                        address: "/drive/login",
                        api: "drive",
                        body: {"username": Crypto.encryptText(username.text), "password": Crypto.encryptText(password.text), "handshake": Crypto.encryptText(handshake)},
                      ).then(
                        (response) {
                          DriveUtils.log("Credentials server returned code: ${response.statusCode}");

                          driveProvider.changeUsername(username.text);
                          driveProvider.changeHandshake(handshake);

                          //Close Loading
                          Navigator.pop(context);
                          //Close Credentials
                          Navigator.pop(context);

                          Storage.saveData("username", username.text);
                          Storage.saveData("handshake", handshake);

                          DriveUtils.log("Returning future...");
                          completer.complete(response);
                        },
                      );
                    },
                    child: const Text("Confirm"),
                  ),
                  //Back Button
                  ElevatedButton(
                    onPressed: () {
                      if (html.window.history.length > 2) {
                        html.window.history.back();
                        html.window.history.back();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Back"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((value) {
      try {
        completer.complete(Response(
            statusCode: 101,
            requestOptions: RequestOptions(
              data: "",
            )));
        DriveUtils.log("Credentials cancelled");
      } catch (_) {}
    });
    return completer.future;
  }

  ///Show a custom alert
  static void alert(BuildContext context, {String title = "Alert", String message = ""}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message, style: Theme.of(context).textTheme.titleMedium, maxLines: 99),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  ///Show the loading dialog
  static void loading(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          content: SizedBox(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 100.0, vertical: 70),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  ///Show a prompt to user type something
  static Future<String> typeInput(BuildContext context, {String title = ""}) {
    Completer<String> completer = Completer<String>();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          TextEditingController input = TextEditingController();
          return Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: AlertDialog(
                title: Column(
                  children: [
                    // Title
                    Text(title),
                    // Input
                    TextField(
                      controller: input,
                      cursorColor: Theme.of(context).colorScheme.tertiary,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Spacer
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => {
                        completer.complete(input.text),
                        Navigator.pop(context),
                      },
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
    return completer.future;
  }

  /// Simple show a alert dialog to the user
  static Future<bool> showQuestion(
    BuildContext context, {
    String title = "",
    String content = "",
    String buttonTitle = "Yes",
    String buttonTitle2 = "No",
  }) {
    final screenSize = MediaQuery.of(context).size;
    Completer<bool> completer = Completer<bool>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: AlertDialog(
              title: Text(title, style: Theme.of(context).textTheme.titleLarge),
              content: Text(content, style: Theme.of(context).textTheme.titleMedium),
              actions: [
                //yes
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    completer.complete(true);
                  },
                  child: Text(buttonTitle, style: Theme.of(context).textTheme.titleMedium),
                ),
                //no
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    completer.complete(false);
                  },
                  child: Text(buttonTitle2, style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
          ),
        );
      },
    );

    return completer.future;
  }
}
