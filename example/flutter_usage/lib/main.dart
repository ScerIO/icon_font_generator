import 'package:flutter/material.dart';

import 'ui/icons.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MyHomePage(),
      );
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Icons view test'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              UiIcons.account,
              UiIcons.arrowLeft,
              UiIcons.collection,
              UiIcons.arrowRight,
            ]
                .map((iconData) => Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(iconData),
                    ))
                .cast<Widget>()
                .toList(),
          ),
        ),
      );
}
