import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_task/angel_task.dart';
import 'package:uuid/uuid.dart';

final Uuid _uuid = new Uuid();

abstract class TaskProtocol {
  static Future<Remote> connect(InternetAddress address, int port) async =>
      new _RemoteServerImpl(address, port);

  static Stream<Remote> listen(HttpServer server) => _listen(server);
}

Stream<Remote> _listen(HttpServer server) {
  var builder = new MessageBuilder();
  var ctrl = new StreamController<Remote>();

  server.listen((req) {
    if (req.headers['angel_task'] == null) {
      var uid = _uuid.v4();
      req.response.headers.set('angel_task', uid);
      var client = new _RemoteClientImpl(req);
      client..send(builder.ack(uid));
    } else {
      req.transform(UTF8.decoder).join().then((str) {
        var data = JSON.decode(str);

        if (data is Map) {
          if (Protocol.isMessage(data) && !Protocol.isAck(data)) {
            var message = new Message.fromJson(data);

            if (message.data['client_id'] is String) {
              // String clientId = message.data['client_id'];
              var client = new _RemoteClientImpl(req);
              client._onMessage.add(message);
            }
          }
        }
      });
    }
  }, cancelOnError: true, onError: ctrl.addError, onDone: () => ctrl.close());

  return ctrl.stream;
}

class _RemoteClientImpl extends Remote {
  final StreamController<Message> _onMessage = new StreamController<Message>();
  final HttpRequest _request;

  _RemoteClientImpl(this._request);

  @override
  Stream<Message> get onMessage => _onMessage.stream;

  @override
  Future send(Message message) async {
    var rs = _request.response;
    rs
      ..headers.set(HttpHeaders.CONTENT_TYPE, ContentType.JSON.toString())
      ..write(JSON.encode(message.toJson()));
    await rs.close();
  }

  @override
  Future<String> ack() =>
      new Future<String>.error('The server cannot receive ACKs!');
}

class _RemoteServerImpl extends Remote {
  Completer<String> _ack = new Completer<String>();
  final HttpClient _client = new HttpClient();
  String _clientId;
  final StreamController<Message> _onMessage = new StreamController<Message>();
  final InternetAddress _address;
  final int _port;

  _RemoteServerImpl(this._address, this._port) {
    _client.open('GET', _address.address, _port, '/').then((rq) async {
      var rs = await rq.close();
      var str = await rs.transform(UTF8.decoder).join();
      var data = JSON.decode(str);

      if (data is Map) {
        if (Protocol.isMessage(data) && !Protocol.isAck(data)) {
          var message = new Message.fromJson(data);

          if (Protocol.isAck(data)) {
            _ack.complete(_clientId = message.taskId);
          } else
            _onMessage.add(message);
        }
      }
    }).catchError((e, st) {
      _client.close(force: true);
      _onMessage.close();
      _ack.completeError(e, st);
    });
  }

  Future<String> ack() => _ack.future;

  @override
  Stream<Message> get onMessage => _onMessage.stream;

  @override
  Future send(Message message) async {
    var rq = await _client.open('POST', _address.address, _port, '/');
    rq
      ..headers.set(HttpHeaders.CONTENT_TYPE, ContentType.JSON.toString())
      ..write(JSON.encode(message.toJson()));

    if (_clientId != null) rq.headers.set('angel_task', _clientId);

    await rq.close();
  }
}
