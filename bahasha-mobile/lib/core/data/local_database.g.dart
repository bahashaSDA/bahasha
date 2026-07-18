// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUserIdMeta = const VerificationMeta(
    'serverUserId',
  );
  @override
  late final GeneratedColumn<String> serverUserId = GeneratedColumn<String>(
    'server_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _churchIdMeta = const VerificationMeta(
    'churchId',
  );
  @override
  late final GeneratedColumn<String> churchId = GeneratedColumn<String>(
    'church_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipStatusMeta = const VerificationMeta(
    'membershipStatus',
  );
  @override
  late final GeneratedColumn<String> membershipStatus = GeneratedColumn<String>(
    'membership_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _registeredAtMeta = const VerificationMeta(
    'registeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> registeredAt = GeneratedColumn<DateTime>(
    'registered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientUuid,
    serverUserId,
    fullName,
    phone,
    churchId,
    membershipStatus,
    visibility,
    synced,
    registeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('server_user_id')) {
      context.handle(
        _serverUserIdMeta,
        serverUserId.isAcceptableOrUnknown(
          data['server_user_id']!,
          _serverUserIdMeta,
        ),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('church_id')) {
      context.handle(
        _churchIdMeta,
        churchId.isAcceptableOrUnknown(data['church_id']!, _churchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_churchIdMeta);
    }
    if (data.containsKey('membership_status')) {
      context.handle(
        _membershipStatusMeta,
        membershipStatus.isAcceptableOrUnknown(
          data['membership_status']!,
          _membershipStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipStatusMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('registered_at')) {
      context.handle(
        _registeredAtMeta,
        registeredAt.isAcceptableOrUnknown(
          data['registered_at']!,
          _registeredAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      serverUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_user_id'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      churchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}church_id'],
      )!,
      membershipStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_status'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      registeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registered_at'],
      )!,
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String clientUuid;
  final String? serverUserId;
  final String fullName;
  final String phone;
  final String churchId;
  final String membershipStatus;
  final String visibility;
  final bool synced;
  final DateTime registeredAt;
  const LocalUser({
    required this.clientUuid,
    this.serverUserId,
    required this.fullName,
    required this.phone,
    required this.churchId,
    required this.membershipStatus,
    required this.visibility,
    required this.synced,
    required this.registeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    if (!nullToAbsent || serverUserId != null) {
      map['server_user_id'] = Variable<String>(serverUserId);
    }
    map['full_name'] = Variable<String>(fullName);
    map['phone'] = Variable<String>(phone);
    map['church_id'] = Variable<String>(churchId);
    map['membership_status'] = Variable<String>(membershipStatus);
    map['visibility'] = Variable<String>(visibility);
    map['synced'] = Variable<bool>(synced);
    map['registered_at'] = Variable<DateTime>(registeredAt);
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      clientUuid: Value(clientUuid),
      serverUserId: serverUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUserId),
      fullName: Value(fullName),
      phone: Value(phone),
      churchId: Value(churchId),
      membershipStatus: Value(membershipStatus),
      visibility: Value(visibility),
      synced: Value(synced),
      registeredAt: Value(registeredAt),
    );
  }

  factory LocalUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      serverUserId: serializer.fromJson<String?>(json['serverUserId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phone: serializer.fromJson<String>(json['phone']),
      churchId: serializer.fromJson<String>(json['churchId']),
      membershipStatus: serializer.fromJson<String>(json['membershipStatus']),
      visibility: serializer.fromJson<String>(json['visibility']),
      synced: serializer.fromJson<bool>(json['synced']),
      registeredAt: serializer.fromJson<DateTime>(json['registeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'serverUserId': serializer.toJson<String?>(serverUserId),
      'fullName': serializer.toJson<String>(fullName),
      'phone': serializer.toJson<String>(phone),
      'churchId': serializer.toJson<String>(churchId),
      'membershipStatus': serializer.toJson<String>(membershipStatus),
      'visibility': serializer.toJson<String>(visibility),
      'synced': serializer.toJson<bool>(synced),
      'registeredAt': serializer.toJson<DateTime>(registeredAt),
    };
  }

  LocalUser copyWith({
    String? clientUuid,
    Value<String?> serverUserId = const Value.absent(),
    String? fullName,
    String? phone,
    String? churchId,
    String? membershipStatus,
    String? visibility,
    bool? synced,
    DateTime? registeredAt,
  }) => LocalUser(
    clientUuid: clientUuid ?? this.clientUuid,
    serverUserId: serverUserId.present ? serverUserId.value : this.serverUserId,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    churchId: churchId ?? this.churchId,
    membershipStatus: membershipStatus ?? this.membershipStatus,
    visibility: visibility ?? this.visibility,
    synced: synced ?? this.synced,
    registeredAt: registeredAt ?? this.registeredAt,
  );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      serverUserId: data.serverUserId.present
          ? data.serverUserId.value
          : this.serverUserId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phone: data.phone.present ? data.phone.value : this.phone,
      churchId: data.churchId.present ? data.churchId.value : this.churchId,
      membershipStatus: data.membershipStatus.present
          ? data.membershipStatus.value
          : this.membershipStatus,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      synced: data.synced.present ? data.synced.value : this.synced,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverUserId: $serverUserId, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('churchId: $churchId, ')
          ..write('membershipStatus: $membershipStatus, ')
          ..write('visibility: $visibility, ')
          ..write('synced: $synced, ')
          ..write('registeredAt: $registeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientUuid,
    serverUserId,
    fullName,
    phone,
    churchId,
    membershipStatus,
    visibility,
    synced,
    registeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.clientUuid == this.clientUuid &&
          other.serverUserId == this.serverUserId &&
          other.fullName == this.fullName &&
          other.phone == this.phone &&
          other.churchId == this.churchId &&
          other.membershipStatus == this.membershipStatus &&
          other.visibility == this.visibility &&
          other.synced == this.synced &&
          other.registeredAt == this.registeredAt);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> clientUuid;
  final Value<String?> serverUserId;
  final Value<String> fullName;
  final Value<String> phone;
  final Value<String> churchId;
  final Value<String> membershipStatus;
  final Value<String> visibility;
  final Value<bool> synced;
  final Value<DateTime> registeredAt;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.clientUuid = const Value.absent(),
    this.serverUserId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    this.churchId = const Value.absent(),
    this.membershipStatus = const Value.absent(),
    this.visibility = const Value.absent(),
    this.synced = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String clientUuid,
    this.serverUserId = const Value.absent(),
    required String fullName,
    required String phone,
    required String churchId,
    required String membershipStatus,
    this.visibility = const Value.absent(),
    this.synced = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       fullName = Value(fullName),
       phone = Value(phone),
       churchId = Value(churchId),
       membershipStatus = Value(membershipStatus);
  static Insertable<LocalUser> custom({
    Expression<String>? clientUuid,
    Expression<String>? serverUserId,
    Expression<String>? fullName,
    Expression<String>? phone,
    Expression<String>? churchId,
    Expression<String>? membershipStatus,
    Expression<String>? visibility,
    Expression<bool>? synced,
    Expression<DateTime>? registeredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (serverUserId != null) 'server_user_id': serverUserId,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (churchId != null) 'church_id': churchId,
      if (membershipStatus != null) 'membership_status': membershipStatus,
      if (visibility != null) 'visibility': visibility,
      if (synced != null) 'synced': synced,
      if (registeredAt != null) 'registered_at': registeredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith({
    Value<String>? clientUuid,
    Value<String?>? serverUserId,
    Value<String>? fullName,
    Value<String>? phone,
    Value<String>? churchId,
    Value<String>? membershipStatus,
    Value<String>? visibility,
    Value<bool>? synced,
    Value<DateTime>? registeredAt,
    Value<int>? rowid,
  }) {
    return LocalUsersCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      serverUserId: serverUserId ?? this.serverUserId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      churchId: churchId ?? this.churchId,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      visibility: visibility ?? this.visibility,
      synced: synced ?? this.synced,
      registeredAt: registeredAt ?? this.registeredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (serverUserId.present) {
      map['server_user_id'] = Variable<String>(serverUserId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (churchId.present) {
      map['church_id'] = Variable<String>(churchId.value);
    }
    if (membershipStatus.present) {
      map['membership_status'] = Variable<String>(membershipStatus.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<DateTime>(registeredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('serverUserId: $serverUserId, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('churchId: $churchId, ')
          ..write('membershipStatus: $membershipStatus, ')
          ..write('visibility: $visibility, ')
          ..write('synced: $synced, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContributionsTable extends Contributions
    with TableInfo<$ContributionsTable, Contribution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _churchIdMeta = const VerificationMeta(
    'churchId',
  );
  @override
  late final GeneratedColumn<String> churchId = GeneratedColumn<String>(
    'church_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<int> totalAmount = GeneratedColumn<int>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allocationsJsonMeta = const VerificationMeta(
    'allocationsJson',
  );
  @override
  late final GeneratedColumn<String> allocationsJson = GeneratedColumn<String>(
    'allocations_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anonymousMeta = const VerificationMeta(
    'anonymous',
  );
  @override
  late final GeneratedColumn<bool> anonymous = GeneratedColumn<bool>(
    'anonymous',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("anonymous" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _counterMeta = const VerificationMeta(
    'counter',
  );
  @override
  late final GeneratedColumn<int> counter = GeneratedColumn<int>(
    'counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonceMeta = const VerificationMeta('nonce');
  @override
  late final GeneratedColumn<String> nonce = GeneratedColumn<String>(
    'nonce',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureReasonMeta = const VerificationMeta(
    'failureReason',
  );
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
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
    id,
    churchId,
    totalAmount,
    allocationsJson,
    anonymous,
    status,
    counter,
    nonce,
    signature,
    failureReason,
    retryCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contributions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contribution> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('church_id')) {
      context.handle(
        _churchIdMeta,
        churchId.isAcceptableOrUnknown(data['church_id']!, _churchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_churchIdMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('allocations_json')) {
      context.handle(
        _allocationsJsonMeta,
        allocationsJson.isAcceptableOrUnknown(
          data['allocations_json']!,
          _allocationsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allocationsJsonMeta);
    }
    if (data.containsKey('anonymous')) {
      context.handle(
        _anonymousMeta,
        anonymous.isAcceptableOrUnknown(data['anonymous']!, _anonymousMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('counter')) {
      context.handle(
        _counterMeta,
        counter.isAcceptableOrUnknown(data['counter']!, _counterMeta),
      );
    } else if (isInserting) {
      context.missing(_counterMeta);
    }
    if (data.containsKey('nonce')) {
      context.handle(
        _nonceMeta,
        nonce.isAcceptableOrUnknown(data['nonce']!, _nonceMeta),
      );
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
        _failureReasonMeta,
        failureReason.isAcceptableOrUnknown(
          data['failure_reason']!,
          _failureReasonMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contribution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contribution(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      churchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}church_id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_amount'],
      )!,
      allocationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allocations_json'],
      )!,
      anonymous: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}anonymous'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      counter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counter'],
      )!,
      nonce: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nonce'],
      ),
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      ),
      failureReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_reason'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContributionsTable createAlias(String alias) {
    return $ContributionsTable(attachedDatabase, alias);
  }
}

class Contribution extends DataClass implements Insertable<Contribution> {
  final String id;
  final String churchId;
  final int totalAmount;
  final String allocationsJson;
  final bool anonymous;
  final String status;
  final int counter;
  final String? nonce;
  final String? signature;
  final String? failureReason;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Contribution({
    required this.id,
    required this.churchId,
    required this.totalAmount,
    required this.allocationsJson,
    required this.anonymous,
    required this.status,
    required this.counter,
    this.nonce,
    this.signature,
    this.failureReason,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['church_id'] = Variable<String>(churchId);
    map['total_amount'] = Variable<int>(totalAmount);
    map['allocations_json'] = Variable<String>(allocationsJson);
    map['anonymous'] = Variable<bool>(anonymous);
    map['status'] = Variable<String>(status);
    map['counter'] = Variable<int>(counter);
    if (!nullToAbsent || nonce != null) {
      map['nonce'] = Variable<String>(nonce);
    }
    if (!nullToAbsent || signature != null) {
      map['signature'] = Variable<String>(signature);
    }
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContributionsCompanion toCompanion(bool nullToAbsent) {
    return ContributionsCompanion(
      id: Value(id),
      churchId: Value(churchId),
      totalAmount: Value(totalAmount),
      allocationsJson: Value(allocationsJson),
      anonymous: Value(anonymous),
      status: Value(status),
      counter: Value(counter),
      nonce: nonce == null && nullToAbsent
          ? const Value.absent()
          : Value(nonce),
      signature: signature == null && nullToAbsent
          ? const Value.absent()
          : Value(signature),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Contribution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contribution(
      id: serializer.fromJson<String>(json['id']),
      churchId: serializer.fromJson<String>(json['churchId']),
      totalAmount: serializer.fromJson<int>(json['totalAmount']),
      allocationsJson: serializer.fromJson<String>(json['allocationsJson']),
      anonymous: serializer.fromJson<bool>(json['anonymous']),
      status: serializer.fromJson<String>(json['status']),
      counter: serializer.fromJson<int>(json['counter']),
      nonce: serializer.fromJson<String?>(json['nonce']),
      signature: serializer.fromJson<String?>(json['signature']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'churchId': serializer.toJson<String>(churchId),
      'totalAmount': serializer.toJson<int>(totalAmount),
      'allocationsJson': serializer.toJson<String>(allocationsJson),
      'anonymous': serializer.toJson<bool>(anonymous),
      'status': serializer.toJson<String>(status),
      'counter': serializer.toJson<int>(counter),
      'nonce': serializer.toJson<String?>(nonce),
      'signature': serializer.toJson<String?>(signature),
      'failureReason': serializer.toJson<String?>(failureReason),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Contribution copyWith({
    String? id,
    String? churchId,
    int? totalAmount,
    String? allocationsJson,
    bool? anonymous,
    String? status,
    int? counter,
    Value<String?> nonce = const Value.absent(),
    Value<String?> signature = const Value.absent(),
    Value<String?> failureReason = const Value.absent(),
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Contribution(
    id: id ?? this.id,
    churchId: churchId ?? this.churchId,
    totalAmount: totalAmount ?? this.totalAmount,
    allocationsJson: allocationsJson ?? this.allocationsJson,
    anonymous: anonymous ?? this.anonymous,
    status: status ?? this.status,
    counter: counter ?? this.counter,
    nonce: nonce.present ? nonce.value : this.nonce,
    signature: signature.present ? signature.value : this.signature,
    failureReason: failureReason.present
        ? failureReason.value
        : this.failureReason,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Contribution copyWithCompanion(ContributionsCompanion data) {
    return Contribution(
      id: data.id.present ? data.id.value : this.id,
      churchId: data.churchId.present ? data.churchId.value : this.churchId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      allocationsJson: data.allocationsJson.present
          ? data.allocationsJson.value
          : this.allocationsJson,
      anonymous: data.anonymous.present ? data.anonymous.value : this.anonymous,
      status: data.status.present ? data.status.value : this.status,
      counter: data.counter.present ? data.counter.value : this.counter,
      nonce: data.nonce.present ? data.nonce.value : this.nonce,
      signature: data.signature.present ? data.signature.value : this.signature,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contribution(')
          ..write('id: $id, ')
          ..write('churchId: $churchId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('allocationsJson: $allocationsJson, ')
          ..write('anonymous: $anonymous, ')
          ..write('status: $status, ')
          ..write('counter: $counter, ')
          ..write('nonce: $nonce, ')
          ..write('signature: $signature, ')
          ..write('failureReason: $failureReason, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    churchId,
    totalAmount,
    allocationsJson,
    anonymous,
    status,
    counter,
    nonce,
    signature,
    failureReason,
    retryCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contribution &&
          other.id == this.id &&
          other.churchId == this.churchId &&
          other.totalAmount == this.totalAmount &&
          other.allocationsJson == this.allocationsJson &&
          other.anonymous == this.anonymous &&
          other.status == this.status &&
          other.counter == this.counter &&
          other.nonce == this.nonce &&
          other.signature == this.signature &&
          other.failureReason == this.failureReason &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContributionsCompanion extends UpdateCompanion<Contribution> {
  final Value<String> id;
  final Value<String> churchId;
  final Value<int> totalAmount;
  final Value<String> allocationsJson;
  final Value<bool> anonymous;
  final Value<String> status;
  final Value<int> counter;
  final Value<String?> nonce;
  final Value<String?> signature;
  final Value<String?> failureReason;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ContributionsCompanion({
    this.id = const Value.absent(),
    this.churchId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.allocationsJson = const Value.absent(),
    this.anonymous = const Value.absent(),
    this.status = const Value.absent(),
    this.counter = const Value.absent(),
    this.nonce = const Value.absent(),
    this.signature = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContributionsCompanion.insert({
    required String id,
    required String churchId,
    required int totalAmount,
    required String allocationsJson,
    this.anonymous = const Value.absent(),
    this.status = const Value.absent(),
    required int counter,
    this.nonce = const Value.absent(),
    this.signature = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       churchId = Value(churchId),
       totalAmount = Value(totalAmount),
       allocationsJson = Value(allocationsJson),
       counter = Value(counter);
  static Insertable<Contribution> custom({
    Expression<String>? id,
    Expression<String>? churchId,
    Expression<int>? totalAmount,
    Expression<String>? allocationsJson,
    Expression<bool>? anonymous,
    Expression<String>? status,
    Expression<int>? counter,
    Expression<String>? nonce,
    Expression<String>? signature,
    Expression<String>? failureReason,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (churchId != null) 'church_id': churchId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (allocationsJson != null) 'allocations_json': allocationsJson,
      if (anonymous != null) 'anonymous': anonymous,
      if (status != null) 'status': status,
      if (counter != null) 'counter': counter,
      if (nonce != null) 'nonce': nonce,
      if (signature != null) 'signature': signature,
      if (failureReason != null) 'failure_reason': failureReason,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContributionsCompanion copyWith({
    Value<String>? id,
    Value<String>? churchId,
    Value<int>? totalAmount,
    Value<String>? allocationsJson,
    Value<bool>? anonymous,
    Value<String>? status,
    Value<int>? counter,
    Value<String?>? nonce,
    Value<String?>? signature,
    Value<String?>? failureReason,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContributionsCompanion(
      id: id ?? this.id,
      churchId: churchId ?? this.churchId,
      totalAmount: totalAmount ?? this.totalAmount,
      allocationsJson: allocationsJson ?? this.allocationsJson,
      anonymous: anonymous ?? this.anonymous,
      status: status ?? this.status,
      counter: counter ?? this.counter,
      nonce: nonce ?? this.nonce,
      signature: signature ?? this.signature,
      failureReason: failureReason ?? this.failureReason,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (churchId.present) {
      map['church_id'] = Variable<String>(churchId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<int>(totalAmount.value);
    }
    if (allocationsJson.present) {
      map['allocations_json'] = Variable<String>(allocationsJson.value);
    }
    if (anonymous.present) {
      map['anonymous'] = Variable<bool>(anonymous.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (counter.present) {
      map['counter'] = Variable<int>(counter.value);
    }
    if (nonce.present) {
      map['nonce'] = Variable<String>(nonce.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('ContributionsCompanion(')
          ..write('id: $id, ')
          ..write('churchId: $churchId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('allocationsJson: $allocationsJson, ')
          ..write('anonymous: $anonymous, ')
          ..write('status: $status, ')
          ..write('counter: $counter, ')
          ..write('nonce: $nonce, ')
          ..write('signature: $signature, ')
          ..write('failureReason: $failureReason, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedChurchesTable extends CachedChurches
    with TableInfo<$CachedChurchesTable, CachedChurche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedChurchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, slug, publicKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_churches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedChurche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedChurche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedChurche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      ),
    );
  }

  @override
  $CachedChurchesTable createAlias(String alias) {
    return $CachedChurchesTable(attachedDatabase, alias);
  }
}

class CachedChurche extends DataClass implements Insertable<CachedChurche> {
  final String id;
  final String name;
  final String slug;
  final String? publicKey;
  const CachedChurche({
    required this.id,
    required this.name,
    required this.slug,
    this.publicKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    return map;
  }

  CachedChurchesCompanion toCompanion(bool nullToAbsent) {
    return CachedChurchesCompanion(
      id: Value(id),
      name: Value(name),
      slug: Value(slug),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
    );
  }

  factory CachedChurche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedChurche(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      slug: serializer.fromJson<String>(json['slug']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'slug': serializer.toJson<String>(slug),
      'publicKey': serializer.toJson<String?>(publicKey),
    };
  }

  CachedChurche copyWith({
    String? id,
    String? name,
    String? slug,
    Value<String?> publicKey = const Value.absent(),
  }) => CachedChurche(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    publicKey: publicKey.present ? publicKey.value : this.publicKey,
  );
  CachedChurche copyWithCompanion(CachedChurchesCompanion data) {
    return CachedChurche(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      slug: data.slug.present ? data.slug.value : this.slug,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedChurche(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('publicKey: $publicKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, slug, publicKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedChurche &&
          other.id == this.id &&
          other.name == this.name &&
          other.slug == this.slug &&
          other.publicKey == this.publicKey);
}

class CachedChurchesCompanion extends UpdateCompanion<CachedChurche> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> slug;
  final Value<String?> publicKey;
  final Value<int> rowid;
  const CachedChurchesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.slug = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedChurchesCompanion.insert({
    required String id,
    required String name,
    required String slug,
    this.publicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       slug = Value(slug);
  static Insertable<CachedChurche> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? slug,
    Expression<String>? publicKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (publicKey != null) 'public_key': publicKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedChurchesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? slug,
    Value<String?>? publicKey,
    Value<int>? rowid,
  }) {
    return CachedChurchesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      publicKey: publicKey ?? this.publicKey,
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
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedChurchesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('publicKey: $publicKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _churchIdMeta = const VerificationMeta(
    'churchId',
  );
  @override
  late final GeneratedColumn<String> churchId = GeneratedColumn<String>(
    'church_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fixedAmountMeta = const VerificationMeta(
    'fixedAmount',
  );
  @override
  late final GeneratedColumn<double> fixedAmount = GeneratedColumn<double>(
    'fixed_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _percentageHintMeta = const VerificationMeta(
    'percentageHint',
  );
  @override
  late final GeneratedColumn<double> percentageHint = GeneratedColumn<double>(
    'percentage_hint',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    churchId,
    name,
    description,
    fixedAmount,
    percentageHint,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('church_id')) {
      context.handle(
        _churchIdMeta,
        churchId.isAcceptableOrUnknown(data['church_id']!, _churchIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('fixed_amount')) {
      context.handle(
        _fixedAmountMeta,
        fixedAmount.isAcceptableOrUnknown(
          data['fixed_amount']!,
          _fixedAmountMeta,
        ),
      );
    }
    if (data.containsKey('percentage_hint')) {
      context.handle(
        _percentageHintMeta,
        percentageHint.isAcceptableOrUnknown(
          data['percentage_hint']!,
          _percentageHintMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      churchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}church_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      fixedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fixed_amount'],
      ),
      percentageHint: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentage_hint'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final String code;
  final String? churchId;
  final String name;
  final String description;
  final double? fixedAmount;
  final double? percentageHint;
  final int sortOrder;
  const CachedCategory({
    required this.code,
    this.churchId,
    required this.name,
    required this.description,
    this.fixedAmount,
    this.percentageHint,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || churchId != null) {
      map['church_id'] = Variable<String>(churchId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || fixedAmount != null) {
      map['fixed_amount'] = Variable<double>(fixedAmount);
    }
    if (!nullToAbsent || percentageHint != null) {
      map['percentage_hint'] = Variable<double>(percentageHint);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      code: Value(code),
      churchId: churchId == null && nullToAbsent
          ? const Value.absent()
          : Value(churchId),
      name: Value(name),
      description: Value(description),
      fixedAmount: fixedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedAmount),
      percentageHint: percentageHint == null && nullToAbsent
          ? const Value.absent()
          : Value(percentageHint),
      sortOrder: Value(sortOrder),
    );
  }

  factory CachedCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      code: serializer.fromJson<String>(json['code']),
      churchId: serializer.fromJson<String?>(json['churchId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      fixedAmount: serializer.fromJson<double?>(json['fixedAmount']),
      percentageHint: serializer.fromJson<double?>(json['percentageHint']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'churchId': serializer.toJson<String?>(churchId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'fixedAmount': serializer.toJson<double?>(fixedAmount),
      'percentageHint': serializer.toJson<double?>(percentageHint),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CachedCategory copyWith({
    String? code,
    Value<String?> churchId = const Value.absent(),
    String? name,
    String? description,
    Value<double?> fixedAmount = const Value.absent(),
    Value<double?> percentageHint = const Value.absent(),
    int? sortOrder,
  }) => CachedCategory(
    code: code ?? this.code,
    churchId: churchId.present ? churchId.value : this.churchId,
    name: name ?? this.name,
    description: description ?? this.description,
    fixedAmount: fixedAmount.present ? fixedAmount.value : this.fixedAmount,
    percentageHint: percentageHint.present
        ? percentageHint.value
        : this.percentageHint,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      code: data.code.present ? data.code.value : this.code,
      churchId: data.churchId.present ? data.churchId.value : this.churchId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      fixedAmount: data.fixedAmount.present
          ? data.fixedAmount.value
          : this.fixedAmount,
      percentageHint: data.percentageHint.present
          ? data.percentageHint.value
          : this.percentageHint,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('code: $code, ')
          ..write('churchId: $churchId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('fixedAmount: $fixedAmount, ')
          ..write('percentageHint: $percentageHint, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    churchId,
    name,
    description,
    fixedAmount,
    percentageHint,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.code == this.code &&
          other.churchId == this.churchId &&
          other.name == this.name &&
          other.description == this.description &&
          other.fixedAmount == this.fixedAmount &&
          other.percentageHint == this.percentageHint &&
          other.sortOrder == this.sortOrder);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<String> code;
  final Value<String?> churchId;
  final Value<String> name;
  final Value<String> description;
  final Value<double?> fixedAmount;
  final Value<double?> percentageHint;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CachedCategoriesCompanion({
    this.code = const Value.absent(),
    this.churchId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.fixedAmount = const Value.absent(),
    this.percentageHint = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    required String code,
    this.churchId = const Value.absent(),
    required String name,
    required String description,
    this.fixedAmount = const Value.absent(),
    this.percentageHint = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       description = Value(description);
  static Insertable<CachedCategory> custom({
    Expression<String>? code,
    Expression<String>? churchId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? fixedAmount,
    Expression<double>? percentageHint,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (churchId != null) 'church_id': churchId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (fixedAmount != null) 'fixed_amount': fixedAmount,
      if (percentageHint != null) 'percentage_hint': percentageHint,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCategoriesCompanion copyWith({
    Value<String>? code,
    Value<String?>? churchId,
    Value<String>? name,
    Value<String>? description,
    Value<double?>? fixedAmount,
    Value<double?>? percentageHint,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CachedCategoriesCompanion(
      code: code ?? this.code,
      churchId: churchId ?? this.churchId,
      name: name ?? this.name,
      description: description ?? this.description,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      percentageHint: percentageHint ?? this.percentageHint,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (churchId.present) {
      map['church_id'] = Variable<String>(churchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (fixedAmount.present) {
      map['fixed_amount'] = Variable<double>(fixedAmount.value);
    }
    if (percentageHint.present) {
      map['percentage_hint'] = Variable<double>(percentageHint.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('code: $code, ')
          ..write('churchId: $churchId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('fixedAmount: $fixedAmount, ')
          ..write('percentageHint: $percentageHint, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _primaryColorMeta = const VerificationMeta(
    'primaryColor',
  );
  @override
  late final GeneratedColumn<String> primaryColor = GeneratedColumn<String>(
    'primary_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#231F4F'),
  );
  static const VerificationMeta _accentColorMeta = const VerificationMeta(
    'accentColor',
  );
  @override
  late final GeneratedColumn<String> accentColor = GeneratedColumn<String>(
    'accent_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#89D385'),
  );
  static const VerificationMeta _backgroundColorMeta = const VerificationMeta(
    'backgroundColor',
  );
  @override
  late final GeneratedColumn<String> backgroundColor = GeneratedColumn<String>(
    'background_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#D1EFBD'),
  );
  static const VerificationMeta _fontScaleMeta = const VerificationMeta(
    'fontScale',
  );
  @override
  late final GeneratedColumn<double> fontScale = GeneratedColumn<double>(
    'font_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    primaryColor,
    accentColor,
    backgroundColor,
    fontScale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('primary_color')) {
      context.handle(
        _primaryColorMeta,
        primaryColor.isAcceptableOrUnknown(
          data['primary_color']!,
          _primaryColorMeta,
        ),
      );
    }
    if (data.containsKey('accent_color')) {
      context.handle(
        _accentColorMeta,
        accentColor.isAcceptableOrUnknown(
          data['accent_color']!,
          _accentColorMeta,
        ),
      );
    }
    if (data.containsKey('background_color')) {
      context.handle(
        _backgroundColorMeta,
        backgroundColor.isAcceptableOrUnknown(
          data['background_color']!,
          _backgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('font_scale')) {
      context.handle(
        _fontScaleMeta,
        fontScale.isAcceptableOrUnknown(data['font_scale']!, _fontScaleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      primaryColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_color'],
      )!,
      accentColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent_color'],
      )!,
      backgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_color'],
      )!,
      fontScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}font_scale'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String mode;
  final String primaryColor;
  final String accentColor;
  final String backgroundColor;
  final double fontScale;
  const AppSetting({
    required this.id,
    required this.mode,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.fontScale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mode'] = Variable<String>(mode);
    map['primary_color'] = Variable<String>(primaryColor);
    map['accent_color'] = Variable<String>(accentColor);
    map['background_color'] = Variable<String>(backgroundColor);
    map['font_scale'] = Variable<double>(fontScale);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      mode: Value(mode),
      primaryColor: Value(primaryColor),
      accentColor: Value(accentColor),
      backgroundColor: Value(backgroundColor),
      fontScale: Value(fontScale),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      primaryColor: serializer.fromJson<String>(json['primaryColor']),
      accentColor: serializer.fromJson<String>(json['accentColor']),
      backgroundColor: serializer.fromJson<String>(json['backgroundColor']),
      fontScale: serializer.fromJson<double>(json['fontScale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>(mode),
      'primaryColor': serializer.toJson<String>(primaryColor),
      'accentColor': serializer.toJson<String>(accentColor),
      'backgroundColor': serializer.toJson<String>(backgroundColor),
      'fontScale': serializer.toJson<double>(fontScale),
    };
  }

  AppSetting copyWith({
    int? id,
    String? mode,
    String? primaryColor,
    String? accentColor,
    String? backgroundColor,
    double? fontScale,
  }) => AppSetting(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    primaryColor: primaryColor ?? this.primaryColor,
    accentColor: accentColor ?? this.accentColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fontScale: fontScale ?? this.fontScale,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      primaryColor: data.primaryColor.present
          ? data.primaryColor.value
          : this.primaryColor,
      accentColor: data.accentColor.present
          ? data.accentColor.value
          : this.accentColor,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      fontScale: data.fontScale.present ? data.fontScale.value : this.fontScale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('accentColor: $accentColor, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('fontScale: $fontScale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    primaryColor,
    accentColor,
    backgroundColor,
    fontScale,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.primaryColor == this.primaryColor &&
          other.accentColor == this.accentColor &&
          other.backgroundColor == this.backgroundColor &&
          other.fontScale == this.fontScale);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> mode;
  final Value<String> primaryColor;
  final Value<String> accentColor;
  final Value<String> backgroundColor;
  final Value<double> fontScale;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.fontScale = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.primaryColor = const Value.absent(),
    this.accentColor = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.fontScale = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<String>? primaryColor,
    Expression<String>? accentColor,
    Expression<String>? backgroundColor,
    Expression<double>? fontScale,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (primaryColor != null) 'primary_color': primaryColor,
      if (accentColor != null) 'accent_color': accentColor,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (fontScale != null) 'font_scale': fontScale,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? mode,
    Value<String>? primaryColor,
    Value<String>? accentColor,
    Value<String>? backgroundColor,
    Value<double>? fontScale,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (primaryColor.present) {
      map['primary_color'] = Variable<String>(primaryColor.value);
    }
    if (accentColor.present) {
      map['accent_color'] = Variable<String>(accentColor.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<String>(backgroundColor.value);
    }
    if (fontScale.present) {
      map['font_scale'] = Variable<double>(fontScale.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('primaryColor: $primaryColor, ')
          ..write('accentColor: $accentColor, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('fontScale: $fontScale')
          ..write(')'))
        .toString();
  }
}

class $SignCounterTable extends SignCounter
    with TableInfo<$SignCounterTable, SignCounterData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignCounterTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sign_counter';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignCounterData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignCounterData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignCounterData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SignCounterTable createAlias(String alias) {
    return $SignCounterTable(attachedDatabase, alias);
  }
}

class SignCounterData extends DataClass implements Insertable<SignCounterData> {
  final int id;
  final int value;
  const SignCounterData({required this.id, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value'] = Variable<int>(value);
    return map;
  }

  SignCounterCompanion toCompanion(bool nullToAbsent) {
    return SignCounterCompanion(id: Value(id), value: Value(value));
  }

  factory SignCounterData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignCounterData(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'value': serializer.toJson<int>(value),
    };
  }

  SignCounterData copyWith({int? id, int? value}) =>
      SignCounterData(id: id ?? this.id, value: value ?? this.value);
  SignCounterData copyWithCompanion(SignCounterCompanion data) {
    return SignCounterData(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignCounterData(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignCounterData &&
          other.id == this.id &&
          other.value == this.value);
}

class SignCounterCompanion extends UpdateCompanion<SignCounterData> {
  final Value<int> id;
  final Value<int> value;
  const SignCounterCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
  });
  SignCounterCompanion.insert({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
  });
  static Insertable<SignCounterData> custom({
    Expression<int>? id,
    Expression<int>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
    });
  }

  SignCounterCompanion copyWith({Value<int>? id, Value<int>? value}) {
    return SignCounterCompanion(id: id ?? this.id, value: value ?? this.value);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignCounterCompanion(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $ContributionsTable contributions = $ContributionsTable(this);
  late final $CachedChurchesTable cachedChurches = $CachedChurchesTable(this);
  late final $CachedCategoriesTable cachedCategories = $CachedCategoriesTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SignCounterTable signCounter = $SignCounterTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localUsers,
    contributions,
    cachedChurches,
    cachedCategories,
    appSettings,
    signCounter,
  ];
}

typedef $$LocalUsersTableCreateCompanionBuilder =
    LocalUsersCompanion Function({
      required String clientUuid,
      Value<String?> serverUserId,
      required String fullName,
      required String phone,
      required String churchId,
      required String membershipStatus,
      Value<String> visibility,
      Value<bool> synced,
      Value<DateTime> registeredAt,
      Value<int> rowid,
    });
typedef $$LocalUsersTableUpdateCompanionBuilder =
    LocalUsersCompanion Function({
      Value<String> clientUuid,
      Value<String?> serverUserId,
      Value<String> fullName,
      Value<String> phone,
      Value<String> churchId,
      Value<String> membershipStatus,
      Value<String> visibility,
      Value<bool> synced,
      Value<DateTime> registeredAt,
      Value<int> rowid,
    });

class $$LocalUsersTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUserId => $composableBuilder(
    column: $table.serverUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get churchId => $composableBuilder(
    column: $table.churchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipStatus => $composableBuilder(
    column: $table.membershipStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUserId => $composableBuilder(
    column: $table.serverUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get churchId => $composableBuilder(
    column: $table.churchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipStatus => $composableBuilder(
    column: $table.membershipStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverUserId => $composableBuilder(
    column: $table.serverUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get churchId =>
      $composableBuilder(column: $table.churchId, builder: (column) => column);

  GeneratedColumn<String> get membershipStatus => $composableBuilder(
    column: $table.membershipStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => column,
  );
}

class $$LocalUsersTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalUsersTable,
          LocalUser,
          $$LocalUsersTableFilterComposer,
          $$LocalUsersTableOrderingComposer,
          $$LocalUsersTableAnnotationComposer,
          $$LocalUsersTableCreateCompanionBuilder,
          $$LocalUsersTableUpdateCompanionBuilder,
          (
            LocalUser,
            BaseReferences<_$LocalDatabase, $LocalUsersTable, LocalUser>,
          ),
          LocalUser,
          PrefetchHooks Function()
        > {
  $$LocalUsersTableTableManager(_$LocalDatabase db, $LocalUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientUuid = const Value.absent(),
                Value<String?> serverUserId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> churchId = const Value.absent(),
                Value<String> membershipStatus = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion(
                clientUuid: clientUuid,
                serverUserId: serverUserId,
                fullName: fullName,
                phone: phone,
                churchId: churchId,
                membershipStatus: membershipStatus,
                visibility: visibility,
                synced: synced,
                registeredAt: registeredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientUuid,
                Value<String?> serverUserId = const Value.absent(),
                required String fullName,
                required String phone,
                required String churchId,
                required String membershipStatus,
                Value<String> visibility = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUsersCompanion.insert(
                clientUuid: clientUuid,
                serverUserId: serverUserId,
                fullName: fullName,
                phone: phone,
                churchId: churchId,
                membershipStatus: membershipStatus,
                visibility: visibility,
                synced: synced,
                registeredAt: registeredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalUsersTable,
      LocalUser,
      $$LocalUsersTableFilterComposer,
      $$LocalUsersTableOrderingComposer,
      $$LocalUsersTableAnnotationComposer,
      $$LocalUsersTableCreateCompanionBuilder,
      $$LocalUsersTableUpdateCompanionBuilder,
      (LocalUser, BaseReferences<_$LocalDatabase, $LocalUsersTable, LocalUser>),
      LocalUser,
      PrefetchHooks Function()
    >;
typedef $$ContributionsTableCreateCompanionBuilder =
    ContributionsCompanion Function({
      required String id,
      required String churchId,
      required int totalAmount,
      required String allocationsJson,
      Value<bool> anonymous,
      Value<String> status,
      required int counter,
      Value<String?> nonce,
      Value<String?> signature,
      Value<String?> failureReason,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ContributionsTableUpdateCompanionBuilder =
    ContributionsCompanion Function({
      Value<String> id,
      Value<String> churchId,
      Value<int> totalAmount,
      Value<String> allocationsJson,
      Value<bool> anonymous,
      Value<String> status,
      Value<int> counter,
      Value<String?> nonce,
      Value<String?> signature,
      Value<String?> failureReason,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ContributionsTableFilterComposer
    extends Composer<_$LocalDatabase, $ContributionsTable> {
  $$ContributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get churchId => $composableBuilder(
    column: $table.churchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allocationsJson => $composableBuilder(
    column: $table.allocationsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get anonymous => $composableBuilder(
    column: $table.anonymous,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContributionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ContributionsTable> {
  $$ContributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get churchId => $composableBuilder(
    column: $table.churchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allocationsJson => $composableBuilder(
    column: $table.allocationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get anonymous => $composableBuilder(
    column: $table.anonymous,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContributionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ContributionsTable> {
  $$ContributionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get churchId =>
      $composableBuilder(column: $table.churchId, builder: (column) => column);

  GeneratedColumn<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allocationsJson => $composableBuilder(
    column: $table.allocationsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get anonymous =>
      $composableBuilder(column: $table.anonymous, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get counter =>
      $composableBuilder(column: $table.counter, builder: (column) => column);

  GeneratedColumn<String> get nonce =>
      $composableBuilder(column: $table.nonce, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContributionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $ContributionsTable,
          Contribution,
          $$ContributionsTableFilterComposer,
          $$ContributionsTableOrderingComposer,
          $$ContributionsTableAnnotationComposer,
          $$ContributionsTableCreateCompanionBuilder,
          $$ContributionsTableUpdateCompanionBuilder,
          (
            Contribution,
            BaseReferences<_$LocalDatabase, $ContributionsTable, Contribution>,
          ),
          Contribution,
          PrefetchHooks Function()
        > {
  $$ContributionsTableTableManager(
    _$LocalDatabase db,
    $ContributionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContributionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContributionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> churchId = const Value.absent(),
                Value<int> totalAmount = const Value.absent(),
                Value<String> allocationsJson = const Value.absent(),
                Value<bool> anonymous = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> counter = const Value.absent(),
                Value<String?> nonce = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContributionsCompanion(
                id: id,
                churchId: churchId,
                totalAmount: totalAmount,
                allocationsJson: allocationsJson,
                anonymous: anonymous,
                status: status,
                counter: counter,
                nonce: nonce,
                signature: signature,
                failureReason: failureReason,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String churchId,
                required int totalAmount,
                required String allocationsJson,
                Value<bool> anonymous = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int counter,
                Value<String?> nonce = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContributionsCompanion.insert(
                id: id,
                churchId: churchId,
                totalAmount: totalAmount,
                allocationsJson: allocationsJson,
                anonymous: anonymous,
                status: status,
                counter: counter,
                nonce: nonce,
                signature: signature,
                failureReason: failureReason,
                retryCount: retryCount,
                createdAt: createdAt,
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

typedef $$ContributionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $ContributionsTable,
      Contribution,
      $$ContributionsTableFilterComposer,
      $$ContributionsTableOrderingComposer,
      $$ContributionsTableAnnotationComposer,
      $$ContributionsTableCreateCompanionBuilder,
      $$ContributionsTableUpdateCompanionBuilder,
      (
        Contribution,
        BaseReferences<_$LocalDatabase, $ContributionsTable, Contribution>,
      ),
      Contribution,
      PrefetchHooks Function()
    >;
typedef $$CachedChurchesTableCreateCompanionBuilder =
    CachedChurchesCompanion Function({
      required String id,
      required String name,
      required String slug,
      Value<String?> publicKey,
      Value<int> rowid,
    });
typedef $$CachedChurchesTableUpdateCompanionBuilder =
    CachedChurchesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> slug,
      Value<String?> publicKey,
      Value<int> rowid,
    });

class $$CachedChurchesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedChurchesTable> {
  $$CachedChurchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedChurchesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedChurchesTable> {
  $$CachedChurchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedChurchesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedChurchesTable> {
  $$CachedChurchesTableAnnotationComposer({
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

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);
}

class $$CachedChurchesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedChurchesTable,
          CachedChurche,
          $$CachedChurchesTableFilterComposer,
          $$CachedChurchesTableOrderingComposer,
          $$CachedChurchesTableAnnotationComposer,
          $$CachedChurchesTableCreateCompanionBuilder,
          $$CachedChurchesTableUpdateCompanionBuilder,
          (
            CachedChurche,
            BaseReferences<
              _$LocalDatabase,
              $CachedChurchesTable,
              CachedChurche
            >,
          ),
          CachedChurche,
          PrefetchHooks Function()
        > {
  $$CachedChurchesTableTableManager(
    _$LocalDatabase db,
    $CachedChurchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedChurchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedChurchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedChurchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String?> publicKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedChurchesCompanion(
                id: id,
                name: name,
                slug: slug,
                publicKey: publicKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String slug,
                Value<String?> publicKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedChurchesCompanion.insert(
                id: id,
                name: name,
                slug: slug,
                publicKey: publicKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedChurchesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedChurchesTable,
      CachedChurche,
      $$CachedChurchesTableFilterComposer,
      $$CachedChurchesTableOrderingComposer,
      $$CachedChurchesTableAnnotationComposer,
      $$CachedChurchesTableCreateCompanionBuilder,
      $$CachedChurchesTableUpdateCompanionBuilder,
      (
        CachedChurche,
        BaseReferences<_$LocalDatabase, $CachedChurchesTable, CachedChurche>,
      ),
      CachedChurche,
      PrefetchHooks Function()
    >;
typedef $$CachedCategoriesTableCreateCompanionBuilder =
    CachedCategoriesCompanion Function({
      required String code,
      Value<String?> churchId,
      required String name,
      required String description,
      Value<double?> fixedAmount,
      Value<double?> percentageHint,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CachedCategoriesTableUpdateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<String> code,
      Value<String?> churchId,
      Value<String> name,
      Value<String> description,
      Value<double?> fixedAmount,
      Value<double?> percentageHint,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get churchId => $composableBuilder(
    column: $table.churchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fixedAmount => $composableBuilder(
    column: $table.fixedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentageHint => $composableBuilder(
    column: $table.percentageHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get churchId => $composableBuilder(
    column: $table.churchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fixedAmount => $composableBuilder(
    column: $table.fixedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentageHint => $composableBuilder(
    column: $table.percentageHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get churchId =>
      $composableBuilder(column: $table.churchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fixedAmount => $composableBuilder(
    column: $table.fixedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get percentageHint => $composableBuilder(
    column: $table.percentageHint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CachedCategoriesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedCategoriesTable,
          CachedCategory,
          $$CachedCategoriesTableFilterComposer,
          $$CachedCategoriesTableOrderingComposer,
          $$CachedCategoriesTableAnnotationComposer,
          $$CachedCategoriesTableCreateCompanionBuilder,
          $$CachedCategoriesTableUpdateCompanionBuilder,
          (
            CachedCategory,
            BaseReferences<
              _$LocalDatabase,
              $CachedCategoriesTable,
              CachedCategory
            >,
          ),
          CachedCategory,
          PrefetchHooks Function()
        > {
  $$CachedCategoriesTableTableManager(
    _$LocalDatabase db,
    $CachedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String?> churchId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double?> fixedAmount = const Value.absent(),
                Value<double?> percentageHint = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion(
                code: code,
                churchId: churchId,
                name: name,
                description: description,
                fixedAmount: fixedAmount,
                percentageHint: percentageHint,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                Value<String?> churchId = const Value.absent(),
                required String name,
                required String description,
                Value<double?> fixedAmount = const Value.absent(),
                Value<double?> percentageHint = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion.insert(
                code: code,
                churchId: churchId,
                name: name,
                description: description,
                fixedAmount: fixedAmount,
                percentageHint: percentageHint,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedCategoriesTable,
      CachedCategory,
      $$CachedCategoriesTableFilterComposer,
      $$CachedCategoriesTableOrderingComposer,
      $$CachedCategoriesTableAnnotationComposer,
      $$CachedCategoriesTableCreateCompanionBuilder,
      $$CachedCategoriesTableUpdateCompanionBuilder,
      (
        CachedCategory,
        BaseReferences<_$LocalDatabase, $CachedCategoriesTable, CachedCategory>,
      ),
      CachedCategory,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> mode,
      Value<String> primaryColor,
      Value<String> accentColor,
      Value<String> backgroundColor,
      Value<double> fontScale,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> mode,
      Value<String> primaryColor,
      Value<String> accentColor,
      Value<String> backgroundColor,
      Value<double> fontScale,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$LocalDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fontScale => $composableBuilder(
    column: $table.fontScale,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$LocalDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fontScale => $composableBuilder(
    column: $table.fontScale,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get primaryColor => $composableBuilder(
    column: $table.primaryColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accentColor => $composableBuilder(
    column: $table.accentColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fontScale =>
      $composableBuilder(column: $table.fontScale, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$LocalDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$LocalDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> primaryColor = const Value.absent(),
                Value<String> accentColor = const Value.absent(),
                Value<String> backgroundColor = const Value.absent(),
                Value<double> fontScale = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                mode: mode,
                primaryColor: primaryColor,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                fontScale: fontScale,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> primaryColor = const Value.absent(),
                Value<String> accentColor = const Value.absent(),
                Value<String> backgroundColor = const Value.absent(),
                Value<double> fontScale = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                mode: mode,
                primaryColor: primaryColor,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                fontScale: fontScale,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$LocalDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SignCounterTableCreateCompanionBuilder =
    SignCounterCompanion Function({Value<int> id, Value<int> value});
typedef $$SignCounterTableUpdateCompanionBuilder =
    SignCounterCompanion Function({Value<int> id, Value<int> value});

class $$SignCounterTableFilterComposer
    extends Composer<_$LocalDatabase, $SignCounterTable> {
  $$SignCounterTableFilterComposer({
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

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignCounterTableOrderingComposer
    extends Composer<_$LocalDatabase, $SignCounterTable> {
  $$SignCounterTableOrderingComposer({
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

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignCounterTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SignCounterTable> {
  $$SignCounterTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SignCounterTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SignCounterTable,
          SignCounterData,
          $$SignCounterTableFilterComposer,
          $$SignCounterTableOrderingComposer,
          $$SignCounterTableAnnotationComposer,
          $$SignCounterTableCreateCompanionBuilder,
          $$SignCounterTableUpdateCompanionBuilder,
          (
            SignCounterData,
            BaseReferences<_$LocalDatabase, $SignCounterTable, SignCounterData>,
          ),
          SignCounterData,
          PrefetchHooks Function()
        > {
  $$SignCounterTableTableManager(_$LocalDatabase db, $SignCounterTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignCounterTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignCounterTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignCounterTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> value = const Value.absent(),
              }) => SignCounterCompanion(id: id, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> value = const Value.absent(),
              }) => SignCounterCompanion.insert(id: id, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignCounterTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SignCounterTable,
      SignCounterData,
      $$SignCounterTableFilterComposer,
      $$SignCounterTableOrderingComposer,
      $$SignCounterTableAnnotationComposer,
      $$SignCounterTableCreateCompanionBuilder,
      $$SignCounterTableUpdateCompanionBuilder,
      (
        SignCounterData,
        BaseReferences<_$LocalDatabase, $SignCounterTable, SignCounterData>,
      ),
      SignCounterData,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$ContributionsTableTableManager get contributions =>
      $$ContributionsTableTableManager(_db, _db.contributions);
  $$CachedChurchesTableTableManager get cachedChurches =>
      $$CachedChurchesTableTableManager(_db, _db.cachedChurches);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SignCounterTableTableManager get signCounter =>
      $$SignCounterTableTableManager(_db, _db.signCounter);
}
