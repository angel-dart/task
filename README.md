# task

[![version 1.0.0](https://img.shields.io/badge/pub-1.0.0-brightgreen.svg)](https://pub.dartlang.org/packages/angel_task)

Support for running and scheduling asynchronous tasks within Angel.
Parameters can be injected into scheduled tasks with the same dependency
injection system used by Angel.

*Coming soon*: Trigger tasks within route handlers. This will require communication between isolates, 
and will be present by the next release!

```dart
main() async {
  var app = await createApp();
  var scheduler = new AngelTaskScheduler(app);

  scheduler.once((Todo singleton) {
    print('3 seconds later, we found our Todo singleton: "${singleton.text}"');
  }, new Duration(seconds: 3));

  Task foo;
  int i = 0;

  foo = scheduler.seconds(1, () {
    print('Printing ${++i} time(s)!');

    if (i >= 3) {
      print('Cancelling foo task...');
      foo.cancel();
    }
  });

  await scheduler.start();
}
```
