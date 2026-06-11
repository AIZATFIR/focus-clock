import 'package:isar/isar.dart';

part 'preset.g.dart';

@collection
class Preset {
  Id id = Isar.autoIncrement;

  late String name;
  late int colorValue;
  String? iconKey;
  late DateTime createdAt;
}
