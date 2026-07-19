// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hub_database.dart';

// ignore_for_file: type=lint
class $ReceivedPayloadsTable extends ReceivedPayloads
    with TableInfo<$ReceivedPayloadsTable, ReceivedPayload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceivedPayloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceUuidMeta = const VerificationMeta(
    'deviceUuid',
  );
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
    'device_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('received'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idempotencyKey,
    payloadJson,
    deviceUuid,
    status,
    attempts,
    lastError,
    receivedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'received_payloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceivedPayload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('device_uuid')) {
      context.handle(
        _deviceUuidMeta,
        deviceUuid.isAcceptableOrUnknown(data['device_uuid']!, _deviceUuidMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idempotencyKey};
  @override
  ReceivedPayload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivedPayload(
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReceivedPayloadsTable createAlias(String alias) {
    return $ReceivedPayloadsTable(attachedDatabase, alias);
  }
}

class ReceivedPayload extends DataClass implements Insertable<ReceivedPayload> {
  /// The idempotency key carried in the payload — dedupes re-received packets.
  final String idempotencyKey;

  /// The raw decrypted payload JSON exactly as reassembled from BLE chunks.
  final String payloadJson;
  final String? deviceUuid;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime receivedAt;
  final DateTime updatedAt;
  const ReceivedPayload({
    required this.idempotencyKey,
    required this.payloadJson,
    this.deviceUuid,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.receivedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || deviceUuid != null) {
      map['device_uuid'] = Variable<String>(deviceUuid);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReceivedPayloadsCompanion toCompanion(bool nullToAbsent) {
    return ReceivedPayloadsCompanion(
      idempotencyKey: Value(idempotencyKey),
      payloadJson: Value(payloadJson),
      deviceUuid: deviceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceUuid),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      receivedAt: Value(receivedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReceivedPayload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivedPayload(
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      deviceUuid: serializer.fromJson<String?>(json['deviceUuid']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'deviceUuid': serializer.toJson<String?>(deviceUuid),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReceivedPayload copyWith({
    String? idempotencyKey,
    String? payloadJson,
    Value<String?> deviceUuid = const Value.absent(),
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? receivedAt,
    DateTime? updatedAt,
  }) => ReceivedPayload(
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    payloadJson: payloadJson ?? this.payloadJson,
    deviceUuid: deviceUuid.present ? deviceUuid.value : this.deviceUuid,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    receivedAt: receivedAt ?? this.receivedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReceivedPayload copyWithCompanion(ReceivedPayloadsCompanion data) {
    return ReceivedPayload(
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedPayload(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idempotencyKey,
    payloadJson,
    deviceUuid,
    status,
    attempts,
    lastError,
    receivedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivedPayload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.payloadJson == this.payloadJson &&
          other.deviceUuid == this.deviceUuid &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.receivedAt == this.receivedAt &&
          other.updatedAt == this.updatedAt);
}

class ReceivedPayloadsCompanion extends UpdateCompanion<ReceivedPayload> {
  final Value<String> idempotencyKey;
  final Value<String> payloadJson;
  final Value<String?> deviceUuid;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> receivedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReceivedPayloadsCompanion({
    this.idempotencyKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceivedPayloadsCompanion.insert({
    required String idempotencyKey,
    required String payloadJson,
    this.deviceUuid = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       payloadJson = Value(payloadJson);
  static Insertable<ReceivedPayload> custom({
    Expression<String>? idempotencyKey,
    Expression<String>? payloadJson,
    Expression<String>? deviceUuid,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (receivedAt != null) 'received_at': receivedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceivedPayloadsCompanion copyWith({
    Value<String>? idempotencyKey,
    Value<String>? payloadJson,
    Value<String?>? deviceUuid,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? receivedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReceivedPayloadsCompanion(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payloadJson: payloadJson ?? this.payloadJson,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      receivedAt: receivedAt ?? this.receivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
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
    return (StringBuffer('ReceivedPayloadsCompanion(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadLogTable extends UploadLog
    with TableInfo<$UploadLogTable, UploadLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('info'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, message, level, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $UploadLogTable createAlias(String alias) {
    return $UploadLogTable(attachedDatabase, alias);
  }
}

class UploadLogData extends DataClass implements Insertable<UploadLogData> {
  final int id;
  final String message;
  final String level;
  final DateTime at;
  const UploadLogData({
    required this.id,
    required this.message,
    required this.level,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message'] = Variable<String>(message);
    map['level'] = Variable<String>(level);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  UploadLogCompanion toCompanion(bool nullToAbsent) {
    return UploadLogCompanion(
      id: Value(id),
      message: Value(message),
      level: Value(level),
      at: Value(at),
    );
  }

  factory UploadLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadLogData(
      id: serializer.fromJson<int>(json['id']),
      message: serializer.fromJson<String>(json['message']),
      level: serializer.fromJson<String>(json['level']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'message': serializer.toJson<String>(message),
      'level': serializer.toJson<String>(level),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  UploadLogData copyWith({
    int? id,
    String? message,
    String? level,
    DateTime? at,
  }) => UploadLogData(
    id: id ?? this.id,
    message: message ?? this.message,
    level: level ?? this.level,
    at: at ?? this.at,
  );
  UploadLogData copyWithCompanion(UploadLogCompanion data) {
    return UploadLogData(
      id: data.id.present ? data.id.value : this.id,
      message: data.message.present ? data.message.value : this.message,
      level: data.level.present ? data.level.value : this.level,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadLogData(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('level: $level, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, message, level, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadLogData &&
          other.id == this.id &&
          other.message == this.message &&
          other.level == this.level &&
          other.at == this.at);
}

class UploadLogCompanion extends UpdateCompanion<UploadLogData> {
  final Value<int> id;
  final Value<String> message;
  final Value<String> level;
  final Value<DateTime> at;
  const UploadLogCompanion({
    this.id = const Value.absent(),
    this.message = const Value.absent(),
    this.level = const Value.absent(),
    this.at = const Value.absent(),
  });
  UploadLogCompanion.insert({
    this.id = const Value.absent(),
    required String message,
    this.level = const Value.absent(),
    this.at = const Value.absent(),
  }) : message = Value(message);
  static Insertable<UploadLogData> custom({
    Expression<int>? id,
    Expression<String>? message,
    Expression<String>? level,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (message != null) 'message': message,
      if (level != null) 'level': level,
      if (at != null) 'at': at,
    });
  }

  UploadLogCompanion copyWith({
    Value<int>? id,
    Value<String>? message,
    Value<String>? level,
    Value<DateTime>? at,
  }) {
    return UploadLogCompanion(
      id: id ?? this.id,
      message: message ?? this.message,
      level: level ?? this.level,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadLogCompanion(')
          ..write('id: $id, ')
          ..write('message: $message, ')
          ..write('level: $level, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

abstract class _$HubDatabase extends GeneratedDatabase {
  _$HubDatabase(QueryExecutor e) : super(e);
  $HubDatabaseManager get managers => $HubDatabaseManager(this);
  late final $ReceivedPayloadsTable receivedPayloads = $ReceivedPayloadsTable(
    this,
  );
  late final $UploadLogTable uploadLog = $UploadLogTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    receivedPayloads,
    uploadLog,
  ];
}

typedef $$ReceivedPayloadsTableCreateCompanionBuilder =
    ReceivedPayloadsCompanion Function({
      required String idempotencyKey,
      required String payloadJson,
      Value<String?> deviceUuid,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> receivedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ReceivedPayloadsTableUpdateCompanionBuilder =
    ReceivedPayloadsCompanion Function({
      Value<String> idempotencyKey,
      Value<String> payloadJson,
      Value<String?> deviceUuid,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> receivedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReceivedPayloadsTableFilterComposer
    extends Composer<_$HubDatabase, $ReceivedPayloadsTable> {
  $$ReceivedPayloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceivedPayloadsTableOrderingComposer
    extends Composer<_$HubDatabase, $ReceivedPayloadsTable> {
  $$ReceivedPayloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceivedPayloadsTableAnnotationComposer
    extends Composer<_$HubDatabase, $ReceivedPayloadsTable> {
  $$ReceivedPayloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReceivedPayloadsTableTableManager
    extends
        RootTableManager<
          _$HubDatabase,
          $ReceivedPayloadsTable,
          ReceivedPayload,
          $$ReceivedPayloadsTableFilterComposer,
          $$ReceivedPayloadsTableOrderingComposer,
          $$ReceivedPayloadsTableAnnotationComposer,
          $$ReceivedPayloadsTableCreateCompanionBuilder,
          $$ReceivedPayloadsTableUpdateCompanionBuilder,
          (
            ReceivedPayload,
            BaseReferences<
              _$HubDatabase,
              $ReceivedPayloadsTable,
              ReceivedPayload
            >,
          ),
          ReceivedPayload,
          PrefetchHooks Function()
        > {
  $$ReceivedPayloadsTableTableManager(
    _$HubDatabase db,
    $ReceivedPayloadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceivedPayloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceivedPayloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceivedPayloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> deviceUuid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceivedPayloadsCompanion(
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                deviceUuid: deviceUuid,
                status: status,
                attempts: attempts,
                lastError: lastError,
                receivedAt: receivedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idempotencyKey,
                required String payloadJson,
                Value<String?> deviceUuid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceivedPayloadsCompanion.insert(
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                deviceUuid: deviceUuid,
                status: status,
                attempts: attempts,
                lastError: lastError,
                receivedAt: receivedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceivedPayloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$HubDatabase,
      $ReceivedPayloadsTable,
      ReceivedPayload,
      $$ReceivedPayloadsTableFilterComposer,
      $$ReceivedPayloadsTableOrderingComposer,
      $$ReceivedPayloadsTableAnnotationComposer,
      $$ReceivedPayloadsTableCreateCompanionBuilder,
      $$ReceivedPayloadsTableUpdateCompanionBuilder,
      (
        ReceivedPayload,
        BaseReferences<_$HubDatabase, $ReceivedPayloadsTable, ReceivedPayload>,
      ),
      ReceivedPayload,
      PrefetchHooks Function()
    >;
typedef $$UploadLogTableCreateCompanionBuilder =
    UploadLogCompanion Function({
      Value<int> id,
      required String message,
      Value<String> level,
      Value<DateTime> at,
    });
typedef $$UploadLogTableUpdateCompanionBuilder =
    UploadLogCompanion Function({
      Value<int> id,
      Value<String> message,
      Value<String> level,
      Value<DateTime> at,
    });

class $$UploadLogTableFilterComposer
    extends Composer<_$HubDatabase, $UploadLogTable> {
  $$UploadLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UploadLogTableOrderingComposer
    extends Composer<_$HubDatabase, $UploadLogTable> {
  $$UploadLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadLogTableAnnotationComposer
    extends Composer<_$HubDatabase, $UploadLogTable> {
  $$UploadLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$UploadLogTableTableManager
    extends
        RootTableManager<
          _$HubDatabase,
          $UploadLogTable,
          UploadLogData,
          $$UploadLogTableFilterComposer,
          $$UploadLogTableOrderingComposer,
          $$UploadLogTableAnnotationComposer,
          $$UploadLogTableCreateCompanionBuilder,
          $$UploadLogTableUpdateCompanionBuilder,
          (
            UploadLogData,
            BaseReferences<_$HubDatabase, $UploadLogTable, UploadLogData>,
          ),
          UploadLogData,
          PrefetchHooks Function()
        > {
  $$UploadLogTableTableManager(_$HubDatabase db, $UploadLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => UploadLogCompanion(
                id: id,
                message: message,
                level: level,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String message,
                Value<String> level = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => UploadLogCompanion.insert(
                id: id,
                message: message,
                level: level,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadLogTableProcessedTableManager =
    ProcessedTableManager<
      _$HubDatabase,
      $UploadLogTable,
      UploadLogData,
      $$UploadLogTableFilterComposer,
      $$UploadLogTableOrderingComposer,
      $$UploadLogTableAnnotationComposer,
      $$UploadLogTableCreateCompanionBuilder,
      $$UploadLogTableUpdateCompanionBuilder,
      (
        UploadLogData,
        BaseReferences<_$HubDatabase, $UploadLogTable, UploadLogData>,
      ),
      UploadLogData,
      PrefetchHooks Function()
    >;

class $HubDatabaseManager {
  final _$HubDatabase _db;
  $HubDatabaseManager(this._db);
  $$ReceivedPayloadsTableTableManager get receivedPayloads =>
      $$ReceivedPayloadsTableTableManager(_db, _db.receivedPayloads);
  $$UploadLogTableTableManager get uploadLog =>
      $$UploadLogTableTableManager(_db, _db.uploadLog);
}
