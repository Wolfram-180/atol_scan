import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: appHeader,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    ),
  );
}

const appHeader = 'App';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appHeader),
      ),
    );
  }
}
