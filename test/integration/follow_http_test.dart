import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/shared/shared.dart' show borrowResource;

typedef _Session = ({Object identity, String token});
typedef _Source = ({String id, Object identity, String token});
typedef _Item = ({String id, bool followed, String session});

Matcher _reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);

void main() {
  test(
    'shared consumers use one physical GET and reject busy HTTP work',
    () async {
      final server = await _Loopback.start();
      addTearDown(server.close);
      final firstGet = server.holdGet();
      final first = borrowResource(server.resources, server.followed('42'));
      final second = borrowResource(server.resources, server.followed('42'));
      final detail = borrowResource(server.resources, server.items('42'));
      final loaded = server.track(first.value.ensureLoaded());
      for (var call = 0; call < 20; call++) {
        expect(identical(loaded, second.value.ensureLoaded()), isTrue);
      }
      expect((await firstGet.arrived).token, 'old');
      expect(server.gets, 1);
      firstGet.release();
      expect(await loaded, isFalse);
      expect(second.value.state.peek().value, isFalse);

      final post = server.holdPost();
      final write = server.track(first.value.update((value) => !value));
      expect(first.value.state.peek().value, isTrue);
      expect(second.value.state.peek().value, isTrue);
      expect(detail.value.state.peek().value.followed, isTrue);
      expect(second.value.state.peek().pending, isTrue);
      expect((await post.arrived).desired, isTrue);
      await expectLater(
        server.track(detail.value.refresh()),
        throwsA(_reason(ResourceReason.busy)),
      );
      await expectLater(
        server.track(second.value.refresh()),
        throwsA(_reason(ResourceReason.busy)),
      );
      await expectLater(
        server.track(second.value.set(false)),
        throwsA(_reason(ResourceReason.busy)),
      );
      await server.quiet();
      expect(server.gets, 1);
      expect(server.posts, 1);
      post.release();
      expect(await write, isTrue);
      await server.quiet();
      expect(server.gets, 1);
      expect(server.posts, 1);
      expect(server.following('old', '42'), isTrue);
      expect(second.value.state.peek().pending, isFalse);
      first.release();
      second.release();
      detail.release();
    },
  );

  test(
    'a real HTTP 500 rolls back both shared consumers and their parent',
    () async {
      final server = await _Loopback.start();
      addTearDown(server.close);
      final first = borrowResource(server.resources, server.followed('42'));
      final second = borrowResource(server.resources, server.followed('42'));
      final detail = borrowResource(server.resources, server.items('42'));
      expect(await server.track(first.value.ensureLoaded()), isFalse);
      final post = server.holdPost(status: HttpStatus.internalServerError);
      final write = server.track(first.value.set(true));
      expect(first.value.state.peek().value, isTrue);
      expect(second.value.state.peek().value, isTrue);
      expect(detail.value.state.peek().value.followed, isTrue);
      await post.arrived;
      post.release();
      Object? failure;
      try {
        await write;
        fail('HTTP 500 must fail the write.');
      } catch (error) {
        failure = error;
      }
      expect(
        failure,
        isA<HttpException>().having(
          (error) => error.message,
          'message',
          contains('500'),
        ),
      );
      expect(first.value.state.peek().value, isFalse);
      expect(second.value.state.peek().value, isFalse);
      expect(detail.value.state.peek().value.followed, isFalse);
      expect(first.value.state.peek().error, same(failure));
      expect(second.value.state.peek().error, same(failure));
      expect(detail.value.state.peek().error, isNull);
      expect(await server.track(first.value.ensureLoaded()), isFalse);
      expect(server.following('old', '42'), isFalse);
      expect(server.gets, 1);
      expect(server.posts, 1);
      first.release();
      second.release();
      detail.release();
    },
  );

  test(
    'writing invalidates a physical GET and aborts only that request',
    () async {
      final server = await _Loopback.start();
      addTearDown(server.close);
      final field = borrowResource(server.resources, server.followed('42'));
      final detail = borrowResource(server.resources, server.items('42'));
      expect(await server.track(field.value.ensureLoaded()), isFalse);
      final staleGet = server.holdGet();
      final refreshed = server.track(detail.value.refresh());
      final interrupted = expectLater(
        refreshed,
        throwsA(_reason(ResourceReason.superseded)),
      );
      await staleGet.arrived;
      expect(server.gets, 2);
      final post = server.holdPost();
      final write = server.track(field.value.set(true));
      await interrupted;
      expect(server.abortedReads, 1);
      expect(detail.value.state.peek().value.followed, isTrue);
      // The POST uses the same HttpClient after the old GET was aborted.
      expect((await post.arrived).token, 'old');
      expect(server.posts, 1);
      await expectLater(
        server.track(detail.value.refresh()),
        throwsA(_reason(ResourceReason.busy)),
      );
      expect(server.gets, 2);
      post.release();
      expect(await write, isTrue);
      // This response captured false before the POST. It cannot publish late.
      staleGet.release();
      await server.quiet();
      expect(detail.value.state.peek().value.followed, isTrue);
      expect(field.value.state.peek().value, isTrue);
      expect(detail.value.state.peek().error, isNull);
      expect(server.gets, 2);
      expect(server.posts, 1);
      // A further round trip proves the shared client remains usable.
      expect(await server.track(field.value.refresh()), isTrue);
      expect(server.gets, 3);
      expect(server.posts, 1);
      field.release();
      detail.release();
    },
  );

  test(
    'an accepted POST keeps its token across namespace replacement',
    () async {
      final server = await _Loopback.start();
      addTearDown(server.close);
      final old = borrowResource(server.resources, server.followed('42'));
      expect(await server.track(old.value.ensureLoaded()), isFalse);
      final post = server.holdPost();
      final write = server.track(old.value.set(true));
      // Replace the session before the deferred writer starts its HTTP request.
      server.session.value = (identity: Object(), token: 'new');
      final current = borrowResource(server.resources, server.followed('42'));
      final detail = borrowResource(server.resources, server.items('42'));
      expect(identical(old.value, current.value), isFalse);
      expect(await server.track(current.value.ensureLoaded()), isFalse);
      expect(detail.value.state.peek().value.session, 'new');
      expect(current.value.state.peek().pending, isFalse);
      final received = await post.arrived;
      expect(received.token, 'old');
      expect(received.desired, isTrue);
      expect(server.posts, 1);
      expect(server.gets, 2);
      expect(
        server.calls
            .where((call) => call.method == 'GET')
            .map((call) => call.token),
        ['old', 'new'],
      );
      post.release();
      expect(await write, isTrue);
      expect(server.following('old', '42'), isTrue);
      expect(server.following('new', '42'), isFalse);
      expect(current.value.state.peek().value, isFalse);
      expect(detail.value.state.peek().value.session, 'new');
      expect(detail.value.state.peek().value.followed, isFalse);
      expect(await server.track(current.value.ensureLoaded()), isFalse);
      expect(server.gets, 2);
      expect(server.posts, 1);
      old.release();
      current.release();
      detail.release();
    },
  );
}

