// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _pinHashMeta =
      const VerificationMeta('pinHash');
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
      'pin_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pinSaltMeta =
      const VerificationMeta('pinSalt');
  @override
  late final GeneratedColumn<String> pinSalt = GeneratedColumn<String>(
      'pin_salt', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cashier'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supabaseIdMeta =
      const VerificationMeta('supabaseId');
  @override
  late final GeneratedColumn<String> supabaseId = GeneratedColumn<String>(
      'supabase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        pinHash,
        pinSalt,
        role,
        isActive,
        createdAt,
        email,
        supabaseId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(_pinHashMeta,
          pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta));
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('pin_salt')) {
      context.handle(_pinSaltMeta,
          pinSalt.isAcceptableOrUnknown(data['pin_salt']!, _pinSaltMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
          _supabaseIdMeta,
          supabaseId.isAcceptableOrUnknown(
              data['supabase_id']!, _supabaseIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      pinHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_hash'])!,
      pinSalt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_salt'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      supabaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supabase_id']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final String pinHash;
  final String pinSalt;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? email;
  final String? supabaseId;
  const User(
      {required this.id,
      required this.name,
      required this.pinHash,
      required this.pinSalt,
      required this.role,
      required this.isActive,
      required this.createdAt,
      this.email,
      this.supabaseId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['pin_hash'] = Variable<String>(pinHash);
    map['pin_salt'] = Variable<String>(pinSalt);
    map['role'] = Variable<String>(role);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<String>(supabaseId);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      pinHash: Value(pinHash),
      pinSalt: Value(pinSalt),
      role: Value(role),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      pinSalt: serializer.fromJson<String>(json['pinSalt']),
      role: serializer.fromJson<String>(json['role']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      email: serializer.fromJson<String?>(json['email']),
      supabaseId: serializer.fromJson<String?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'pinHash': serializer.toJson<String>(pinHash),
      'pinSalt': serializer.toJson<String>(pinSalt),
      'role': serializer.toJson<String>(role),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'email': serializer.toJson<String?>(email),
      'supabaseId': serializer.toJson<String?>(supabaseId),
    };
  }

  User copyWith(
          {int? id,
          String? name,
          String? pinHash,
          String? pinSalt,
          String? role,
          bool? isActive,
          DateTime? createdAt,
          Value<String?> email = const Value.absent(),
          Value<String?> supabaseId = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        pinHash: pinHash ?? this.pinHash,
        pinSalt: pinSalt ?? this.pinSalt,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        email: email.present ? email.value : this.email,
        supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      pinSalt: data.pinSalt.present ? data.pinSalt.value : this.pinSalt,
      role: data.role.present ? data.role.value : this.role,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      email: data.email.present ? data.email.value : this.email,
      supabaseId:
          data.supabaseId.present ? data.supabaseId.value : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('email: $email, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, pinHash, pinSalt, role, isActive, createdAt, email, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.pinHash == this.pinHash &&
          other.pinSalt == this.pinSalt &&
          other.role == this.role &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.email == this.email &&
          other.supabaseId == this.supabaseId);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> pinHash;
  final Value<String> pinSalt;
  final Value<String> role;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<String?> email;
  final Value<String?> supabaseId;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.email = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String pinHash,
    this.pinSalt = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.email = const Value.absent(),
    this.supabaseId = const Value.absent(),
  })  : name = Value(name),
        pinHash = Value(pinHash);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? pinHash,
    Expression<String>? pinSalt,
    Expression<String>? role,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<String>? email,
    Expression<String>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pinHash != null) 'pin_hash': pinHash,
      if (pinSalt != null) 'pin_salt': pinSalt,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (email != null) 'email': email,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? pinHash,
      Value<String>? pinSalt,
      Value<String>? role,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<String?>? email,
      Value<String?>? supabaseId}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (pinSalt.present) {
      map['pin_salt'] = Variable<String>(pinSalt.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<String>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('email: $email, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 80),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#6366F1'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, name, color, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String color;
  final int sortOrder;
  const Category(
      {required this.id,
      required this.name,
      required this.color,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({int? id, String? name, String? color, int? sortOrder}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> color;
  final Value<int> sortOrder;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? color,
      Value<int>? sortOrder}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _priceHtMeta =
      const VerificationMeta('priceHt');
  @override
  late final GeneratedColumn<double> priceHt = GeneratedColumn<double>(
      'price_ht', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _stockQtyMeta =
      const VerificationMeta('stockQty');
  @override
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
      'stock_qty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stockAlertMeta =
      const VerificationMeta('stockAlert');
  @override
  late final GeneratedColumn<int> stockAlert = GeneratedColumn<int>(
      'stock_alert', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pce'));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        barcode,
        name,
        description,
        categoryId,
        priceHt,
        taxRate,
        costPrice,
        stockQty,
        stockAlert,
        unit,
        imagePath,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('price_ht')) {
      context.handle(_priceHtMeta,
          priceHt.isAcceptableOrUnknown(data['price_ht']!, _priceHtMeta));
    } else if (isInserting) {
      context.missing(_priceHtMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('stock_qty')) {
      context.handle(_stockQtyMeta,
          stockQty.isAcceptableOrUnknown(data['stock_qty']!, _stockQtyMeta));
    }
    if (data.containsKey('stock_alert')) {
      context.handle(
          _stockAlertMeta,
          stockAlert.isAcceptableOrUnknown(
              data['stock_alert']!, _stockAlertMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      priceHt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_ht'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price'])!,
      stockQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_qty'])!,
      stockAlert: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_alert'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String? barcode;
  final String name;
  final String description;
  final int? categoryId;
  final double priceHt;
  final double taxRate;
  final double costPrice;
  final int stockQty;
  final int stockAlert;
  final String unit;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product(
      {required this.id,
      this.barcode,
      required this.name,
      required this.description,
      this.categoryId,
      required this.priceHt,
      required this.taxRate,
      required this.costPrice,
      required this.stockQty,
      required this.stockAlert,
      required this.unit,
      this.imagePath,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['price_ht'] = Variable<double>(priceHt);
    map['tax_rate'] = Variable<double>(taxRate);
    map['cost_price'] = Variable<double>(costPrice);
    map['stock_qty'] = Variable<int>(stockQty);
    map['stock_alert'] = Variable<int>(stockAlert);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: Value(name),
      description: Value(description),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      priceHt: Value(priceHt),
      taxRate: Value(taxRate),
      costPrice: Value(costPrice),
      stockQty: Value(stockQty),
      stockAlert: Value(stockAlert),
      unit: Value(unit),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      priceHt: serializer.fromJson<double>(json['priceHt']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      stockQty: serializer.fromJson<int>(json['stockQty']),
      stockAlert: serializer.fromJson<int>(json['stockAlert']),
      unit: serializer.fromJson<String>(json['unit']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'categoryId': serializer.toJson<int?>(categoryId),
      'priceHt': serializer.toJson<double>(priceHt),
      'taxRate': serializer.toJson<double>(taxRate),
      'costPrice': serializer.toJson<double>(costPrice),
      'stockQty': serializer.toJson<int>(stockQty),
      'stockAlert': serializer.toJson<int>(stockAlert),
      'unit': serializer.toJson<String>(unit),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith(
          {int? id,
          Value<String?> barcode = const Value.absent(),
          String? name,
          String? description,
          Value<int?> categoryId = const Value.absent(),
          double? priceHt,
          double? taxRate,
          double? costPrice,
          int? stockQty,
          int? stockAlert,
          String? unit,
          Value<String?> imagePath = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Product(
        id: id ?? this.id,
        barcode: barcode.present ? barcode.value : this.barcode,
        name: name ?? this.name,
        description: description ?? this.description,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        priceHt: priceHt ?? this.priceHt,
        taxRate: taxRate ?? this.taxRate,
        costPrice: costPrice ?? this.costPrice,
        stockQty: stockQty ?? this.stockQty,
        stockAlert: stockAlert ?? this.stockAlert,
        unit: unit ?? this.unit,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      priceHt: data.priceHt.present ? data.priceHt.value : this.priceHt,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      stockQty: data.stockQty.present ? data.stockQty.value : this.stockQty,
      stockAlert:
          data.stockAlert.present ? data.stockAlert.value : this.stockAlert,
      unit: data.unit.present ? data.unit.value : this.unit,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('priceHt: $priceHt, ')
          ..write('taxRate: $taxRate, ')
          ..write('costPrice: $costPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('stockAlert: $stockAlert, ')
          ..write('unit: $unit, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      barcode,
      name,
      description,
      categoryId,
      priceHt,
      taxRate,
      costPrice,
      stockQty,
      stockAlert,
      unit,
      imagePath,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.priceHt == this.priceHt &&
          other.taxRate == this.taxRate &&
          other.costPrice == this.costPrice &&
          other.stockQty == this.stockQty &&
          other.stockAlert == this.stockAlert &&
          other.unit == this.unit &&
          other.imagePath == this.imagePath &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String?> barcode;
  final Value<String> name;
  final Value<String> description;
  final Value<int?> categoryId;
  final Value<double> priceHt;
  final Value<double> taxRate;
  final Value<double> costPrice;
  final Value<int> stockQty;
  final Value<int> stockAlert;
  final Value<String> unit;
  final Value<String?> imagePath;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.priceHt = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.stockAlert = const Value.absent(),
    this.unit = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    required double priceHt,
    this.taxRate = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.stockAlert = const Value.absent(),
    this.unit = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        priceHt = Value(priceHt);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? categoryId,
    Expression<double>? priceHt,
    Expression<double>? taxRate,
    Expression<double>? costPrice,
    Expression<int>? stockQty,
    Expression<int>? stockAlert,
    Expression<String>? unit,
    Expression<String>? imagePath,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (priceHt != null) 'price_ht': priceHt,
      if (taxRate != null) 'tax_rate': taxRate,
      if (costPrice != null) 'cost_price': costPrice,
      if (stockQty != null) 'stock_qty': stockQty,
      if (stockAlert != null) 'stock_alert': stockAlert,
      if (unit != null) 'unit': unit,
      if (imagePath != null) 'image_path': imagePath,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? barcode,
      Value<String>? name,
      Value<String>? description,
      Value<int?>? categoryId,
      Value<double>? priceHt,
      Value<double>? taxRate,
      Value<double>? costPrice,
      Value<int>? stockQty,
      Value<int>? stockAlert,
      Value<String>? unit,
      Value<String?>? imagePath,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ProductsCompanion(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priceHt: priceHt ?? this.priceHt,
      taxRate: taxRate ?? this.taxRate,
      costPrice: costPrice ?? this.costPrice,
      stockQty: stockQty ?? this.stockQty,
      stockAlert: stockAlert ?? this.stockAlert,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (priceHt.present) {
      map['price_ht'] = Variable<double>(priceHt.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (stockQty.present) {
      map['stock_qty'] = Variable<int>(stockQty.value);
    }
    if (stockAlert.present) {
      map['stock_alert'] = Variable<int>(stockAlert.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('priceHt: $priceHt, ')
          ..write('taxRate: $taxRate, ')
          ..write('costPrice: $costPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('stockAlert: $stockAlert, ')
          ..write('unit: $unit, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _loyaltyPointsMeta =
      const VerificationMeta('loyaltyPoints');
  @override
  late final GeneratedColumn<double> loyaltyPoints = GeneratedColumn<double>(
      'loyalty_points', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, email, loyaltyPoints, notes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('loyalty_points')) {
      context.handle(
          _loyaltyPointsMeta,
          loyaltyPoints.isAcceptableOrUnknown(
              data['loyalty_points']!, _loyaltyPointsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      loyaltyPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}loyalty_points'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final double loyaltyPoints;
  final String notes;
  final DateTime createdAt;
  const Customer(
      {required this.id,
      required this.name,
      this.phone,
      this.email,
      required this.loyaltyPoints,
      required this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['loyalty_points'] = Variable<double>(loyaltyPoints);
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      loyaltyPoints: Value(loyaltyPoints),
      notes: Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      loyaltyPoints: serializer.fromJson<double>(json['loyaltyPoints']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'loyaltyPoints': serializer.toJson<double>(loyaltyPoints),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Customer copyWith(
          {int? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          double? loyaltyPoints,
          String? notes,
          DateTime? createdAt}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      loyaltyPoints: data.loyaltyPoints.present
          ? data.loyaltyPoints.value
          : this.loyaltyPoints,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, email, loyaltyPoints, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.loyaltyPoints == this.loyaltyPoints &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<double> loyaltyPoints;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<double>? loyaltyPoints,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? email,
      Value<double>? loyaltyPoints,
      Value<String>? notes,
      Value<DateTime>? createdAt}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (loyaltyPoints.present) {
      map['loyalty_points'] = Variable<double>(loyaltyPoints.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CashSessionsTable extends CashSessions
    with TableInfo<$CashSessionsTable, CashSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _startingCashMeta =
      const VerificationMeta('startingCash');
  @override
  late final GeneratedColumn<double> startingCash = GeneratedColumn<double>(
      'starting_cash', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _endingCashMeta =
      const VerificationMeta('endingCash');
  @override
  late final GeneratedColumn<double> endingCash = GeneratedColumn<double>(
      'ending_cash', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _expectedCashMeta =
      const VerificationMeta('expectedCash');
  @override
  late final GeneratedColumn<double> expectedCash = GeneratedColumn<double>(
      'expected_cash', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _discrepancyMeta =
      const VerificationMeta('discrepancy');
  @override
  late final GeneratedColumn<double> discrepancy = GeneratedColumn<double>(
      'discrepancy', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        startedAt,
        endedAt,
        startingCash,
        endingCash,
        expectedCash,
        discrepancy,
        status,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<CashSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('starting_cash')) {
      context.handle(
          _startingCashMeta,
          startingCash.isAcceptableOrUnknown(
              data['starting_cash']!, _startingCashMeta));
    } else if (isInserting) {
      context.missing(_startingCashMeta);
    }
    if (data.containsKey('ending_cash')) {
      context.handle(
          _endingCashMeta,
          endingCash.isAcceptableOrUnknown(
              data['ending_cash']!, _endingCashMeta));
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
          _expectedCashMeta,
          expectedCash.isAcceptableOrUnknown(
              data['expected_cash']!, _expectedCashMeta));
    }
    if (data.containsKey('discrepancy')) {
      context.handle(
          _discrepancyMeta,
          discrepancy.isAcceptableOrUnknown(
              data['discrepancy']!, _discrepancyMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      startingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}starting_cash'])!,
      endingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ending_cash']),
      expectedCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_cash']),
      discrepancy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discrepancy']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
    );
  }

  @override
  $CashSessionsTable createAlias(String alias) {
    return $CashSessionsTable(attachedDatabase, alias);
  }
}

class CashSession extends DataClass implements Insertable<CashSession> {
  final int id;
  final int userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double startingCash;
  final double? endingCash;
  final double? expectedCash;
  final double? discrepancy;
  final String status;
  final String notes;
  const CashSession(
      {required this.id,
      required this.userId,
      required this.startedAt,
      this.endedAt,
      required this.startingCash,
      this.endingCash,
      this.expectedCash,
      this.discrepancy,
      required this.status,
      required this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['starting_cash'] = Variable<double>(startingCash);
    if (!nullToAbsent || endingCash != null) {
      map['ending_cash'] = Variable<double>(endingCash);
    }
    if (!nullToAbsent || expectedCash != null) {
      map['expected_cash'] = Variable<double>(expectedCash);
    }
    if (!nullToAbsent || discrepancy != null) {
      map['discrepancy'] = Variable<double>(discrepancy);
    }
    map['status'] = Variable<String>(status);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  CashSessionsCompanion toCompanion(bool nullToAbsent) {
    return CashSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      startingCash: Value(startingCash),
      endingCash: endingCash == null && nullToAbsent
          ? const Value.absent()
          : Value(endingCash),
      expectedCash: expectedCash == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCash),
      discrepancy: discrepancy == null && nullToAbsent
          ? const Value.absent()
          : Value(discrepancy),
      status: Value(status),
      notes: Value(notes),
    );
  }

  factory CashSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashSession(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      startingCash: serializer.fromJson<double>(json['startingCash']),
      endingCash: serializer.fromJson<double?>(json['endingCash']),
      expectedCash: serializer.fromJson<double?>(json['expectedCash']),
      discrepancy: serializer.fromJson<double?>(json['discrepancy']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'startingCash': serializer.toJson<double>(startingCash),
      'endingCash': serializer.toJson<double?>(endingCash),
      'expectedCash': serializer.toJson<double?>(expectedCash),
      'discrepancy': serializer.toJson<double?>(discrepancy),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String>(notes),
    };
  }

  CashSession copyWith(
          {int? id,
          int? userId,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          double? startingCash,
          Value<double?> endingCash = const Value.absent(),
          Value<double?> expectedCash = const Value.absent(),
          Value<double?> discrepancy = const Value.absent(),
          String? status,
          String? notes}) =>
      CashSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        startingCash: startingCash ?? this.startingCash,
        endingCash: endingCash.present ? endingCash.value : this.endingCash,
        expectedCash:
            expectedCash.present ? expectedCash.value : this.expectedCash,
        discrepancy: discrepancy.present ? discrepancy.value : this.discrepancy,
        status: status ?? this.status,
        notes: notes ?? this.notes,
      );
  CashSession copyWithCompanion(CashSessionsCompanion data) {
    return CashSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      startingCash: data.startingCash.present
          ? data.startingCash.value
          : this.startingCash,
      endingCash:
          data.endingCash.present ? data.endingCash.value : this.endingCash,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      discrepancy:
          data.discrepancy.present ? data.discrepancy.value : this.discrepancy,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startingCash: $startingCash, ')
          ..write('endingCash: $endingCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('discrepancy: $discrepancy, ')
          ..write('status: $status, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, startedAt, endedAt, startingCash,
      endingCash, expectedCash, discrepancy, status, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.startingCash == this.startingCash &&
          other.endingCash == this.endingCash &&
          other.expectedCash == this.expectedCash &&
          other.discrepancy == this.discrepancy &&
          other.status == this.status &&
          other.notes == this.notes);
}

class CashSessionsCompanion extends UpdateCompanion<CashSession> {
  final Value<int> id;
  final Value<int> userId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> startingCash;
  final Value<double?> endingCash;
  final Value<double?> expectedCash;
  final Value<double?> discrepancy;
  final Value<String> status;
  final Value<String> notes;
  const CashSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.startingCash = const Value.absent(),
    this.endingCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.discrepancy = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
  });
  CashSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required double startingCash,
    this.endingCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.discrepancy = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
  })  : userId = Value(userId),
        startingCash = Value(startingCash);
  static Insertable<CashSession> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? startingCash,
    Expression<double>? endingCash,
    Expression<double>? expectedCash,
    Expression<double>? discrepancy,
    Expression<String>? status,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (startingCash != null) 'starting_cash': startingCash,
      if (endingCash != null) 'ending_cash': endingCash,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (discrepancy != null) 'discrepancy': discrepancy,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    });
  }

  CashSessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<double>? startingCash,
      Value<double?>? endingCash,
      Value<double?>? expectedCash,
      Value<double?>? discrepancy,
      Value<String>? status,
      Value<String>? notes}) {
    return CashSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      startingCash: startingCash ?? this.startingCash,
      endingCash: endingCash ?? this.endingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      discrepancy: discrepancy ?? this.discrepancy,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (startingCash.present) {
      map['starting_cash'] = Variable<double>(startingCash.value);
    }
    if (endingCash.present) {
      map['ending_cash'] = Variable<double>(endingCash.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<double>(expectedCash.value);
    }
    if (discrepancy.present) {
      map['discrepancy'] = Variable<double>(discrepancy.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startingCash: $startingCash, ')
          ..write('endingCash: $endingCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('discrepancy: $discrepancy, ')
          ..write('status: $status, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
      'ref', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cashSessionIdMeta =
      const VerificationMeta('cashSessionId');
  @override
  late final GeneratedColumn<int> cashSessionId = GeneratedColumn<int>(
      'cash_session_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cash_sessions (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _totalHtMeta =
      const VerificationMeta('totalHt');
  @override
  late final GeneratedColumn<double> totalHt = GeneratedColumn<double>(
      'total_ht', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalTaxMeta =
      const VerificationMeta('totalTax');
  @override
  late final GeneratedColumn<double> totalTax = GeneratedColumn<double>(
      'total_tax', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalTtcMeta =
      const VerificationMeta('totalTtc');
  @override
  late final GeneratedColumn<double> totalTtc = GeneratedColumn<double>(
      'total_ttc', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('completed'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ref,
        cashSessionId,
        userId,
        customerId,
        totalHt,
        totalTax,
        totalTtc,
        discountAmount,
        status,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(Insertable<Sale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ref')) {
      context.handle(
          _refMeta, ref.isAcceptableOrUnknown(data['ref']!, _refMeta));
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('cash_session_id')) {
      context.handle(
          _cashSessionIdMeta,
          cashSessionId.isAcceptableOrUnknown(
              data['cash_session_id']!, _cashSessionIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('total_ht')) {
      context.handle(_totalHtMeta,
          totalHt.isAcceptableOrUnknown(data['total_ht']!, _totalHtMeta));
    } else if (isInserting) {
      context.missing(_totalHtMeta);
    }
    if (data.containsKey('total_tax')) {
      context.handle(_totalTaxMeta,
          totalTax.isAcceptableOrUnknown(data['total_tax']!, _totalTaxMeta));
    } else if (isInserting) {
      context.missing(_totalTaxMeta);
    }
    if (data.containsKey('total_ttc')) {
      context.handle(_totalTtcMeta,
          totalTtc.isAcceptableOrUnknown(data['total_ttc']!, _totalTtcMeta));
    } else if (isInserting) {
      context.missing(_totalTtcMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ref: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref'])!,
      cashSessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cash_session_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_id']),
      totalHt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_ht'])!,
      totalTax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_tax'])!,
      totalTtc: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_ttc'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_amount'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final int id;
  final String ref;
  final int? cashSessionId;
  final int userId;
  final int? customerId;
  final double totalHt;
  final double totalTax;
  final double totalTtc;
  final double discountAmount;
  final String status;
  final String note;
  final DateTime createdAt;
  const Sale(
      {required this.id,
      required this.ref,
      this.cashSessionId,
      required this.userId,
      this.customerId,
      required this.totalHt,
      required this.totalTax,
      required this.totalTtc,
      required this.discountAmount,
      required this.status,
      required this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ref'] = Variable<String>(ref);
    if (!nullToAbsent || cashSessionId != null) {
      map['cash_session_id'] = Variable<int>(cashSessionId);
    }
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    map['total_ht'] = Variable<double>(totalHt);
    map['total_tax'] = Variable<double>(totalTax);
    map['total_ttc'] = Variable<double>(totalTtc);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['status'] = Variable<String>(status);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      ref: Value(ref),
      cashSessionId: cashSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashSessionId),
      userId: Value(userId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      totalHt: Value(totalHt),
      totalTax: Value(totalTax),
      totalTtc: Value(totalTtc),
      discountAmount: Value(discountAmount),
      status: Value(status),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<int>(json['id']),
      ref: serializer.fromJson<String>(json['ref']),
      cashSessionId: serializer.fromJson<int?>(json['cashSessionId']),
      userId: serializer.fromJson<int>(json['userId']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      totalHt: serializer.fromJson<double>(json['totalHt']),
      totalTax: serializer.fromJson<double>(json['totalTax']),
      totalTtc: serializer.fromJson<double>(json['totalTtc']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ref': serializer.toJson<String>(ref),
      'cashSessionId': serializer.toJson<int?>(cashSessionId),
      'userId': serializer.toJson<int>(userId),
      'customerId': serializer.toJson<int?>(customerId),
      'totalHt': serializer.toJson<double>(totalHt),
      'totalTax': serializer.toJson<double>(totalTax),
      'totalTtc': serializer.toJson<double>(totalTtc),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sale copyWith(
          {int? id,
          String? ref,
          Value<int?> cashSessionId = const Value.absent(),
          int? userId,
          Value<int?> customerId = const Value.absent(),
          double? totalHt,
          double? totalTax,
          double? totalTtc,
          double? discountAmount,
          String? status,
          String? note,
          DateTime? createdAt}) =>
      Sale(
        id: id ?? this.id,
        ref: ref ?? this.ref,
        cashSessionId:
            cashSessionId.present ? cashSessionId.value : this.cashSessionId,
        userId: userId ?? this.userId,
        customerId: customerId.present ? customerId.value : this.customerId,
        totalHt: totalHt ?? this.totalHt,
        totalTax: totalTax ?? this.totalTax,
        totalTtc: totalTtc ?? this.totalTtc,
        discountAmount: discountAmount ?? this.discountAmount,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      ref: data.ref.present ? data.ref.value : this.ref,
      cashSessionId: data.cashSessionId.present
          ? data.cashSessionId.value
          : this.cashSessionId,
      userId: data.userId.present ? data.userId.value : this.userId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      totalHt: data.totalHt.present ? data.totalHt.value : this.totalHt,
      totalTax: data.totalTax.present ? data.totalTax.value : this.totalTax,
      totalTtc: data.totalTtc.present ? data.totalTtc.value : this.totalTtc,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('cashSessionId: $cashSessionId, ')
          ..write('userId: $userId, ')
          ..write('customerId: $customerId, ')
          ..write('totalHt: $totalHt, ')
          ..write('totalTax: $totalTax, ')
          ..write('totalTtc: $totalTtc, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ref, cashSessionId, userId, customerId,
      totalHt, totalTax, totalTtc, discountAmount, status, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.ref == this.ref &&
          other.cashSessionId == this.cashSessionId &&
          other.userId == this.userId &&
          other.customerId == this.customerId &&
          other.totalHt == this.totalHt &&
          other.totalTax == this.totalTax &&
          other.totalTtc == this.totalTtc &&
          other.discountAmount == this.discountAmount &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<int> id;
  final Value<String> ref;
  final Value<int?> cashSessionId;
  final Value<int> userId;
  final Value<int?> customerId;
  final Value<double> totalHt;
  final Value<double> totalTax;
  final Value<double> totalTtc;
  final Value<double> discountAmount;
  final Value<String> status;
  final Value<String> note;
  final Value<DateTime> createdAt;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.ref = const Value.absent(),
    this.cashSessionId = const Value.absent(),
    this.userId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.totalHt = const Value.absent(),
    this.totalTax = const Value.absent(),
    this.totalTtc = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SalesCompanion.insert({
    this.id = const Value.absent(),
    required String ref,
    this.cashSessionId = const Value.absent(),
    required int userId,
    this.customerId = const Value.absent(),
    required double totalHt,
    required double totalTax,
    required double totalTtc,
    this.discountAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : ref = Value(ref),
        userId = Value(userId),
        totalHt = Value(totalHt),
        totalTax = Value(totalTax),
        totalTtc = Value(totalTtc);
  static Insertable<Sale> custom({
    Expression<int>? id,
    Expression<String>? ref,
    Expression<int>? cashSessionId,
    Expression<int>? userId,
    Expression<int>? customerId,
    Expression<double>? totalHt,
    Expression<double>? totalTax,
    Expression<double>? totalTtc,
    Expression<double>? discountAmount,
    Expression<String>? status,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ref != null) 'ref': ref,
      if (cashSessionId != null) 'cash_session_id': cashSessionId,
      if (userId != null) 'user_id': userId,
      if (customerId != null) 'customer_id': customerId,
      if (totalHt != null) 'total_ht': totalHt,
      if (totalTax != null) 'total_tax': totalTax,
      if (totalTtc != null) 'total_ttc': totalTtc,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SalesCompanion copyWith(
      {Value<int>? id,
      Value<String>? ref,
      Value<int?>? cashSessionId,
      Value<int>? userId,
      Value<int?>? customerId,
      Value<double>? totalHt,
      Value<double>? totalTax,
      Value<double>? totalTtc,
      Value<double>? discountAmount,
      Value<String>? status,
      Value<String>? note,
      Value<DateTime>? createdAt}) {
    return SalesCompanion(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      cashSessionId: cashSessionId ?? this.cashSessionId,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      totalHt: totalHt ?? this.totalHt,
      totalTax: totalTax ?? this.totalTax,
      totalTtc: totalTtc ?? this.totalTtc,
      discountAmount: discountAmount ?? this.discountAmount,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (cashSessionId.present) {
      map['cash_session_id'] = Variable<int>(cashSessionId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (totalHt.present) {
      map['total_ht'] = Variable<double>(totalHt.value);
    }
    if (totalTax.present) {
      map['total_tax'] = Variable<double>(totalTax.value);
    }
    if (totalTtc.present) {
      map['total_ttc'] = Variable<double>(totalTtc.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('cashSessionId: $cashSessionId, ')
          ..write('userId: $userId, ')
          ..write('customerId: $customerId, ')
          ..write('totalHt: $totalHt, ')
          ..write('totalTax: $totalTax, ')
          ..write('totalTtc: $totalTtc, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sales (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceHtMeta =
      const VerificationMeta('unitPriceHt');
  @override
  late final GeneratedColumn<double> unitPriceHt = GeneratedColumn<double>(
      'unit_price_ht', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _discountPctMeta =
      const VerificationMeta('discountPct');
  @override
  late final GeneratedColumn<double> discountPct = GeneratedColumn<double>(
      'discount_pct', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _lineTotalMeta =
      const VerificationMeta('lineTotal');
  @override
  late final GeneratedColumn<double> lineTotal = GeneratedColumn<double>(
      'line_total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        saleId,
        productId,
        productName,
        unitPriceHt,
        taxRate,
        quantity,
        discountPct,
        lineTotal
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(Insertable<SaleItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('unit_price_ht')) {
      context.handle(
          _unitPriceHtMeta,
          unitPriceHt.isAcceptableOrUnknown(
              data['unit_price_ht']!, _unitPriceHtMeta));
    } else if (isInserting) {
      context.missing(_unitPriceHtMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    } else if (isInserting) {
      context.missing(_taxRateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('discount_pct')) {
      context.handle(
          _discountPctMeta,
          discountPct.isAcceptableOrUnknown(
              data['discount_pct']!, _discountPctMeta));
    }
    if (data.containsKey('line_total')) {
      context.handle(_lineTotalMeta,
          lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta));
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sale_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      unitPriceHt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_price_ht'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      discountPct: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount_pct'])!,
      lineTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}line_total'])!,
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItem extends DataClass implements Insertable<SaleItem> {
  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final double unitPriceHt;
  final double taxRate;
  final int quantity;
  final double discountPct;
  final double lineTotal;
  const SaleItem(
      {required this.id,
      required this.saleId,
      required this.productId,
      required this.productName,
      required this.unitPriceHt,
      required this.taxRate,
      required this.quantity,
      required this.discountPct,
      required this.lineTotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    map['unit_price_ht'] = Variable<double>(unitPriceHt);
    map['tax_rate'] = Variable<double>(taxRate);
    map['quantity'] = Variable<int>(quantity);
    map['discount_pct'] = Variable<double>(discountPct);
    map['line_total'] = Variable<double>(lineTotal);
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productName: Value(productName),
      unitPriceHt: Value(unitPriceHt),
      taxRate: Value(taxRate),
      quantity: Value(quantity),
      discountPct: Value(discountPct),
      lineTotal: Value(lineTotal),
    );
  }

  factory SaleItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItem(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      unitPriceHt: serializer.fromJson<double>(json['unitPriceHt']),
      taxRate: serializer.fromJson<double>(json['taxRate']),
      quantity: serializer.fromJson<int>(json['quantity']),
      discountPct: serializer.fromJson<double>(json['discountPct']),
      lineTotal: serializer.fromJson<double>(json['lineTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'unitPriceHt': serializer.toJson<double>(unitPriceHt),
      'taxRate': serializer.toJson<double>(taxRate),
      'quantity': serializer.toJson<int>(quantity),
      'discountPct': serializer.toJson<double>(discountPct),
      'lineTotal': serializer.toJson<double>(lineTotal),
    };
  }

  SaleItem copyWith(
          {int? id,
          int? saleId,
          int? productId,
          String? productName,
          double? unitPriceHt,
          double? taxRate,
          int? quantity,
          double? discountPct,
          double? lineTotal}) =>
      SaleItem(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        unitPriceHt: unitPriceHt ?? this.unitPriceHt,
        taxRate: taxRate ?? this.taxRate,
        quantity: quantity ?? this.quantity,
        discountPct: discountPct ?? this.discountPct,
        lineTotal: lineTotal ?? this.lineTotal,
      );
  SaleItem copyWithCompanion(SaleItemsCompanion data) {
    return SaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      unitPriceHt:
          data.unitPriceHt.present ? data.unitPriceHt.value : this.unitPriceHt,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      discountPct:
          data.discountPct.present ? data.discountPct.value : this.discountPct,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('unitPriceHt: $unitPriceHt, ')
          ..write('taxRate: $taxRate, ')
          ..write('quantity: $quantity, ')
          ..write('discountPct: $discountPct, ')
          ..write('lineTotal: $lineTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, saleId, productId, productName,
      unitPriceHt, taxRate, quantity, discountPct, lineTotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.unitPriceHt == this.unitPriceHt &&
          other.taxRate == this.taxRate &&
          other.quantity == this.quantity &&
          other.discountPct == this.discountPct &&
          other.lineTotal == this.lineTotal);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItem> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<int> productId;
  final Value<String> productName;
  final Value<double> unitPriceHt;
  final Value<double> taxRate;
  final Value<int> quantity;
  final Value<double> discountPct;
  final Value<double> lineTotal;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.unitPriceHt = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.quantity = const Value.absent(),
    this.discountPct = const Value.absent(),
    this.lineTotal = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required int productId,
    required String productName,
    required double unitPriceHt,
    required double taxRate,
    required int quantity,
    this.discountPct = const Value.absent(),
    required double lineTotal,
  })  : saleId = Value(saleId),
        productId = Value(productId),
        productName = Value(productName),
        unitPriceHt = Value(unitPriceHt),
        taxRate = Value(taxRate),
        quantity = Value(quantity),
        lineTotal = Value(lineTotal);
  static Insertable<SaleItem> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<double>? unitPriceHt,
    Expression<double>? taxRate,
    Expression<int>? quantity,
    Expression<double>? discountPct,
    Expression<double>? lineTotal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (unitPriceHt != null) 'unit_price_ht': unitPriceHt,
      if (taxRate != null) 'tax_rate': taxRate,
      if (quantity != null) 'quantity': quantity,
      if (discountPct != null) 'discount_pct': discountPct,
      if (lineTotal != null) 'line_total': lineTotal,
    });
  }

  SaleItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? saleId,
      Value<int>? productId,
      Value<String>? productName,
      Value<double>? unitPriceHt,
      Value<double>? taxRate,
      Value<int>? quantity,
      Value<double>? discountPct,
      Value<double>? lineTotal}) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPriceHt: unitPriceHt ?? this.unitPriceHt,
      taxRate: taxRate ?? this.taxRate,
      quantity: quantity ?? this.quantity,
      discountPct: discountPct ?? this.discountPct,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (unitPriceHt.present) {
      map['unit_price_ht'] = Variable<double>(unitPriceHt.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (discountPct.present) {
      map['discount_pct'] = Variable<double>(discountPct.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<double>(lineTotal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('unitPriceHt: $unitPriceHt, ')
          ..write('taxRate: $taxRate, ')
          ..write('quantity: $quantity, ')
          ..write('discountPct: $discountPct, ')
          ..write('lineTotal: $lineTotal')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sales (id)'));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _changeGivenMeta =
      const VerificationMeta('changeGiven');
  @override
  late final GeneratedColumn<double> changeGiven = GeneratedColumn<double>(
      'change_given', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, saleId, method, amount, changeGiven, paidAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<Payment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('change_given')) {
      context.handle(
          _changeGivenMeta,
          changeGiven.isAcceptableOrUnknown(
              data['change_given']!, _changeGivenMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sale_id'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      changeGiven: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}change_given'])!,
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at'])!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final int id;
  final int saleId;
  final String method;
  final double amount;
  final double changeGiven;
  final DateTime paidAt;
  const Payment(
      {required this.id,
      required this.saleId,
      required this.method,
      required this.amount,
      required this.changeGiven,
      required this.paidAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['method'] = Variable<String>(method);
    map['amount'] = Variable<double>(amount);
    map['change_given'] = Variable<double>(changeGiven);
    map['paid_at'] = Variable<DateTime>(paidAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      method: Value(method),
      amount: Value(amount),
      changeGiven: Value(changeGiven),
      paidAt: Value(paidAt),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      method: serializer.fromJson<String>(json['method']),
      amount: serializer.fromJson<double>(json['amount']),
      changeGiven: serializer.fromJson<double>(json['changeGiven']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'method': serializer.toJson<String>(method),
      'amount': serializer.toJson<double>(amount),
      'changeGiven': serializer.toJson<double>(changeGiven),
      'paidAt': serializer.toJson<DateTime>(paidAt),
    };
  }

  Payment copyWith(
          {int? id,
          int? saleId,
          String? method,
          double? amount,
          double? changeGiven,
          DateTime? paidAt}) =>
      Payment(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        method: method ?? this.method,
        amount: amount ?? this.amount,
        changeGiven: changeGiven ?? this.changeGiven,
        paidAt: paidAt ?? this.paidAt,
      );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      method: data.method.present ? data.method.value : this.method,
      amount: data.amount.present ? data.amount.value : this.amount,
      changeGiven:
          data.changeGiven.present ? data.changeGiven.value : this.changeGiven,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('changeGiven: $changeGiven, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, saleId, method, amount, changeGiven, paidAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.method == this.method &&
          other.amount == this.amount &&
          other.changeGiven == this.changeGiven &&
          other.paidAt == this.paidAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<String> method;
  final Value<double> amount;
  final Value<double> changeGiven;
  final Value<DateTime> paidAt;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.method = const Value.absent(),
    this.amount = const Value.absent(),
    this.changeGiven = const Value.absent(),
    this.paidAt = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    required String method,
    required double amount,
    this.changeGiven = const Value.absent(),
    this.paidAt = const Value.absent(),
  })  : saleId = Value(saleId),
        method = Value(method),
        amount = Value(amount);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<String>? method,
    Expression<double>? amount,
    Expression<double>? changeGiven,
    Expression<DateTime>? paidAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (method != null) 'method': method,
      if (amount != null) 'amount': amount,
      if (changeGiven != null) 'change_given': changeGiven,
      if (paidAt != null) 'paid_at': paidAt,
    });
  }

  PaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? saleId,
      Value<String>? method,
      Value<double>? amount,
      Value<double>? changeGiven,
      Value<DateTime>? paidAt}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      changeGiven: changeGiven ?? this.changeGiven,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (changeGiven.present) {
      map['change_given'] = Variable<double>(changeGiven.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('changeGiven: $changeGiven, ')
          ..write('paidAt: $paidAt')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyDeltaMeta =
      const VerificationMeta('qtyDelta');
  @override
  late final GeneratedColumn<int> qtyDelta = GeneratedColumn<int>(
      'qty_delta', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _qtyAfterMeta =
      const VerificationMeta('qtyAfter');
  @override
  late final GeneratedColumn<int> qtyAfter = GeneratedColumn<int>(
      'qty_after', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _inventoryRefMeta =
      const VerificationMeta('inventoryRef');
  @override
  late final GeneratedColumn<String> inventoryRef = GeneratedColumn<String>(
      'inventory_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _movedAtMeta =
      const VerificationMeta('movedAt');
  @override
  late final GeneratedColumn<DateTime> movedAt = GeneratedColumn<DateTime>(
      'moved_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productId,
        userId,
        type,
        qtyDelta,
        qtyAfter,
        reason,
        inventoryRef,
        movedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(Insertable<StockMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('qty_delta')) {
      context.handle(_qtyDeltaMeta,
          qtyDelta.isAcceptableOrUnknown(data['qty_delta']!, _qtyDeltaMeta));
    } else if (isInserting) {
      context.missing(_qtyDeltaMeta);
    }
    if (data.containsKey('qty_after')) {
      context.handle(_qtyAfterMeta,
          qtyAfter.isAcceptableOrUnknown(data['qty_after']!, _qtyAfterMeta));
    } else if (isInserting) {
      context.missing(_qtyAfterMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('inventory_ref')) {
      context.handle(
          _inventoryRefMeta,
          inventoryRef.isAcceptableOrUnknown(
              data['inventory_ref']!, _inventoryRefMeta));
    }
    if (data.containsKey('moved_at')) {
      context.handle(_movedAtMeta,
          movedAt.isAcceptableOrUnknown(data['moved_at']!, _movedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      qtyDelta: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}qty_delta'])!,
      qtyAfter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}qty_after'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      inventoryRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}inventory_ref']),
      movedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}moved_at'])!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final int id;
  final int productId;
  final int? userId;
  final String type;
  final int qtyDelta;
  final int qtyAfter;
  final String reason;
  final String? inventoryRef;
  final DateTime movedAt;
  const StockMovement(
      {required this.id,
      required this.productId,
      this.userId,
      required this.type,
      required this.qtyDelta,
      required this.qtyAfter,
      required this.reason,
      this.inventoryRef,
      required this.movedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    map['type'] = Variable<String>(type);
    map['qty_delta'] = Variable<int>(qtyDelta);
    map['qty_after'] = Variable<int>(qtyAfter);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || inventoryRef != null) {
      map['inventory_ref'] = Variable<String>(inventoryRef);
    }
    map['moved_at'] = Variable<DateTime>(movedAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      type: Value(type),
      qtyDelta: Value(qtyDelta),
      qtyAfter: Value(qtyAfter),
      reason: Value(reason),
      inventoryRef: inventoryRef == null && nullToAbsent
          ? const Value.absent()
          : Value(inventoryRef),
      movedAt: Value(movedAt),
    );
  }

  factory StockMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      userId: serializer.fromJson<int?>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      qtyDelta: serializer.fromJson<int>(json['qtyDelta']),
      qtyAfter: serializer.fromJson<int>(json['qtyAfter']),
      reason: serializer.fromJson<String>(json['reason']),
      inventoryRef: serializer.fromJson<String?>(json['inventoryRef']),
      movedAt: serializer.fromJson<DateTime>(json['movedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'userId': serializer.toJson<int?>(userId),
      'type': serializer.toJson<String>(type),
      'qtyDelta': serializer.toJson<int>(qtyDelta),
      'qtyAfter': serializer.toJson<int>(qtyAfter),
      'reason': serializer.toJson<String>(reason),
      'inventoryRef': serializer.toJson<String?>(inventoryRef),
      'movedAt': serializer.toJson<DateTime>(movedAt),
    };
  }

  StockMovement copyWith(
          {int? id,
          int? productId,
          Value<int?> userId = const Value.absent(),
          String? type,
          int? qtyDelta,
          int? qtyAfter,
          String? reason,
          Value<String?> inventoryRef = const Value.absent(),
          DateTime? movedAt}) =>
      StockMovement(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        userId: userId.present ? userId.value : this.userId,
        type: type ?? this.type,
        qtyDelta: qtyDelta ?? this.qtyDelta,
        qtyAfter: qtyAfter ?? this.qtyAfter,
        reason: reason ?? this.reason,
        inventoryRef:
            inventoryRef.present ? inventoryRef.value : this.inventoryRef,
        movedAt: movedAt ?? this.movedAt,
      );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      qtyDelta: data.qtyDelta.present ? data.qtyDelta.value : this.qtyDelta,
      qtyAfter: data.qtyAfter.present ? data.qtyAfter.value : this.qtyAfter,
      reason: data.reason.present ? data.reason.value : this.reason,
      inventoryRef: data.inventoryRef.present
          ? data.inventoryRef.value
          : this.inventoryRef,
      movedAt: data.movedAt.present ? data.movedAt.value : this.movedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('qtyDelta: $qtyDelta, ')
          ..write('qtyAfter: $qtyAfter, ')
          ..write('reason: $reason, ')
          ..write('inventoryRef: $inventoryRef, ')
          ..write('movedAt: $movedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, userId, type, qtyDelta,
      qtyAfter, reason, inventoryRef, movedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.qtyDelta == this.qtyDelta &&
          other.qtyAfter == this.qtyAfter &&
          other.reason == this.reason &&
          other.inventoryRef == this.inventoryRef &&
          other.movedAt == this.movedAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<int> id;
  final Value<int> productId;
  final Value<int?> userId;
  final Value<String> type;
  final Value<int> qtyDelta;
  final Value<int> qtyAfter;
  final Value<String> reason;
  final Value<String?> inventoryRef;
  final Value<DateTime> movedAt;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.qtyDelta = const Value.absent(),
    this.qtyAfter = const Value.absent(),
    this.reason = const Value.absent(),
    this.inventoryRef = const Value.absent(),
    this.movedAt = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    this.userId = const Value.absent(),
    required String type,
    required int qtyDelta,
    required int qtyAfter,
    this.reason = const Value.absent(),
    this.inventoryRef = const Value.absent(),
    this.movedAt = const Value.absent(),
  })  : productId = Value(productId),
        type = Value(type),
        qtyDelta = Value(qtyDelta),
        qtyAfter = Value(qtyAfter);
  static Insertable<StockMovement> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<int>? userId,
    Expression<String>? type,
    Expression<int>? qtyDelta,
    Expression<int>? qtyAfter,
    Expression<String>? reason,
    Expression<String>? inventoryRef,
    Expression<DateTime>? movedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (qtyDelta != null) 'qty_delta': qtyDelta,
      if (qtyAfter != null) 'qty_after': qtyAfter,
      if (reason != null) 'reason': reason,
      if (inventoryRef != null) 'inventory_ref': inventoryRef,
      if (movedAt != null) 'moved_at': movedAt,
    });
  }

  StockMovementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? productId,
      Value<int?>? userId,
      Value<String>? type,
      Value<int>? qtyDelta,
      Value<int>? qtyAfter,
      Value<String>? reason,
      Value<String?>? inventoryRef,
      Value<DateTime>? movedAt}) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      qtyDelta: qtyDelta ?? this.qtyDelta,
      qtyAfter: qtyAfter ?? this.qtyAfter,
      reason: reason ?? this.reason,
      inventoryRef: inventoryRef ?? this.inventoryRef,
      movedAt: movedAt ?? this.movedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (qtyDelta.present) {
      map['qty_delta'] = Variable<int>(qtyDelta.value);
    }
    if (qtyAfter.present) {
      map['qty_after'] = Variable<int>(qtyAfter.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (inventoryRef.present) {
      map['inventory_ref'] = Variable<String>(inventoryRef.value);
    }
    if (movedAt.present) {
      map['moved_at'] = Variable<DateTime>(movedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('qtyDelta: $qtyDelta, ')
          ..write('qtyAfter: $qtyAfter, ')
          ..write('reason: $reason, ')
          ..write('inventoryRef: $inventoryRef, ')
          ..write('movedAt: $movedAt')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<int> saleId = GeneratedColumn<int>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('UNIQUE REFERENCES sales (id)'));
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('escpos'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPrintedMeta =
      const VerificationMeta('isPrinted');
  @override
  late final GeneratedColumn<bool> isPrinted = GeneratedColumn<bool>(
      'is_printed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_printed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _printedAtMeta =
      const VerificationMeta('printedAt');
  @override
  late final GeneratedColumn<DateTime> printedAt = GeneratedColumn<DateTime>(
      'printed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, saleId, format, content, isPrinted, printedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(Insertable<Receipt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_printed')) {
      context.handle(_isPrintedMeta,
          isPrinted.isAcceptableOrUnknown(data['is_printed']!, _isPrintedMeta));
    }
    if (data.containsKey('printed_at')) {
      context.handle(_printedAtMeta,
          printedAt.isAcceptableOrUnknown(data['printed_at']!, _printedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sale_id'])!,
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      isPrinted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_printed'])!,
      printedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}printed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final int id;
  final int saleId;
  final String format;
  final String content;
  final bool isPrinted;
  final DateTime? printedAt;
  final DateTime createdAt;
  const Receipt(
      {required this.id,
      required this.saleId,
      required this.format,
      required this.content,
      required this.isPrinted,
      this.printedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_id'] = Variable<int>(saleId);
    map['format'] = Variable<String>(format);
    map['content'] = Variable<String>(content);
    map['is_printed'] = Variable<bool>(isPrinted);
    if (!nullToAbsent || printedAt != null) {
      map['printed_at'] = Variable<DateTime>(printedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      format: Value(format),
      content: Value(content),
      isPrinted: Value(isPrinted),
      printedAt: printedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(printedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<int>(json['id']),
      saleId: serializer.fromJson<int>(json['saleId']),
      format: serializer.fromJson<String>(json['format']),
      content: serializer.fromJson<String>(json['content']),
      isPrinted: serializer.fromJson<bool>(json['isPrinted']),
      printedAt: serializer.fromJson<DateTime?>(json['printedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleId': serializer.toJson<int>(saleId),
      'format': serializer.toJson<String>(format),
      'content': serializer.toJson<String>(content),
      'isPrinted': serializer.toJson<bool>(isPrinted),
      'printedAt': serializer.toJson<DateTime?>(printedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Receipt copyWith(
          {int? id,
          int? saleId,
          String? format,
          String? content,
          bool? isPrinted,
          Value<DateTime?> printedAt = const Value.absent(),
          DateTime? createdAt}) =>
      Receipt(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        format: format ?? this.format,
        content: content ?? this.content,
        isPrinted: isPrinted ?? this.isPrinted,
        printedAt: printedAt.present ? printedAt.value : this.printedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      format: data.format.present ? data.format.value : this.format,
      content: data.content.present ? data.content.value : this.content,
      isPrinted: data.isPrinted.present ? data.isPrinted.value : this.isPrinted,
      printedAt: data.printedAt.present ? data.printedAt.value : this.printedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('format: $format, ')
          ..write('content: $content, ')
          ..write('isPrinted: $isPrinted, ')
          ..write('printedAt: $printedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, saleId, format, content, isPrinted, printedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.format == this.format &&
          other.content == this.content &&
          other.isPrinted == this.isPrinted &&
          other.printedAt == this.printedAt &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<int> id;
  final Value<int> saleId;
  final Value<String> format;
  final Value<String> content;
  final Value<bool> isPrinted;
  final Value<DateTime?> printedAt;
  final Value<DateTime> createdAt;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.format = const Value.absent(),
    this.content = const Value.absent(),
    this.isPrinted = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.id = const Value.absent(),
    required int saleId,
    this.format = const Value.absent(),
    required String content,
    this.isPrinted = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : saleId = Value(saleId),
        content = Value(content);
  static Insertable<Receipt> custom({
    Expression<int>? id,
    Expression<int>? saleId,
    Expression<String>? format,
    Expression<String>? content,
    Expression<bool>? isPrinted,
    Expression<DateTime>? printedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (format != null) 'format': format,
      if (content != null) 'content': content,
      if (isPrinted != null) 'is_printed': isPrinted,
      if (printedAt != null) 'printed_at': printedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReceiptsCompanion copyWith(
      {Value<int>? id,
      Value<int>? saleId,
      Value<String>? format,
      Value<String>? content,
      Value<bool>? isPrinted,
      Value<DateTime?>? printedAt,
      Value<DateTime>? createdAt}) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      format: format ?? this.format,
      content: content ?? this.content,
      isPrinted: isPrinted ?? this.isPrinted,
      printedAt: printedAt ?? this.printedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<int>(saleId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isPrinted.present) {
      map['is_printed'] = Variable<bool>(isPrinted.value);
    }
    if (printedAt.present) {
      map['printed_at'] = Variable<DateTime>(printedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('format: $format, ')
          ..write('content: $content, ')
          ..write('isPrinted: $isPrinted, ')
          ..write('printedAt: $printedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InventorySessionsTable extends InventorySessions
    with TableInfo<$InventorySessionsTable, InventorySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventorySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
      'ref', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _totalProductsMeta =
      const VerificationMeta('totalProducts');
  @override
  late final GeneratedColumn<int> totalProducts = GeneratedColumn<int>(
      'total_products', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discrepanciesMeta =
      const VerificationMeta('discrepancies');
  @override
  late final GeneratedColumn<int> discrepancies = GeneratedColumn<int>(
      'discrepancies', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ref,
        userId,
        status,
        notes,
        totalProducts,
        discrepancies,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<InventorySession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ref')) {
      context.handle(
          _refMeta, ref.isAcceptableOrUnknown(data['ref']!, _refMeta));
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('total_products')) {
      context.handle(
          _totalProductsMeta,
          totalProducts.isAcceptableOrUnknown(
              data['total_products']!, _totalProductsMeta));
    }
    if (data.containsKey('discrepancies')) {
      context.handle(
          _discrepanciesMeta,
          discrepancies.isAcceptableOrUnknown(
              data['discrepancies']!, _discrepanciesMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventorySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventorySession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ref: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      totalProducts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_products'])!,
      discrepancies: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}discrepancies'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $InventorySessionsTable createAlias(String alias) {
    return $InventorySessionsTable(attachedDatabase, alias);
  }
}

class InventorySession extends DataClass
    implements Insertable<InventorySession> {
  final int id;
  final String ref;
  final int userId;
  final String status;
  final String notes;
  final int totalProducts;
  final int discrepancies;
  final DateTime startedAt;
  final DateTime? completedAt;
  const InventorySession(
      {required this.id,
      required this.ref,
      required this.userId,
      required this.status,
      required this.notes,
      required this.totalProducts,
      required this.discrepancies,
      required this.startedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ref'] = Variable<String>(ref);
    map['user_id'] = Variable<int>(userId);
    map['status'] = Variable<String>(status);
    map['notes'] = Variable<String>(notes);
    map['total_products'] = Variable<int>(totalProducts);
    map['discrepancies'] = Variable<int>(discrepancies);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  InventorySessionsCompanion toCompanion(bool nullToAbsent) {
    return InventorySessionsCompanion(
      id: Value(id),
      ref: Value(ref),
      userId: Value(userId),
      status: Value(status),
      notes: Value(notes),
      totalProducts: Value(totalProducts),
      discrepancies: Value(discrepancies),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory InventorySession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventorySession(
      id: serializer.fromJson<int>(json['id']),
      ref: serializer.fromJson<String>(json['ref']),
      userId: serializer.fromJson<int>(json['userId']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String>(json['notes']),
      totalProducts: serializer.fromJson<int>(json['totalProducts']),
      discrepancies: serializer.fromJson<int>(json['discrepancies']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ref': serializer.toJson<String>(ref),
      'userId': serializer.toJson<int>(userId),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String>(notes),
      'totalProducts': serializer.toJson<int>(totalProducts),
      'discrepancies': serializer.toJson<int>(discrepancies),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  InventorySession copyWith(
          {int? id,
          String? ref,
          int? userId,
          String? status,
          String? notes,
          int? totalProducts,
          int? discrepancies,
          DateTime? startedAt,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      InventorySession(
        id: id ?? this.id,
        ref: ref ?? this.ref,
        userId: userId ?? this.userId,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        totalProducts: totalProducts ?? this.totalProducts,
        discrepancies: discrepancies ?? this.discrepancies,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  InventorySession copyWithCompanion(InventorySessionsCompanion data) {
    return InventorySession(
      id: data.id.present ? data.id.value : this.id,
      ref: data.ref.present ? data.ref.value : this.ref,
      userId: data.userId.present ? data.userId.value : this.userId,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      totalProducts: data.totalProducts.present
          ? data.totalProducts.value
          : this.totalProducts,
      discrepancies: data.discrepancies.present
          ? data.discrepancies.value
          : this.discrepancies,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventorySession(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('totalProducts: $totalProducts, ')
          ..write('discrepancies: $discrepancies, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ref, userId, status, notes, totalProducts,
      discrepancies, startedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventorySession &&
          other.id == this.id &&
          other.ref == this.ref &&
          other.userId == this.userId &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.totalProducts == this.totalProducts &&
          other.discrepancies == this.discrepancies &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class InventorySessionsCompanion extends UpdateCompanion<InventorySession> {
  final Value<int> id;
  final Value<String> ref;
  final Value<int> userId;
  final Value<String> status;
  final Value<String> notes;
  final Value<int> totalProducts;
  final Value<int> discrepancies;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  const InventorySessionsCompanion({
    this.id = const Value.absent(),
    this.ref = const Value.absent(),
    this.userId = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalProducts = const Value.absent(),
    this.discrepancies = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  InventorySessionsCompanion.insert({
    this.id = const Value.absent(),
    required String ref,
    required int userId,
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalProducts = const Value.absent(),
    this.discrepancies = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  })  : ref = Value(ref),
        userId = Value(userId);
  static Insertable<InventorySession> custom({
    Expression<int>? id,
    Expression<String>? ref,
    Expression<int>? userId,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<int>? totalProducts,
    Expression<int>? discrepancies,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ref != null) 'ref': ref,
      if (userId != null) 'user_id': userId,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (totalProducts != null) 'total_products': totalProducts,
      if (discrepancies != null) 'discrepancies': discrepancies,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  InventorySessionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? ref,
      Value<int>? userId,
      Value<String>? status,
      Value<String>? notes,
      Value<int>? totalProducts,
      Value<int>? discrepancies,
      Value<DateTime>? startedAt,
      Value<DateTime?>? completedAt}) {
    return InventorySessionsCompanion(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      totalProducts: totalProducts ?? this.totalProducts,
      discrepancies: discrepancies ?? this.discrepancies,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (totalProducts.present) {
      map['total_products'] = Variable<int>(totalProducts.value);
    }
    if (discrepancies.present) {
      map['discrepancies'] = Variable<int>(discrepancies.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventorySessionsCompanion(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('totalProducts: $totalProducts, ')
          ..write('discrepancies: $discrepancies, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryLinesTable extends InventoryLines
    with TableInfo<$InventoryLinesTable, InventoryLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES inventory_sessions (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expectedQtyMeta =
      const VerificationMeta('expectedQty');
  @override
  late final GeneratedColumn<int> expectedQty = GeneratedColumn<int>(
      'expected_qty', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _countedQtyMeta =
      const VerificationMeta('countedQty');
  @override
  late final GeneratedColumn<int> countedQty = GeneratedColumn<int>(
      'counted_qty', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _differenceMeta =
      const VerificationMeta('difference');
  @override
  late final GeneratedColumn<int> difference = GeneratedColumn<int>(
      'difference', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isValidatedMeta =
      const VerificationMeta('isValidated');
  @override
  late final GeneratedColumn<bool> isValidated = GeneratedColumn<bool>(
      'is_validated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_validated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        productId,
        productName,
        barcode,
        expectedQty,
        countedQty,
        difference,
        isValidated,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_lines';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryLine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('expected_qty')) {
      context.handle(
          _expectedQtyMeta,
          expectedQty.isAcceptableOrUnknown(
              data['expected_qty']!, _expectedQtyMeta));
    } else if (isInserting) {
      context.missing(_expectedQtyMeta);
    }
    if (data.containsKey('counted_qty')) {
      context.handle(
          _countedQtyMeta,
          countedQty.isAcceptableOrUnknown(
              data['counted_qty']!, _countedQtyMeta));
    }
    if (data.containsKey('difference')) {
      context.handle(
          _differenceMeta,
          difference.isAcceptableOrUnknown(
              data['difference']!, _differenceMeta));
    }
    if (data.containsKey('is_validated')) {
      context.handle(
          _isValidatedMeta,
          isValidated.isAcceptableOrUnknown(
              data['is_validated']!, _isValidatedMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryLine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      expectedQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expected_qty'])!,
      countedQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}counted_qty']),
      difference: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difference']),
      isValidated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_validated'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
    );
  }

  @override
  $InventoryLinesTable createAlias(String alias) {
    return $InventoryLinesTable(attachedDatabase, alias);
  }
}

class InventoryLine extends DataClass implements Insertable<InventoryLine> {
  final int id;
  final int sessionId;
  final int productId;
  final String productName;
  final String? barcode;
  final int expectedQty;
  final int? countedQty;
  final int? difference;
  final bool isValidated;
  final String notes;
  const InventoryLine(
      {required this.id,
      required this.sessionId,
      required this.productId,
      required this.productName,
      this.barcode,
      required this.expectedQty,
      this.countedQty,
      this.difference,
      required this.isValidated,
      required this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['expected_qty'] = Variable<int>(expectedQty);
    if (!nullToAbsent || countedQty != null) {
      map['counted_qty'] = Variable<int>(countedQty);
    }
    if (!nullToAbsent || difference != null) {
      map['difference'] = Variable<int>(difference);
    }
    map['is_validated'] = Variable<bool>(isValidated);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  InventoryLinesCompanion toCompanion(bool nullToAbsent) {
    return InventoryLinesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      productId: Value(productId),
      productName: Value(productName),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      expectedQty: Value(expectedQty),
      countedQty: countedQty == null && nullToAbsent
          ? const Value.absent()
          : Value(countedQty),
      difference: difference == null && nullToAbsent
          ? const Value.absent()
          : Value(difference),
      isValidated: Value(isValidated),
      notes: Value(notes),
    );
  }

  factory InventoryLine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryLine(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      expectedQty: serializer.fromJson<int>(json['expectedQty']),
      countedQty: serializer.fromJson<int?>(json['countedQty']),
      difference: serializer.fromJson<int?>(json['difference']),
      isValidated: serializer.fromJson<bool>(json['isValidated']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'barcode': serializer.toJson<String?>(barcode),
      'expectedQty': serializer.toJson<int>(expectedQty),
      'countedQty': serializer.toJson<int?>(countedQty),
      'difference': serializer.toJson<int?>(difference),
      'isValidated': serializer.toJson<bool>(isValidated),
      'notes': serializer.toJson<String>(notes),
    };
  }

  InventoryLine copyWith(
          {int? id,
          int? sessionId,
          int? productId,
          String? productName,
          Value<String?> barcode = const Value.absent(),
          int? expectedQty,
          Value<int?> countedQty = const Value.absent(),
          Value<int?> difference = const Value.absent(),
          bool? isValidated,
          String? notes}) =>
      InventoryLine(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        barcode: barcode.present ? barcode.value : this.barcode,
        expectedQty: expectedQty ?? this.expectedQty,
        countedQty: countedQty.present ? countedQty.value : this.countedQty,
        difference: difference.present ? difference.value : this.difference,
        isValidated: isValidated ?? this.isValidated,
        notes: notes ?? this.notes,
      );
  InventoryLine copyWithCompanion(InventoryLinesCompanion data) {
    return InventoryLine(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      expectedQty:
          data.expectedQty.present ? data.expectedQty.value : this.expectedQty,
      countedQty:
          data.countedQty.present ? data.countedQty.value : this.countedQty,
      difference:
          data.difference.present ? data.difference.value : this.difference,
      isValidated:
          data.isValidated.present ? data.isValidated.value : this.isValidated,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLine(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('barcode: $barcode, ')
          ..write('expectedQty: $expectedQty, ')
          ..write('countedQty: $countedQty, ')
          ..write('difference: $difference, ')
          ..write('isValidated: $isValidated, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, productId, productName,
      barcode, expectedQty, countedQty, difference, isValidated, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryLine &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.barcode == this.barcode &&
          other.expectedQty == this.expectedQty &&
          other.countedQty == this.countedQty &&
          other.difference == this.difference &&
          other.isValidated == this.isValidated &&
          other.notes == this.notes);
}

class InventoryLinesCompanion extends UpdateCompanion<InventoryLine> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> productId;
  final Value<String> productName;
  final Value<String?> barcode;
  final Value<int> expectedQty;
  final Value<int?> countedQty;
  final Value<int?> difference;
  final Value<bool> isValidated;
  final Value<String> notes;
  const InventoryLinesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.barcode = const Value.absent(),
    this.expectedQty = const Value.absent(),
    this.countedQty = const Value.absent(),
    this.difference = const Value.absent(),
    this.isValidated = const Value.absent(),
    this.notes = const Value.absent(),
  });
  InventoryLinesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int productId,
    required String productName,
    this.barcode = const Value.absent(),
    required int expectedQty,
    this.countedQty = const Value.absent(),
    this.difference = const Value.absent(),
    this.isValidated = const Value.absent(),
    this.notes = const Value.absent(),
  })  : sessionId = Value(sessionId),
        productId = Value(productId),
        productName = Value(productName),
        expectedQty = Value(expectedQty);
  static Insertable<InventoryLine> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<String>? barcode,
    Expression<int>? expectedQty,
    Expression<int>? countedQty,
    Expression<int>? difference,
    Expression<bool>? isValidated,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (barcode != null) 'barcode': barcode,
      if (expectedQty != null) 'expected_qty': expectedQty,
      if (countedQty != null) 'counted_qty': countedQty,
      if (difference != null) 'difference': difference,
      if (isValidated != null) 'is_validated': isValidated,
      if (notes != null) 'notes': notes,
    });
  }

  InventoryLinesCompanion copyWith(
      {Value<int>? id,
      Value<int>? sessionId,
      Value<int>? productId,
      Value<String>? productName,
      Value<String?>? barcode,
      Value<int>? expectedQty,
      Value<int?>? countedQty,
      Value<int?>? difference,
      Value<bool>? isValidated,
      Value<String>? notes}) {
    return InventoryLinesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      expectedQty: expectedQty ?? this.expectedQty,
      countedQty: countedQty ?? this.countedQty,
      difference: difference ?? this.difference,
      isValidated: isValidated ?? this.isValidated,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (expectedQty.present) {
      map['expected_qty'] = Variable<int>(expectedQty.value);
    }
    if (countedQty.present) {
      map['counted_qty'] = Variable<int>(countedQty.value);
    }
    if (difference.present) {
      map['difference'] = Variable<int>(difference.value);
    }
    if (isValidated.present) {
      map['is_validated'] = Variable<bool>(isValidated.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLinesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('barcode: $barcode, ')
          ..write('expectedQty: $expectedQty, ')
          ..write('countedQty: $countedQty, ')
          ..write('difference: $difference, ')
          ..write('isValidated: $isValidated, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('upsert'));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        action,
        payload,
        status,
        retryCount,
        errorMessage,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String entityType;
  final int entityId;
  final String action;
  final String payload;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.action,
      required this.payload,
      required this.status,
      required this.retryCount,
      this.errorMessage,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<int>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      status: Value(status),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? entityType,
          int? entityId,
          String? action,
          String? payload,
          String? status,
          int? retryCount,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SyncQueueData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, action, payload,
      status, retryCount, errorMessage, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<int> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required int entityId,
    this.action = const Value.absent(),
    required String payload,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        payload = Value(payload);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<int>? entityId,
      Value<String>? action,
      Value<String>? payload,
      Value<String>? status,
      Value<int>? retryCount,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ShopsTable extends Shops with TableInfo<$ShopsTable, Shop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCurrentMeta =
      const VerificationMeta('isCurrent');
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
      'is_current', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_current" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, name, address, isCurrent];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shops';
  @override
  VerificationContext validateIntegrity(Insertable<Shop> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('is_current')) {
      context.handle(_isCurrentMeta,
          isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shop(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      isCurrent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_current'])!,
    );
  }

  @override
  $ShopsTable createAlias(String alias) {
    return $ShopsTable(attachedDatabase, alias);
  }
}

class Shop extends DataClass implements Insertable<Shop> {
  final String id;
  final String name;
  final String? address;
  final bool isCurrent;
  const Shop(
      {required this.id,
      required this.name,
      this.address,
      required this.isCurrent});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['is_current'] = Variable<bool>(isCurrent);
    return map;
  }

  ShopsCompanion toCompanion(bool nullToAbsent) {
    return ShopsCompanion(
      id: Value(id),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      isCurrent: Value(isCurrent),
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shop(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'isCurrent': serializer.toJson<bool>(isCurrent),
    };
  }

  Shop copyWith(
          {String? id,
          String? name,
          Value<String?> address = const Value.absent(),
          bool? isCurrent}) =>
      Shop(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address.present ? address.value : this.address,
        isCurrent: isCurrent ?? this.isCurrent,
      );
  Shop copyWithCompanion(ShopsCompanion data) {
    return Shop(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shop(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, address, isCurrent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shop &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.isCurrent == this.isCurrent);
}

class ShopsCompanion extends UpdateCompanion<Shop> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> address;
  final Value<bool> isCurrent;
  final Value<int> rowid;
  const ShopsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShopsCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Shop> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<bool>? isCurrent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (isCurrent != null) 'is_current': isCurrent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShopsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? address,
      Value<bool>? isCurrent,
      Value<int>? rowid}) {
    return ShopsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isCurrent: isCurrent ?? this.isCurrent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockTransfersTable extends StockTransfers
    with TableInfo<$StockTransfersTable, StockTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
      'ref', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceShopIdMeta =
      const VerificationMeta('sourceShopId');
  @override
  late final GeneratedColumn<String> sourceShopId = GeneratedColumn<String>(
      'source_shop_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetShopIdMeta =
      const VerificationMeta('targetShopId');
  @override
  late final GeneratedColumn<String> targetShopId = GeneratedColumn<String>(
      'target_shop_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ref,
        sourceShopId,
        targetShopId,
        status,
        notes,
        createdAt,
        receivedAt,
        remoteId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_transfers';
  @override
  VerificationContext validateIntegrity(Insertable<StockTransfer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ref')) {
      context.handle(
          _refMeta, ref.isAcceptableOrUnknown(data['ref']!, _refMeta));
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('source_shop_id')) {
      context.handle(
          _sourceShopIdMeta,
          sourceShopId.isAcceptableOrUnknown(
              data['source_shop_id']!, _sourceShopIdMeta));
    } else if (isInserting) {
      context.missing(_sourceShopIdMeta);
    }
    if (data.containsKey('target_shop_id')) {
      context.handle(
          _targetShopIdMeta,
          targetShopId.isAcceptableOrUnknown(
              data['target_shop_id']!, _targetShopIdMeta));
    } else if (isInserting) {
      context.missing(_targetShopIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockTransfer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ref: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ref'])!,
      sourceShopId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_shop_id'])!,
      targetShopId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_shop_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at']),
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
    );
  }

  @override
  $StockTransfersTable createAlias(String alias) {
    return $StockTransfersTable(attachedDatabase, alias);
  }
}

class StockTransfer extends DataClass implements Insertable<StockTransfer> {
  final int id;
  final String ref;
  final String sourceShopId;
  final String targetShopId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final String? remoteId;
  const StockTransfer(
      {required this.id,
      required this.ref,
      required this.sourceShopId,
      required this.targetShopId,
      required this.status,
      this.notes,
      required this.createdAt,
      this.receivedAt,
      this.remoteId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ref'] = Variable<String>(ref);
    map['source_shop_id'] = Variable<String>(sourceShopId);
    map['target_shop_id'] = Variable<String>(targetShopId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  StockTransfersCompanion toCompanion(bool nullToAbsent) {
    return StockTransfersCompanion(
      id: Value(id),
      ref: Value(ref),
      sourceShopId: Value(sourceShopId),
      targetShopId: Value(targetShopId),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory StockTransfer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockTransfer(
      id: serializer.fromJson<int>(json['id']),
      ref: serializer.fromJson<String>(json['ref']),
      sourceShopId: serializer.fromJson<String>(json['sourceShopId']),
      targetShopId: serializer.fromJson<String>(json['targetShopId']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ref': serializer.toJson<String>(ref),
      'sourceShopId': serializer.toJson<String>(sourceShopId),
      'targetShopId': serializer.toJson<String>(targetShopId),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  StockTransfer copyWith(
          {int? id,
          String? ref,
          String? sourceShopId,
          String? targetShopId,
          String? status,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> receivedAt = const Value.absent(),
          Value<String?> remoteId = const Value.absent()}) =>
      StockTransfer(
        id: id ?? this.id,
        ref: ref ?? this.ref,
        sourceShopId: sourceShopId ?? this.sourceShopId,
        targetShopId: targetShopId ?? this.targetShopId,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
      );
  StockTransfer copyWithCompanion(StockTransfersCompanion data) {
    return StockTransfer(
      id: data.id.present ? data.id.value : this.id,
      ref: data.ref.present ? data.ref.value : this.ref,
      sourceShopId: data.sourceShopId.present
          ? data.sourceShopId.value
          : this.sourceShopId,
      targetShopId: data.targetShopId.present
          ? data.targetShopId.value
          : this.targetShopId,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockTransfer(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('sourceShopId: $sourceShopId, ')
          ..write('targetShopId: $targetShopId, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ref, sourceShopId, targetShopId, status,
      notes, createdAt, receivedAt, remoteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockTransfer &&
          other.id == this.id &&
          other.ref == this.ref &&
          other.sourceShopId == this.sourceShopId &&
          other.targetShopId == this.targetShopId &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.receivedAt == this.receivedAt &&
          other.remoteId == this.remoteId);
}

class StockTransfersCompanion extends UpdateCompanion<StockTransfer> {
  final Value<int> id;
  final Value<String> ref;
  final Value<String> sourceShopId;
  final Value<String> targetShopId;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> receivedAt;
  final Value<String?> remoteId;
  const StockTransfersCompanion({
    this.id = const Value.absent(),
    this.ref = const Value.absent(),
    this.sourceShopId = const Value.absent(),
    this.targetShopId = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
  });
  StockTransfersCompanion.insert({
    this.id = const Value.absent(),
    required String ref,
    required String sourceShopId,
    required String targetShopId,
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
  })  : ref = Value(ref),
        sourceShopId = Value(sourceShopId),
        targetShopId = Value(targetShopId);
  static Insertable<StockTransfer> custom({
    Expression<int>? id,
    Expression<String>? ref,
    Expression<String>? sourceShopId,
    Expression<String>? targetShopId,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? receivedAt,
    Expression<String>? remoteId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ref != null) 'ref': ref,
      if (sourceShopId != null) 'source_shop_id': sourceShopId,
      if (targetShopId != null) 'target_shop_id': targetShopId,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (remoteId != null) 'remote_id': remoteId,
    });
  }

  StockTransfersCompanion copyWith(
      {Value<int>? id,
      Value<String>? ref,
      Value<String>? sourceShopId,
      Value<String>? targetShopId,
      Value<String>? status,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime?>? receivedAt,
      Value<String?>? remoteId}) {
    return StockTransfersCompanion(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      sourceShopId: sourceShopId ?? this.sourceShopId,
      targetShopId: targetShopId ?? this.targetShopId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (sourceShopId.present) {
      map['source_shop_id'] = Variable<String>(sourceShopId.value);
    }
    if (targetShopId.present) {
      map['target_shop_id'] = Variable<String>(targetShopId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockTransfersCompanion(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('sourceShopId: $sourceShopId, ')
          ..write('targetShopId: $targetShopId, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }
}

class $StockTransferItemsTable extends StockTransferItems
    with TableInfo<$StockTransferItemsTable, StockTransferItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockTransferItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _transferIdMeta =
      const VerificationMeta('transferId');
  @override
  late final GeneratedColumn<int> transferId = GeneratedColumn<int>(
      'transfer_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES stock_transfers (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _quantitySentMeta =
      const VerificationMeta('quantitySent');
  @override
  late final GeneratedColumn<int> quantitySent = GeneratedColumn<int>(
      'quantity_sent', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quantityReceivedMeta =
      const VerificationMeta('quantityReceived');
  @override
  late final GeneratedColumn<int> quantityReceived = GeneratedColumn<int>(
      'quantity_received', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, transferId, productId, quantitySent, quantityReceived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_transfer_items';
  @override
  VerificationContext validateIntegrity(Insertable<StockTransferItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
          _transferIdMeta,
          transferId.isAcceptableOrUnknown(
              data['transfer_id']!, _transferIdMeta));
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_sent')) {
      context.handle(
          _quantitySentMeta,
          quantitySent.isAcceptableOrUnknown(
              data['quantity_sent']!, _quantitySentMeta));
    } else if (isInserting) {
      context.missing(_quantitySentMeta);
    }
    if (data.containsKey('quantity_received')) {
      context.handle(
          _quantityReceivedMeta,
          quantityReceived.isAcceptableOrUnknown(
              data['quantity_received']!, _quantityReceivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockTransferItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockTransferItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transferId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transfer_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      quantitySent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity_sent'])!,
      quantityReceived: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity_received']),
    );
  }

  @override
  $StockTransferItemsTable createAlias(String alias) {
    return $StockTransferItemsTable(attachedDatabase, alias);
  }
}

class StockTransferItem extends DataClass
    implements Insertable<StockTransferItem> {
  final int id;
  final int transferId;
  final int productId;
  final int quantitySent;
  final int? quantityReceived;
  const StockTransferItem(
      {required this.id,
      required this.transferId,
      required this.productId,
      required this.quantitySent,
      this.quantityReceived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transfer_id'] = Variable<int>(transferId);
    map['product_id'] = Variable<int>(productId);
    map['quantity_sent'] = Variable<int>(quantitySent);
    if (!nullToAbsent || quantityReceived != null) {
      map['quantity_received'] = Variable<int>(quantityReceived);
    }
    return map;
  }

  StockTransferItemsCompanion toCompanion(bool nullToAbsent) {
    return StockTransferItemsCompanion(
      id: Value(id),
      transferId: Value(transferId),
      productId: Value(productId),
      quantitySent: Value(quantitySent),
      quantityReceived: quantityReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityReceived),
    );
  }

  factory StockTransferItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockTransferItem(
      id: serializer.fromJson<int>(json['id']),
      transferId: serializer.fromJson<int>(json['transferId']),
      productId: serializer.fromJson<int>(json['productId']),
      quantitySent: serializer.fromJson<int>(json['quantitySent']),
      quantityReceived: serializer.fromJson<int?>(json['quantityReceived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transferId': serializer.toJson<int>(transferId),
      'productId': serializer.toJson<int>(productId),
      'quantitySent': serializer.toJson<int>(quantitySent),
      'quantityReceived': serializer.toJson<int?>(quantityReceived),
    };
  }

  StockTransferItem copyWith(
          {int? id,
          int? transferId,
          int? productId,
          int? quantitySent,
          Value<int?> quantityReceived = const Value.absent()}) =>
      StockTransferItem(
        id: id ?? this.id,
        transferId: transferId ?? this.transferId,
        productId: productId ?? this.productId,
        quantitySent: quantitySent ?? this.quantitySent,
        quantityReceived: quantityReceived.present
            ? quantityReceived.value
            : this.quantityReceived,
      );
  StockTransferItem copyWithCompanion(StockTransferItemsCompanion data) {
    return StockTransferItem(
      id: data.id.present ? data.id.value : this.id,
      transferId:
          data.transferId.present ? data.transferId.value : this.transferId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantitySent: data.quantitySent.present
          ? data.quantitySent.value
          : this.quantitySent,
      quantityReceived: data.quantityReceived.present
          ? data.quantityReceived.value
          : this.quantityReceived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockTransferItem(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('quantitySent: $quantitySent, ')
          ..write('quantityReceived: $quantityReceived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transferId, productId, quantitySent, quantityReceived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockTransferItem &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.productId == this.productId &&
          other.quantitySent == this.quantitySent &&
          other.quantityReceived == this.quantityReceived);
}

class StockTransferItemsCompanion extends UpdateCompanion<StockTransferItem> {
  final Value<int> id;
  final Value<int> transferId;
  final Value<int> productId;
  final Value<int> quantitySent;
  final Value<int?> quantityReceived;
  const StockTransferItemsCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantitySent = const Value.absent(),
    this.quantityReceived = const Value.absent(),
  });
  StockTransferItemsCompanion.insert({
    this.id = const Value.absent(),
    required int transferId,
    required int productId,
    required int quantitySent,
    this.quantityReceived = const Value.absent(),
  })  : transferId = Value(transferId),
        productId = Value(productId),
        quantitySent = Value(quantitySent);
  static Insertable<StockTransferItem> custom({
    Expression<int>? id,
    Expression<int>? transferId,
    Expression<int>? productId,
    Expression<int>? quantitySent,
    Expression<int>? quantityReceived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (productId != null) 'product_id': productId,
      if (quantitySent != null) 'quantity_sent': quantitySent,
      if (quantityReceived != null) 'quantity_received': quantityReceived,
    });
  }

  StockTransferItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? transferId,
      Value<int>? productId,
      Value<int>? quantitySent,
      Value<int?>? quantityReceived}) {
    return StockTransferItemsCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      productId: productId ?? this.productId,
      quantitySent: quantitySent ?? this.quantitySent,
      quantityReceived: quantityReceived ?? this.quantityReceived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<int>(transferId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (quantitySent.present) {
      map['quantity_sent'] = Variable<int>(quantitySent.value);
    }
    if (quantityReceived.present) {
      map['quantity_received'] = Variable<int>(quantityReceived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockTransferItemsCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('quantitySent: $quantitySent, ')
          ..write('quantityReceived: $quantityReceived')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _actorIdMeta =
      const VerificationMeta('actorId');
  @override
  late final GeneratedColumn<int> actorId = GeneratedColumn<int>(
      'actor_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetEntityTypeMeta =
      const VerificationMeta('targetEntityType');
  @override
  late final GeneratedColumn<String> targetEntityType = GeneratedColumn<String>(
      'target_entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetEntityIdMeta =
      const VerificationMeta('targetEntityId');
  @override
  late final GeneratedColumn<int> targetEntityId = GeneratedColumn<int>(
      'target_entity_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _detailsMeta =
      const VerificationMeta('details');
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
      'details', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        actorId,
        action,
        targetEntityType,
        targetEntityId,
        details,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('actor_id')) {
      context.handle(_actorIdMeta,
          actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta));
    } else if (isInserting) {
      context.missing(_actorIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('target_entity_type')) {
      context.handle(
          _targetEntityTypeMeta,
          targetEntityType.isAcceptableOrUnknown(
              data['target_entity_type']!, _targetEntityTypeMeta));
    } else if (isInserting) {
      context.missing(_targetEntityTypeMeta);
    }
    if (data.containsKey('target_entity_id')) {
      context.handle(
          _targetEntityIdMeta,
          targetEntityId.isAcceptableOrUnknown(
              data['target_entity_id']!, _targetEntityIdMeta));
    } else if (isInserting) {
      context.missing(_targetEntityIdMeta);
    }
    if (data.containsKey('details')) {
      context.handle(_detailsMeta,
          details.isAcceptableOrUnknown(data['details']!, _detailsMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      actorId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}actor_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      targetEntityType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_entity_type'])!,
      targetEntityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_entity_id'])!,
      details: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final int id;
  final int actorId;
  final String action;
  final String targetEntityType;
  final int targetEntityId;
  final String? details;
  final DateTime timestamp;
  const AuditLog(
      {required this.id,
      required this.actorId,
      required this.action,
      required this.targetEntityType,
      required this.targetEntityId,
      this.details,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['actor_id'] = Variable<int>(actorId);
    map['action'] = Variable<String>(action);
    map['target_entity_type'] = Variable<String>(targetEntityType);
    map['target_entity_id'] = Variable<int>(targetEntityId);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      actorId: Value(actorId),
      action: Value(action),
      targetEntityType: Value(targetEntityType),
      targetEntityId: Value(targetEntityId),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      timestamp: Value(timestamp),
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<int>(json['id']),
      actorId: serializer.fromJson<int>(json['actorId']),
      action: serializer.fromJson<String>(json['action']),
      targetEntityType: serializer.fromJson<String>(json['targetEntityType']),
      targetEntityId: serializer.fromJson<int>(json['targetEntityId']),
      details: serializer.fromJson<String?>(json['details']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actorId': serializer.toJson<int>(actorId),
      'action': serializer.toJson<String>(action),
      'targetEntityType': serializer.toJson<String>(targetEntityType),
      'targetEntityId': serializer.toJson<int>(targetEntityId),
      'details': serializer.toJson<String?>(details),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AuditLog copyWith(
          {int? id,
          int? actorId,
          String? action,
          String? targetEntityType,
          int? targetEntityId,
          Value<String?> details = const Value.absent(),
          DateTime? timestamp}) =>
      AuditLog(
        id: id ?? this.id,
        actorId: actorId ?? this.actorId,
        action: action ?? this.action,
        targetEntityType: targetEntityType ?? this.targetEntityType,
        targetEntityId: targetEntityId ?? this.targetEntityId,
        details: details.present ? details.value : this.details,
        timestamp: timestamp ?? this.timestamp,
      );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      action: data.action.present ? data.action.value : this.action,
      targetEntityType: data.targetEntityType.present
          ? data.targetEntityType.value
          : this.targetEntityType,
      targetEntityId: data.targetEntityId.present
          ? data.targetEntityId.value
          : this.targetEntityId,
      details: data.details.present ? data.details.value : this.details,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('actorId: $actorId, ')
          ..write('action: $action, ')
          ..write('targetEntityType: $targetEntityType, ')
          ..write('targetEntityId: $targetEntityId, ')
          ..write('details: $details, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, actorId, action, targetEntityType,
      targetEntityId, details, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.actorId == this.actorId &&
          other.action == this.action &&
          other.targetEntityType == this.targetEntityType &&
          other.targetEntityId == this.targetEntityId &&
          other.details == this.details &&
          other.timestamp == this.timestamp);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<int> id;
  final Value<int> actorId;
  final Value<String> action;
  final Value<String> targetEntityType;
  final Value<int> targetEntityId;
  final Value<String?> details;
  final Value<DateTime> timestamp;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.actorId = const Value.absent(),
    this.action = const Value.absent(),
    this.targetEntityType = const Value.absent(),
    this.targetEntityId = const Value.absent(),
    this.details = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    this.id = const Value.absent(),
    required int actorId,
    required String action,
    required String targetEntityType,
    required int targetEntityId,
    this.details = const Value.absent(),
    this.timestamp = const Value.absent(),
  })  : actorId = Value(actorId),
        action = Value(action),
        targetEntityType = Value(targetEntityType),
        targetEntityId = Value(targetEntityId);
  static Insertable<AuditLog> custom({
    Expression<int>? id,
    Expression<int>? actorId,
    Expression<String>? action,
    Expression<String>? targetEntityType,
    Expression<int>? targetEntityId,
    Expression<String>? details,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorId != null) 'actor_id': actorId,
      if (action != null) 'action': action,
      if (targetEntityType != null) 'target_entity_type': targetEntityType,
      if (targetEntityId != null) 'target_entity_id': targetEntityId,
      if (details != null) 'details': details,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  AuditLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? actorId,
      Value<String>? action,
      Value<String>? targetEntityType,
      Value<int>? targetEntityId,
      Value<String?>? details,
      Value<DateTime>? timestamp}) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      action: action ?? this.action,
      targetEntityType: targetEntityType ?? this.targetEntityType,
      targetEntityId: targetEntityId ?? this.targetEntityId,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<int>(actorId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (targetEntityType.present) {
      map['target_entity_type'] = Variable<String>(targetEntityType.value);
    }
    if (targetEntityId.present) {
      map['target_entity_id'] = Variable<int>(targetEntityId.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('actorId: $actorId, ')
          ..write('action: $action, ')
          ..write('targetEntityType: $targetEntityType, ')
          ..write('targetEntityId: $targetEntityId, ')
          ..write('details: $details, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$PosDatabase extends GeneratedDatabase {
  _$PosDatabase(QueryExecutor e) : super(e);
  $PosDatabaseManager get managers => $PosDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $CashSessionsTable cashSessions = $CashSessionsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $InventorySessionsTable inventorySessions =
      $InventorySessionsTable(this);
  late final $InventoryLinesTable inventoryLines = $InventoryLinesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $ShopsTable shops = $ShopsTable(this);
  late final $StockTransfersTable stockTransfers = $StockTransfersTable(this);
  late final $StockTransferItemsTable stockTransferItems =
      $StockTransferItemsTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final SalesDao salesDao = SalesDao(this as PosDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        categories,
        products,
        customers,
        cashSessions,
        sales,
        saleItems,
        payments,
        stockMovements,
        receipts,
        inventorySessions,
        inventoryLines,
        appSettings,
        syncQueue,
        shops,
        stockTransfers,
        stockTransferItems,
        auditLogs
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String name,
  required String pinHash,
  Value<String> pinSalt,
  Value<String> role,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<String?> email,
  Value<String?> supabaseId,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> pinHash,
  Value<String> pinSalt,
  Value<String> role,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<String?> email,
  Value<String?> supabaseId,
});

final class $$UsersTableReferences
    extends BaseReferences<_$PosDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CashSessionsTable, List<CashSession>>
      _cashSessionsRefsTable(_$PosDatabase db) => MultiTypedResultKey.fromTable(
          db.cashSessions,
          aliasName: $_aliasNameGenerator(db.users.id, db.cashSessions.userId));

  $$CashSessionsTableProcessedTableManager get cashSessionsRefs {
    final manager = $$CashSessionsTableTableManager($_db, $_db.cashSessions)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$PosDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName: $_aliasNameGenerator(db.users.id, db.sales.userId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName:
                  $_aliasNameGenerator(db.users.id, db.stockMovements.userId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InventorySessionsTable, List<InventorySession>>
      _inventorySessionsRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.inventorySessions,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.inventorySessions.userId));

  $$InventorySessionsTableProcessedTableManager get inventorySessionsRefs {
    final manager =
        $$InventorySessionsTableTableManager($_db, $_db.inventorySessions)
            .filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_inventorySessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AuditLogsTable, List<AuditLog>>
      _auditLogsRefsTable(_$PosDatabase db) => MultiTypedResultKey.fromTable(
          db.auditLogs,
          aliasName: $_aliasNameGenerator(db.users.id, db.auditLogs.actorId));

  $$AuditLogsTableProcessedTableManager get auditLogsRefs {
    final manager = $$AuditLogsTableTableManager($_db, $_db.auditLogs)
        .filter((f) => f.actorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_auditLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersTableFilterComposer extends Composer<_$PosDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinSalt => $composableBuilder(
      column: $table.pinSalt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnFilters(column));

  Expression<bool> cashSessionsRefs(
      Expression<bool> Function($$CashSessionsTableFilterComposer f) f) {
    final $$CashSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashSessions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashSessionsTableFilterComposer(
              $db: $db,
              $table: $db.cashSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> inventorySessionsRefs(
      Expression<bool> Function($$InventorySessionsTableFilterComposer f) f) {
    final $$InventorySessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventorySessions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventorySessionsTableFilterComposer(
              $db: $db,
              $table: $db.inventorySessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> auditLogsRefs(
      Expression<bool> Function($$AuditLogsTableFilterComposer f) f) {
    final $$AuditLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLogs,
        getReferencedColumn: (t) => t.actorId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogsTableFilterComposer(
              $db: $db,
              $table: $db.auditLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$PosDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinSalt => $composableBuilder(
      column: $table.pinSalt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$PosDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get pinSalt =>
      $composableBuilder(column: $table.pinSalt, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get supabaseId => $composableBuilder(
      column: $table.supabaseId, builder: (column) => column);

  Expression<T> cashSessionsRefs<T extends Object>(
      Expression<T> Function($$CashSessionsTableAnnotationComposer a) f) {
    final $$CashSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashSessions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.cashSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> inventorySessionsRefs<T extends Object>(
      Expression<T> Function($$InventorySessionsTableAnnotationComposer a) f) {
    final $$InventorySessionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.inventorySessions,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InventorySessionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.inventorySessions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> auditLogsRefs<T extends Object>(
      Expression<T> Function($$AuditLogsTableAnnotationComposer a) f) {
    final $$AuditLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLogs,
        getReferencedColumn: (t) => t.actorId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.auditLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$PosDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool cashSessionsRefs,
        bool salesRefs,
        bool stockMovementsRefs,
        bool inventorySessionsRefs,
        bool auditLogsRefs})> {
  $$UsersTableTableManager(_$PosDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> pinHash = const Value.absent(),
            Value<String> pinSalt = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            pinHash: pinHash,
            pinSalt: pinSalt,
            role: role,
            isActive: isActive,
            createdAt: createdAt,
            email: email,
            supabaseId: supabaseId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String pinHash,
            Value<String> pinSalt = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> supabaseId = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            pinHash: pinHash,
            pinSalt: pinSalt,
            role: role,
            isActive: isActive,
            createdAt: createdAt,
            email: email,
            supabaseId: supabaseId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {cashSessionsRefs = false,
              salesRefs = false,
              stockMovementsRefs = false,
              inventorySessionsRefs = false,
              auditLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cashSessionsRefs) db.cashSessions,
                if (salesRefs) db.sales,
                if (stockMovementsRefs) db.stockMovements,
                if (inventorySessionsRefs) db.inventorySessions,
                if (auditLogsRefs) db.auditLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cashSessionsRefs)
                    await $_getPrefetchedData<User, $UsersTable, CashSession>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._cashSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .cashSessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (salesRefs)
                    await $_getPrefetchedData<User, $UsersTable, Sale>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).salesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<User, $UsersTable, StockMovement>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (inventorySessionsRefs)
                    await $_getPrefetchedData<User, $UsersTable,
                            InventorySession>(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._inventorySessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .inventorySessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (auditLogsRefs)
                    await $_getPrefetchedData<User, $UsersTable, AuditLog>(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._auditLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).auditLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.actorId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool cashSessionsRefs,
        bool salesRefs,
        bool stockMovementsRefs,
        bool inventorySessionsRefs,
        bool auditLogsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> color,
  Value<int> sortOrder,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> color,
  Value<int> sortOrder,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$PosDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<Product>> _productsRefsTable(
          _$PosDatabase db) =>
      MultiTypedResultKey.fromTable(db.products,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.products.categoryId));

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$PosDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> productsRefs(
      Expression<bool> Function($$ProductsTableFilterComposer f) f) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$PosDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$PosDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
      Expression<T> Function($$ProductsTableAnnotationComposer a) f) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$PosDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool productsRefs})> {
  $$CategoriesTableTableManager(_$PosDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            color: color,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Product>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._productsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .productsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool productsRefs})>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String?> barcode,
  required String name,
  Value<String> description,
  Value<int?> categoryId,
  required double priceHt,
  Value<double> taxRate,
  Value<double> costPrice,
  Value<int> stockQty,
  Value<int> stockAlert,
  Value<String> unit,
  Value<String?> imagePath,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String?> barcode,
  Value<String> name,
  Value<String> description,
  Value<int?> categoryId,
  Value<double> priceHt,
  Value<double> taxRate,
  Value<double> costPrice,
  Value<int> stockQty,
  Value<int> stockAlert,
  Value<String> unit,
  Value<String?> imagePath,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$PosDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$PosDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.products.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
      _saleItemsRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.saleItems,
              aliasName:
                  $_aliasNameGenerator(db.products.id, db.saleItems.productId));

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager($_db, $_db.saleItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.stockMovements.productId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InventoryLinesTable, List<InventoryLine>>
      _inventoryLinesRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.inventoryLines,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.inventoryLines.productId));

  $$InventoryLinesTableProcessedTableManager get inventoryLinesRefs {
    final manager = $$InventoryLinesTableTableManager($_db, $_db.inventoryLines)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockTransferItemsTable, List<StockTransferItem>>
      _stockTransferItemsRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockTransferItems,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.stockTransferItems.productId));

  $$StockTransferItemsTableProcessedTableManager get stockTransferItemsRefs {
    final manager =
        $$StockTransferItemsTableTableManager($_db, $_db.stockTransferItems)
            .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_stockTransferItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$PosDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceHt => $composableBuilder(
      column: $table.priceHt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stockQty => $composableBuilder(
      column: $table.stockQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stockAlert => $composableBuilder(
      column: $table.stockAlert, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> saleItemsRefs(
      Expression<bool> Function($$SaleItemsTableFilterComposer f) f) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableFilterComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> inventoryLinesRefs(
      Expression<bool> Function($$InventoryLinesTableFilterComposer f) f) {
    final $$InventoryLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryLines,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryLinesTableFilterComposer(
              $db: $db,
              $table: $db.inventoryLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockTransferItemsRefs(
      Expression<bool> Function($$StockTransferItemsTableFilterComposer f) f) {
    final $$StockTransferItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockTransferItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockTransferItemsTableFilterComposer(
              $db: $db,
              $table: $db.stockTransferItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$PosDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceHt => $composableBuilder(
      column: $table.priceHt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stockQty => $composableBuilder(
      column: $table.stockQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stockAlert => $composableBuilder(
      column: $table.stockAlert, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$PosDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get priceHt =>
      $composableBuilder(column: $table.priceHt, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<int> get stockQty =>
      $composableBuilder(column: $table.stockQty, builder: (column) => column);

  GeneratedColumn<int> get stockAlert => $composableBuilder(
      column: $table.stockAlert, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> saleItemsRefs<T extends Object>(
      Expression<T> Function($$SaleItemsTableAnnotationComposer a) f) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> inventoryLinesRefs<T extends Object>(
      Expression<T> Function($$InventoryLinesTableAnnotationComposer a) f) {
    final $$InventoryLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryLines,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.inventoryLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockTransferItemsRefs<T extends Object>(
      Expression<T> Function($$StockTransferItemsTableAnnotationComposer a) f) {
    final $$StockTransferItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.stockTransferItems,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$StockTransferItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.stockTransferItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function(
        {bool categoryId,
        bool saleItemsRefs,
        bool stockMovementsRefs,
        bool inventoryLinesRefs,
        bool stockTransferItemsRefs})> {
  $$ProductsTableTableManager(_$PosDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<double> priceHt = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<int> stockQty = const Value.absent(),
            Value<int> stockAlert = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            barcode: barcode,
            name: name,
            description: description,
            categoryId: categoryId,
            priceHt: priceHt,
            taxRate: taxRate,
            costPrice: costPrice,
            stockQty: stockQty,
            stockAlert: stockAlert,
            unit: unit,
            imagePath: imagePath,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            required double priceHt,
            Value<double> taxRate = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<int> stockQty = const Value.absent(),
            Value<int> stockAlert = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            barcode: barcode,
            name: name,
            description: description,
            categoryId: categoryId,
            priceHt: priceHt,
            taxRate: taxRate,
            costPrice: costPrice,
            stockQty: stockQty,
            stockAlert: stockAlert,
            unit: unit,
            imagePath: imagePath,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              saleItemsRefs = false,
              stockMovementsRefs = false,
              inventoryLinesRefs = false,
              stockTransferItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (saleItemsRefs) db.saleItems,
                if (stockMovementsRefs) db.stockMovements,
                if (inventoryLinesRefs) db.inventoryLines,
                if (stockTransferItemsRefs) db.stockTransferItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ProductsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ProductsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (saleItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            SaleItem>(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._saleItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .saleItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            StockMovement>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (inventoryLinesRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            InventoryLine>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._inventoryLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .inventoryLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (stockTransferItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            StockTransferItem>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._stockTransferItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .stockTransferItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function(
        {bool categoryId,
        bool saleItemsRefs,
        bool stockMovementsRefs,
        bool inventoryLinesRefs,
        bool stockTransferItemsRefs})>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> phone,
  Value<String?> email,
  Value<double> loyaltyPoints,
  Value<String> notes,
  Value<DateTime> createdAt,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> email,
  Value<double> loyaltyPoints,
  Value<String> notes,
  Value<DateTime> createdAt,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$PosDatabase, $CustomersTable, Customer> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$PosDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName:
              $_aliasNameGenerator(db.customers.id, db.sales.customerId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$PosDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get loyaltyPoints => $composableBuilder(
      column: $table.loyaltyPoints, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$PosDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get loyaltyPoints => $composableBuilder(
      column: $table.loyaltyPoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$PosDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<double> get loyaltyPoints => $composableBuilder(
      column: $table.loyaltyPoints, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableTableManager extends RootTableManager<
    _$PosDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, $$CustomersTableReferences),
    Customer,
    PrefetchHooks Function({bool salesRefs})> {
  $$CustomersTableTableManager(_$PosDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<double> loyaltyPoints = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            email: email,
            loyaltyPoints: loyaltyPoints,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<double> loyaltyPoints = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            email: email,
            loyaltyPoints: loyaltyPoints,
            notes: notes,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CustomersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({salesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (salesRefs) db.sales],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (salesRefs)
                    await $_getPrefetchedData<Customer, $CustomersTable, Sale>(
                        currentTable: table,
                        referencedTable:
                            $$CustomersTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomersTableReferences(db, table, p0).salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.customerId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, $$CustomersTableReferences),
    Customer,
    PrefetchHooks Function({bool salesRefs})>;
typedef $$CashSessionsTableCreateCompanionBuilder = CashSessionsCompanion
    Function({
  Value<int> id,
  required int userId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  required double startingCash,
  Value<double?> endingCash,
  Value<double?> expectedCash,
  Value<double?> discrepancy,
  Value<String> status,
  Value<String> notes,
});
typedef $$CashSessionsTableUpdateCompanionBuilder = CashSessionsCompanion
    Function({
  Value<int> id,
  Value<int> userId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<double> startingCash,
  Value<double?> endingCash,
  Value<double?> expectedCash,
  Value<double?> discrepancy,
  Value<String> status,
  Value<String> notes,
});

final class $$CashSessionsTableReferences
    extends BaseReferences<_$PosDatabase, $CashSessionsTable, CashSession> {
  $$CashSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$PosDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.cashSessions.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
          _$PosDatabase db) =>
      MultiTypedResultKey.fromTable(db.sales,
          aliasName:
              $_aliasNameGenerator(db.cashSessions.id, db.sales.cashSessionId));

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.cashSessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CashSessionsTableFilterComposer
    extends Composer<_$PosDatabase, $CashSessionsTable> {
  $$CashSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startingCash => $composableBuilder(
      column: $table.startingCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get endingCash => $composableBuilder(
      column: $table.endingCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedCash => $composableBuilder(
      column: $table.expectedCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discrepancy => $composableBuilder(
      column: $table.discrepancy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> salesRefs(
      Expression<bool> Function($$SalesTableFilterComposer f) f) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.cashSessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CashSessionsTableOrderingComposer
    extends Composer<_$PosDatabase, $CashSessionsTable> {
  $$CashSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startingCash => $composableBuilder(
      column: $table.startingCash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get endingCash => $composableBuilder(
      column: $table.endingCash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get expectedCash => $composableBuilder(
      column: $table.expectedCash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discrepancy => $composableBuilder(
      column: $table.discrepancy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashSessionsTableAnnotationComposer
    extends Composer<_$PosDatabase, $CashSessionsTable> {
  $$CashSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get startingCash => $composableBuilder(
      column: $table.startingCash, builder: (column) => column);

  GeneratedColumn<double> get endingCash => $composableBuilder(
      column: $table.endingCash, builder: (column) => column);

  GeneratedColumn<double> get expectedCash => $composableBuilder(
      column: $table.expectedCash, builder: (column) => column);

  GeneratedColumn<double> get discrepancy => $composableBuilder(
      column: $table.discrepancy, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> salesRefs<T extends Object>(
      Expression<T> Function($$SalesTableAnnotationComposer a) f) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.cashSessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CashSessionsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $CashSessionsTable,
    CashSession,
    $$CashSessionsTableFilterComposer,
    $$CashSessionsTableOrderingComposer,
    $$CashSessionsTableAnnotationComposer,
    $$CashSessionsTableCreateCompanionBuilder,
    $$CashSessionsTableUpdateCompanionBuilder,
    (CashSession, $$CashSessionsTableReferences),
    CashSession,
    PrefetchHooks Function({bool userId, bool salesRefs})> {
  $$CashSessionsTableTableManager(_$PosDatabase db, $CashSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> startingCash = const Value.absent(),
            Value<double?> endingCash = const Value.absent(),
            Value<double?> expectedCash = const Value.absent(),
            Value<double?> discrepancy = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> notes = const Value.absent(),
          }) =>
              CashSessionsCompanion(
            id: id,
            userId: userId,
            startedAt: startedAt,
            endedAt: endedAt,
            startingCash: startingCash,
            endingCash: endingCash,
            expectedCash: expectedCash,
            discrepancy: discrepancy,
            status: status,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            required double startingCash,
            Value<double?> endingCash = const Value.absent(),
            Value<double?> expectedCash = const Value.absent(),
            Value<double?> discrepancy = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> notes = const Value.absent(),
          }) =>
              CashSessionsCompanion.insert(
            id: id,
            userId: userId,
            startedAt: startedAt,
            endedAt: endedAt,
            startingCash: startingCash,
            endingCash: endingCash,
            expectedCash: expectedCash,
            discrepancy: discrepancy,
            status: status,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CashSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false, salesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (salesRefs) db.sales],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$CashSessionsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$CashSessionsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (salesRefs)
                    await $_getPrefetchedData<CashSession, $CashSessionsTable,
                            Sale>(
                        currentTable: table,
                        referencedTable:
                            $$CashSessionsTableReferences._salesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CashSessionsTableReferences(db, table, p0)
                                .salesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.cashSessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CashSessionsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $CashSessionsTable,
    CashSession,
    $$CashSessionsTableFilterComposer,
    $$CashSessionsTableOrderingComposer,
    $$CashSessionsTableAnnotationComposer,
    $$CashSessionsTableCreateCompanionBuilder,
    $$CashSessionsTableUpdateCompanionBuilder,
    (CashSession, $$CashSessionsTableReferences),
    CashSession,
    PrefetchHooks Function({bool userId, bool salesRefs})>;
typedef $$SalesTableCreateCompanionBuilder = SalesCompanion Function({
  Value<int> id,
  required String ref,
  Value<int?> cashSessionId,
  required int userId,
  Value<int?> customerId,
  required double totalHt,
  required double totalTax,
  required double totalTtc,
  Value<double> discountAmount,
  Value<String> status,
  Value<String> note,
  Value<DateTime> createdAt,
});
typedef $$SalesTableUpdateCompanionBuilder = SalesCompanion Function({
  Value<int> id,
  Value<String> ref,
  Value<int?> cashSessionId,
  Value<int> userId,
  Value<int?> customerId,
  Value<double> totalHt,
  Value<double> totalTax,
  Value<double> totalTtc,
  Value<double> discountAmount,
  Value<String> status,
  Value<String> note,
  Value<DateTime> createdAt,
});

final class $$SalesTableReferences
    extends BaseReferences<_$PosDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CashSessionsTable _cashSessionIdTable(_$PosDatabase db) =>
      db.cashSessions.createAlias(
          $_aliasNameGenerator(db.sales.cashSessionId, db.cashSessions.id));

  $$CashSessionsTableProcessedTableManager? get cashSessionId {
    final $_column = $_itemColumn<int>('cash_session_id');
    if ($_column == null) return null;
    final manager = $$CashSessionsTableTableManager($_db, $_db.cashSessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _userIdTable(_$PosDatabase db) =>
      db.users.createAlias($_aliasNameGenerator(db.sales.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CustomersTable _customerIdTable(_$PosDatabase db) => db.customers
      .createAlias($_aliasNameGenerator(db.sales.customerId, db.customers.id));

  $$CustomersTableProcessedTableManager? get customerId {
    final $_column = $_itemColumn<int>('customer_id');
    if ($_column == null) return null;
    final manager = $$CustomersTableTableManager($_db, $_db.customers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
      _saleItemsRefsTable(_$PosDatabase db) => MultiTypedResultKey.fromTable(
          db.saleItems,
          aliasName: $_aliasNameGenerator(db.sales.id, db.saleItems.saleId));

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager($_db, $_db.saleItems)
        .filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
          _$PosDatabase db) =>
      MultiTypedResultKey.fromTable(db.payments,
          aliasName: $_aliasNameGenerator(db.sales.id, db.payments.saleId));

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager($_db, $_db.payments)
        .filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
          _$PosDatabase db) =>
      MultiTypedResultKey.fromTable(db.receipts,
          aliasName: $_aliasNameGenerator(db.sales.id, db.receipts.saleId));

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager($_db, $_db.receipts)
        .filter((f) => f.saleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SalesTableFilterComposer extends Composer<_$PosDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalHt => $composableBuilder(
      column: $table.totalHt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalTax => $composableBuilder(
      column: $table.totalTax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalTtc => $composableBuilder(
      column: $table.totalTtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CashSessionsTableFilterComposer get cashSessionId {
    final $$CashSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashSessionId,
        referencedTable: $db.cashSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashSessionsTableFilterComposer(
              $db: $db,
              $table: $db.cashSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableFilterComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> saleItemsRefs(
      Expression<bool> Function($$SaleItemsTableFilterComposer f) f) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableFilterComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> paymentsRefs(
      Expression<bool> Function($$PaymentsTableFilterComposer f) f) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableFilterComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> receiptsRefs(
      Expression<bool> Function($$ReceiptsTableFilterComposer f) f) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableFilterComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$PosDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalHt => $composableBuilder(
      column: $table.totalHt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalTax => $composableBuilder(
      column: $table.totalTax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalTtc => $composableBuilder(
      column: $table.totalTtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CashSessionsTableOrderingComposer get cashSessionId {
    final $$CashSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashSessionId,
        referencedTable: $db.cashSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.cashSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableOrderingComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SalesTableAnnotationComposer
    extends Composer<_$PosDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<double> get totalHt =>
      $composableBuilder(column: $table.totalHt, builder: (column) => column);

  GeneratedColumn<double> get totalTax =>
      $composableBuilder(column: $table.totalTax, builder: (column) => column);

  GeneratedColumn<double> get totalTtc =>
      $composableBuilder(column: $table.totalTtc, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CashSessionsTableAnnotationComposer get cashSessionId {
    final $$CashSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cashSessionId,
        referencedTable: $db.cashSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.cashSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> saleItemsRefs<T extends Object>(
      Expression<T> Function($$SaleItemsTableAnnotationComposer a) f) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.saleItems,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SaleItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.saleItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
      Expression<T> Function($$PaymentsTableAnnotationComposer a) f) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> receiptsRefs<T extends Object>(
      Expression<T> Function($$ReceiptsTableAnnotationComposer a) f) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.saleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableAnnotationComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SalesTableTableManager extends RootTableManager<
    _$PosDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, $$SalesTableReferences),
    Sale,
    PrefetchHooks Function(
        {bool cashSessionId,
        bool userId,
        bool customerId,
        bool saleItemsRefs,
        bool paymentsRefs,
        bool receiptsRefs})> {
  $$SalesTableTableManager(_$PosDatabase db, $SalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> ref = const Value.absent(),
            Value<int?> cashSessionId = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<double> totalHt = const Value.absent(),
            Value<double> totalTax = const Value.absent(),
            Value<double> totalTtc = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SalesCompanion(
            id: id,
            ref: ref,
            cashSessionId: cashSessionId,
            userId: userId,
            customerId: customerId,
            totalHt: totalHt,
            totalTax: totalTax,
            totalTtc: totalTtc,
            discountAmount: discountAmount,
            status: status,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String ref,
            Value<int?> cashSessionId = const Value.absent(),
            required int userId,
            Value<int?> customerId = const Value.absent(),
            required double totalHt,
            required double totalTax,
            required double totalTtc,
            Value<double> discountAmount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SalesCompanion.insert(
            id: id,
            ref: ref,
            cashSessionId: cashSessionId,
            userId: userId,
            customerId: customerId,
            totalHt: totalHt,
            totalTax: totalTax,
            totalTtc: totalTtc,
            discountAmount: discountAmount,
            status: status,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SalesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {cashSessionId = false,
              userId = false,
              customerId = false,
              saleItemsRefs = false,
              paymentsRefs = false,
              receiptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (saleItemsRefs) db.saleItems,
                if (paymentsRefs) db.payments,
                if (receiptsRefs) db.receipts
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cashSessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cashSessionId,
                    referencedTable:
                        $$SalesTableReferences._cashSessionIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._cashSessionIdTable(db).id,
                  ) as T;
                }
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable: $$SalesTableReferences._userIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (customerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.customerId,
                    referencedTable:
                        $$SalesTableReferences._customerIdTable(db),
                    referencedColumn:
                        $$SalesTableReferences._customerIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (saleItemsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, SaleItem>(
                        currentTable: table,
                        referencedTable:
                            $$SalesTableReferences._saleItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SalesTableReferences(db, table, p0).saleItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.saleId == item.id),
                        typedResults: items),
                  if (paymentsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, Payment>(
                        currentTable: table,
                        referencedTable:
                            $$SalesTableReferences._paymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SalesTableReferences(db, table, p0).paymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.saleId == item.id),
                        typedResults: items),
                  if (receiptsRefs)
                    await $_getPrefetchedData<Sale, $SalesTable, Receipt>(
                        currentTable: table,
                        referencedTable:
                            $$SalesTableReferences._receiptsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SalesTableReferences(db, table, p0).receiptsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.saleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SalesTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, $$SalesTableReferences),
    Sale,
    PrefetchHooks Function(
        {bool cashSessionId,
        bool userId,
        bool customerId,
        bool saleItemsRefs,
        bool paymentsRefs,
        bool receiptsRefs})>;
typedef $$SaleItemsTableCreateCompanionBuilder = SaleItemsCompanion Function({
  Value<int> id,
  required int saleId,
  required int productId,
  required String productName,
  required double unitPriceHt,
  required double taxRate,
  required int quantity,
  Value<double> discountPct,
  required double lineTotal,
});
typedef $$SaleItemsTableUpdateCompanionBuilder = SaleItemsCompanion Function({
  Value<int> id,
  Value<int> saleId,
  Value<int> productId,
  Value<String> productName,
  Value<double> unitPriceHt,
  Value<double> taxRate,
  Value<int> quantity,
  Value<double> discountPct,
  Value<double> lineTotal,
});

final class $$SaleItemsTableReferences
    extends BaseReferences<_$PosDatabase, $SaleItemsTable, SaleItem> {
  $$SaleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$PosDatabase db) => db.sales
      .createAlias($_aliasNameGenerator(db.saleItems.saleId, db.sales.id));

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$PosDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.saleItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SaleItemsTableFilterComposer
    extends Composer<_$PosDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitPriceHt => $composableBuilder(
      column: $table.unitPriceHt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountPct => $composableBuilder(
      column: $table.discountPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lineTotal => $composableBuilder(
      column: $table.lineTotal, builder: (column) => ColumnFilters(column));

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SaleItemsTableOrderingComposer
    extends Composer<_$PosDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitPriceHt => $composableBuilder(
      column: $table.unitPriceHt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountPct => $composableBuilder(
      column: $table.discountPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lineTotal => $composableBuilder(
      column: $table.lineTotal, builder: (column) => ColumnOrderings(column));

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableOrderingComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SaleItemsTableAnnotationComposer
    extends Composer<_$PosDatabase, $SaleItemsTable> {
  $$SaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<double> get unitPriceHt => $composableBuilder(
      column: $table.unitPriceHt, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get discountPct => $composableBuilder(
      column: $table.discountPct, builder: (column) => column);

  GeneratedColumn<double> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SaleItemsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $SaleItemsTable,
    SaleItem,
    $$SaleItemsTableFilterComposer,
    $$SaleItemsTableOrderingComposer,
    $$SaleItemsTableAnnotationComposer,
    $$SaleItemsTableCreateCompanionBuilder,
    $$SaleItemsTableUpdateCompanionBuilder,
    (SaleItem, $$SaleItemsTableReferences),
    SaleItem,
    PrefetchHooks Function({bool saleId, bool productId})> {
  $$SaleItemsTableTableManager(_$PosDatabase db, $SaleItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> saleId = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<double> unitPriceHt = const Value.absent(),
            Value<double> taxRate = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> discountPct = const Value.absent(),
            Value<double> lineTotal = const Value.absent(),
          }) =>
              SaleItemsCompanion(
            id: id,
            saleId: saleId,
            productId: productId,
            productName: productName,
            unitPriceHt: unitPriceHt,
            taxRate: taxRate,
            quantity: quantity,
            discountPct: discountPct,
            lineTotal: lineTotal,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int saleId,
            required int productId,
            required String productName,
            required double unitPriceHt,
            required double taxRate,
            required int quantity,
            Value<double> discountPct = const Value.absent(),
            required double lineTotal,
          }) =>
              SaleItemsCompanion.insert(
            id: id,
            saleId: saleId,
            productId: productId,
            productName: productName,
            unitPriceHt: unitPriceHt,
            taxRate: taxRate,
            quantity: quantity,
            discountPct: discountPct,
            lineTotal: lineTotal,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SaleItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({saleId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (saleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.saleId,
                    referencedTable:
                        $$SaleItemsTableReferences._saleIdTable(db),
                    referencedColumn:
                        $$SaleItemsTableReferences._saleIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$SaleItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$SaleItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SaleItemsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $SaleItemsTable,
    SaleItem,
    $$SaleItemsTableFilterComposer,
    $$SaleItemsTableOrderingComposer,
    $$SaleItemsTableAnnotationComposer,
    $$SaleItemsTableCreateCompanionBuilder,
    $$SaleItemsTableUpdateCompanionBuilder,
    (SaleItem, $$SaleItemsTableReferences),
    SaleItem,
    PrefetchHooks Function({bool saleId, bool productId})>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  required int saleId,
  required String method,
  required double amount,
  Value<double> changeGiven,
  Value<DateTime> paidAt,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<int> saleId,
  Value<String> method,
  Value<double> amount,
  Value<double> changeGiven,
  Value<DateTime> paidAt,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$PosDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$PosDatabase db) => db.sales
      .createAlias($_aliasNameGenerator(db.payments.saleId, db.sales.id));

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$PosDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get changeGiven => $composableBuilder(
      column: $table.changeGiven, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$PosDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get changeGiven => $composableBuilder(
      column: $table.changeGiven, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableOrderingComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$PosDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get changeGiven => $composableBuilder(
      column: $table.changeGiven, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, $$PaymentsTableReferences),
    Payment,
    PrefetchHooks Function({bool saleId})> {
  $$PaymentsTableTableManager(_$PosDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> saleId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<double> changeGiven = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            saleId: saleId,
            method: method,
            amount: amount,
            changeGiven: changeGiven,
            paidAt: paidAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int saleId,
            required String method,
            required double amount,
            Value<double> changeGiven = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            saleId: saleId,
            method: method,
            amount: amount,
            changeGiven: changeGiven,
            paidAt: paidAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PaymentsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (saleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.saleId,
                    referencedTable: $$PaymentsTableReferences._saleIdTable(db),
                    referencedColumn:
                        $$PaymentsTableReferences._saleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, $$PaymentsTableReferences),
    Payment,
    PrefetchHooks Function({bool saleId})>;
typedef $$StockMovementsTableCreateCompanionBuilder = StockMovementsCompanion
    Function({
  Value<int> id,
  required int productId,
  Value<int?> userId,
  required String type,
  required int qtyDelta,
  required int qtyAfter,
  Value<String> reason,
  Value<String?> inventoryRef,
  Value<DateTime> movedAt,
});
typedef $$StockMovementsTableUpdateCompanionBuilder = StockMovementsCompanion
    Function({
  Value<int> id,
  Value<int> productId,
  Value<int?> userId,
  Value<String> type,
  Value<int> qtyDelta,
  Value<int> qtyAfter,
  Value<String> reason,
  Value<String?> inventoryRef,
  Value<DateTime> movedAt,
});

final class $$StockMovementsTableReferences
    extends BaseReferences<_$PosDatabase, $StockMovementsTable, StockMovement> {
  $$StockMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$PosDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.stockMovements.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _userIdTable(_$PosDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.stockMovements.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    final $_column = $_itemColumn<int>('user_id');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockMovementsTableFilterComposer
    extends Composer<_$PosDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qtyDelta => $composableBuilder(
      column: $table.qtyDelta, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qtyAfter => $composableBuilder(
      column: $table.qtyAfter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inventoryRef => $composableBuilder(
      column: $table.inventoryRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get movedAt => $composableBuilder(
      column: $table.movedAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$PosDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qtyDelta => $composableBuilder(
      column: $table.qtyDelta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qtyAfter => $composableBuilder(
      column: $table.qtyAfter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inventoryRef => $composableBuilder(
      column: $table.inventoryRef,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get movedAt => $composableBuilder(
      column: $table.movedAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$PosDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get qtyDelta =>
      $composableBuilder(column: $table.qtyDelta, builder: (column) => column);

  GeneratedColumn<int> get qtyAfter =>
      $composableBuilder(column: $table.qtyAfter, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get inventoryRef => $composableBuilder(
      column: $table.inventoryRef, builder: (column) => column);

  GeneratedColumn<DateTime> get movedAt =>
      $composableBuilder(column: $table.movedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $StockMovementsTable,
    StockMovement,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (StockMovement, $$StockMovementsTableReferences),
    StockMovement,
    PrefetchHooks Function({bool productId, bool userId})> {
  $$StockMovementsTableTableManager(
      _$PosDatabase db, $StockMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<int?> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> qtyDelta = const Value.absent(),
            Value<int> qtyAfter = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> inventoryRef = const Value.absent(),
            Value<DateTime> movedAt = const Value.absent(),
          }) =>
              StockMovementsCompanion(
            id: id,
            productId: productId,
            userId: userId,
            type: type,
            qtyDelta: qtyDelta,
            qtyAfter: qtyAfter,
            reason: reason,
            inventoryRef: inventoryRef,
            movedAt: movedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int productId,
            Value<int?> userId = const Value.absent(),
            required String type,
            required int qtyDelta,
            required int qtyAfter,
            Value<String> reason = const Value.absent(),
            Value<String?> inventoryRef = const Value.absent(),
            Value<DateTime> movedAt = const Value.absent(),
          }) =>
              StockMovementsCompanion.insert(
            id: id,
            productId: productId,
            userId: userId,
            type: type,
            qtyDelta: qtyDelta,
            qtyAfter: qtyAfter,
            reason: reason,
            inventoryRef: inventoryRef,
            movedAt: movedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$StockMovementsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._productIdTable(db).id,
                  ) as T;
                }
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$StockMovementsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StockMovementsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $StockMovementsTable,
    StockMovement,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (StockMovement, $$StockMovementsTableReferences),
    StockMovement,
    PrefetchHooks Function({bool productId, bool userId})>;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  required int saleId,
  Value<String> format,
  required String content,
  Value<bool> isPrinted,
  Value<DateTime?> printedAt,
  Value<DateTime> createdAt,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<int> saleId,
  Value<String> format,
  Value<String> content,
  Value<bool> isPrinted,
  Value<DateTime?> printedAt,
  Value<DateTime> createdAt,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$PosDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SalesTable _saleIdTable(_$PosDatabase db) => db.sales
      .createAlias($_aliasNameGenerator(db.receipts.saleId, db.sales.id));

  $$SalesTableProcessedTableManager get saleId {
    final $_column = $_itemColumn<int>('sale_id')!;

    final manager = $$SalesTableTableManager($_db, $_db.sales)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$PosDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrinted => $composableBuilder(
      column: $table.isPrinted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get printedAt => $composableBuilder(
      column: $table.printedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SalesTableFilterComposer get saleId {
    final $$SalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableFilterComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$PosDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrinted => $composableBuilder(
      column: $table.isPrinted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get printedAt => $composableBuilder(
      column: $table.printedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SalesTableOrderingComposer get saleId {
    final $$SalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableOrderingComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$PosDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isPrinted =>
      $composableBuilder(column: $table.isPrinted, builder: (column) => column);

  GeneratedColumn<DateTime> get printedAt =>
      $composableBuilder(column: $table.printedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SalesTableAnnotationComposer get saleId {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.saleId,
        referencedTable: $db.sales,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SalesTableAnnotationComposer(
              $db: $db,
              $table: $db.sales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, $$ReceiptsTableReferences),
    Receipt,
    PrefetchHooks Function({bool saleId})> {
  $$ReceiptsTableTableManager(_$PosDatabase db, $ReceiptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> saleId = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<bool> isPrinted = const Value.absent(),
            Value<DateTime?> printedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ReceiptsCompanion(
            id: id,
            saleId: saleId,
            format: format,
            content: content,
            isPrinted: isPrinted,
            printedAt: printedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int saleId,
            Value<String> format = const Value.absent(),
            required String content,
            Value<bool> isPrinted = const Value.absent(),
            Value<DateTime?> printedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ReceiptsCompanion.insert(
            id: id,
            saleId: saleId,
            format: format,
            content: content,
            isPrinted: isPrinted,
            printedAt: printedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ReceiptsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({saleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (saleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.saleId,
                    referencedTable: $$ReceiptsTableReferences._saleIdTable(db),
                    referencedColumn:
                        $$ReceiptsTableReferences._saleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReceiptsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, $$ReceiptsTableReferences),
    Receipt,
    PrefetchHooks Function({bool saleId})>;
typedef $$InventorySessionsTableCreateCompanionBuilder
    = InventorySessionsCompanion Function({
  Value<int> id,
  required String ref,
  required int userId,
  Value<String> status,
  Value<String> notes,
  Value<int> totalProducts,
  Value<int> discrepancies,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
});
typedef $$InventorySessionsTableUpdateCompanionBuilder
    = InventorySessionsCompanion Function({
  Value<int> id,
  Value<String> ref,
  Value<int> userId,
  Value<String> status,
  Value<String> notes,
  Value<int> totalProducts,
  Value<int> discrepancies,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
});

final class $$InventorySessionsTableReferences extends BaseReferences<
    _$PosDatabase, $InventorySessionsTable, InventorySession> {
  $$InventorySessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$PosDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.inventorySessions.userId, db.users.id));

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$InventoryLinesTable, List<InventoryLine>>
      _inventoryLinesRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.inventoryLines,
              aliasName: $_aliasNameGenerator(
                  db.inventorySessions.id, db.inventoryLines.sessionId));

  $$InventoryLinesTableProcessedTableManager get inventoryLinesRefs {
    final manager = $$InventoryLinesTableTableManager($_db, $_db.inventoryLines)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryLinesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InventorySessionsTableFilterComposer
    extends Composer<_$PosDatabase, $InventorySessionsTable> {
  $$InventorySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalProducts => $composableBuilder(
      column: $table.totalProducts, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discrepancies => $composableBuilder(
      column: $table.discrepancies, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> inventoryLinesRefs(
      Expression<bool> Function($$InventoryLinesTableFilterComposer f) f) {
    final $$InventoryLinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryLines,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryLinesTableFilterComposer(
              $db: $db,
              $table: $db.inventoryLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InventorySessionsTableOrderingComposer
    extends Composer<_$PosDatabase, $InventorySessionsTable> {
  $$InventorySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalProducts => $composableBuilder(
      column: $table.totalProducts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discrepancies => $composableBuilder(
      column: $table.discrepancies,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventorySessionsTableAnnotationComposer
    extends Composer<_$PosDatabase, $InventorySessionsTable> {
  $$InventorySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get totalProducts => $composableBuilder(
      column: $table.totalProducts, builder: (column) => column);

  GeneratedColumn<int> get discrepancies => $composableBuilder(
      column: $table.discrepancies, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> inventoryLinesRefs<T extends Object>(
      Expression<T> Function($$InventoryLinesTableAnnotationComposer a) f) {
    final $$InventoryLinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryLines,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryLinesTableAnnotationComposer(
              $db: $db,
              $table: $db.inventoryLines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InventorySessionsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $InventorySessionsTable,
    InventorySession,
    $$InventorySessionsTableFilterComposer,
    $$InventorySessionsTableOrderingComposer,
    $$InventorySessionsTableAnnotationComposer,
    $$InventorySessionsTableCreateCompanionBuilder,
    $$InventorySessionsTableUpdateCompanionBuilder,
    (InventorySession, $$InventorySessionsTableReferences),
    InventorySession,
    PrefetchHooks Function({bool userId, bool inventoryLinesRefs})> {
  $$InventorySessionsTableTableManager(
      _$PosDatabase db, $InventorySessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventorySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventorySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventorySessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> ref = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> totalProducts = const Value.absent(),
            Value<int> discrepancies = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              InventorySessionsCompanion(
            id: id,
            ref: ref,
            userId: userId,
            status: status,
            notes: notes,
            totalProducts: totalProducts,
            discrepancies: discrepancies,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String ref,
            required int userId,
            Value<String> status = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> totalProducts = const Value.absent(),
            Value<int> discrepancies = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              InventorySessionsCompanion.insert(
            id: id,
            ref: ref,
            userId: userId,
            status: status,
            notes: notes,
            totalProducts: totalProducts,
            discrepancies: discrepancies,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InventorySessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {userId = false, inventoryLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (inventoryLinesRefs) db.inventoryLines
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$InventorySessionsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$InventorySessionsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inventoryLinesRefs)
                    await $_getPrefetchedData<InventorySession,
                            $InventorySessionsTable, InventoryLine>(
                        currentTable: table,
                        referencedTable: $$InventorySessionsTableReferences
                            ._inventoryLinesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InventorySessionsTableReferences(db, table, p0)
                                .inventoryLinesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InventorySessionsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $InventorySessionsTable,
    InventorySession,
    $$InventorySessionsTableFilterComposer,
    $$InventorySessionsTableOrderingComposer,
    $$InventorySessionsTableAnnotationComposer,
    $$InventorySessionsTableCreateCompanionBuilder,
    $$InventorySessionsTableUpdateCompanionBuilder,
    (InventorySession, $$InventorySessionsTableReferences),
    InventorySession,
    PrefetchHooks Function({bool userId, bool inventoryLinesRefs})>;
typedef $$InventoryLinesTableCreateCompanionBuilder = InventoryLinesCompanion
    Function({
  Value<int> id,
  required int sessionId,
  required int productId,
  required String productName,
  Value<String?> barcode,
  required int expectedQty,
  Value<int?> countedQty,
  Value<int?> difference,
  Value<bool> isValidated,
  Value<String> notes,
});
typedef $$InventoryLinesTableUpdateCompanionBuilder = InventoryLinesCompanion
    Function({
  Value<int> id,
  Value<int> sessionId,
  Value<int> productId,
  Value<String> productName,
  Value<String?> barcode,
  Value<int> expectedQty,
  Value<int?> countedQty,
  Value<int?> difference,
  Value<bool> isValidated,
  Value<String> notes,
});

final class $$InventoryLinesTableReferences
    extends BaseReferences<_$PosDatabase, $InventoryLinesTable, InventoryLine> {
  $$InventoryLinesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $InventorySessionsTable _sessionIdTable(_$PosDatabase db) =>
      db.inventorySessions.createAlias($_aliasNameGenerator(
          db.inventoryLines.sessionId, db.inventorySessions.id));

  $$InventorySessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager =
        $$InventorySessionsTableTableManager($_db, $_db.inventorySessions)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$PosDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.inventoryLines.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$InventoryLinesTableFilterComposer
    extends Composer<_$PosDatabase, $InventoryLinesTable> {
  $$InventoryLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expectedQty => $composableBuilder(
      column: $table.expectedQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get countedQty => $composableBuilder(
      column: $table.countedQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isValidated => $composableBuilder(
      column: $table.isValidated, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$InventorySessionsTableFilterComposer get sessionId {
    final $$InventorySessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.inventorySessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventorySessionsTableFilterComposer(
              $db: $db,
              $table: $db.inventorySessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryLinesTableOrderingComposer
    extends Composer<_$PosDatabase, $InventoryLinesTable> {
  $$InventoryLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expectedQty => $composableBuilder(
      column: $table.expectedQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get countedQty => $composableBuilder(
      column: $table.countedQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isValidated => $composableBuilder(
      column: $table.isValidated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$InventorySessionsTableOrderingComposer get sessionId {
    final $$InventorySessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.inventorySessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventorySessionsTableOrderingComposer(
              $db: $db,
              $table: $db.inventorySessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryLinesTableAnnotationComposer
    extends Composer<_$PosDatabase, $InventoryLinesTable> {
  $$InventoryLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get expectedQty => $composableBuilder(
      column: $table.expectedQty, builder: (column) => column);

  GeneratedColumn<int> get countedQty => $composableBuilder(
      column: $table.countedQty, builder: (column) => column);

  GeneratedColumn<int> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => column);

  GeneratedColumn<bool> get isValidated => $composableBuilder(
      column: $table.isValidated, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$InventorySessionsTableAnnotationComposer get sessionId {
    final $$InventorySessionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.sessionId,
            referencedTable: $db.inventorySessions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InventorySessionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.inventorySessions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryLinesTableTableManager extends RootTableManager<
    _$PosDatabase,
    $InventoryLinesTable,
    InventoryLine,
    $$InventoryLinesTableFilterComposer,
    $$InventoryLinesTableOrderingComposer,
    $$InventoryLinesTableAnnotationComposer,
    $$InventoryLinesTableCreateCompanionBuilder,
    $$InventoryLinesTableUpdateCompanionBuilder,
    (InventoryLine, $$InventoryLinesTableReferences),
    InventoryLine,
    PrefetchHooks Function({bool sessionId, bool productId})> {
  $$InventoryLinesTableTableManager(
      _$PosDatabase db, $InventoryLinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sessionId = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<int> expectedQty = const Value.absent(),
            Value<int?> countedQty = const Value.absent(),
            Value<int?> difference = const Value.absent(),
            Value<bool> isValidated = const Value.absent(),
            Value<String> notes = const Value.absent(),
          }) =>
              InventoryLinesCompanion(
            id: id,
            sessionId: sessionId,
            productId: productId,
            productName: productName,
            barcode: barcode,
            expectedQty: expectedQty,
            countedQty: countedQty,
            difference: difference,
            isValidated: isValidated,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sessionId,
            required int productId,
            required String productName,
            Value<String?> barcode = const Value.absent(),
            required int expectedQty,
            Value<int?> countedQty = const Value.absent(),
            Value<int?> difference = const Value.absent(),
            Value<bool> isValidated = const Value.absent(),
            Value<String> notes = const Value.absent(),
          }) =>
              InventoryLinesCompanion.insert(
            id: id,
            sessionId: sessionId,
            productId: productId,
            productName: productName,
            barcode: barcode,
            expectedQty: expectedQty,
            countedQty: countedQty,
            difference: difference,
            isValidated: isValidated,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InventoryLinesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$InventoryLinesTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$InventoryLinesTableReferences._sessionIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$InventoryLinesTableReferences._productIdTable(db),
                    referencedColumn:
                        $$InventoryLinesTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$InventoryLinesTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $InventoryLinesTable,
    InventoryLine,
    $$InventoryLinesTableFilterComposer,
    $$InventoryLinesTableOrderingComposer,
    $$InventoryLinesTableAnnotationComposer,
    $$InventoryLinesTableCreateCompanionBuilder,
    $$InventoryLinesTableUpdateCompanionBuilder,
    (InventoryLine, $$InventoryLinesTableReferences),
    InventoryLine,
    PrefetchHooks Function({bool sessionId, bool productId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$PosDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$PosDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$PosDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$PosDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$PosDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$PosDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String entityType,
  required int entityId,
  Value<String> action,
  required String payload,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> entityType,
  Value<int> entityId,
  Value<String> action,
  Value<String> payload,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$PosDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$PosDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$PosDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$PosDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$PosDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$PosDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<int> entityId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            status: status,
            retryCount: retryCount,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required int entityId,
            Value<String> action = const Value.absent(),
            required String payload,
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            status: status,
            retryCount: retryCount,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$PosDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$ShopsTableCreateCompanionBuilder = ShopsCompanion Function({
  required String id,
  required String name,
  Value<String?> address,
  Value<bool> isCurrent,
  Value<int> rowid,
});
typedef $$ShopsTableUpdateCompanionBuilder = ShopsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> address,
  Value<bool> isCurrent,
  Value<int> rowid,
});

class $$ShopsTableFilterComposer extends Composer<_$PosDatabase, $ShopsTable> {
  $$ShopsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCurrent => $composableBuilder(
      column: $table.isCurrent, builder: (column) => ColumnFilters(column));
}

class $$ShopsTableOrderingComposer
    extends Composer<_$PosDatabase, $ShopsTable> {
  $$ShopsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
      column: $table.isCurrent, builder: (column) => ColumnOrderings(column));
}

class $$ShopsTableAnnotationComposer
    extends Composer<_$PosDatabase, $ShopsTable> {
  $$ShopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);
}

class $$ShopsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $ShopsTable,
    Shop,
    $$ShopsTableFilterComposer,
    $$ShopsTableOrderingComposer,
    $$ShopsTableAnnotationComposer,
    $$ShopsTableCreateCompanionBuilder,
    $$ShopsTableUpdateCompanionBuilder,
    (Shop, BaseReferences<_$PosDatabase, $ShopsTable, Shop>),
    Shop,
    PrefetchHooks Function()> {
  $$ShopsTableTableManager(_$PosDatabase db, $ShopsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<bool> isCurrent = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShopsCompanion(
            id: id,
            name: name,
            address: address,
            isCurrent: isCurrent,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> address = const Value.absent(),
            Value<bool> isCurrent = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShopsCompanion.insert(
            id: id,
            name: name,
            address: address,
            isCurrent: isCurrent,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShopsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $ShopsTable,
    Shop,
    $$ShopsTableFilterComposer,
    $$ShopsTableOrderingComposer,
    $$ShopsTableAnnotationComposer,
    $$ShopsTableCreateCompanionBuilder,
    $$ShopsTableUpdateCompanionBuilder,
    (Shop, BaseReferences<_$PosDatabase, $ShopsTable, Shop>),
    Shop,
    PrefetchHooks Function()>;
typedef $$StockTransfersTableCreateCompanionBuilder = StockTransfersCompanion
    Function({
  Value<int> id,
  required String ref,
  required String sourceShopId,
  required String targetShopId,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime?> receivedAt,
  Value<String?> remoteId,
});
typedef $$StockTransfersTableUpdateCompanionBuilder = StockTransfersCompanion
    Function({
  Value<int> id,
  Value<String> ref,
  Value<String> sourceShopId,
  Value<String> targetShopId,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime?> receivedAt,
  Value<String?> remoteId,
});

final class $$StockTransfersTableReferences
    extends BaseReferences<_$PosDatabase, $StockTransfersTable, StockTransfer> {
  $$StockTransfersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockTransferItemsTable, List<StockTransferItem>>
      _stockTransferItemsRefsTable(_$PosDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockTransferItems,
              aliasName: $_aliasNameGenerator(
                  db.stockTransfers.id, db.stockTransferItems.transferId));

  $$StockTransferItemsTableProcessedTableManager get stockTransferItemsRefs {
    final manager =
        $$StockTransferItemsTableTableManager($_db, $_db.stockTransferItems)
            .filter((f) => f.transferId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_stockTransferItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StockTransfersTableFilterComposer
    extends Composer<_$PosDatabase, $StockTransfersTable> {
  $$StockTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceShopId => $composableBuilder(
      column: $table.sourceShopId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetShopId => $composableBuilder(
      column: $table.targetShopId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  Expression<bool> stockTransferItemsRefs(
      Expression<bool> Function($$StockTransferItemsTableFilterComposer f) f) {
    final $$StockTransferItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockTransferItems,
        getReferencedColumn: (t) => t.transferId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockTransferItemsTableFilterComposer(
              $db: $db,
              $table: $db.stockTransferItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StockTransfersTableOrderingComposer
    extends Composer<_$PosDatabase, $StockTransfersTable> {
  $$StockTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ref => $composableBuilder(
      column: $table.ref, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceShopId => $composableBuilder(
      column: $table.sourceShopId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetShopId => $composableBuilder(
      column: $table.targetShopId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));
}

class $$StockTransfersTableAnnotationComposer
    extends Composer<_$PosDatabase, $StockTransfersTable> {
  $$StockTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<String> get sourceShopId => $composableBuilder(
      column: $table.sourceShopId, builder: (column) => column);

  GeneratedColumn<String> get targetShopId => $composableBuilder(
      column: $table.targetShopId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  Expression<T> stockTransferItemsRefs<T extends Object>(
      Expression<T> Function($$StockTransferItemsTableAnnotationComposer a) f) {
    final $$StockTransferItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.stockTransferItems,
            getReferencedColumn: (t) => t.transferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$StockTransferItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.stockTransferItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$StockTransfersTableTableManager extends RootTableManager<
    _$PosDatabase,
    $StockTransfersTable,
    StockTransfer,
    $$StockTransfersTableFilterComposer,
    $$StockTransfersTableOrderingComposer,
    $$StockTransfersTableAnnotationComposer,
    $$StockTransfersTableCreateCompanionBuilder,
    $$StockTransfersTableUpdateCompanionBuilder,
    (StockTransfer, $$StockTransfersTableReferences),
    StockTransfer,
    PrefetchHooks Function({bool stockTransferItemsRefs})> {
  $$StockTransfersTableTableManager(
      _$PosDatabase db, $StockTransfersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockTransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> ref = const Value.absent(),
            Value<String> sourceShopId = const Value.absent(),
            Value<String> targetShopId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
          }) =>
              StockTransfersCompanion(
            id: id,
            ref: ref,
            sourceShopId: sourceShopId,
            targetShopId: targetShopId,
            status: status,
            notes: notes,
            createdAt: createdAt,
            receivedAt: receivedAt,
            remoteId: remoteId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String ref,
            required String sourceShopId,
            required String targetShopId,
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
          }) =>
              StockTransfersCompanion.insert(
            id: id,
            ref: ref,
            sourceShopId: sourceShopId,
            targetShopId: targetShopId,
            status: status,
            notes: notes,
            createdAt: createdAt,
            receivedAt: receivedAt,
            remoteId: remoteId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockTransfersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({stockTransferItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockTransferItemsRefs) db.stockTransferItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockTransferItemsRefs)
                    await $_getPrefetchedData<StockTransfer,
                            $StockTransfersTable, StockTransferItem>(
                        currentTable: table,
                        referencedTable: $$StockTransfersTableReferences
                            ._stockTransferItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StockTransfersTableReferences(db, table, p0)
                                .stockTransferItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.transferId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StockTransfersTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $StockTransfersTable,
    StockTransfer,
    $$StockTransfersTableFilterComposer,
    $$StockTransfersTableOrderingComposer,
    $$StockTransfersTableAnnotationComposer,
    $$StockTransfersTableCreateCompanionBuilder,
    $$StockTransfersTableUpdateCompanionBuilder,
    (StockTransfer, $$StockTransfersTableReferences),
    StockTransfer,
    PrefetchHooks Function({bool stockTransferItemsRefs})>;
typedef $$StockTransferItemsTableCreateCompanionBuilder
    = StockTransferItemsCompanion Function({
  Value<int> id,
  required int transferId,
  required int productId,
  required int quantitySent,
  Value<int?> quantityReceived,
});
typedef $$StockTransferItemsTableUpdateCompanionBuilder
    = StockTransferItemsCompanion Function({
  Value<int> id,
  Value<int> transferId,
  Value<int> productId,
  Value<int> quantitySent,
  Value<int?> quantityReceived,
});

final class $$StockTransferItemsTableReferences extends BaseReferences<
    _$PosDatabase, $StockTransferItemsTable, StockTransferItem> {
  $$StockTransferItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $StockTransfersTable _transferIdTable(_$PosDatabase db) =>
      db.stockTransfers.createAlias($_aliasNameGenerator(
          db.stockTransferItems.transferId, db.stockTransfers.id));

  $$StockTransfersTableProcessedTableManager get transferId {
    final $_column = $_itemColumn<int>('transfer_id')!;

    final manager = $$StockTransfersTableTableManager($_db, $_db.stockTransfers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transferIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$PosDatabase db) =>
      db.products.createAlias($_aliasNameGenerator(
          db.stockTransferItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockTransferItemsTableFilterComposer
    extends Composer<_$PosDatabase, $StockTransferItemsTable> {
  $$StockTransferItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantitySent => $composableBuilder(
      column: $table.quantitySent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantityReceived => $composableBuilder(
      column: $table.quantityReceived,
      builder: (column) => ColumnFilters(column));

  $$StockTransfersTableFilterComposer get transferId {
    final $$StockTransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transferId,
        referencedTable: $db.stockTransfers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockTransfersTableFilterComposer(
              $db: $db,
              $table: $db.stockTransfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockTransferItemsTableOrderingComposer
    extends Composer<_$PosDatabase, $StockTransferItemsTable> {
  $$StockTransferItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantitySent => $composableBuilder(
      column: $table.quantitySent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantityReceived => $composableBuilder(
      column: $table.quantityReceived,
      builder: (column) => ColumnOrderings(column));

  $$StockTransfersTableOrderingComposer get transferId {
    final $$StockTransfersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transferId,
        referencedTable: $db.stockTransfers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockTransfersTableOrderingComposer(
              $db: $db,
              $table: $db.stockTransfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockTransferItemsTableAnnotationComposer
    extends Composer<_$PosDatabase, $StockTransferItemsTable> {
  $$StockTransferItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantitySent => $composableBuilder(
      column: $table.quantitySent, builder: (column) => column);

  GeneratedColumn<int> get quantityReceived => $composableBuilder(
      column: $table.quantityReceived, builder: (column) => column);

  $$StockTransfersTableAnnotationComposer get transferId {
    final $$StockTransfersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transferId,
        referencedTable: $db.stockTransfers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockTransfersTableAnnotationComposer(
              $db: $db,
              $table: $db.stockTransfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockTransferItemsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $StockTransferItemsTable,
    StockTransferItem,
    $$StockTransferItemsTableFilterComposer,
    $$StockTransferItemsTableOrderingComposer,
    $$StockTransferItemsTableAnnotationComposer,
    $$StockTransferItemsTableCreateCompanionBuilder,
    $$StockTransferItemsTableUpdateCompanionBuilder,
    (StockTransferItem, $$StockTransferItemsTableReferences),
    StockTransferItem,
    PrefetchHooks Function({bool transferId, bool productId})> {
  $$StockTransferItemsTableTableManager(
      _$PosDatabase db, $StockTransferItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockTransferItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockTransferItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockTransferItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> transferId = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<int> quantitySent = const Value.absent(),
            Value<int?> quantityReceived = const Value.absent(),
          }) =>
              StockTransferItemsCompanion(
            id: id,
            transferId: transferId,
            productId: productId,
            quantitySent: quantitySent,
            quantityReceived: quantityReceived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int transferId,
            required int productId,
            required int quantitySent,
            Value<int?> quantityReceived = const Value.absent(),
          }) =>
              StockTransferItemsCompanion.insert(
            id: id,
            transferId: transferId,
            productId: productId,
            quantitySent: quantitySent,
            quantityReceived: quantityReceived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockTransferItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({transferId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transferId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transferId,
                    referencedTable: $$StockTransferItemsTableReferences
                        ._transferIdTable(db),
                    referencedColumn: $$StockTransferItemsTableReferences
                        ._transferIdTable(db)
                        .id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$StockTransferItemsTableReferences._productIdTable(db),
                    referencedColumn: $$StockTransferItemsTableReferences
                        ._productIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StockTransferItemsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $StockTransferItemsTable,
    StockTransferItem,
    $$StockTransferItemsTableFilterComposer,
    $$StockTransferItemsTableOrderingComposer,
    $$StockTransferItemsTableAnnotationComposer,
    $$StockTransferItemsTableCreateCompanionBuilder,
    $$StockTransferItemsTableUpdateCompanionBuilder,
    (StockTransferItem, $$StockTransferItemsTableReferences),
    StockTransferItem,
    PrefetchHooks Function({bool transferId, bool productId})>;
typedef $$AuditLogsTableCreateCompanionBuilder = AuditLogsCompanion Function({
  Value<int> id,
  required int actorId,
  required String action,
  required String targetEntityType,
  required int targetEntityId,
  Value<String?> details,
  Value<DateTime> timestamp,
});
typedef $$AuditLogsTableUpdateCompanionBuilder = AuditLogsCompanion Function({
  Value<int> id,
  Value<int> actorId,
  Value<String> action,
  Value<String> targetEntityType,
  Value<int> targetEntityId,
  Value<String?> details,
  Value<DateTime> timestamp,
});

final class $$AuditLogsTableReferences
    extends BaseReferences<_$PosDatabase, $AuditLogsTable, AuditLog> {
  $$AuditLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _actorIdTable(_$PosDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.auditLogs.actorId, db.users.id));

  $$UsersTableProcessedTableManager get actorId {
    final $_column = $_itemColumn<int>('actor_id')!;

    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_actorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AuditLogsTableFilterComposer
    extends Composer<_$PosDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetEntityType => $composableBuilder(
      column: $table.targetEntityType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetEntityId => $composableBuilder(
      column: $table.targetEntityId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get actorId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.actorId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$PosDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetEntityType => $composableBuilder(
      column: $table.targetEntityType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetEntityId => $composableBuilder(
      column: $table.targetEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get details => $composableBuilder(
      column: $table.details, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get actorId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.actorId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$PosDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get targetEntityType => $composableBuilder(
      column: $table.targetEntityType, builder: (column) => column);

  GeneratedColumn<int> get targetEntityId => $composableBuilder(
      column: $table.targetEntityId, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$UsersTableAnnotationComposer get actorId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.actorId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableTableManager extends RootTableManager<
    _$PosDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, $$AuditLogsTableReferences),
    AuditLog,
    PrefetchHooks Function({bool actorId})> {
  $$AuditLogsTableTableManager(_$PosDatabase db, $AuditLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> actorId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> targetEntityType = const Value.absent(),
            Value<int> targetEntityId = const Value.absent(),
            Value<String?> details = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              AuditLogsCompanion(
            id: id,
            actorId: actorId,
            action: action,
            targetEntityType: targetEntityType,
            targetEntityId: targetEntityId,
            details: details,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int actorId,
            required String action,
            required String targetEntityType,
            required int targetEntityId,
            Value<String?> details = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              AuditLogsCompanion.insert(
            id: id,
            actorId: actorId,
            action: action,
            targetEntityType: targetEntityType,
            targetEntityId: targetEntityId,
            details: details,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AuditLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({actorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (actorId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.actorId,
                    referencedTable:
                        $$AuditLogsTableReferences._actorIdTable(db),
                    referencedColumn:
                        $$AuditLogsTableReferences._actorIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AuditLogsTableProcessedTableManager = ProcessedTableManager<
    _$PosDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, $$AuditLogsTableReferences),
    AuditLog,
    PrefetchHooks Function({bool actorId})>;

class $PosDatabaseManager {
  final _$PosDatabase _db;
  $PosDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$CashSessionsTableTableManager get cashSessions =>
      $$CashSessionsTableTableManager(_db, _db.cashSessions);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$InventorySessionsTableTableManager get inventorySessions =>
      $$InventorySessionsTableTableManager(_db, _db.inventorySessions);
  $$InventoryLinesTableTableManager get inventoryLines =>
      $$InventoryLinesTableTableManager(_db, _db.inventoryLines);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$ShopsTableTableManager get shops =>
      $$ShopsTableTableManager(_db, _db.shops);
  $$StockTransfersTableTableManager get stockTransfers =>
      $$StockTransfersTableTableManager(_db, _db.stockTransfers);
  $$StockTransferItemsTableTableManager get stockTransferItems =>
      $$StockTransferItemsTableTableManager(_db, _db.stockTransferItems);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
}
