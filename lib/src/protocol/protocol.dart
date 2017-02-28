import 'message.dart';

abstract class Protocol {
  static bool isAck(Map packet) {
    return packet['type'] == MessageType.values.indexOf(MessageType.ACK) &&
        packet['task_id'] is String;
  }

  static bool isMessage(Map packet) {
    var type = packet['type'];

    if (type is int && type >= 0 && type < MessageType.values.length) {
      if (packet['task_id'] is String) {
        return packet['data'] is Map;
      }
    }

    return false;
  }
}
