import 'dart:async';
import 'message.dart';
import 'remote.dart';

class Server implements StreamConsumer<Remote> {
  bool _closed = false;

  onRunTask(Message message, Remote client) {}

  onInvalidCommand(Message message, Remote client) {}

  @override
  Future addStream(Stream<Remote> stream) {
    if (_closed) throw new StateError('Cannot add stream to closed server.');

    var c = new Completer();

    stream.listen(handleClient,
        cancelOnError: true,
        onDone: () => c.complete(),
        onError: c.completeError);

    return c.future;
  }

  @override
  Future close() async {
    _closed = true;
  }

  void handleClient(Remote client) {
    client.onMessage.listen((message) {
      switch (message.type) {
        case MessageType.RUN_TASK:
          onRunTask(message, client);
          break;
        default:
          onInvalidCommand(message, client);
      }
    });
  }
}
