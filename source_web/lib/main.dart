import 'package:flutter/material.dart';
import 'package:drive/pages/home.dart';
import 'package:drive/pages/provider.dart';
import 'package:provider/provider.dart';

const isDebug = !bool.fromEnvironment('dart.vm.product');

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriveProvider()),
      ],
      child: const Drive(),
    ),
  );
}

class Drive extends StatelessWidget {
  //Colors variables
  static const Map<String, Color> colors = {
    "primary": Color.fromARGB(255, 78, 78, 78),
    "secondary": Color.fromARGB(255, 42, 128, 168),
    "tertiary": Colors.white,
    "seedColor": Colors.lightBlueAccent,
    "background": Color.fromARGB(255, 51, 49, 49),
  };
  const Drive({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drive',
      theme: ThemeData(
        //--------------
        //Colors
        //--------------
        colorScheme: ColorScheme.fromSeed(
          //Default Colors
          seedColor: colors["seedColor"]!,

          //Used in large interfaces
          primary: colors["primary"]!,
          //Used in buttons
          secondary: colors["secondary"]!,
          //Used in visibility things like texts
          tertiary: colors["tertiary"],
        ),
        // Used in small interfaces
        primaryColor: colors["primary"],
        //Used in borders
        secondaryHeaderColor: colors["secondary"],
        //Scafolld background
        scaffoldBackgroundColor: const Color.fromARGB(255, 104, 102, 102),
        useMaterial3: true,

        //--------------
        //Widgets Themes
        //--------------
        iconTheme: IconThemeData(
          color: colors["tertiary"],
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: colors["tertiary"], fontSize: 24, overflow: TextOverflow.ellipsis),
          titleMedium: TextStyle(color: colors["tertiary"], fontSize: 16, overflow: TextOverflow.ellipsis),
          titleSmall: TextStyle(color: colors["tertiary"], fontSize: 6, overflow: TextOverflow.ellipsis),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors["secondary"],
            foregroundColor: colors["tertiary"],
            surfaceTintColor: colors["secondary"],
            shadowColor: colors["secondary"],
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors["tertiary"]!),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors["secondary"]!),
          ),
        ),
        dialogTheme: DialogTheme(
          titleTextStyle: TextStyle(color: colors["tertiary"], fontSize: 24, overflow: TextOverflow.ellipsis),
          contentTextStyle: TextStyle(color: colors["tertiary"], fontSize: 16, overflow: TextOverflow.ellipsis),
          backgroundColor: colors["primary"],
        ),
        dialogBackgroundColor: colors["primary"],
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.blue.withOpacity(0.3),
          selectionHandleColor: Colors.blue,
        ),
      ),
      routes: {
        "home": (context) => const DriveHome(),
      },
      home: const DriveHome(),
    );
  }
}