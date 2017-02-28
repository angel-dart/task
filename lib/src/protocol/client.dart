import 'dart:async';
import 'message.dart';
import 'remote.dart';

class Client implements StreamSink<Message>, StreamConsumer<Message> {
  bool _closed = false;
  var _closeFuture = new Completer();
  final Remote server;

  Client(this.server);

  @override
  Future addStream(Stream<Message> stream) {
    if (_closed) throw new StateError('Cannot add stream to closed client.');

    var c = new Completer();

    stream.listen(add,
        cancelOnError: true,
        onDone: () => c.complete(),
        onError: c.completeError);

    return c.future;
  }

  @override
  Future close() async {
    _closed = true;
    _closeFuture.complete();
  }

  @override
  void add(Message data) {
    if (_closed) throw new StateError('Cannot add stream to closed client.');
    server.send(data);
  }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
    _closeFuture.completeError(errorEvent);
    throw errorEvent;
  }

  @override
  Future get done => _closeFuture.future;
}
