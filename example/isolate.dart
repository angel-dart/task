import 'dart:isolate';
import 'package:angel_task/isolate.dart';
import 'common.dart';

main() async {
  var recv = new ReceivePort();
  var onClient = await TaskProtocol.listen(recv);
  var serverEndpoint = await TaskProtocol.connect(recv.sendPort);
  await runExample(serverEndpoint, onClient);
}