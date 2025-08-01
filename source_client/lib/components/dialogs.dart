import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drive/components/auth.dart';
import 'package:drive/components/cryptography.dart';
import 'package:drive/components/drive.dart';
import 'package:drive/pages/storage.dart';
import 'package:flutter/material.dart';
import 'package:drive/components/web_server.dart';
import 'package:provider/provider.dart';

class Dialogs {
  ///Ask for drive credentials and update the auth
  ///if the server returns the auth
  static Future<Response> driveCredentials(BuildContext context) async {
    DriveUtils.log("Instanciating dialog for credentials");

    AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

    TextEditingController username = TextEditingController();
    TextEditingController password = TextEditingController();

    Completer<Response> completer = Completer<Response>();

    final bool containsPrivateKey = await Storage.getData("privatekey") == null ? false : true;

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
              // Confirmations buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //Confirm Button
                  ElevatedButton(
                    onPressed: () async {
                      DriveUtils.log("Confirming credentials...");
                      loading(context);

                      authProvider.changeUsername(username.text);

                      // Requesting public key for login
                      {
                        Response response = await WebServer.sendMessage(
                          context,
                          address: "/drive/requestloginkey",
                          api: "drive",
                          requestType: "get",
                        );

                        if (WebServer.errorTreatment(context, "drive", response)) {
                          loading(context);
                          await Cryptography.updatePublicKey(response.data["message"]);
                        } else {
                          return;
                        }
                      }

                      DriveUtils.log("Login key received");

                      final String encryptedPassword = await Cryptography.encryptText(password.text);
                      final String localPrivateKey = await Storage.getData("privatekey") as String;
                      final String localPublicKey = await Storage.getData("publickey") as String;
                      await Cryptography.updatePrivateKey(localPrivateKey);

                      DriveUtils.log("Keys set up");

                      Response response = await WebServer.sendMessage(
                        context,
                        address: "/drive/login",
                        api: "drive",
                        body: {
                          "username": username.text,
                          "password": encryptedPassword,
                          "publickey": localPublicKey,
                        },
                      );

                      DriveUtils.log("Login request received");

                      if (WebServer.errorTreatment(context, "drive", response)) {
                        try {
                          loading(context);
                          final Map data = response.data["message"];

                          data["auth"] = await Cryptography.decryptText(data["auth"]);
                          data["publickey"] = data["publickey"];
                          data["created"] = await Cryptography.decryptText(data["created"]);

                          authProvider.changeUsername(username.text);
                          Storage.saveData("username", username.text);
                          authProvider.changeAuth(data["auth"]);
                          Storage.saveData("auth", data["auth"]);

                          await Cryptography.updatePublicKey(data["publickey"]);
                          completer.complete(response);
                        } catch (error) {
                          closeLoading(context);
                          alert(context, title: "Encrypt Error", message: "Something went wrong while decrypting the data, try recreating your key");
                          return;
                        }
                      } else
                        return;
                    },
                    child: const Text("Confirm"),
                  ),
                  //Back Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, "home", (route) => false);
                    },
                    child: const Text("Back"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Reset key & Server Address
              Row(
                children: [
                  // Reset Keys
                  TextButton(
                      onPressed: () async {
                        final result = await Dialogs.showQuestion(context, title: "Rebuild keys?", content: "Are you sure you want to rebuild your keys? this might take a long time");
                        if (result) {
                          await Dialogs.generateKeys(context);
                        }
                      },
                      child: Text(
                        "Reset Keys",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: containsPrivateKey ? Colors.white : Colors.red,
                            ),
                      )),
                  const Spacer(),
                  // Server Address
                  TextButton(
                      onPressed: () async {
                        final result = await Dialogs.typeInput(context, title: "Changing Server Address");
                        if (result == null) return;
                        WebServer.serverAddress = result;
                        Storage.saveData("server_address", result);
                      },
                      child: Text(
                        "Change IP",
                        style: Theme.of(context).textTheme.titleMedium,
                      )),
                ],
              )
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
  static Future alert(BuildContext context, {String title = "Alert", String message = ""}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message, style: Theme.of(context).textTheme.titleMedium, maxLines: 99),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  ///Show the loading dialog
  static bool _isLoading = false;
  static void loading(BuildContext context) {
    if (_isLoading) return;
    _isLoading = true;

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

  static void closeLoading(BuildContext context) {
    if (_isLoading) Navigator.pop(context);
    _isLoading = false;
  }

  ///Show a prompt to user type something
  static Future<String?> typeInput(BuildContext context, {String title = ""}) async {
    TextEditingController input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true, // permite fechar tocando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Text(title),
              TextField(
                controller: input,
                cursorColor: Theme.of(context).colorScheme.tertiary,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, input.text); // retorna valor
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
        );
      },
    );

    // result pode ser null se o usuário fechou o diálogo sem confirmar
    return result;
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

  // Genereta keys options
  static Future<bool> generateKeys(
    BuildContext context, {
    String title = "Refresh Secure Keys",
    String content = "Do you wish to refresh secure keys? this might take a long time if you select locale, but if you select serverside it might be dangerous for your security.",
    String buttonTitle = "Locale",
    String buttonTitle2 = "Server Side",
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
                TextButton(
                  onPressed: () async {
                    Dialogs.loading(context);
                    await Future.delayed(Durations.long3);
                    Map<String, String> keys = await Cryptography.generateRSAKeyPair();
                    await Storage.saveData("privatekey", keys["privatekey"]);
                    await Storage.saveData("publickey", keys["publickey"]);
                    Dialogs.closeLoading(context);

                    Navigator.of(context).pop();
                    completer.complete(true);
                  },
                  child: Text(buttonTitle, style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () async {
                    Dialogs.loading(context);
                    Response response = await WebServer.sendMessage(
                      context,
                      address: "/drive/requestkeys",
                      api: "drive",
                      requestType: "get",
                    );
                    if (!WebServer.errorTreatment(context, "drive", response)) return;
                    await Storage.saveData("privatekey", response.data["message"]["privatekey"]);
                    await Storage.saveData("publickey", response.data["message"]["publickey"]);

                    await Cryptography.updatePrivateKey(response.data["message"]["privatekey"]);
                    await Cryptography.updatePublicKey(response.data["message"]["publickey"]);

                    Dialogs.closeLoading(context);

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
