# task

[![version 1.0.0](https://img.shields.io/badge/pub-1.0.0-brightgreen.svg)](https://pub.dartlang.org/packages/angel_task)

Support for running and scheduling asynchronous tasks within Angel.
Parameters can be injected into scheduled tasks with the same dependency
injection system used by Angel.


```dart
main() async {
  var app = await createApp();
  var scheduler = new AngelTaskScheduler(app);

  // Run a one-off task, with an optional delay.
  scheduler.once((Todo singleton) {
    print('3 seconds later, we found our Todo singleton: "${singleton.text}"');
  }, new Duration(seconds: 3));

  Task foo;
  int i = 0;

  // Periodically run functionality, complete with dependency injection...
  foo = scheduler.seconds(1, () {
    print('Printing ${++i} time(s)!');

    if (i >= 3) {
      print('Cancelling foo task...');
      foo.cancel();
    }
  });
  
  // Named tasks!
  var greetTask = scheduler.minutes(3, (String message) => print(message), name: 'greet');

  await scheduler.start();
  
  // Run a named task
  var result = await scheduler.run('greet', ['Hello, world!']);
}
```

# TaskClient
Use the `TaskClient` API to invoke tasks in the main isolate within child nodes.

```dart
main() {
  
}

void isolateMain(SendPort master) {
  var app = new Angel();
  var client = new TaskClient(master);
  
  master.connect().then((_) async {
    var result = await client.run('greet', args: ['Hello, world!']);
    
    // Handle errors...
    if (!result.successful) {
      print(result.error);
      print(result.stack);
    }
  });
  
  // You can inject the client as a singleton
  app.container.singleton(client);
  
  app.get('/async_task', (TaskClient client) async {
    var asyncGreet = await client.run('greet', args: ['Async!!!']);
    return {'ok': asyncGreet.successful};
  });
}
```