final class _Received {
  const _Received(this.method, this.id, this.token, this.desired);
  final String method;
  final String id;
  final String token;
  final bool? desired;
}

final class _Plan {
  _Plan(this.status) {
    // Teardown can cancel a plan whose request never reached the server.
    unawaited(
      _arrived.future.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
  }

  final int status;
  final _arrived = Completer<_Received>();
  final _released = Completer<void>();

  Future<_Received> get arrived =>
      _arrived.future.timeout(const Duration(seconds: 5));

  void release() {
    if (!_released.isCompleted) _released.complete();
  }

  void close() {
    release();
    if (!_arrived.isCompleted) {
      _arrived.completeError(
        StateError('Server closed before request arrival.'),
      );
    }
  }
}

final class _Loopback {
  _Loopback(this._server) {
    _client.connectionTimeout = const Duration(seconds: 3);
    _client.maxConnectionsPerHost = 4;
    resources = Resources(
      namespace: () => session.value.identity,
      maxIdle: 4,
      retain: const Duration(minutes: 1),
    );
    items = Family<String, Query<_Source, _Item>>(
      create: (id) => Query(
        source: () {
          final current = session.value;
          return (id: id, identity: current.identity, token: current.token);
        },
        load: _read,
      ),
      dispose: (query) => query.dispose(),
    );
    followed = items.fieldAck<bool>(
      select: (item) => item.followed,
      apply: (item, desired) =>
          (id: item.id, followed: desired, session: item.session),
      write: _write,
    );
    _listener = _server.listen((request) {
      final operation = _serve(request);
      _handlers.add(operation);
      unawaited(operation.whenComplete(() => _handlers.remove(operation)));
    });
  }

