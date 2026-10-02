import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_buddy/gif_buddy_client.dart';

void main() {
  test('sends encoded text and accepts clearing the matrix', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = <String>[];
    final subscription = server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/text');
      final body = await utf8.decoder.bind(request).join();
      received.add(Uri.splitQueryString(body)['text']!);
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"ok":true}');
      await request.response.close();
    });
    try {
      final client = GifBuddyClient('127.0.0.1:${server.port}');
      await client.sendText('DAVID & BADGE + 18330');
      await client.sendText('');
      expect(received, ['DAVID & BADGE + 18330', '']);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });
  test(
    'rejects unsupported characters and overlong text before networking',
    () async {
      final client = GifBuddyClient('127.0.0.1:1');
      await expectLater(client.sendText('hello\nworld'), throwsArgumentError);
      await expectLater(client.sendText('hello 🌞'), throwsArgumentError);
      await expectLater(client.sendText('x' * 161), throwsArgumentError);
    },
  );
  test('reports device rejection', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 400;
      request.response.write('Invalid text');
      await request.response.close();
    });
    try {
      await expectLater(
        GifBuddyClient('127.0.0.1:${server.port}').sendText('HELLO'),
        throwsA(isA<DeviceUnreachableException>()),
      );
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
