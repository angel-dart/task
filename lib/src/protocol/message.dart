class Message {
  MessageType type;
  String taskId;
  final Map<String, dynamic> data = {};

  Message({this.type, this.taskId, Map<String, dynamic> data: const {}}) {
    this.data.addAll(data ?? {});
  }

  factory Message.fromJson(Map json) {
    return new Message(
        type: MessageType.values[json['type']],
        taskId: json['task_id'],
        data: json['data']);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': MessageType.values.indexOf(type),
      'task_id': taskId,
      'data': data
    };
  }
}

enum MessageType { ACK, RUN_TASK, TASK_COMPLETE, TASK_ERROR }
