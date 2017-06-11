import 'task_result.dart';

class TaskResultImpl implements TaskResult {
  @override
  final bool successful;

  @override
  final String error, stack;

  TaskResultImpl(this.successful, {this.error, this.stack});

  static TaskResultImpl parse(Map map) => new TaskResultImpl(map['successful'],
      error: map['error'], stack: map['stack']);

  Map<String, dynamic> toJson() {
    return {'successful': successful, 'error': error, 'stack': stack};
  }
}
