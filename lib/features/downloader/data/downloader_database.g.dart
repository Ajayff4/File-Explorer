// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloader_database.dart';

// ignore_for_file: type=lint
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
  @override
  late final GeneratedColumnWithTypeConverter<DownloadQuality?, int> quality =
      GeneratedColumn<int>('quality', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<DownloadQuality?>(
              $DownloadTaskRowsTable.$converterqualityn);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadAudioFormat, int>
      audioFormat = GeneratedColumn<int>('audio_format', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<DownloadAudioFormat>(
              $DownloadTaskRowsTable.$converteraudioFormat);
  static const VerificationMeta _playlistMeta =
      const VerificationMeta('playlist');
  @override
  late final GeneratedColumn<bool> playlist = GeneratedColumn<bool>(
      'playlist', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("playlist" IN (0, 1))'),
      defaultValue: const Constant(false));
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
        quality,
        audioFormat,
        playlist,
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
    if (data.containsKey('playlist')) {
      context.handle(_playlistMeta,
          playlist.isAcceptableOrUnknown(data['playlist']!, _playlistMeta));
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
      quality: $DownloadTaskRowsTable.$converterqualityn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}quality'])),
      audioFormat: $DownloadTaskRowsTable.$converteraudioFormat.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}audio_format'])!),
      playlist: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}playlist'])!,
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
  static JsonTypeConverter2<DownloadQuality, int, int> $converterquality =
      const EnumIndexConverter<DownloadQuality>(DownloadQuality.values);
  static JsonTypeConverter2<DownloadQuality?, int?, int?> $converterqualityn =
      JsonTypeConverter2.asNullable($converterquality);
  static JsonTypeConverter2<DownloadAudioFormat, int, int>
      $converteraudioFormat =
      const EnumIndexConverter<DownloadAudioFormat>(DownloadAudioFormat.values);
  static JsonTypeConverter2<DownloadTaskStatus, int, int> $converterstatus =
      const EnumIndexConverter<DownloadTaskStatus>(DownloadTaskStatus.values);
}

class DownloadTaskRow extends DataClass implements Insertable<DownloadTaskRow> {
  final String id;
  final String url;
  final DownloadMediaType mediaType;
  final DownloadQuality? quality;
  final DownloadAudioFormat audioFormat;
  final bool playlist;
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
      this.quality,
      required this.audioFormat,
      required this.playlist,
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
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<int>(
          $DownloadTaskRowsTable.$converterqualityn.toSql(quality));
    }
    {
      map['audio_format'] = Variable<int>(
          $DownloadTaskRowsTable.$converteraudioFormat.toSql(audioFormat));
    }
    map['playlist'] = Variable<bool>(playlist);
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
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      audioFormat: Value(audioFormat),
      playlist: Value(playlist),
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
      quality: $DownloadTaskRowsTable.$converterqualityn
          .fromJson(serializer.fromJson<int?>(json['quality'])),
      audioFormat: $DownloadTaskRowsTable.$converteraudioFormat
          .fromJson(serializer.fromJson<int>(json['audioFormat'])),
      playlist: serializer.fromJson<bool>(json['playlist']),
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
      'quality': serializer.toJson<int?>(
          $DownloadTaskRowsTable.$converterqualityn.toJson(quality)),
      'audioFormat': serializer.toJson<int>(
          $DownloadTaskRowsTable.$converteraudioFormat.toJson(audioFormat)),
      'playlist': serializer.toJson<bool>(playlist),
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
          Value<DownloadQuality?> quality = const Value.absent(),
          DownloadAudioFormat? audioFormat,
          bool? playlist,
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
        quality: quality.present ? quality.value : this.quality,
        audioFormat: audioFormat ?? this.audioFormat,
        playlist: playlist ?? this.playlist,
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
      quality: data.quality.present ? data.quality.value : this.quality,
      audioFormat:
          data.audioFormat.present ? data.audioFormat.value : this.audioFormat,
      playlist: data.playlist.present ? data.playlist.value : this.playlist,
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
          ..write('quality: $quality, ')
          ..write('audioFormat: $audioFormat, ')
          ..write('playlist: $playlist, ')
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
      quality,
      audioFormat,
      playlist,
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
          other.quality == this.quality &&
          other.audioFormat == this.audioFormat &&
          other.playlist == this.playlist &&
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
  final Value<DownloadQuality?> quality;
  final Value<DownloadAudioFormat> audioFormat;
  final Value<bool> playlist;
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
    this.quality = const Value.absent(),
    this.audioFormat = const Value.absent(),
    this.playlist = const Value.absent(),
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
    this.quality = const Value.absent(),
    this.audioFormat = const Value.absent(),
    this.playlist = const Value.absent(),
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
    Expression<int>? quality,
    Expression<int>? audioFormat,
    Expression<bool>? playlist,
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
      if (quality != null) 'quality': quality,
      if (audioFormat != null) 'audio_format': audioFormat,
      if (playlist != null) 'playlist': playlist,
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
      Value<DownloadQuality?>? quality,
      Value<DownloadAudioFormat>? audioFormat,
      Value<bool>? playlist,
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
      quality: quality ?? this.quality,
      audioFormat: audioFormat ?? this.audioFormat,
      playlist: playlist ?? this.playlist,
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
    if (quality.present) {
      map['quality'] = Variable<int>(
          $DownloadTaskRowsTable.$converterqualityn.toSql(quality.value));
    }
    if (audioFormat.present) {
      map['audio_format'] = Variable<int>($DownloadTaskRowsTable
          .$converteraudioFormat
          .toSql(audioFormat.value));
    }
    if (playlist.present) {
      map['playlist'] = Variable<bool>(playlist.value);
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
          ..write('quality: $quality, ')
          ..write('audioFormat: $audioFormat, ')
          ..write('playlist: $playlist, ')
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

abstract class _$DownloaderDatabase extends GeneratedDatabase {
  _$DownloaderDatabase(QueryExecutor e) : super(e);
  $DownloaderDatabaseManager get managers => $DownloaderDatabaseManager(this);
  late final $DownloadTaskRowsTable downloadTaskRows =
      $DownloadTaskRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloadTaskRows];
}

