import 'dart:async';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:uuid/uuid.dart';
import 'protocol.dart';
import 'scheduler.dart';
import 'task.dart';
import 'task_result_impl.dart';

/// Schedules and runs tasks within the context of a loaded application.
class AngelTaskScheduler extends TaskScheduler {
  final Map<String, SendPort> _clients = {};
  bool _started = false;
  final List<_TaskImpl> _tasks = [];
  final Uuid _uuid = new Uuid();
  final Angel app;
  final ReceivePort receivePort = new ReceivePort();

  AngelTaskScheduler(this.app);

  @override
  Task schedule(Duration duration, Function callback, {String name}) {
    var task =
        new _TaskImpl(app, duration, callback, preInject(callback), name: name);
    _tasks.add(task);
    if (_started) task.run();
    return task;
  }

  @override
  Future close() {
    receivePort.close();
    return Future.wait(_tasks.map((t) => t.cancel()));
  }

  @override
  Task once(Function callback, [Duration delay]) {
    var task = new _OnceTaskImpl(app, delay, callback, preInject(callback));
    _tasks.add(task);
    if (_started) task.run();
    return task;
  }

  @override
  Future run(String name, [List args, Map<Symbol, dynamic> named]) {
    var task = _tasks.firstWhere((t) => t.name != null && t.name == name,
        orElse: () =>
            throw new UnsupportedError('No task found named \'$name\'.'));
    return task.run(args, named);
  }

  @override
  Future start() {
    receivePort.listen(handleMessage);
    return new Future.sync(() {
      for (var task in _tasks.where((t) => !t._closed)) {
        task._start();
      }

      _started = true;
    });
  }

  handleMessage(Map data) {
    var message = Message.parse(data);

    switch (message.type) {
      case MessageType.REQUEST_ID:
        var id = _uuid.v4();
        var client = _clients[id] = message.sendPort;
        client
            .send(new Message(MessageType.ASSIGNED_ID, clientId: id).toJson());
        break;
      case MessageType.RUN_TASK:
        var client = _clients[message.clientId];

        if (client != null) {
          run(
              message.taskName,
              message.args,
              message.named?.keys?.fold<Map<Symbol, dynamic>>({}, (out, k) {
                return out..[new Symbol(k)] = message.named[k];
              })).then((_) {
            client.send(new Message(MessageType.TASK_COMPLETED,
                messageId: message.messageId,
                taskResult: new TaskResultImpl(true).toJson()));
          }).catchError((e, st) {
            client.send(new Message(MessageType.TASK_COMPLETED,
                messageId: message.messageId,
                taskResult: new TaskResultImpl(false,
                        error: e.toString(), stack: st.toString())
                    .toJson()));
          });
        }
        break;
      default:
        break;
    }
  }

  @override
  void define(String name, Function callback) {
    _tasks.add(new _OnceTaskImpl(app, null, callback, preInject(callback)));
  }
}

class _TaskImpl implements Task {
  bool _closed = false;
  final StreamController _results = new StreamController();
  Timer _timer;
  final Angel app;
  final Function callback;
  final Duration frequency;
  final String name;
  final InjectionRequest injection;

  _TaskImpl(this.app, this.frequency, this.callback, this.injection,
      {this.name});

  @override
  Stream get results => _results.stream;

  Future run([List args, Map<Symbol, dynamic> named]) async {
    if (_closed) throw new StateError('Cannot run a cancelled task.');
    var r = await _run(callback, injection, app, args, named);
    _results.add(r);
    return r;
  }

  void _start() {
    if (frequency != null) _timer = new Timer.periodic(frequency, (_) => run());
  }

  @override
  Future cancel() async {
    _timer.cancel();
    _results.close();
    _closed = true;
  }

  @override
  toString() {
    if (name != null)
      return 'Task: $name';
    else
      return super.toString();
  }
}

class _OnceTaskImpl extends _TaskImpl {
  _OnceTaskImpl(
      Angel app, Duration delay, Function callback, InjectionRequest injection)
      : super(app, delay ?? new Duration(), callback, injection);

  run([List args, Map<Symbol, dynamic> named]) async {
    var result = await super.run(args, named);
    cancel();
    return result;
  }
}

_run(Function callback, InjectionRequest injection, Angel app,
    [List arguments, Map<Symbol, dynamic> namedParams]) {
  List args = []..addAll(arguments ?? []);
  Map<Symbol, dynamic> named = {}..addAll(namedParams ?? {});

  void inject(requirement) {
    if (requirement is List &&
        requirement.length >= 2 &&
        requirement[0] is String &&
        requirement[1] is Type) {
      inject(requirement[1]);
    } else if (requirement is Type)
      args.add(app.container.make(requirement));
    else {
      throw new UnimplementedError(
          'Cannot inject \'$requirement\'. The task scheduler only supports parameters with type annotations.');
    }
  }

  injection.required.skip(args.length).forEach(inject);
  injection.named.forEach((k, v) {
    named.putIfAbsent(new Symbol(k), () {
      if (v == dynamic || v == Null || v == Object || v == null)
        throw new UnimplementedError('Cannot inject \'$k\' as type \'$v\'.');
      return app.container.make(v);
    });
  });

  return Function.apply(callback, args, named);
}
