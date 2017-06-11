import 'dart:async';
import 'dart:isolate';
import 'package:uuid/uuid.dart';
import 'protocol.dart';
import 'task_result.dart';
import 'task_result_impl.dart';

class AngelTaskClient {
  final Completer _connect = new Completer();
  final Map<String, Completer<Message>> _awaiting = {};
  String _id;
  ReceivePort _receivePort;
  final Uuid _uuid = new Uuid();

  ReceivePort get receivePort => _receivePort;

  /// A [SendPort] that points back to a master isolate.
  final SendPort server;

  AngelTaskClient(this.server);

  Future connect() {
    if (_connect.isCompleted)
      throw new StateError('This TaskClient is already connected!');
    _receivePort = new ReceivePort()..listen(handleMessage);
    server.send(
        new Message(MessageType.REQUEST_ID, sendPort: _receivePort.sendPort));
    return _connect.future;
  }

  handleMessage(Map data) {
    var message = Message.parse(data);

    switch (message.type) {
      case MessageType.ASSIGNED_ID:
        if (_id == null) {
          _connect.complete(_id = message.clientId);
        }
        break;
      case MessageType.TASK_COMPLETED:
        // TODO: Handle task completion
        break;
      default:
        break;
    }
  }

  Future close() async {
    receivePort.close();
    _awaiting.clear();
  }

  Future<TaskResult> run(String name,
      {List args, Map<String, dynamic> named, Duration timeout}) {
    var c = new Completer<TaskResult>();
    var id = _uuid.v4();
    Timer timer;

    server.send(new Message(MessageType.RUN_TASK,
        taskName: name, args: args, named: named));

    var msg = _awaiting[id] = new Completer<Message>();

    msg.future.then((message) {
      timer?.cancel();
      if (!c.isCompleted) c.complete(TaskResultImpl.parse(message.taskResult));
    }).catchError(c.completeError);

    if (timeout != null) {
      timer = new Timer(timeout, () {
        if (!c.isCompleted)
          c.completeError(new TimeoutException(
              'Remote task run exceeded timeout of ${timeout.inMilliseconds}ms.',
              timeout));
      });
    }

    return c.future;
  }
}
