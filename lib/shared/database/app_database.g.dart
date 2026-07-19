// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransferTaskRowsTable extends TransferTaskRows
    with TableInfo<$TransferTaskRowsTable, TransferTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferTaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumnWithTypeConverter<TransferOperation, int>
      operation = GeneratedColumn<int>('operation', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransferOperation>(
              $TransferTaskRowsTable.$converteroperation);
  static const VerificationMeta _sourcePathsJsonMeta =
      const VerificationMeta('sourcePathsJson');
  @override
  late final GeneratedColumn<String> sourcePathsJson = GeneratedColumn<String>(
      'source_paths_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<TransferTaskStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TransferTaskStatus>(
              $TransferTaskRowsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _destinationPathMeta =
      const VerificationMeta('destinationPath');
  @override
  late final GeneratedColumn<String> destinationPath = GeneratedColumn<String>(
      'destination_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transferredBytesMeta =
      const VerificationMeta('transferredBytes');
  @override
  late final GeneratedColumn<int> transferredBytes = GeneratedColumn<int>(
      'transferred_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _currentItemPathMeta =
      const VerificationMeta('currentItemPath');
  @override
  late final GeneratedColumn<String> currentItemPath = GeneratedColumn<String>(
      'current_item_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conflictPolicyMeta =
      const VerificationMeta('conflictPolicy');
  @override
  late final GeneratedColumnWithTypeConverter<ConflictPolicy, int>
      conflictPolicy = GeneratedColumn<int>(
              'conflict_policy', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ConflictPolicy>(
              $TransferTaskRowsTable.$converterconflictPolicy);
  static const VerificationMeta _failureMessageMeta =
      const VerificationMeta('failureMessage');
  @override
  late final GeneratedColumn<String> failureMessage = GeneratedColumn<String>(
      'failure_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _failureCodeMeta =
      const VerificationMeta('failureCode');
  @override
  late final GeneratedColumnWithTypeConverter<TransferFailureCode?, int>
      failureCode = GeneratedColumn<int>('failure_code', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<TransferFailureCode?>(
              $TransferTaskRowsTable.$converterfailureCoden);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operation,
        sourcePathsJson,
        displayName,
        status,
        createdAt,
        updatedAt,
        destinationPath,
        transferredBytes,
        totalBytes,
        currentItemPath,
        conflictPolicy,
        failureMessage,
        failureCode
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_task_rows';
  @override
  VerificationContext validateIntegrity(Insertable<TransferTaskRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    context.handle(_operationMeta, const VerificationResult.success());
    if (data.containsKey('source_paths_json')) {
      context.handle(
          _sourcePathsJsonMeta,
          sourcePathsJson.isAcceptableOrUnknown(
              data['source_paths_json']!, _sourcePathsJsonMeta));
    } else if (isInserting) {
      context.missing(_sourcePathsJsonMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    context.handle(_statusMeta, const VerificationResult.success());
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('destination_path')) {
      context.handle(
          _destinationPathMeta,
          destinationPath.isAcceptableOrUnknown(
              data['destination_path']!, _destinationPathMeta));
    }
    if (data.containsKey('transferred_bytes')) {
      context.handle(
          _transferredBytesMeta,
          transferredBytes.isAcceptableOrUnknown(
              data['transferred_bytes']!, _transferredBytesMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('current_item_path')) {
      context.handle(
          _currentItemPathMeta,
          currentItemPath.isAcceptableOrUnknown(
              data['current_item_path']!, _currentItemPathMeta));
    }
    context.handle(_conflictPolicyMeta, const VerificationResult.success());
    if (data.containsKey('failure_message')) {
      context.handle(
          _failureMessageMeta,
          failureMessage.isAcceptableOrUnknown(
              data['failure_message']!, _failureMessageMeta));
    }
    context.handle(_failureCodeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferTaskRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      operation: $TransferTaskRowsTable.$converteroperation.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}operation'])!),
      sourcePathsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_paths_json'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      status: $TransferTaskRowsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      destinationPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}destination_path']),
      transferredBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transferred_bytes'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes']),
      currentItemPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_item_path']),
      conflictPolicy: $TransferTaskRowsTable.$converterconflictPolicy.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}conflict_policy'])!),
      failureMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_message']),
      failureCode: $TransferTaskRowsTable.$converterfailureCoden.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}failure_code'])),
    );
  }

  @override
  $TransferTaskRowsTable createAlias(String alias) {
    return $TransferTaskRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransferOperation, int, int> $converteroperation =
      const EnumIndexConverter<TransferOperation>(TransferOperation.values);
  static JsonTypeConverter2<TransferTaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<TransferTaskStatus>(TransferTaskStatus.values);
  static JsonTypeConverter2<ConflictPolicy, int, int> $converterconflictPolicy =
      const EnumIndexConverter<ConflictPolicy>(ConflictPolicy.values);
  static JsonTypeConverter2<TransferFailureCode, int, int>
      $converterfailureCode =
      const EnumIndexConverter<TransferFailureCode>(TransferFailureCode.values);
  static JsonTypeConverter2<TransferFailureCode?, int?, int?>
      $converterfailureCoden =
      JsonTypeConverter2.asNullable($converterfailureCode);
}

class TransferTaskRow extends DataClass implements Insertable<TransferTaskRow> {
  final String id;
  final TransferOperation operation;
  final String sourcePathsJson;
  final String displayName;
  final TransferTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? destinationPath;
  final int transferredBytes;
  final int? totalBytes;
  final String? currentItemPath;
  final ConflictPolicy conflictPolicy;
  final String? failureMessage;
  final TransferFailureCode? failureCode;
  const TransferTaskRow(
      {required this.id,
      required this.operation,
      required this.sourcePathsJson,
      required this.displayName,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.destinationPath,
      required this.transferredBytes,
      this.totalBytes,
      this.currentItemPath,
      required this.conflictPolicy,
      this.failureMessage,
      this.failureCode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['operation'] = Variable<int>(
          $TransferTaskRowsTable.$converteroperation.toSql(operation));
    }
    map['source_paths_json'] = Variable<String>(sourcePathsJson);
    map['display_name'] = Variable<String>(displayName);
    {
      map['status'] =
          Variable<int>($TransferTaskRowsTable.$converterstatus.toSql(status));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || destinationPath != null) {
      map['destination_path'] = Variable<String>(destinationPath);
    }
    map['transferred_bytes'] = Variable<int>(transferredBytes);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    if (!nullToAbsent || currentItemPath != null) {
      map['current_item_path'] = Variable<String>(currentItemPath);
    }
    {
      map['conflict_policy'] = Variable<int>($TransferTaskRowsTable
          .$converterconflictPolicy
          .toSql(conflictPolicy));
    }
    if (!nullToAbsent || failureMessage != null) {
      map['failure_message'] = Variable<String>(failureMessage);
    }
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<int>(
          $TransferTaskRowsTable.$converterfailureCoden.toSql(failureCode));
    }
    return map;
  }

  TransferTaskRowsCompanion toCompanion(bool nullToAbsent) {
    return TransferTaskRowsCompanion(
      id: Value(id),
      operation: Value(operation),
      sourcePathsJson: Value(sourcePathsJson),
      displayName: Value(displayName),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      destinationPath: destinationPath == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationPath),
      transferredBytes: Value(transferredBytes),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      currentItemPath: currentItemPath == null && nullToAbsent
          ? const Value.absent()
          : Value(currentItemPath),
      conflictPolicy: Value(conflictPolicy),
      failureMessage: failureMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(failureMessage),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
    );
  }

  factory TransferTaskRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferTaskRow(
      id: serializer.fromJson<String>(json['id']),
      operation: $TransferTaskRowsTable.$converteroperation
          .fromJson(serializer.fromJson<int>(json['operation'])),
      sourcePathsJson: serializer.fromJson<String>(json['sourcePathsJson']),
      displayName: serializer.fromJson<String>(json['displayName']),
      status: $TransferTaskRowsTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      destinationPath: serializer.fromJson<String?>(json['destinationPath']),
      transferredBytes: serializer.fromJson<int>(json['transferredBytes']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      currentItemPath: serializer.fromJson<String?>(json['currentItemPath']),
      conflictPolicy: $TransferTaskRowsTable.$converterconflictPolicy
          .fromJson(serializer.fromJson<int>(json['conflictPolicy'])),
      failureMessage: serializer.fromJson<String?>(json['failureMessage']),
      failureCode: $TransferTaskRowsTable.$converterfailureCoden
          .fromJson(serializer.fromJson<int?>(json['failureCode'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operation': serializer.toJson<int>(
          $TransferTaskRowsTable.$converteroperation.toJson(operation)),
      'sourcePathsJson': serializer.toJson<String>(sourcePathsJson),
      'displayName': serializer.toJson<String>(displayName),
      'status': serializer
          .toJson<int>($TransferTaskRowsTable.$converterstatus.toJson(status)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'destinationPath': serializer.toJson<String?>(destinationPath),
      'transferredBytes': serializer.toJson<int>(transferredBytes),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'currentItemPath': serializer.toJson<String?>(currentItemPath),
      'conflictPolicy': serializer.toJson<int>($TransferTaskRowsTable
          .$converterconflictPolicy
          .toJson(conflictPolicy)),
      'failureMessage': serializer.toJson<String?>(failureMessage),
      'failureCode': serializer.toJson<int?>(
          $TransferTaskRowsTable.$converterfailureCoden.toJson(failureCode)),
    };
  }

  TransferTaskRow copyWith(
          {String? id,
          TransferOperation? operation,
          String? sourcePathsJson,
          String? displayName,
          TransferTaskStatus? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<String?> destinationPath = const Value.absent(),
          int? transferredBytes,
          Value<int?> totalBytes = const Value.absent(),
          Value<String?> currentItemPath = const Value.absent(),
          ConflictPolicy? conflictPolicy,
          Value<String?> failureMessage = const Value.absent(),
          Value<TransferFailureCode?> failureCode = const Value.absent()}) =>
      TransferTaskRow(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        sourcePathsJson: sourcePathsJson ?? this.sourcePathsJson,
        displayName: displayName ?? this.displayName,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        destinationPath: destinationPath.present
            ? destinationPath.value
            : this.destinationPath,
        transferredBytes: transferredBytes ?? this.transferredBytes,
        totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
        currentItemPath: currentItemPath.present
            ? currentItemPath.value
            : this.currentItemPath,
        conflictPolicy: conflictPolicy ?? this.conflictPolicy,
        failureMessage:
            failureMessage.present ? failureMessage.value : this.failureMessage,
        failureCode: failureCode.present ? failureCode.value : this.failureCode,
      );
  TransferTaskRow copyWithCompanion(TransferTaskRowsCompanion data) {
    return TransferTaskRow(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      sourcePathsJson: data.sourcePathsJson.present
          ? data.sourcePathsJson.value
          : this.sourcePathsJson,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      destinationPath: data.destinationPath.present
          ? data.destinationPath.value
          : this.destinationPath,
      transferredBytes: data.transferredBytes.present
          ? data.transferredBytes.value
          : this.transferredBytes,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      currentItemPath: data.currentItemPath.present
          ? data.currentItemPath.value
          : this.currentItemPath,
      conflictPolicy: data.conflictPolicy.present
          ? data.conflictPolicy.value
          : this.conflictPolicy,
      failureMessage: data.failureMessage.present
          ? data.failureMessage.value
          : this.failureMessage,
      failureCode:
          data.failureCode.present ? data.failureCode.value : this.failureCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferTaskRow(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('sourcePathsJson: $sourcePathsJson, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('destinationPath: $destinationPath, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('currentItemPath: $currentItemPath, ')
          ..write('conflictPolicy: $conflictPolicy, ')
          ..write('failureMessage: $failureMessage, ')
          ..write('failureCode: $failureCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      operation,
      sourcePathsJson,
      displayName,
      status,
      createdAt,
      updatedAt,
      destinationPath,
      transferredBytes,
      totalBytes,
      currentItemPath,
      conflictPolicy,
      failureMessage,
      failureCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferTaskRow &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.sourcePathsJson == this.sourcePathsJson &&
          other.displayName == this.displayName &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.destinationPath == this.destinationPath &&
          other.transferredBytes == this.transferredBytes &&
          other.totalBytes == this.totalBytes &&
          other.currentItemPath == this.currentItemPath &&
          other.conflictPolicy == this.conflictPolicy &&
          other.failureMessage == this.failureMessage &&
          other.failureCode == this.failureCode);
}

class TransferTaskRowsCompanion extends UpdateCompanion<TransferTaskRow> {
  final Value<String> id;
  final Value<TransferOperation> operation;
  final Value<String> sourcePathsJson;
  final Value<String> displayName;
  final Value<TransferTaskStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> destinationPath;
  final Value<int> transferredBytes;
  final Value<int?> totalBytes;
  final Value<String?> currentItemPath;
  final Value<ConflictPolicy> conflictPolicy;
  final Value<String?> failureMessage;
  final Value<TransferFailureCode?> failureCode;
  final Value<int> rowid;
  const TransferTaskRowsCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.sourcePathsJson = const Value.absent(),
    this.displayName = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.destinationPath = const Value.absent(),
    this.transferredBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.currentItemPath = const Value.absent(),
    this.conflictPolicy = const Value.absent(),
    this.failureMessage = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferTaskRowsCompanion.insert({
    required String id,
    required TransferOperation operation,
    required String sourcePathsJson,
    required String displayName,
    required TransferTaskStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.destinationPath = const Value.absent(),
    this.transferredBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.currentItemPath = const Value.absent(),
    required ConflictPolicy conflictPolicy,
    this.failureMessage = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        operation = Value(operation),
        sourcePathsJson = Value(sourcePathsJson),
        displayName = Value(displayName),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        conflictPolicy = Value(conflictPolicy);
  static Insertable<TransferTaskRow> custom({
    Expression<String>? id,
    Expression<int>? operation,
    Expression<String>? sourcePathsJson,
    Expression<String>? displayName,
    Expression<int>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? destinationPath,
    Expression<int>? transferredBytes,
    Expression<int>? totalBytes,
    Expression<String>? currentItemPath,
    Expression<int>? conflictPolicy,
    Expression<String>? failureMessage,
    Expression<int>? failureCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (sourcePathsJson != null) 'source_paths_json': sourcePathsJson,
      if (displayName != null) 'display_name': displayName,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (destinationPath != null) 'destination_path': destinationPath,
      if (transferredBytes != null) 'transferred_bytes': transferredBytes,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (currentItemPath != null) 'current_item_path': currentItemPath,
      if (conflictPolicy != null) 'conflict_policy': conflictPolicy,
      if (failureMessage != null) 'failure_message': failureMessage,
      if (failureCode != null) 'failure_code': failureCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferTaskRowsCompanion copyWith(
      {Value<String>? id,
      Value<TransferOperation>? operation,
      Value<String>? sourcePathsJson,
      Value<String>? displayName,
      Value<TransferTaskStatus>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String?>? destinationPath,
      Value<int>? transferredBytes,
      Value<int?>? totalBytes,
      Value<String?>? currentItemPath,
      Value<ConflictPolicy>? conflictPolicy,
      Value<String?>? failureMessage,
      Value<TransferFailureCode?>? failureCode,
      Value<int>? rowid}) {
    return TransferTaskRowsCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      sourcePathsJson: sourcePathsJson ?? this.sourcePathsJson,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      destinationPath: destinationPath ?? this.destinationPath,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      currentItemPath: currentItemPath ?? this.currentItemPath,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      failureMessage: failureMessage ?? this.failureMessage,
      failureCode: failureCode ?? this.failureCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<int>(
          $TransferTaskRowsTable.$converteroperation.toSql(operation.value));
    }
    if (sourcePathsJson.present) {
      map['source_paths_json'] = Variable<String>(sourcePathsJson.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $TransferTaskRowsTable.$converterstatus.toSql(status.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (destinationPath.present) {
      map['destination_path'] = Variable<String>(destinationPath.value);
    }
    if (transferredBytes.present) {
      map['transferred_bytes'] = Variable<int>(transferredBytes.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (currentItemPath.present) {
      map['current_item_path'] = Variable<String>(currentItemPath.value);
    }
    if (conflictPolicy.present) {
      map['conflict_policy'] = Variable<int>($TransferTaskRowsTable
          .$converterconflictPolicy
          .toSql(conflictPolicy.value));
    }
    if (failureMessage.present) {
      map['failure_message'] = Variable<String>(failureMessage.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<int>($TransferTaskRowsTable
          .$converterfailureCoden
          .toSql(failureCode.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferTaskRowsCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('sourcePathsJson: $sourcePathsJson, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('destinationPath: $destinationPath, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('currentItemPath: $currentItemPath, ')
          ..write('conflictPolicy: $conflictPolicy, ')
          ..write('failureMessage: $failureMessage, ')
          ..write('failureCode: $failureCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransferTaskRowsTable transferTaskRows =
      $TransferTaskRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [transferTaskRows];
}

typedef $$TransferTaskRowsTableCreateCompanionBuilder
    = TransferTaskRowsCompanion Function({
  required String id,
  required TransferOperation operation,
  required String sourcePathsJson,
  required String displayName,
  required TransferTaskStatus status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> destinationPath,
  Value<int> transferredBytes,
  Value<int?> totalBytes,
  Value<String?> currentItemPath,
  required ConflictPolicy conflictPolicy,
  Value<String?> failureMessage,
  Value<TransferFailureCode?> failureCode,
  Value<int> rowid,
});
typedef $$TransferTaskRowsTableUpdateCompanionBuilder
    = TransferTaskRowsCompanion Function({
  Value<String> id,
  Value<TransferOperation> operation,
  Value<String> sourcePathsJson,
  Value<String> displayName,
  Value<TransferTaskStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> destinationPath,
  Value<int> transferredBytes,
  Value<int?> totalBytes,
  Value<String?> currentItemPath,
  Value<ConflictPolicy> conflictPolicy,
  Value<String?> failureMessage,
  Value<TransferFailureCode?> failureCode,
  Value<int> rowid,
});

class $$TransferTaskRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TransferTaskRowsTable> {
  $$TransferTaskRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransferOperation, TransferOperation, int>
      get operation => $composableBuilder(
          column: $table.operation,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get sourcePathsJson => $composableBuilder(
      column: $table.sourcePathsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransferTaskStatus, TransferTaskStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get destinationPath => $composableBuilder(
      column: $table.destinationPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transferredBytes => $composableBuilder(
      column: $table.transferredBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentItemPath => $composableBuilder(
      column: $table.currentItemPath,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ConflictPolicy, ConflictPolicy, int>
      get conflictPolicy => $composableBuilder(
          column: $table.conflictPolicy,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get failureMessage => $composableBuilder(
      column: $table.failureMessage,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TransferFailureCode?, TransferFailureCode, int>
      get failureCode => $composableBuilder(
          column: $table.failureCode,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$TransferTaskRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferTaskRowsTable> {
  $$TransferTaskRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourcePathsJson => $composableBuilder(
      column: $table.sourcePathsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get destinationPath => $composableBuilder(
      column: $table.destinationPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transferredBytes => $composableBuilder(
      column: $table.transferredBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentItemPath => $composableBuilder(
      column: $table.currentItemPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get conflictPolicy => $composableBuilder(
      column: $table.conflictPolicy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get failureMessage => $composableBuilder(
      column: $table.failureMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get failureCode => $composableBuilder(
      column: $table.failureCode, builder: (column) => ColumnOrderings(column));
}

class $$TransferTaskRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferTaskRowsTable> {
  $$TransferTaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransferOperation, int> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get sourcePathsJson => $composableBuilder(
      column: $table.sourcePathsJson, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransferTaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get destinationPath => $composableBuilder(
      column: $table.destinationPath, builder: (column) => column);

  GeneratedColumn<int> get transferredBytes => $composableBuilder(
      column: $table.transferredBytes, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<String> get currentItemPath => $composableBuilder(
      column: $table.currentItemPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConflictPolicy, int> get conflictPolicy =>
      $composableBuilder(
          column: $table.conflictPolicy, builder: (column) => column);

  GeneratedColumn<String> get failureMessage => $composableBuilder(
      column: $table.failureMessage, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransferFailureCode?, int> get failureCode =>
      $composableBuilder(
          column: $table.failureCode, builder: (column) => column);
}

class $$TransferTaskRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransferTaskRowsTable,
    TransferTaskRow,
    $$TransferTaskRowsTableFilterComposer,
    $$TransferTaskRowsTableOrderingComposer,
    $$TransferTaskRowsTableAnnotationComposer,
    $$TransferTaskRowsTableCreateCompanionBuilder,
    $$TransferTaskRowsTableUpdateCompanionBuilder,
    (
      TransferTaskRow,
      BaseReferences<_$AppDatabase, $TransferTaskRowsTable, TransferTaskRow>
    ),
    TransferTaskRow,
    PrefetchHooks Function()> {
  $$TransferTaskRowsTableTableManager(
      _$AppDatabase db, $TransferTaskRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferTaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferTaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferTaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<TransferOperation> operation = const Value.absent(),
            Value<String> sourcePathsJson = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<TransferTaskStatus> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> destinationPath = const Value.absent(),
            Value<int> transferredBytes = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<String?> currentItemPath = const Value.absent(),
            Value<ConflictPolicy> conflictPolicy = const Value.absent(),
            Value<String?> failureMessage = const Value.absent(),
            Value<TransferFailureCode?> failureCode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferTaskRowsCompanion(
            id: id,
            operation: operation,
            sourcePathsJson: sourcePathsJson,
            displayName: displayName,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            destinationPath: destinationPath,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            currentItemPath: currentItemPath,
            conflictPolicy: conflictPolicy,
            failureMessage: failureMessage,
            failureCode: failureCode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required TransferOperation operation,
            required String sourcePathsJson,
            required String displayName,
            required TransferTaskStatus status,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String?> destinationPath = const Value.absent(),
            Value<int> transferredBytes = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<String?> currentItemPath = const Value.absent(),
            required ConflictPolicy conflictPolicy,
            Value<String?> failureMessage = const Value.absent(),
            Value<TransferFailureCode?> failureCode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransferTaskRowsCompanion.insert(
            id: id,
            operation: operation,
            sourcePathsJson: sourcePathsJson,
            displayName: displayName,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            destinationPath: destinationPath,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            currentItemPath: currentItemPath,
            conflictPolicy: conflictPolicy,
            failureMessage: failureMessage,
            failureCode: failureCode,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransferTaskRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransferTaskRowsTable,
    TransferTaskRow,
    $$TransferTaskRowsTableFilterComposer,
    $$TransferTaskRowsTableOrderingComposer,
    $$TransferTaskRowsTableAnnotationComposer,
    $$TransferTaskRowsTableCreateCompanionBuilder,
    $$TransferTaskRowsTableUpdateCompanionBuilder,
    (
      TransferTaskRow,
      BaseReferences<_$AppDatabase, $TransferTaskRowsTable, TransferTaskRow>
    ),
    TransferTaskRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransferTaskRowsTableTableManager get transferTaskRows =>
      $$TransferTaskRowsTableTableManager(_db, _db.transferTaskRows);
}
