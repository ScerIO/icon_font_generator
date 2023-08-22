import 'package:flutter/material.dart';

import 'ui/icons.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Icons view test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              UiIcons.account,
              UiIcons.arrowLeft,
              UiIcons.collection,
              UiIcons.arrowRight,
            ]
                .map((iconData) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(iconData),
                    ))
                .cast<Widget>()
                .toList(),
          ),
        ),
      );
}
