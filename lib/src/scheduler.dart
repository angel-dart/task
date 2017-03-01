import 'dart:async';
import 'task.dart';

/// Asynchronously runs tasks.
abstract class TaskScheduler {
  /// Starts running tasks.
  Future start();

  /// Cancels and clears all registered tasks.
  Future close();

  /// Runs the task with the given name.
  dynamic run(String name, List args, [Map<Symbol, dynamic> named]);

  /// Runs the given callback once only.
  Task once(Function callback, [Duration duration]);

  /// Schedules a callback to run infinitely, recurring at the given duration.
  Task schedule(Duration duration, Function callback, {String name});

  /// Schedules a callback to repeat over a set amount of days.
  Task days(int days, Function callback, {String name}) =>
      schedule(new Duration(days: days), callback, name: name);

  /// Schedules a callback to repeat over a set amount of hours.
  Task hours(int hours, Function callback, {String name}) =>
      schedule(new Duration(hours: hours), callback, name: name);

  /// Schedules a callback to repeat over a set amount of minutes.
  Task minutes(int minutes, Function callback, {String name}) =>
      schedule(new Duration(minutes: minutes), callback, name: name);

  /// Schedules a callback to repeat over a set amount of seconds.
  Task seconds(int seconds, Function callback, {String name}) =>
      schedule(new Duration(seconds: seconds), callback, name: name);

  /// Schedules a callback to repeat over a set amount of milliseconds.
  Task milliseconds(int milliseconds, Function callback, {String name}) =>
      schedule(new Duration(milliseconds: milliseconds), callback, name: name);

  /// Schedules a callback to repeat over a set amount of microseconds.
  Task microseconds(int microseconds, Function callback, {String name}) =>
      schedule(new Duration(microseconds: microseconds), callback, name: name);
}
