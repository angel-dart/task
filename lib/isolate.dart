import 'dart:async';
import 'dart:isolate';
import 'package:angel_task/angel_task.dart';
import 'package:uuid/uuid.dart';

final Uuid _uuid = new Uuid();

abstract class TaskProtocol {
  static Future<Remote> connect(SendPort sendPort) async =>
      new _RemoteServerImpl(sendPort);

  static Stream<Remote> listen(ReceivePort receivePort) => _listen(receivePort);
}

Stream<Remote> _listen(ReceivePort receivePort) {
  var builder = new MessageBuilder();
  var ctrl = new StreamController<Remote>();
  Map<String, _RemoteClientImpl> clients = {};

  receivePort.listen(
      (data) {
        if (data is SendPort) {
          var uid = _uuid.v4();
          var client = new _RemoteClientImpl(data);
          clients[uid] = client..send(builder.ack(uid));
        } else if (data is Map) {
          if (Protocol.isMessage(data) && !Protocol.isAck(data)) {
            var message = new Message.fromJson(data);

            if (message.data['client_id'] is String) {
              String clientId = message.data['client_id'];

              if (clients.containsKey(clientId)) {
                var client = clients[clientId];
                client._onMessage.add(message);
              }
            }
          }
        }
      },
      cancelOnError: true,
      onError: ctrl.addError,
      onDone: () async {
        for (var client in clients.values) {
          await client._onMessage.close();
        }

        clients.clear();
        await ctrl.close();
      });

  return ctrl.stream;
}

class _RemoteClientImpl extends Remote {
  final StreamController<Message> _onMessage = new StreamController<Message>();
  final SendPort _sendPort;

  _RemoteClientImpl(this._sendPort);

  @override
  Stream<Message> get onMessage => _onMessage.stream;

  @override
  Future send(Message message) {
    return new Future.sync(() {
      _sendPort.send(message.toJson());
    });
  }

  @override
  Future<String> ack() =>
      new Future<String>.error('The server cannot receive ACKs!');
}

class _RemoteServerImpl extends Remote {
  Completer<String> _ack = new Completer<String>();
  String _clientId;
  final StreamController<Message> _onMessage = new StreamController<Message>();
  final SendPort _sendPort;

  _RemoteServerImpl(this._sendPort) {
    var recv = new ReceivePort();

    recv.listen(
        (data) {
          if (data is Map) {
            if (Protocol.isMessage(data)) {
              var message = new Message.fromJson(data);

              if (Protocol.isAck(data)) {
                _ack.complete(_clientId = message.taskId);
              } else {
                _onMessage.add(message);
              }
            }
          }
        },
        cancelOnError: true,
        onDone: () {
          _onMessage.close();

          if (!_ack.isCompleted)
            _ack.completeError(
                new StateError('Server never acknowledged client.'));
        });

    _sendPort.send(recv.sendPort);
  }

  Future<String> ack() => _ack.future;

  @override
  Stream<Message> get onMessage => _onMessage.stream;

  @override
  Future send(Message message) {
    return new Future.sync(() {
      message.data['client_id'] = _clientId;
      _sendPort.send(message.toJson());
    });
  }
}
