import 'package:example/widgets/icons.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(UiIcons.account),
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
              .map((icondata) => Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(icondata),
                  ))
              .cast<Widget>()
              .toList(),
        ),
      ),
    );
  }
}
