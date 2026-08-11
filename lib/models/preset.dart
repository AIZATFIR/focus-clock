import 'package:isar/isar.dart';

part 'preset.g.dart';

@collection
@Name('Preset227440')
class Preset {
  Id id = Isar.autoIncrement;

  late String name;
  late int colorValue;
  String? iconKey;
  late DateTime createdAt;
}
