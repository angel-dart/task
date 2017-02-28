import 'dart:async';
import 'package:angel_task/angel_task.dart';

runExample(Remote serverEndpoint, Stream<Remote> onClient) {
  var server = new DemoServer();
  onClient.pipe(server);

  return serverEndpoint.ack().then((_) {
    var client = new Client(serverEndpoint);
    client.add(new MessageBuilder().runTask('Hello, world!'));
  });
}

class DemoServer extends Server {
  @override
  handleClient(Remote client) {
    client.send(new Message(type: MessageType.RUN_TASK, data: {'foo': 'bar'}));
  }

  @override
  onRunTask(Message message, Remote client) {
    print('Task: ${message.toJson()}');
  }
}
