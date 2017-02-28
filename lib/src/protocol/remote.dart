import 'dart:async';
import 'message.dart';

abstract class Remote {
  Future<String> ack();
  Stream<Message> get onMessage;
  Future send(Message message);
}