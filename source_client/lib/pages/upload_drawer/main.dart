import 'package:drive/components/screen.dart';
import 'package:drive/pages/upload_drawer/landscape.dart';
import 'package:drive/pages/upload_drawer/portrait.dart';
import 'package:flutter/material.dart';

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = Screen.isPortrait(size);

    return isPortrait ? const Portrait() : const Landscape();
  }
}
