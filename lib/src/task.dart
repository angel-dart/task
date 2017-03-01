import 'dart:async';

abstract class Task {
  String get name;
  Duration get frequency;
  Future cancel();
}