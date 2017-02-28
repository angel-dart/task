import 'dart:io';
import 'package:angel_task/http.dart';
import 'common.dart';

main() async {
  var server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 3000);
  var onClient = await TaskProtocol.listen(server);
  print('Listening at http://${server.address.address}:${server.port}');

  var serverEndpoint = await TaskProtocol.connect(server.address, server.port);
  await runExample(serverEndpoint, onClient);
}
