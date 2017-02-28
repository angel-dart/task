import 'package:uuid/uuid.dart';
import 'message.dart';

class MessageBuilder {
  final Uuid _uuid = new Uuid();

  Message runTask(String name, [Map<String, dynamic> params = const {}]) {
    return new Message(
        type: MessageType.RUN_TASK,
        taskId: _uuid.v4(),
        data: {'params': params ?? {}});
  }

  Message ack(String uid) {
    return new Message(type: MessageType.ACK, taskId: uid);
  }
}