typedef $$DownloadTaskRowsTableCreateCompanionBuilder
    = DownloadTaskRowsCompanion Function({
  required String id,
  required String url,
  required DownloadMediaType mediaType,
  Value<DownloadQuality?> quality,
  Value<DownloadAudioFormat> audioFormat,
  Value<bool> playlist,
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
  Value<DownloadQuality?> quality,
  Value<DownloadAudioFormat> audioFormat,
  Value<bool> playlist,
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
    extends Composer<_$DownloaderDatabase, $DownloadTaskRowsTable> {
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

  ColumnWithTypeConverterFilters<DownloadQuality?, DownloadQuality, int>
      get quality => $composableBuilder(
          column: $table.quality,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DownloadAudioFormat, DownloadAudioFormat, int>
      get audioFormat => $composableBuilder(
          column: $table.audioFormat,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get playlist => $composableBuilder(
      column: $table.playlist, builder: (column) => ColumnFilters(column));

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
    extends Composer<_$DownloaderDatabase, $DownloadTaskRowsTable> {
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

  ColumnOrderings<int> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get audioFormat => $composableBuilder(
      column: $table.audioFormat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get playlist => $composableBuilder(
      column: $table.playlist, builder: (column) => ColumnOrderings(column));

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
    extends Composer<_$DownloaderDatabase, $DownloadTaskRowsTable> {
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

  GeneratedColumnWithTypeConverter<DownloadQuality?, int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadAudioFormat, int> get audioFormat =>
      $composableBuilder(
          column: $table.audioFormat, builder: (column) => column);

  GeneratedColumn<bool> get playlist =>
      $composableBuilder(column: $table.playlist, builder: (column) => column);

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
    _$DownloaderDatabase,
    $DownloadTaskRowsTable,
    DownloadTaskRow,
    $$DownloadTaskRowsTableFilterComposer,
    $$DownloadTaskRowsTableOrderingComposer,
    $$DownloadTaskRowsTableAnnotationComposer,
    $$DownloadTaskRowsTableCreateCompanionBuilder,
    $$DownloadTaskRowsTableUpdateCompanionBuilder,
    (
      DownloadTaskRow,
      BaseReferences<_$DownloaderDatabase, $DownloadTaskRowsTable,
          DownloadTaskRow>
    ),
    DownloadTaskRow,
    PrefetchHooks Function()> {
  $$DownloadTaskRowsTableTableManager(
      _$DownloaderDatabase db, $DownloadTaskRowsTable table)
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
            Value<DownloadQuality?> quality = const Value.absent(),
            Value<DownloadAudioFormat> audioFormat = const Value.absent(),
            Value<bool> playlist = const Value.absent(),
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
            quality: quality,
            audioFormat: audioFormat,
            playlist: playlist,
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
            Value<DownloadQuality?> quality = const Value.absent(),
            Value<DownloadAudioFormat> audioFormat = const Value.absent(),
            Value<bool> playlist = const Value.absent(),
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
            quality: quality,
            audioFormat: audioFormat,
            playlist: playlist,
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
    _$DownloaderDatabase,
    $DownloadTaskRowsTable,
    DownloadTaskRow,
    $$DownloadTaskRowsTableFilterComposer,
    $$DownloadTaskRowsTableOrderingComposer,
    $$DownloadTaskRowsTableAnnotationComposer,
    $$DownloadTaskRowsTableCreateCompanionBuilder,
    $$DownloadTaskRowsTableUpdateCompanionBuilder,
    (
      DownloadTaskRow,
      BaseReferences<_$DownloaderDatabase, $DownloadTaskRowsTable,
          DownloadTaskRow>
    ),
    DownloadTaskRow,
    PrefetchHooks Function()>;

class $DownloaderDatabaseManager {
  final _$DownloaderDatabase _db;
  $DownloaderDatabaseManager(this._db);
  $$DownloadTaskRowsTableTableManager get downloadTaskRows =>
      $$DownloadTaskRowsTableTableManager(_db, _db.downloadTaskRows);
}
