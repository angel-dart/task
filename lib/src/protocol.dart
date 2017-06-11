import 'dart:isolate';

enum MessageType { REQUEST_ID, ASSIGNED_ID, RUN_TASK, TASK_COMPLETED }

class Message {
  final MessageType type;
  final String clientId, messageId, taskName;
  final List args;
  final Map named, taskResult;
  final SendPort sendPort;

  Message(this.type,
      {this.clientId,
      this.messageId,
      this.taskName,
      this.args,
      this.named,
      this.taskResult,
      this.sendPort});

  static Message parse(Map map) => new Message(MessageType.values[map['type']],
      clientId: map['client_id'],
      messageId: map['message_id'],
      taskName: map['task_name'],
      args: map['args'] is List ? map['args'] : null,
      named: map['named'] is Map ? map['named'] : null,
      taskResult: map['task_result'] is Map ? map['task_result'] : null,
      sendPort: map['send_port']);

  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.values.indexOf(type),
      'client_id': clientId,
      'message_id': messageId,
      'task_name': taskName,
      'args': args,
      'named': named,
      'task_result': taskResult,
      'send_port': sendPort
    };
  }
}
