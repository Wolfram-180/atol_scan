import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uniscan/presentations/orders/selected_order_appbar.dart';

import '../../data/implements/scanner_impl.dart';
import '../../data/providers/selected_order_provider.dart';
import '../../styles/text_styles.dart';
import 'selected_order_alert.dart';
import 'selected_order_items_list.dart';

class PDAWidget extends ConsumerStatefulWidget {
  final String orderId;

  const PDAWidget({
    Key? key,
    required this.orderId,
    this.onChanged,
    this.onNotFound,
    this.child,
    this.getFocusNode,
    this.autoFocus = true,
  }) : super(key: key);

  ///listen barcode change
  final ValueChanged<String>? onChanged;

  ///listen barcode not found
  final VoidCallback? onNotFound;

  ///limit use of TextField
  final Widget? child;

  ///get focus node to handle from external
  final Function(FocusNode focusNode)? getFocusNode;

  final bool autoFocus;

  @override
  ConsumerState<PDAWidget> createState() => _PDAWidget();
}

class _PDAWidget extends ConsumerState<PDAWidget> {
  static const String _notFound = '404_PDA_SCAN_NOT_FOUND';
  static const String _startScanLabelKey = 'F12';
  static const String _endScanLabelKey = 'ENTER';
  final BehaviorSubject<String> _subject = BehaviorSubject();
  late final StreamSubscription _streamSubscription;
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _chars = StringBuffer();

  @override
  void initState() {
    super.initState();
    widget.getFocusNode?.call(_focusNode);
    _streamSubscription = _subject.stream
        .debounceTime(const Duration(milliseconds: 50))
        .listen((code) {
      if (code == _notFound) {
        // log('[PDA SCAN LOG]: $_notFound');
        widget.onNotFound?.call();
      } else {
        // log('[PDA SCAN LOG]: $code');
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
    var selectedOrder = ref.watch(selectedOrdersProvider(widget.orderId));

    // ignore: unused_local_variable
    final messenger = ScaffoldMessenger.of(context);
    ScannImpl scan = ScannImpl();

    return Scaffold(
      appBar: selectedOrderAppBar(false, widget.orderId),
      body: Consumer(builder: ((context, ref, child) {
        return selectedOrder.when(
            loading: () => const Scaffold(
                    body: Center(
                        child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ))),
            error: (error, _) => Center(
                    child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: rFirm12,
                )),
            data: (data) {
              log(data.toString());

              return KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: (KeyEvent event) {
                  switch (event.runtimeType) {
                    case KeyDownEvent:
                      {
                        if (event.logicalKey.keyLabel.length == 1) {
                          if (event.character?.isNotEmpty ?? false) {
                            _chars.write(event.character![0]);
                          } else {
                            _chars.write(
                                event.logicalKey.keyLabel.characters.first);
                          }
                          // log('[_chars]: ${_chars.toString()}');
                          _subject.add(_chars.toString());
                        }
                        return;
                      }
                    case KeyUpEvent:
                      {
                        switch (event.logicalKey.keyLabel.toUpperCase()) {
                          case _startScanLabelKey:
                            {
                              _subject.add(_notFound);
                              return;
                            }
                          case _endScanLabelKey:
                            {
                              scan.checkExist(_chars.toString(), data)
                                  ? _chars.toString().length < 15
                                      ? scan.checkTrueSign(
                                              _chars.toString(), data)
                                          ? selectedOrderAlert(context,
                                              'Сканируйте Честный знак!', '')
                                          : scan.sendScan(
                                              context,
                                              _chars.toString(),
                                              widget.orderId,
                                              true,
                                              ref)
                                      : scan.sendScan(
                                          context,
                                          _chars.toString(),
                                          widget.orderId,
                                          true,
                                          ref)
                                  : selectedOrderAlert(
                                      context,
                                      'Данного товара нет в сборке!',
                                      'lib/images/lottie/close.json');
                              _chars.clear();
                              return;
                            }
                        }
                      }
                  }
                },
                child: selectedOrderItemsList(data),
              );
            });
      })),
    );
  }
}

extension on ScaffoldMessengerState {
  // ignore: unused_element
  void _toast(String message) {
    showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
    ));
  }
}
