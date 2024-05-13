import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

final scanProvider = StateProvider((ref) => 'не найдено');

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({
    super.key,
    this.onChanged,
    this.onNotFound,
    // this.child,
    this.getFocusNode,
    this.autoFocus = true,
  });

  ///listen barcode change
  final ValueChanged<String>? onChanged;

  ///listen barcode not found
  final VoidCallback? onNotFound;

  ///limit use of TextField
  // final Widget? child;

  ///get focus node to handle from external
  final Function(FocusNode focusNode)? getFocusNode;

  final bool autoFocus;

  @override
  ConsumerState<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends ConsumerState<MainScreen> {
  static const String _notFound = '404_PDA_SCAN_NOT_FOUND';
  static const String _startScanLabelKey = 'F11';
  static const String _endScanLabelKey = 'ENTER';
  final BehaviorSubject<String> _subject = BehaviorSubject();
  late final StreamSubscription _streamSubscription;
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _chars = StringBuffer();
  bool packMode = true;

  @override
  void initState() {
    super.initState();
    widget.getFocusNode?.call(_focusNode);

    _streamSubscription = _subject.stream
        .debounceTime(const Duration(milliseconds: 10))
        .listen((code) {
      if (code == _notFound) {
        widget.onNotFound?.call();
      } else {
        widget.onChanged?.call(code);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _subject.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: (KeyEvent event) {
              switch (event.runtimeType) {
                case KeyDownEvent:
                  {
                    print('1');
                    if (event.logicalKey.keyLabel.length == 1) {
                      print('2');
                      if (event.character?.isNotEmpty ?? false) {
                        _chars.write(event.character![0]);
                        print('3');
                      } else {
                        print('4');
                        _chars
                            .write(event.logicalKey.keyLabel.characters.first);
                      }
                      print('5');
                      _subject.add(_chars.toString());
                    }
                    return;
                  }
                case KeyUpEvent:
                  {
                    switch (event.logicalKey.keyLabel.toUpperCase()) {
                      case _startScanLabelKey:
                        {
                          print('6');
                          ref.read(scanProvider.notifier).state =
                              _chars.toString();
                          _subject.add(_chars.toString());
                          _chars.clear();
                          return;
                        }
                      case _endScanLabelKey:
                        {
                          print('7');
                          ref.read(scanProvider.notifier).state =
                              _chars.toString();
                          _chars.clear();
                          return;
                        }
                    }
                  }
              }
            },
            child: mainScreenWidget()));
  }
}

Widget mainScreenWidget() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Froza ATOL test:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(
          height: 20,
        ),
        Consumer(builder: (context, ref, child) {
          final scanResult = ref.watch(scanProvider);
          return Text(
            scanResult,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
            textAlign: TextAlign.center,
          );
        })
      ],
    ),
  );
}
