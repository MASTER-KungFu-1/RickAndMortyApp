// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterDtoAdapter extends TypeAdapter<CharacterDto> {
  @override
  final int typeId = 0;

  @override
  CharacterDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterDto(
      id: fields[0] as int,
      name: fields[1] as String,
      status: fields[2] as String,
      species: fields[3] as String,
      type: fields[4] as String,
      gender: fields[5] as String,
      image: fields[6] as String,
      url: fields[7] as String,
      created: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterDto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.species)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.gender)
      ..writeByte(6)
      ..write(obj.image)
      ..writeByte(7)
      ..write(obj.url)
      ..writeByte(8)
      ..write(obj.created);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
