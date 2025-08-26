// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomListAdapter extends TypeAdapter<CustomList> {
  @override
  final int typeId = 1;

  @override
  CustomList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomList(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      movieIds: (fields[3] as List).cast<int>(),
      contentTypes: (fields[6] as List?)?.cast<String>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomList obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.movieIds)
      ..writeByte(6)
      ..write(obj.contentTypes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