  static Future<_Loopback> start() async =>
      _Loopback(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final _client = HttpClient();
  final session = Value<_Session>((identity: Object(), token: 'old'));
  late final Resources resources;
  late final Family<String, Query<_Source, _Item>> items;
  late final ResourceRef<RemoteValue<_Source, bool>> Function(String) followed;
  late final StreamSubscription<HttpRequest> _listener;
  final calls = <_Received>[];
  final _getPlans = Queue<_Plan>();
  final _postPlans = Queue<_Plan>();
  final _plans = <_Plan>[];
  final _handlers = <Future<void>>{};
  final _operations = <Future<void>>[];
  final _serverErrors = <Object>[];
  final _following = <String, Map<String, bool>>{};
  var abortedReads = 0;
  var _closed = false;

  int get gets => calls.where((call) => call.method == 'GET').length;
  int get posts => calls.where((call) => call.method == 'POST').length;
  bool following(String token, String id) => _following[token]?[id] ?? false;

  _Plan holdGet() {
    final plan = _Plan(HttpStatus.ok);
    _plans.add(plan);
    _getPlans.add(plan);
    return plan;
  }

  _Plan holdPost({int status = HttpStatus.ok}) {
    final plan = _Plan(status);
    _plans.add(plan);
    _postPlans.add(plan);
    return plan;
  }

  Future<T> track<T>(Future<T> operation) {
    _operations.add(
      operation.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
    return operation;
  }

  Future<void> quiet() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Uri _uri(String path) => Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: _server.port,
    path: path,
  );

  Future<_Item> _read(_Source source, ReadRequest request) async {
    final uri = _uri('/items/${source.id}');
    final transport = await _client.getUrl(uri);
    transport.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${source.token}',
    );
    final cancelled = request.onCancel(() {
      abortedReads++;
      transport.abort(HttpException('Read invalidated', uri: uri));
    });
    try {
      final response = await transport.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GET ${response.statusCode}', uri: uri);
      }
      final value = jsonDecode(body) as Map<String, dynamic>;
      return (
        id: value['id'] as String,
        followed: value['followed'] as bool,
        session: value['session'] as String,
      );
    } finally {
      cancelled.dispose();
    }
  }

  Future<void> _write(_Source source, bool desired) async {
    final uri = _uri('/items/${source.id}/follow');
    final transport = await _client.postUrl(uri);
    transport.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${source.token}',
    );
    transport.headers.contentType = ContentType.json;
    transport.write(jsonEncode({'followed': desired}));
    final response = await transport.close();
    await response.drain<void>();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('POST ${response.statusCode}', uri: uri);
    }
  }

  Future<void> _serve(HttpRequest request) async {
    try {
      final token = request.headers
          .value(HttpHeaders.authorizationHeader)!
          .replaceFirst('Bearer ', '');
      final id = request.uri.pathSegments[1];
      final method = request.method;
      bool? desired;
      _Plan? plan;
      if (method == 'GET') {
        if (_getPlans.isNotEmpty) plan = _getPlans.removeFirst();
      } else if (method == 'POST') {
        if (_postPlans.isNotEmpty) plan = _postPlans.removeFirst();
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        desired = body['followed'] as bool;
      } else {
        throw StateError('Unexpected HTTP method: $method');
      }
      final received = _Received(method, id, token, desired);
      calls.add(received);
      final snapshot = {
        'id': id,
        'followed': following(token, id),
        'session': token,
      };
      plan?._arrived.complete(received);
      if (plan != null) await plan._released.future;
      final status = plan?.status ?? HttpStatus.ok;
      if (method == 'POST' && status == HttpStatus.ok) {
        (_following[token] ??= {})[id] = desired!;
      }
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(
          status != HttpStatus.ok
              ? {'error': 'write failed'}
              : method == 'GET'
              ? snapshot
              : {'ok': true},
        ),
      );
      await request.response.close();
    } on IOException {
      // A deliberately aborted read can disconnect before its gate opens.
    } catch (error) {
      if (!_closed) _serverErrors.add(error);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    resources.dispose();
    for (final plan in _plans) {
      plan.close();
    }
    _client.close(force: true);
    await _server.close(force: true);
    await _listener.cancel();
    await Future.wait(_handlers.toList()).timeout(const Duration(seconds: 3));
    await Future.wait(_operations).timeout(const Duration(seconds: 3));
    expect(_serverErrors, isEmpty);
  }
}
