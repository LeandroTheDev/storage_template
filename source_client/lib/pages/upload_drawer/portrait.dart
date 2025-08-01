import 'package:drive/components/drive.dart';
import 'package:drive/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Portrait extends StatelessWidget {
  const Portrait({super.key});

  @override
  Widget build(BuildContext context) {
    final driveProvider = Provider.of<DriveProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Drawer(
      width: screenSize.width * 0.5,
      child: Container(
        color: Drive.colors["primary"],
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Uploads",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: driveProvider.uploadStatus.length,
                  itemBuilder: (context, index) => SizedBox(
                    height: 50,
                    width: screenSize.width * 0.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // File name
                        SizedBox(
                          width: screenSize.width * 0.2,
                          child: Text(
                            driveProvider.uploadStatus.keys.toList()[index],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        // Upload Progress indicator
                        driveProvider.uploadStatus.values.toList()[index] >= 100
                            // Success Upload
                            ? Icon(Icons.check, color: Drive.colors["seedColor"])
                            : driveProvider.uploadStatus.values.toList()[index] == -1
                                // Error upload
                                ? const Icon(Icons.close, color: Colors.red)
                                // Uploading
                                : SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      value: driveProvider.uploadStatus.values.toList()[index] / 100,
                                      color: Drive.colors["seedColor"],
                                      strokeWidth: 5,
                                      backgroundColor: Drive.colors["background"],
                                    ),
                                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
