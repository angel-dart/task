import 'package:angel_framework/angel_framework.dart';
import 'package:angel_task/angel_task.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  AngelTaskScheduler scheduler;

  setUp(() async {
    app = new Angel();
    scheduler = new AngelTaskScheduler(app);
    await scheduler.start();
  });

  tearDown(() async {
    await scheduler.close();
    await app.close();
  });

  test('sets correct durations', () {
    expect(scheduler.once(null).frequency, new Duration(seconds: 0));
    expect(scheduler.once(null, new Duration(seconds: 2)).frequency,
        new Duration(seconds: 2));
    expect(scheduler.days(2, null).frequency, new Duration(days: 2));
    expect(scheduler.hours(2, null).frequency, new Duration(hours: 2));
    expect(scheduler.minutes(2, null).frequency, new Duration(minutes: 2));
    expect(scheduler.seconds(2, null).frequency, new Duration(seconds: 2));
    expect(scheduler.milliseconds(2, null).frequency,
        new Duration(milliseconds: 2));
    expect(scheduler.microseconds(2, null).frequency,
        new Duration(microseconds: 2));
  });

  group('named tasks', () {
    test('sets correct name', () {
      expect(
          scheduler.schedule(new Duration(seconds: 2), null, name: 'foo').name,
          'foo');
    });

    test('define+run by name', () async {
      scheduler.define('compute_two', () => 2);
      expect(await scheduler.run('compute_two'), 2);
    });

    test('pass args to named', () async {
      scheduler.define('times_two', (int n) => n * 2);
      expect(await scheduler.run('times_two', [2]), 4);
    });

    test('pass named args to named', () async {
      scheduler.define('add', (int x, {int y}) => x + y);
      expect(await scheduler.run('add', [2], {#y: 4}), 6);
    });
  });

  test('results stream', () async {
    var task = scheduler.once(() => 34);
    expect(await task.results.first, 34);
  });

  test('task toString()', () async {
    expect(scheduler.once(null).toString(), isNot('foo'));
    expect(scheduler.seconds(2, null, name: 'foo').toString(), 'Task: foo');
  });
}
