import 'package:drive/components/auth.dart';
import 'package:drive/components/dialogs.dart';
import 'package:drive/components/screen.dart';
import 'package:drive/pages/generic_view/toolbar.dart';
import 'package:drive/pages/generic_view/landscape.dart';
import 'package:drive/pages/generic_view/portrait.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Main extends StatelessWidget {
  final String fileName;
  const Main({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = Screen.isPortrait(size);

    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.auth.isEmpty) Dialogs.driveCredentials(context);

    return Scaffold(
      appBar: const ToolBar(),
      body: isPortrait ? const Portrait() : const Landscape(),
    );
  }
}
