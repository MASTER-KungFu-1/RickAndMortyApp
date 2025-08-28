import 'package:hive/hive.dart';
import '../../core/errors/app_error.dart';
import '../../core/services/image_service.dart';
import '../../domain/entities/character.dart';

part 'character_dto.g.dart';

@HiveType(typeId: 0)
class CharacterDto extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String status;

  @HiveField(3)
  final String species;

  @HiveField(4)
  final String type;

  @HiveField(5)
  final String gender;

  @HiveField(6)
  final String image;

  @HiveField(7)
  final String url;

  @HiveField(8)
  final String created;

  CharacterDto({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.image,
    required this.url,
    required this.created,
  });

  factory CharacterDto.fromJson(Map<String, dynamic> json) {
    try {
      return CharacterDto(
        id: _validateInt(json, 'id'),
        name: _validateString(json, 'name'),
        status: _validateString(json, 'status'),
        species: _validateString(json, 'species'),
        type: _validateString(json, 'type'),
        gender: _validateString(json, 'gender'),
        image: _validateString(json, 'image'),
        url: _validateString(json, 'url'),
        created: _validateString(json, 'created'),
      );
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      throw DataParsingError.invalidJson('Ошибка создания CharacterDto: $e');
    }
  }

  Future<String?> getGitHubImageUrl() async {
    try {
      return await ImageService.getImageUrl(id.toString(), name);
    } catch (e) {
      return null;
    }
  }

  static int _validateInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      throw ValidationError.missingField(field);
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw ValidationError.invalidField(
        field, 'Ожидался int, получен: ${value.runtimeType}');
  }

  static String _validateString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'species': species,
      'type': type,
      'gender': gender,
      'image': image,
      'url': url,
      'created': created,
    };
  }

  Character toEntity() {
    return Character(
      id: id,
      name: name,
      status: status,
      species: species,
      type: type,
      gender: gender,
      image: image,
      url: url,
      created: DateTime.parse(created),
    );
  }
}
