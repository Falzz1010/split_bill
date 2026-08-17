// ignore_for_file: avoid_print, unintended_html_in_doc_comment

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Connect to the Flutter debug VM service and dump the widget tree.
/// Usage: dart vm_dump.dart <ws-url> [ext.flutter.debugDumpApp|ext.flutter.debugDumpRenderTree]
Future<void> main(List<String> args) async {
  final url = args.isNotEmpty ? args[0] : 'ws://127.0.0.1:46541/L7UPQ8DAQHA=/ws';
  final method = args.length > 1 ? args[1] : 'ext.flutter.debugDumpApp';

  final ws = await WebSocket.connect(url);
  var id = 0;
  final pending = <int, Completer<Map<String, dynamic>>>{};

  ws.listen((data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    final respId = msg['id'];
    if (respId != null && pending.containsKey(respId)) {
      pending.remove(respId)!.complete(msg);
    }
  });

  Future<Map<String, dynamic>> call(String m, [Map<String, dynamic>? params]) {
    final c = Completer<Map<String, dynamic>>();
    pending[++id] = c;
    ws.add(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': m,
      'params': params ?? {},
    }));
    return c.future;
  }

  final vm = await call('getVM');
  final isolates = (vm['result']['isolates'] as List);
  if (isolates.isEmpty) {
    print('NO ISOLATES');
    await ws.close();
    exit(1);
  }
  final isolateId = isolates.first['id'];
  final resp = await call(method, {'isolateId': isolateId});
  final result = resp['result'];
  if (result is Map && result['data'] != null) {
    print(result['data']);
  } else {
    print(jsonEncode(resp));
  }
  await ws.close();
  exit(0);
}
