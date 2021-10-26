import 'package:example/widgets/icons.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      );
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: Icon(UiIcons.account),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              UiIcons.account,
              UiIcons.arrow_left,
              UiIcons.collection,
              UiIcons.arrow_right,
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
