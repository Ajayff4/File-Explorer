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
    if (data.containsKey('failure_message')) {
      context.handle(
          _failureMessageMeta,
          failureMessage.isAcceptableOrUnknown(
              data['failure_message']!, _failureMessageMeta));
    }
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

class $FavoriteLocationRowsTable extends FavoriteLocationRows
    with TableInfo<$FavoriteLocationRowsTable, FavoriteLocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteLocationRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  @override
  List<GeneratedColumn> get $columns => [path, label, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_location_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<FavoriteLocationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  FavoriteLocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteLocationRow(
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FavoriteLocationRowsTable createAlias(String alias) {
    return $FavoriteLocationRowsTable(attachedDatabase, alias);
  }
}

class FavoriteLocationRow extends DataClass
    implements Insertable<FavoriteLocationRow> {
  final String path;
  final String label;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FavoriteLocationRow(
      {required this.path,
      required this.label,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FavoriteLocationRowsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteLocationRowsCompanion(
      path: Value(path),
      label: Value(label),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FavoriteLocationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteLocationRow(
      path: serializer.fromJson<String>(json['path']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FavoriteLocationRow copyWith(
          {String? path,
          String? label,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FavoriteLocationRow(
        path: path ?? this.path,
        label: label ?? this.label,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FavoriteLocationRow copyWithCompanion(FavoriteLocationRowsCompanion data) {
    return FavoriteLocationRow(
      path: data.path.present ? data.path.value : this.path,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteLocationRow(')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, label, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteLocationRow &&
          other.path == this.path &&
          other.label == this.label &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FavoriteLocationRowsCompanion
    extends UpdateCompanion<FavoriteLocationRow> {
  final Value<String> path;
  final Value<String> label;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FavoriteLocationRowsCompanion({
    this.path = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteLocationRowsCompanion.insert({
    required String path,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : path = Value(path),
        label = Value(label),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FavoriteLocationRow> custom({
    Expression<String>? path,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteLocationRowsCompanion copyWith(
      {Value<String>? path,
      Value<String>? label,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return FavoriteLocationRowsCompanion(
      path: path ?? this.path,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
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
    return (StringBuffer('FavoriteLocationRowsCompanion(')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentLocationRowsTable extends RecentLocationRows
    with TableInfo<$RecentLocationRowsTable, RecentLocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentLocationRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _openCountMeta =
      const VerificationMeta('openCount');
  @override
  late final GeneratedColumn<int> openCount = GeneratedColumn<int>(
      'open_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isFolderMeta =
      const VerificationMeta('isFolder');
  @override
  late final GeneratedColumn<bool> isFolder = GeneratedColumn<bool>(
      'is_folder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_folder" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [path, label, openedAt, openCount, isFolder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_location_rows';
  @override
  VerificationContext validateIntegrity(Insertable<RecentLocationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('open_count')) {
      context.handle(_openCountMeta,
          openCount.isAcceptableOrUnknown(data['open_count']!, _openCountMeta));
    }
    if (data.containsKey('is_folder')) {
      context.handle(_isFolderMeta,
          isFolder.isAcceptableOrUnknown(data['is_folder']!, _isFolderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  RecentLocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentLocationRow(
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at'])!,
      openCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}open_count'])!,
      isFolder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_folder'])!,
    );
  }

  @override
  $RecentLocationRowsTable createAlias(String alias) {
    return $RecentLocationRowsTable(attachedDatabase, alias);
  }
}

class RecentLocationRow extends DataClass
    implements Insertable<RecentLocationRow> {
  final String path;
  final String label;
  final DateTime openedAt;
  final int openCount;
  final bool isFolder;
  const RecentLocationRow(
      {required this.path,
      required this.label,
      required this.openedAt,
      required this.openCount,
      required this.isFolder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['label'] = Variable<String>(label);
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['open_count'] = Variable<int>(openCount);
    map['is_folder'] = Variable<bool>(isFolder);
    return map;
  }

  RecentLocationRowsCompanion toCompanion(bool nullToAbsent) {
    return RecentLocationRowsCompanion(
      path: Value(path),
      label: Value(label),
      openedAt: Value(openedAt),
      openCount: Value(openCount),
      isFolder: Value(isFolder),
    );
  }

  factory RecentLocationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentLocationRow(
      path: serializer.fromJson<String>(json['path']),
      label: serializer.fromJson<String>(json['label']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      openCount: serializer.fromJson<int>(json['openCount']),
      isFolder: serializer.fromJson<bool>(json['isFolder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'label': serializer.toJson<String>(label),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'openCount': serializer.toJson<int>(openCount),
      'isFolder': serializer.toJson<bool>(isFolder),
    };
  }

  RecentLocationRow copyWith(
          {String? path,
          String? label,
          DateTime? openedAt,
          int? openCount,
          bool? isFolder}) =>
      RecentLocationRow(
        path: path ?? this.path,
        label: label ?? this.label,
        openedAt: openedAt ?? this.openedAt,
        openCount: openCount ?? this.openCount,
        isFolder: isFolder ?? this.isFolder,
      );
  RecentLocationRow copyWithCompanion(RecentLocationRowsCompanion data) {
    return RecentLocationRow(
      path: data.path.present ? data.path.value : this.path,
      label: data.label.present ? data.label.value : this.label,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openCount: data.openCount.present ? data.openCount.value : this.openCount,
      isFolder: data.isFolder.present ? data.isFolder.value : this.isFolder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentLocationRow(')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('openedAt: $openedAt, ')
          ..write('openCount: $openCount, ')
          ..write('isFolder: $isFolder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, label, openedAt, openCount, isFolder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentLocationRow &&
          other.path == this.path &&
          other.label == this.label &&
          other.openedAt == this.openedAt &&
          other.openCount == this.openCount &&
          other.isFolder == this.isFolder);
}

class RecentLocationRowsCompanion extends UpdateCompanion<RecentLocationRow> {
  final Value<String> path;
  final Value<String> label;
  final Value<DateTime> openedAt;
  final Value<int> openCount;
  final Value<bool> isFolder;
  final Value<int> rowid;
  const RecentLocationRowsCompanion({
    this.path = const Value.absent(),
    this.label = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openCount = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentLocationRowsCompanion.insert({
    required String path,
    required String label,
    required DateTime openedAt,
    this.openCount = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : path = Value(path),
        label = Value(label),
        openedAt = Value(openedAt);
  static Insertable<RecentLocationRow> custom({
    Expression<String>? path,
    Expression<String>? label,
    Expression<DateTime>? openedAt,
    Expression<int>? openCount,
    Expression<bool>? isFolder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (label != null) 'label': label,
      if (openedAt != null) 'opened_at': openedAt,
      if (openCount != null) 'open_count': openCount,
      if (isFolder != null) 'is_folder': isFolder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentLocationRowsCompanion copyWith(
      {Value<String>? path,
      Value<String>? label,
      Value<DateTime>? openedAt,
      Value<int>? openCount,
      Value<bool>? isFolder,
      Value<int>? rowid}) {
    return RecentLocationRowsCompanion(
      path: path ?? this.path,
      label: label ?? this.label,
      openedAt: openedAt ?? this.openedAt,
      openCount: openCount ?? this.openCount,
      isFolder: isFolder ?? this.isFolder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openCount.present) {
      map['open_count'] = Variable<int>(openCount.value);
    }
    if (isFolder.present) {
      map['is_folder'] = Variable<bool>(isFolder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentLocationRowsCompanion(')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('openedAt: $openedAt, ')
          ..write('openCount: $openCount, ')
          ..write('isFolder: $isFolder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchIndexEntryRowsTable extends SearchIndexEntryRows
    with TableInfo<$SearchIndexEntryRowsTable, SearchIndexEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchIndexEntryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rootPathMeta =
      const VerificationMeta('rootPath');
  @override
  late final GeneratedColumn<String> rootPath = GeneratedColumn<String>(
      'root_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentPathMeta =
      const VerificationMeta('parentPath');
  @override
  late final GeneratedColumn<String> parentPath = GeneratedColumn<String>(
      'parent_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<FileSystemEntryType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<FileSystemEntryType>(
              $SearchIndexEntryRowsTable.$convertertype);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _childrenCountMeta =
      const VerificationMeta('childrenCount');
  @override
  late final GeneratedColumn<int> childrenCount = GeneratedColumn<int>(
      'children_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<int> depth = GeneratedColumn<int>(
      'depth', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _indexedAtMeta =
      const VerificationMeta('indexedAt');
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
      'indexed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        path,
        rootPath,
        parentPath,
        name,
        type,
        modifiedAt,
        sizeBytes,
        childrenCount,
        depth,
        indexedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_index_entry_rows';
  @override
  VerificationContext validateIntegrity(
      Insertable<SearchIndexEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('root_path')) {
      context.handle(_rootPathMeta,
          rootPath.isAcceptableOrUnknown(data['root_path']!, _rootPathMeta));
    } else if (isInserting) {
      context.missing(_rootPathMeta);
    }
    if (data.containsKey('parent_path')) {
      context.handle(
          _parentPathMeta,
          parentPath.isAcceptableOrUnknown(
              data['parent_path']!, _parentPathMeta));
    } else if (isInserting) {
      context.missing(_parentPathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('children_count')) {
      context.handle(
          _childrenCountMeta,
          childrenCount.isAcceptableOrUnknown(
              data['children_count']!, _childrenCountMeta));
    }
    if (data.containsKey('depth')) {
      context.handle(
          _depthMeta, depth.isAcceptableOrUnknown(data['depth']!, _depthMeta));
    } else if (isInserting) {
      context.missing(_depthMeta);
    }
    if (data.containsKey('indexed_at')) {
      context.handle(_indexedAtMeta,
          indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta));
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rootPath, path};
  @override
  SearchIndexEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchIndexEntryRow(
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      rootPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}root_path'])!,
      parentPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_path'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $SearchIndexEntryRowsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      childrenCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}children_count']),
      depth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}depth'])!,
      indexedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}indexed_at'])!,
    );
  }

  @override
  $SearchIndexEntryRowsTable createAlias(String alias) {
    return $SearchIndexEntryRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FileSystemEntryType, int, int> $convertertype =
      const EnumIndexConverter<FileSystemEntryType>(FileSystemEntryType.values);
}

class SearchIndexEntryRow extends DataClass
    implements Insertable<SearchIndexEntryRow> {
  final String path;
  final String rootPath;
  final String parentPath;
  final String name;
  final FileSystemEntryType type;
  final DateTime modifiedAt;
  final int? sizeBytes;
  final int? childrenCount;
  final int depth;
  final DateTime indexedAt;
  const SearchIndexEntryRow(
      {required this.path,
      required this.rootPath,
      required this.parentPath,
      required this.name,
      required this.type,
      required this.modifiedAt,
      this.sizeBytes,
      this.childrenCount,
      required this.depth,
      required this.indexedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['root_path'] = Variable<String>(rootPath);
    map['parent_path'] = Variable<String>(parentPath);
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<int>($SearchIndexEntryRowsTable.$convertertype.toSql(type));
    }
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || childrenCount != null) {
      map['children_count'] = Variable<int>(childrenCount);
    }
    map['depth'] = Variable<int>(depth);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  SearchIndexEntryRowsCompanion toCompanion(bool nullToAbsent) {
    return SearchIndexEntryRowsCompanion(
      path: Value(path),
      rootPath: Value(rootPath),
      parentPath: Value(parentPath),
      name: Value(name),
      type: Value(type),
      modifiedAt: Value(modifiedAt),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      childrenCount: childrenCount == null && nullToAbsent
          ? const Value.absent()
          : Value(childrenCount),
      depth: Value(depth),
      indexedAt: Value(indexedAt),
    );
  }

  factory SearchIndexEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchIndexEntryRow(
      path: serializer.fromJson<String>(json['path']),
      rootPath: serializer.fromJson<String>(json['rootPath']),
      parentPath: serializer.fromJson<String>(json['parentPath']),
      name: serializer.fromJson<String>(json['name']),
      type: $SearchIndexEntryRowsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      childrenCount: serializer.fromJson<int?>(json['childrenCount']),
      depth: serializer.fromJson<int>(json['depth']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'rootPath': serializer.toJson<String>(rootPath),
      'parentPath': serializer.toJson<String>(parentPath),
      'name': serializer.toJson<String>(name),
      'type': serializer
          .toJson<int>($SearchIndexEntryRowsTable.$convertertype.toJson(type)),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'childrenCount': serializer.toJson<int?>(childrenCount),
      'depth': serializer.toJson<int>(depth),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  SearchIndexEntryRow copyWith(
          {String? path,
          String? rootPath,
          String? parentPath,
          String? name,
          FileSystemEntryType? type,
          DateTime? modifiedAt,
          Value<int?> sizeBytes = const Value.absent(),
          Value<int?> childrenCount = const Value.absent(),
          int? depth,
          DateTime? indexedAt}) =>
      SearchIndexEntryRow(
        path: path ?? this.path,
        rootPath: rootPath ?? this.rootPath,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        type: type ?? this.type,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
        childrenCount:
            childrenCount.present ? childrenCount.value : this.childrenCount,
        depth: depth ?? this.depth,
        indexedAt: indexedAt ?? this.indexedAt,
      );
  SearchIndexEntryRow copyWithCompanion(SearchIndexEntryRowsCompanion data) {
    return SearchIndexEntryRow(
      path: data.path.present ? data.path.value : this.path,
      rootPath: data.rootPath.present ? data.rootPath.value : this.rootPath,
      parentPath:
          data.parentPath.present ? data.parentPath.value : this.parentPath,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      childrenCount: data.childrenCount.present
          ? data.childrenCount.value
          : this.childrenCount,
      depth: data.depth.present ? data.depth.value : this.depth,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexEntryRow(')
          ..write('path: $path, ')
          ..write('rootPath: $rootPath, ')
          ..write('parentPath: $parentPath, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('childrenCount: $childrenCount, ')
          ..write('depth: $depth, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, rootPath, parentPath, name, type,
      modifiedAt, sizeBytes, childrenCount, depth, indexedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchIndexEntryRow &&
          other.path == this.path &&
          other.rootPath == this.rootPath &&
          other.parentPath == this.parentPath &&
          other.name == this.name &&
          other.type == this.type &&
          other.modifiedAt == this.modifiedAt &&
          other.sizeBytes == this.sizeBytes &&
          other.childrenCount == this.childrenCount &&
          other.depth == this.depth &&
          other.indexedAt == this.indexedAt);
}

class SearchIndexEntryRowsCompanion
    extends UpdateCompanion<SearchIndexEntryRow> {
  final Value<String> path;
  final Value<String> rootPath;
  final Value<String> parentPath;
  final Value<String> name;
  final Value<FileSystemEntryType> type;
  final Value<DateTime> modifiedAt;
  final Value<int?> sizeBytes;
  final Value<int?> childrenCount;
  final Value<int> depth;
  final Value<DateTime> indexedAt;
  final Value<int> rowid;
  const SearchIndexEntryRowsCompanion({
    this.path = const Value.absent(),
    this.rootPath = const Value.absent(),
    this.parentPath = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.childrenCount = const Value.absent(),
    this.depth = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchIndexEntryRowsCompanion.insert({
    required String path,
    required String rootPath,
    required String parentPath,
    required String name,
    required FileSystemEntryType type,
    required DateTime modifiedAt,
    this.sizeBytes = const Value.absent(),
    this.childrenCount = const Value.absent(),
    required int depth,
    required DateTime indexedAt,
    this.rowid = const Value.absent(),
  })  : path = Value(path),
        rootPath = Value(rootPath),
        parentPath = Value(parentPath),
        name = Value(name),
        type = Value(type),
        modifiedAt = Value(modifiedAt),
        depth = Value(depth),
        indexedAt = Value(indexedAt);
  static Insertable<SearchIndexEntryRow> custom({
    Expression<String>? path,
    Expression<String>? rootPath,
    Expression<String>? parentPath,
    Expression<String>? name,
    Expression<int>? type,
    Expression<DateTime>? modifiedAt,
    Expression<int>? sizeBytes,
    Expression<int>? childrenCount,
    Expression<int>? depth,
    Expression<DateTime>? indexedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (rootPath != null) 'root_path': rootPath,
      if (parentPath != null) 'parent_path': parentPath,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (childrenCount != null) 'children_count': childrenCount,
      if (depth != null) 'depth': depth,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchIndexEntryRowsCompanion copyWith(
      {Value<String>? path,
      Value<String>? rootPath,
      Value<String>? parentPath,
      Value<String>? name,
      Value<FileSystemEntryType>? type,
      Value<DateTime>? modifiedAt,
      Value<int?>? sizeBytes,
      Value<int?>? childrenCount,
      Value<int>? depth,
      Value<DateTime>? indexedAt,
      Value<int>? rowid}) {
    return SearchIndexEntryRowsCompanion(
      path: path ?? this.path,
      rootPath: rootPath ?? this.rootPath,
      parentPath: parentPath ?? this.parentPath,
      name: name ?? this.name,
      type: type ?? this.type,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      childrenCount: childrenCount ?? this.childrenCount,
      depth: depth ?? this.depth,
      indexedAt: indexedAt ?? this.indexedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (rootPath.present) {
      map['root_path'] = Variable<String>(rootPath.value);
    }
    if (parentPath.present) {
      map['parent_path'] = Variable<String>(parentPath.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $SearchIndexEntryRowsTable.$convertertype.toSql(type.value));
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (childrenCount.present) {
      map['children_count'] = Variable<int>(childrenCount.value);
    }
    if (depth.present) {
      map['depth'] = Variable<int>(depth.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexEntryRowsCompanion(')
          ..write('path: $path, ')
          ..write('rootPath: $rootPath, ')
          ..write('parentPath: $parentPath, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('childrenCount: $childrenCount, ')
          ..write('depth: $depth, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
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
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_rows';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SettingRow(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
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

  SettingRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
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
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<SettingRow> custom({
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

  SettingRowsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SettingRowsCompanion(
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
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadTaskRowsTable extends DownloadTaskRows
    with TableInfo<$DownloadTaskRowsTable, DownloadTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadTaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadMediaType, int>
      mediaType = GeneratedColumn<int>('media_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DownloadMediaType>(
              $DownloadTaskRowsTable.$convertermediaType);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadTaskStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<DownloadTaskStatus>(
              $DownloadTaskRowsTable.$converterstatus);
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
  static const VerificationMeta _outputDirectoryMeta =
      const VerificationMeta('outputDirectory');
  @override
  late final GeneratedColumn<String> outputDirectory = GeneratedColumn<String>(
      'output_directory', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _speedBytesPerSecondMeta =
      const VerificationMeta('speedBytesPerSecond');
  @override
  late final GeneratedColumn<double> speedBytesPerSecond =
      GeneratedColumn<double>('speed_bytes_per_second', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _failureMessageMeta =
      const VerificationMeta('failureMessage');
  @override
  late final GeneratedColumn<String> failureMessage = GeneratedColumn<String>(
      'failure_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        url,
        mediaType,
        title,
        status,
        createdAt,
        updatedAt,
        outputDirectory,
        transferredBytes,
        totalBytes,
        speedBytesPerSecond,
        fileName,
        failureMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_task_rows';
  @override
  VerificationContext validateIntegrity(Insertable<DownloadTaskRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
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
    if (data.containsKey('output_directory')) {
      context.handle(
          _outputDirectoryMeta,
          outputDirectory.isAcceptableOrUnknown(
              data['output_directory']!, _outputDirectoryMeta));
    } else if (isInserting) {
      context.missing(_outputDirectoryMeta);
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
    if (data.containsKey('speed_bytes_per_second')) {
      context.handle(
          _speedBytesPerSecondMeta,
          speedBytesPerSecond.isAcceptableOrUnknown(
              data['speed_bytes_per_second']!, _speedBytesPerSecondMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    }
    if (data.containsKey('failure_message')) {
      context.handle(
          _failureMessageMeta,
          failureMessage.isAcceptableOrUnknown(
              data['failure_message']!, _failureMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadTaskRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      mediaType: $DownloadTaskRowsTable.$convertermediaType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}media_type'])!),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      status: $DownloadTaskRowsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      outputDirectory: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}output_directory'])!,
      transferredBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}transferred_bytes'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes']),
      speedBytesPerSecond: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}speed_bytes_per_second'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name']),
      failureMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_message']),
    );
  }

  @override
  $DownloadTaskRowsTable createAlias(String alias) {
    return $DownloadTaskRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadMediaType, int, int> $convertermediaType =
      const EnumIndexConverter<DownloadMediaType>(DownloadMediaType.values);
  static JsonTypeConverter2<DownloadTaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<DownloadTaskStatus>(DownloadTaskStatus.values);
}

class DownloadTaskRow extends DataClass implements Insertable<DownloadTaskRow> {
  final String id;
  final String url;
  final DownloadMediaType mediaType;
  final String? title;
  final DownloadTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String outputDirectory;
  final int transferredBytes;
  final int? totalBytes;
  final double speedBytesPerSecond;
  final String? fileName;
  final String? failureMessage;
  const DownloadTaskRow(
      {required this.id,
      required this.url,
      required this.mediaType,
      this.title,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      required this.outputDirectory,
      required this.transferredBytes,
      this.totalBytes,
      required this.speedBytesPerSecond,
      this.fileName,
      this.failureMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    {
      map['media_type'] = Variable<int>(
          $DownloadTaskRowsTable.$convertermediaType.toSql(mediaType));
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    {
      map['status'] =
          Variable<int>($DownloadTaskRowsTable.$converterstatus.toSql(status));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['output_directory'] = Variable<String>(outputDirectory);
    map['transferred_bytes'] = Variable<int>(transferredBytes);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    map['speed_bytes_per_second'] = Variable<double>(speedBytesPerSecond);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || failureMessage != null) {
      map['failure_message'] = Variable<String>(failureMessage);
    }
    return map;
  }

  DownloadTaskRowsCompanion toCompanion(bool nullToAbsent) {
    return DownloadTaskRowsCompanion(
      id: Value(id),
      url: Value(url),
      mediaType: Value(mediaType),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      outputDirectory: Value(outputDirectory),
      transferredBytes: Value(transferredBytes),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      speedBytesPerSecond: Value(speedBytesPerSecond),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      failureMessage: failureMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(failureMessage),
    );
  }

  factory DownloadTaskRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadTaskRow(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      mediaType: $DownloadTaskRowsTable.$convertermediaType
          .fromJson(serializer.fromJson<int>(json['mediaType'])),
      title: serializer.fromJson<String?>(json['title']),
      status: $DownloadTaskRowsTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      outputDirectory: serializer.fromJson<String>(json['outputDirectory']),
      transferredBytes: serializer.fromJson<int>(json['transferredBytes']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      speedBytesPerSecond:
          serializer.fromJson<double>(json['speedBytesPerSecond']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      failureMessage: serializer.fromJson<String?>(json['failureMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'mediaType': serializer.toJson<int>(
          $DownloadTaskRowsTable.$convertermediaType.toJson(mediaType)),
      'title': serializer.toJson<String?>(title),
      'status': serializer
          .toJson<int>($DownloadTaskRowsTable.$converterstatus.toJson(status)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'outputDirectory': serializer.toJson<String>(outputDirectory),
      'transferredBytes': serializer.toJson<int>(transferredBytes),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'speedBytesPerSecond': serializer.toJson<double>(speedBytesPerSecond),
      'fileName': serializer.toJson<String?>(fileName),
      'failureMessage': serializer.toJson<String?>(failureMessage),
    };
  }

  DownloadTaskRow copyWith(
          {String? id,
          String? url,
          DownloadMediaType? mediaType,
          Value<String?> title = const Value.absent(),
          DownloadTaskStatus? status,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? outputDirectory,
          int? transferredBytes,
          Value<int?> totalBytes = const Value.absent(),
          double? speedBytesPerSecond,
          Value<String?> fileName = const Value.absent(),
          Value<String?> failureMessage = const Value.absent()}) =>
      DownloadTaskRow(
        id: id ?? this.id,
        url: url ?? this.url,
        mediaType: mediaType ?? this.mediaType,
        title: title.present ? title.value : this.title,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        outputDirectory: outputDirectory ?? this.outputDirectory,
        transferredBytes: transferredBytes ?? this.transferredBytes,
        totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
        speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
        fileName: fileName.present ? fileName.value : this.fileName,
        failureMessage:
            failureMessage.present ? failureMessage.value : this.failureMessage,
      );
  DownloadTaskRow copyWithCompanion(DownloadTaskRowsCompanion data) {
    return DownloadTaskRow(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      outputDirectory: data.outputDirectory.present
          ? data.outputDirectory.value
          : this.outputDirectory,
      transferredBytes: data.transferredBytes.present
          ? data.transferredBytes.value
          : this.transferredBytes,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      speedBytesPerSecond: data.speedBytesPerSecond.present
          ? data.speedBytesPerSecond.value
          : this.speedBytesPerSecond,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      failureMessage: data.failureMessage.present
          ? data.failureMessage.value
          : this.failureMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTaskRow(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('outputDirectory: $outputDirectory, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('speedBytesPerSecond: $speedBytesPerSecond, ')
          ..write('fileName: $fileName, ')
          ..write('failureMessage: $failureMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      url,
      mediaType,
      title,
      status,
      createdAt,
      updatedAt,
      outputDirectory,
      transferredBytes,
      totalBytes,
      speedBytesPerSecond,
      fileName,
      failureMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadTaskRow &&
          other.id == this.id &&
          other.url == this.url &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.outputDirectory == this.outputDirectory &&
          other.transferredBytes == this.transferredBytes &&
          other.totalBytes == this.totalBytes &&
          other.speedBytesPerSecond == this.speedBytesPerSecond &&
          other.fileName == this.fileName &&
          other.failureMessage == this.failureMessage);
}

class DownloadTaskRowsCompanion extends UpdateCompanion<DownloadTaskRow> {
  final Value<String> id;
  final Value<String> url;
  final Value<DownloadMediaType> mediaType;
  final Value<String?> title;
  final Value<DownloadTaskStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> outputDirectory;
  final Value<int> transferredBytes;
  final Value<int?> totalBytes;
  final Value<double> speedBytesPerSecond;
  final Value<String?> fileName;
  final Value<String?> failureMessage;
  final Value<int> rowid;
  const DownloadTaskRowsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.outputDirectory = const Value.absent(),
    this.transferredBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.speedBytesPerSecond = const Value.absent(),
    this.fileName = const Value.absent(),
    this.failureMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadTaskRowsCompanion.insert({
    required String id,
    required String url,
    required DownloadMediaType mediaType,
    this.title = const Value.absent(),
    required DownloadTaskStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String outputDirectory,
    this.transferredBytes = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.speedBytesPerSecond = const Value.absent(),
    this.fileName = const Value.absent(),
    this.failureMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        url = Value(url),
        mediaType = Value(mediaType),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        outputDirectory = Value(outputDirectory);
  static Insertable<DownloadTaskRow> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<int>? mediaType,
    Expression<String>? title,
    Expression<int>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? outputDirectory,
    Expression<int>? transferredBytes,
    Expression<int>? totalBytes,
    Expression<double>? speedBytesPerSecond,
    Expression<String>? fileName,
    Expression<String>? failureMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (outputDirectory != null) 'output_directory': outputDirectory,
      if (transferredBytes != null) 'transferred_bytes': transferredBytes,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (speedBytesPerSecond != null)
        'speed_bytes_per_second': speedBytesPerSecond,
      if (fileName != null) 'file_name': fileName,
      if (failureMessage != null) 'failure_message': failureMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadTaskRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? url,
      Value<DownloadMediaType>? mediaType,
      Value<String?>? title,
      Value<DownloadTaskStatus>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? outputDirectory,
      Value<int>? transferredBytes,
      Value<int?>? totalBytes,
      Value<double>? speedBytesPerSecond,
      Value<String?>? fileName,
      Value<String?>? failureMessage,
      Value<int>? rowid}) {
    return DownloadTaskRowsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      fileName: fileName ?? this.fileName,
      failureMessage: failureMessage ?? this.failureMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<int>(
          $DownloadTaskRowsTable.$convertermediaType.toSql(mediaType.value));
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $DownloadTaskRowsTable.$converterstatus.toSql(status.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (outputDirectory.present) {
      map['output_directory'] = Variable<String>(outputDirectory.value);
    }
    if (transferredBytes.present) {
      map['transferred_bytes'] = Variable<int>(transferredBytes.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (speedBytesPerSecond.present) {
      map['speed_bytes_per_second'] =
          Variable<double>(speedBytesPerSecond.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (failureMessage.present) {
      map['failure_message'] = Variable<String>(failureMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTaskRowsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('outputDirectory: $outputDirectory, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('speedBytesPerSecond: $speedBytesPerSecond, ')
          ..write('fileName: $fileName, ')
          ..write('failureMessage: $failureMessage, ')
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
  late final $FavoriteLocationRowsTable favoriteLocationRows =
      $FavoriteLocationRowsTable(this);
  late final $RecentLocationRowsTable recentLocationRows =
      $RecentLocationRowsTable(this);
  late final $SearchIndexEntryRowsTable searchIndexEntryRows =
      $SearchIndexEntryRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  late final $DownloadTaskRowsTable downloadTaskRows =
      $DownloadTaskRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        transferTaskRows,
        favoriteLocationRows,
        recentLocationRows,
        searchIndexEntryRows,
        settingRows,
        downloadTaskRows
      ];
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
typedef $$FavoriteLocationRowsTableCreateCompanionBuilder
    = FavoriteLocationRowsCompanion Function({
  required String path,
  required String label,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FavoriteLocationRowsTableUpdateCompanionBuilder
    = FavoriteLocationRowsCompanion Function({
  Value<String> path,
  Value<String> label,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$FavoriteLocationRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteLocationRowsTable> {
  $$FavoriteLocationRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FavoriteLocationRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteLocationRowsTable> {
  $$FavoriteLocationRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FavoriteLocationRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteLocationRowsTable> {
  $$FavoriteLocationRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FavoriteLocationRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoriteLocationRowsTable,
    FavoriteLocationRow,
    $$FavoriteLocationRowsTableFilterComposer,
    $$FavoriteLocationRowsTableOrderingComposer,
    $$FavoriteLocationRowsTableAnnotationComposer,
    $$FavoriteLocationRowsTableCreateCompanionBuilder,
    $$FavoriteLocationRowsTableUpdateCompanionBuilder,
    (
      FavoriteLocationRow,
      BaseReferences<_$AppDatabase, $FavoriteLocationRowsTable,
          FavoriteLocationRow>
    ),
    FavoriteLocationRow,
    PrefetchHooks Function()> {
  $$FavoriteLocationRowsTableTableManager(
      _$AppDatabase db, $FavoriteLocationRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteLocationRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteLocationRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteLocationRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> path = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteLocationRowsCompanion(
            path: path,
            label: label,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String path,
            required String label,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteLocationRowsCompanion.insert(
            path: path,
            label: label,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteLocationRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $FavoriteLocationRowsTable,
        FavoriteLocationRow,
        $$FavoriteLocationRowsTableFilterComposer,
        $$FavoriteLocationRowsTableOrderingComposer,
        $$FavoriteLocationRowsTableAnnotationComposer,
        $$FavoriteLocationRowsTableCreateCompanionBuilder,
        $$FavoriteLocationRowsTableUpdateCompanionBuilder,
        (
          FavoriteLocationRow,
          BaseReferences<_$AppDatabase, $FavoriteLocationRowsTable,
              FavoriteLocationRow>
        ),
        FavoriteLocationRow,
        PrefetchHooks Function()>;
typedef $$RecentLocationRowsTableCreateCompanionBuilder
    = RecentLocationRowsCompanion Function({
  required String path,
  required String label,
  required DateTime openedAt,
  Value<int> openCount,
  Value<bool> isFolder,
  Value<int> rowid,
});
typedef $$RecentLocationRowsTableUpdateCompanionBuilder
    = RecentLocationRowsCompanion Function({
  Value<String> path,
  Value<String> label,
  Value<DateTime> openedAt,
  Value<int> openCount,
  Value<bool> isFolder,
  Value<int> rowid,
});

class $$RecentLocationRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentLocationRowsTable> {
  $$RecentLocationRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openCount => $composableBuilder(
      column: $table.openCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFolder => $composableBuilder(
      column: $table.isFolder, builder: (column) => ColumnFilters(column));
}

class $$RecentLocationRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentLocationRowsTable> {
  $$RecentLocationRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openCount => $composableBuilder(
      column: $table.openCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFolder => $composableBuilder(
      column: $table.isFolder, builder: (column) => ColumnOrderings(column));
}

class $$RecentLocationRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentLocationRowsTable> {
  $$RecentLocationRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<int> get openCount =>
      $composableBuilder(column: $table.openCount, builder: (column) => column);

  GeneratedColumn<bool> get isFolder =>
      $composableBuilder(column: $table.isFolder, builder: (column) => column);
}

class $$RecentLocationRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecentLocationRowsTable,
    RecentLocationRow,
    $$RecentLocationRowsTableFilterComposer,
    $$RecentLocationRowsTableOrderingComposer,
    $$RecentLocationRowsTableAnnotationComposer,
    $$RecentLocationRowsTableCreateCompanionBuilder,
    $$RecentLocationRowsTableUpdateCompanionBuilder,
    (
      RecentLocationRow,
      BaseReferences<_$AppDatabase, $RecentLocationRowsTable, RecentLocationRow>
    ),
    RecentLocationRow,
    PrefetchHooks Function()> {
  $$RecentLocationRowsTableTableManager(
      _$AppDatabase db, $RecentLocationRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentLocationRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentLocationRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentLocationRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> path = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<int> openCount = const Value.absent(),
            Value<bool> isFolder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecentLocationRowsCompanion(
            path: path,
            label: label,
            openedAt: openedAt,
            openCount: openCount,
            isFolder: isFolder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String path,
            required String label,
            required DateTime openedAt,
            Value<int> openCount = const Value.absent(),
            Value<bool> isFolder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecentLocationRowsCompanion.insert(
            path: path,
            label: label,
            openedAt: openedAt,
            openCount: openCount,
            isFolder: isFolder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecentLocationRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecentLocationRowsTable,
    RecentLocationRow,
    $$RecentLocationRowsTableFilterComposer,
    $$RecentLocationRowsTableOrderingComposer,
    $$RecentLocationRowsTableAnnotationComposer,
    $$RecentLocationRowsTableCreateCompanionBuilder,
    $$RecentLocationRowsTableUpdateCompanionBuilder,
    (
      RecentLocationRow,
      BaseReferences<_$AppDatabase, $RecentLocationRowsTable, RecentLocationRow>
    ),
    RecentLocationRow,
    PrefetchHooks Function()>;
typedef $$SearchIndexEntryRowsTableCreateCompanionBuilder
    = SearchIndexEntryRowsCompanion Function({
  required String path,
  required String rootPath,
  required String parentPath,
  required String name,
  required FileSystemEntryType type,
  required DateTime modifiedAt,
  Value<int?> sizeBytes,
  Value<int?> childrenCount,
  required int depth,
  required DateTime indexedAt,
  Value<int> rowid,
});
typedef $$SearchIndexEntryRowsTableUpdateCompanionBuilder
    = SearchIndexEntryRowsCompanion Function({
  Value<String> path,
  Value<String> rootPath,
  Value<String> parentPath,
  Value<String> name,
  Value<FileSystemEntryType> type,
  Value<DateTime> modifiedAt,
  Value<int?> sizeBytes,
  Value<int?> childrenCount,
  Value<int> depth,
  Value<DateTime> indexedAt,
  Value<int> rowid,
});

class $$SearchIndexEntryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SearchIndexEntryRowsTable> {
  $$SearchIndexEntryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootPath => $composableBuilder(
      column: $table.rootPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentPath => $composableBuilder(
      column: $table.parentPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<FileSystemEntryType, FileSystemEntryType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get childrenCount => $composableBuilder(
      column: $table.childrenCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get depth => $composableBuilder(
      column: $table.depth, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
      column: $table.indexedAt, builder: (column) => ColumnFilters(column));
}

class $$SearchIndexEntryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchIndexEntryRowsTable> {
  $$SearchIndexEntryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootPath => $composableBuilder(
      column: $table.rootPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentPath => $composableBuilder(
      column: $table.parentPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get childrenCount => $composableBuilder(
      column: $table.childrenCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get depth => $composableBuilder(
      column: $table.depth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
      column: $table.indexedAt, builder: (column) => ColumnOrderings(column));
}

class $$SearchIndexEntryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchIndexEntryRowsTable> {
  $$SearchIndexEntryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => column);

  GeneratedColumn<String> get parentPath => $composableBuilder(
      column: $table.parentPath, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FileSystemEntryType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get childrenCount => $composableBuilder(
      column: $table.childrenCount, builder: (column) => column);

  GeneratedColumn<int> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);
}

class $$SearchIndexEntryRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SearchIndexEntryRowsTable,
    SearchIndexEntryRow,
    $$SearchIndexEntryRowsTableFilterComposer,
    $$SearchIndexEntryRowsTableOrderingComposer,
    $$SearchIndexEntryRowsTableAnnotationComposer,
    $$SearchIndexEntryRowsTableCreateCompanionBuilder,
    $$SearchIndexEntryRowsTableUpdateCompanionBuilder,
    (
      SearchIndexEntryRow,
      BaseReferences<_$AppDatabase, $SearchIndexEntryRowsTable,
          SearchIndexEntryRow>
    ),
    SearchIndexEntryRow,
    PrefetchHooks Function()> {
  $$SearchIndexEntryRowsTableTableManager(
      _$AppDatabase db, $SearchIndexEntryRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchIndexEntryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchIndexEntryRowsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchIndexEntryRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> path = const Value.absent(),
            Value<String> rootPath = const Value.absent(),
            Value<String> parentPath = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<FileSystemEntryType> type = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<int?> childrenCount = const Value.absent(),
            Value<int> depth = const Value.absent(),
            Value<DateTime> indexedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchIndexEntryRowsCompanion(
            path: path,
            rootPath: rootPath,
            parentPath: parentPath,
            name: name,
            type: type,
            modifiedAt: modifiedAt,
            sizeBytes: sizeBytes,
            childrenCount: childrenCount,
            depth: depth,
            indexedAt: indexedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String path,
            required String rootPath,
            required String parentPath,
            required String name,
            required FileSystemEntryType type,
            required DateTime modifiedAt,
            Value<int?> sizeBytes = const Value.absent(),
            Value<int?> childrenCount = const Value.absent(),
            required int depth,
            required DateTime indexedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchIndexEntryRowsCompanion.insert(
            path: path,
            rootPath: rootPath,
            parentPath: parentPath,
            name: name,
            type: type,
            modifiedAt: modifiedAt,
            sizeBytes: sizeBytes,
            childrenCount: childrenCount,
            depth: depth,
            indexedAt: indexedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SearchIndexEntryRowsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SearchIndexEntryRowsTable,
        SearchIndexEntryRow,
        $$SearchIndexEntryRowsTableFilterComposer,
        $$SearchIndexEntryRowsTableOrderingComposer,
        $$SearchIndexEntryRowsTableAnnotationComposer,
        $$SearchIndexEntryRowsTableCreateCompanionBuilder,
        $$SearchIndexEntryRowsTableUpdateCompanionBuilder,
        (
          SearchIndexEntryRow,
          BaseReferences<_$AppDatabase, $SearchIndexEntryRowsTable,
              SearchIndexEntryRow>
        ),
        SearchIndexEntryRow,
        PrefetchHooks Function()>;
typedef $$SettingRowsTableCreateCompanionBuilder = SettingRowsCompanion
    Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SettingRowsTableUpdateCompanionBuilder = SettingRowsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SettingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
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

class $$SettingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
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

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
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

class $$SettingRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingRowsTable,
    SettingRow,
    $$SettingRowsTableFilterComposer,
    $$SettingRowsTableOrderingComposer,
    $$SettingRowsTableAnnotationComposer,
    $$SettingRowsTableCreateCompanionBuilder,
    $$SettingRowsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingRowsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingRowsCompanion.insert(
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

typedef $$SettingRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingRowsTable,
    SettingRow,
    $$SettingRowsTableFilterComposer,
    $$SettingRowsTableOrderingComposer,
    $$SettingRowsTableAnnotationComposer,
    $$SettingRowsTableCreateCompanionBuilder,
    $$SettingRowsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;
typedef $$DownloadTaskRowsTableCreateCompanionBuilder
    = DownloadTaskRowsCompanion Function({
  required String id,
  required String url,
  required DownloadMediaType mediaType,
  Value<String?> title,
  required DownloadTaskStatus status,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String outputDirectory,
  Value<int> transferredBytes,
  Value<int?> totalBytes,
  Value<double> speedBytesPerSecond,
  Value<String?> fileName,
  Value<String?> failureMessage,
  Value<int> rowid,
});
typedef $$DownloadTaskRowsTableUpdateCompanionBuilder
    = DownloadTaskRowsCompanion Function({
  Value<String> id,
  Value<String> url,
  Value<DownloadMediaType> mediaType,
  Value<String?> title,
  Value<DownloadTaskStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> outputDirectory,
  Value<int> transferredBytes,
  Value<int?> totalBytes,
  Value<double> speedBytesPerSecond,
  Value<String?> fileName,
  Value<String?> failureMessage,
  Value<int> rowid,
});

class $$DownloadTaskRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadTaskRowsTable> {
  $$DownloadTaskRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DownloadMediaType, DownloadMediaType, int>
      get mediaType => $composableBuilder(
          column: $table.mediaType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DownloadTaskStatus, DownloadTaskStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outputDirectory => $composableBuilder(
      column: $table.outputDirectory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transferredBytes => $composableBuilder(
      column: $table.transferredBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speedBytesPerSecond => $composableBuilder(
      column: $table.speedBytesPerSecond,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get failureMessage => $composableBuilder(
      column: $table.failureMessage,
      builder: (column) => ColumnFilters(column));
}

class $$DownloadTaskRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadTaskRowsTable> {
  $$DownloadTaskRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outputDirectory => $composableBuilder(
      column: $table.outputDirectory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transferredBytes => $composableBuilder(
      column: $table.transferredBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speedBytesPerSecond => $composableBuilder(
      column: $table.speedBytesPerSecond,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get failureMessage => $composableBuilder(
      column: $table.failureMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$DownloadTaskRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadTaskRowsTable> {
  $$DownloadTaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadMediaType, int> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadTaskStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get outputDirectory => $composableBuilder(
      column: $table.outputDirectory, builder: (column) => column);

  GeneratedColumn<int> get transferredBytes => $composableBuilder(
      column: $table.transferredBytes, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<double> get speedBytesPerSecond => $composableBuilder(
      column: $table.speedBytesPerSecond, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get failureMessage => $composableBuilder(
      column: $table.failureMessage, builder: (column) => column);
}

class $$DownloadTaskRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadTaskRowsTable,
    DownloadTaskRow,
    $$DownloadTaskRowsTableFilterComposer,
    $$DownloadTaskRowsTableOrderingComposer,
    $$DownloadTaskRowsTableAnnotationComposer,
    $$DownloadTaskRowsTableCreateCompanionBuilder,
    $$DownloadTaskRowsTableUpdateCompanionBuilder,
    (
      DownloadTaskRow,
      BaseReferences<_$AppDatabase, $DownloadTaskRowsTable, DownloadTaskRow>
    ),
    DownloadTaskRow,
    PrefetchHooks Function()> {
  $$DownloadTaskRowsTableTableManager(
      _$AppDatabase db, $DownloadTaskRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadTaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadTaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadTaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<DownloadMediaType> mediaType = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<DownloadTaskStatus> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> outputDirectory = const Value.absent(),
            Value<int> transferredBytes = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<double> speedBytesPerSecond = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> failureMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadTaskRowsCompanion(
            id: id,
            url: url,
            mediaType: mediaType,
            title: title,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            outputDirectory: outputDirectory,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            speedBytesPerSecond: speedBytesPerSecond,
            fileName: fileName,
            failureMessage: failureMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String url,
            required DownloadMediaType mediaType,
            Value<String?> title = const Value.absent(),
            required DownloadTaskStatus status,
            required DateTime createdAt,
            required DateTime updatedAt,
            required String outputDirectory,
            Value<int> transferredBytes = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<double> speedBytesPerSecond = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> failureMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadTaskRowsCompanion.insert(
            id: id,
            url: url,
            mediaType: mediaType,
            title: title,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            outputDirectory: outputDirectory,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            speedBytesPerSecond: speedBytesPerSecond,
            fileName: fileName,
            failureMessage: failureMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadTaskRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadTaskRowsTable,
    DownloadTaskRow,
    $$DownloadTaskRowsTableFilterComposer,
    $$DownloadTaskRowsTableOrderingComposer,
    $$DownloadTaskRowsTableAnnotationComposer,
    $$DownloadTaskRowsTableCreateCompanionBuilder,
    $$DownloadTaskRowsTableUpdateCompanionBuilder,
    (
      DownloadTaskRow,
      BaseReferences<_$AppDatabase, $DownloadTaskRowsTable, DownloadTaskRow>
    ),
    DownloadTaskRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransferTaskRowsTableTableManager get transferTaskRows =>
      $$TransferTaskRowsTableTableManager(_db, _db.transferTaskRows);
  $$FavoriteLocationRowsTableTableManager get favoriteLocationRows =>
      $$FavoriteLocationRowsTableTableManager(_db, _db.favoriteLocationRows);
  $$RecentLocationRowsTableTableManager get recentLocationRows =>
      $$RecentLocationRowsTableTableManager(_db, _db.recentLocationRows);
  $$SearchIndexEntryRowsTableTableManager get searchIndexEntryRows =>
      $$SearchIndexEntryRowsTableTableManager(_db, _db.searchIndexEntryRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
  $$DownloadTaskRowsTableTableManager get downloadTaskRows =>
      $$DownloadTaskRowsTableTableManager(_db, _db.downloadTaskRows);
}
