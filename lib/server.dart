import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'angel_task.dart';

/// Schedules and runs tasks within the context of a loaded application.
class AngelTaskScheduler extends TaskScheduler {
  final List<_TaskImpl> _tasks = [];
  final Angel app;

  AngelTaskScheduler(this.app);

  @override
  Task schedule(Duration duration, Function callback, {String name}) {
    var task = new _TaskImpl(app, duration, callback, preInject(callback));
    _tasks.add(task);
    return task;
  }

  @override
  Future close() {
    return Future.wait(_tasks.map((t) => t.cancel()));
  }

  @override
  Task once(Function callback, [Duration duration]) {
    var task = new _OnceTaskImpl(app, duration, callback, preInject(callback));
    _tasks.add(task);
    return task;
  }

  @override
  run(String name, List args, [Map<Symbol, dynamic> named]) {
    var task = _tasks.firstWhere((t) => t.name != null && t.name == name,
        orElse: () =>
            throw new UnsupportedError('No task found named \'$name\'.'));
    return task.run();
  }

  @override
  Future start() {
    return new Future.sync(() {
      for (var task in _tasks.where((t) => !t._closed)) {
        task._start();
      }
    });
  }
}

class _TaskImpl implements Task {
  bool _closed = false;
  Timer _timer;
  final Angel app;
  final Function callback;
  final Duration frequency;
  final String name;
  final InjectionRequest injection;

  _TaskImpl(this.app, this.frequency, this.callback, this.injection,
      {this.name});

  run() {
    if (_closed) throw new StateError('Cannot run a cancelled task.');
    _run(callback, injection, app);
  }

  void _start() {
    _timer = new Timer.periodic(frequency, (_) => run());
  }

  @override
  Future cancel() async {
    _timer.cancel();
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
  _OnceTaskImpl(Angel app, Duration frequency, Function callback,
      InjectionRequest injection)
      : super(app, frequency, callback, injection);

  run() {
    var result = super.run();

    if (result is Future)
      return result.then((r) {
        cancel();
        return r;
      });
    else {
      cancel();
      return result;
    }
  }
}

_run(Function callback, InjectionRequest injection, Angel app) {
  List args = [];
  Map<Symbol, dynamic> named = {};

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

  injection.required.forEach(inject);
  injection.named.forEach((k, v) {
    if (v == dynamic || v == Null || v == Object || v == null)
      throw new UnimplementedError('Cannot inject \'$k\' as type \'$v\'.');
    named[new Symbol(k)] = app.container.make(v);
  });

  return Function.apply(callback, args, named);
}
