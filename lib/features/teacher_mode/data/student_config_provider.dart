import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentConfig {
  final String roomCode;
  final String name;

  StudentConfig(this.roomCode, this.name);
}

final studentConfigProvider = StateProvider<StudentConfig?>((ref) => null);
