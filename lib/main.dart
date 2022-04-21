import 'package:flutter/material.dart';
import 'package:ursmart/homepage.dart';
import 'package:ursmart/screens/conection.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body:  ConectionWithGadget(),
      ),
    );
  }
}