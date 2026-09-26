// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalDevicesTable extends LocalDevices
    with TableInfo<$LocalDevicesTable, LocalDeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('ESP Smart Energy'),
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Jakarta'),
  );
  static const VerificationMeta _tariffPerKwhMeta = const VerificationMeta(
    'tariffPerKwh',
  );
  @override
  late final GeneratedColumn<double> tariffPerKwh = GeneratedColumn<double>(
    'tariff_per_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1650),
  );
  static const VerificationMeta _gridCo2KgPerKwhMeta = const VerificationMeta(
    'gridCo2KgPerKwh',
  );
  @override
  late final GeneratedColumn<double> gridCo2KgPerKwh = GeneratedColumn<double>(
    'grid_co2_kg_per_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.42),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    name,
    endpoint,
    timezone,
    tariffPerKwh,
    gridCo2KgPerKwh,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('tariff_per_kwh')) {
      context.handle(
        _tariffPerKwhMeta,
        tariffPerKwh.isAcceptableOrUnknown(
          data['tariff_per_kwh']!,
          _tariffPerKwhMeta,
        ),
      );
    }
    if (data.containsKey('grid_co2_kg_per_kwh')) {
      context.handle(
        _gridCo2KgPerKwhMeta,
        gridCo2KgPerKwh.isAcceptableOrUnknown(
          data['grid_co2_kg_per_kwh']!,
          _gridCo2KgPerKwhMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalDeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDeviceRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      tariffPerKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tariff_per_kwh'],
      )!,
      gridCo2KgPerKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grid_co2_kg_per_kwh'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalDevicesTable createAlias(String alias) {
    return $LocalDevicesTable(attachedDatabase, alias);
  }
}

class LocalDeviceRow extends DataClass implements Insertable<LocalDeviceRow> {
  final String localId;
  final String name;
  final String? endpoint;
  final String timezone;
  final double tariffPerKwh;
  final double gridCo2KgPerKwh;
  final DateTime createdAt;
  const LocalDeviceRow({
    required this.localId,
    required this.name,
    this.endpoint,
    required this.timezone,
    required this.tariffPerKwh,
    required this.gridCo2KgPerKwh,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || endpoint != null) {
      map['endpoint'] = Variable<String>(endpoint);
    }
    map['timezone'] = Variable<String>(timezone);
    map['tariff_per_kwh'] = Variable<double>(tariffPerKwh);
    map['grid_co2_kg_per_kwh'] = Variable<double>(gridCo2KgPerKwh);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalDevicesCompanion toCompanion(bool nullToAbsent) {
    return LocalDevicesCompanion(
      localId: Value(localId),
      name: Value(name),
      endpoint: endpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(endpoint),
      timezone: Value(timezone),
      tariffPerKwh: Value(tariffPerKwh),
      gridCo2KgPerKwh: Value(gridCo2KgPerKwh),
      createdAt: Value(createdAt),
    );
  }

  factory LocalDeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDeviceRow(
      localId: serializer.fromJson<String>(json['localId']),
      name: serializer.fromJson<String>(json['name']),
      endpoint: serializer.fromJson<String?>(json['endpoint']),
      timezone: serializer.fromJson<String>(json['timezone']),
      tariffPerKwh: serializer.fromJson<double>(json['tariffPerKwh']),
      gridCo2KgPerKwh: serializer.fromJson<double>(json['gridCo2KgPerKwh']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'name': serializer.toJson<String>(name),
      'endpoint': serializer.toJson<String?>(endpoint),
      'timezone': serializer.toJson<String>(timezone),
      'tariffPerKwh': serializer.toJson<double>(tariffPerKwh),
      'gridCo2KgPerKwh': serializer.toJson<double>(gridCo2KgPerKwh),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalDeviceRow copyWith({
    String? localId,
    String? name,
    Value<String?> endpoint = const Value.absent(),
    String? timezone,
    double? tariffPerKwh,
    double? gridCo2KgPerKwh,
    DateTime? createdAt,
  }) => LocalDeviceRow(
    localId: localId ?? this.localId,
    name: name ?? this.name,
    endpoint: endpoint.present ? endpoint.value : this.endpoint,
    timezone: timezone ?? this.timezone,
    tariffPerKwh: tariffPerKwh ?? this.tariffPerKwh,
    gridCo2KgPerKwh: gridCo2KgPerKwh ?? this.gridCo2KgPerKwh,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalDeviceRow copyWithCompanion(LocalDevicesCompanion data) {
    return LocalDeviceRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      name: data.name.present ? data.name.value : this.name,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      tariffPerKwh: data.tariffPerKwh.present
          ? data.tariffPerKwh.value
          : this.tariffPerKwh,
      gridCo2KgPerKwh: data.gridCo2KgPerKwh.present
          ? data.gridCo2KgPerKwh.value
          : this.gridCo2KgPerKwh,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeviceRow(')
          ..write('localId: $localId, ')
          ..write('name: $name, ')
          ..write('endpoint: $endpoint, ')
          ..write('timezone: $timezone, ')
          ..write('tariffPerKwh: $tariffPerKwh, ')
          ..write('gridCo2KgPerKwh: $gridCo2KgPerKwh, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    name,
    endpoint,
    timezone,
    tariffPerKwh,
    gridCo2KgPerKwh,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDeviceRow &&
          other.localId == this.localId &&
          other.name == this.name &&
          other.endpoint == this.endpoint &&
          other.timezone == this.timezone &&
          other.tariffPerKwh == this.tariffPerKwh &&
          other.gridCo2KgPerKwh == this.gridCo2KgPerKwh &&
          other.createdAt == this.createdAt);
}

class LocalDevicesCompanion extends UpdateCompanion<LocalDeviceRow> {
  final Value<String> localId;
  final Value<String> name;
  final Value<String?> endpoint;
  final Value<String> timezone;
  final Value<double> tariffPerKwh;
  final Value<double> gridCo2KgPerKwh;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalDevicesCompanion({
    this.localId = const Value.absent(),
    this.name = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.timezone = const Value.absent(),
    this.tariffPerKwh = const Value.absent(),
    this.gridCo2KgPerKwh = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDevicesCompanion.insert({
    required String localId,
    this.name = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.timezone = const Value.absent(),
    this.tariffPerKwh = const Value.absent(),
    this.gridCo2KgPerKwh = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       createdAt = Value(createdAt);
  static Insertable<LocalDeviceRow> custom({
    Expression<String>? localId,
    Expression<String>? name,
    Expression<String>? endpoint,
    Expression<String>? timezone,
    Expression<double>? tariffPerKwh,
    Expression<double>? gridCo2KgPerKwh,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (name != null) 'name': name,
      if (endpoint != null) 'endpoint': endpoint,
      if (timezone != null) 'timezone': timezone,
      if (tariffPerKwh != null) 'tariff_per_kwh': tariffPerKwh,
      if (gridCo2KgPerKwh != null) 'grid_co2_kg_per_kwh': gridCo2KgPerKwh,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDevicesCompanion copyWith({
    Value<String>? localId,
    Value<String>? name,
    Value<String?>? endpoint,
    Value<String>? timezone,
    Value<double>? tariffPerKwh,
    Value<double>? gridCo2KgPerKwh,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalDevicesCompanion(
      localId: localId ?? this.localId,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      timezone: timezone ?? this.timezone,
      tariffPerKwh: tariffPerKwh ?? this.tariffPerKwh,
      gridCo2KgPerKwh: gridCo2KgPerKwh ?? this.gridCo2KgPerKwh,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (tariffPerKwh.present) {
      map['tariff_per_kwh'] = Variable<double>(tariffPerKwh.value);
    }
    if (gridCo2KgPerKwh.present) {
      map['grid_co2_kg_per_kwh'] = Variable<double>(gridCo2KgPerKwh.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDevicesCompanion(')
          ..write('localId: $localId, ')
          ..write('name: $name, ')
          ..write('endpoint: $endpoint, ')
          ..write('timezone: $timezone, ')
          ..write('tariffPerKwh: $tariffPerKwh, ')
          ..write('gridCo2KgPerKwh: $gridCo2KgPerKwh, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MinuteAggregatesTable extends MinuteAggregates
    with TableInfo<$MinuteAggregatesTable, MinuteAggregateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MinuteAggregatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceKeyMeta = const VerificationMeta(
    'deviceKey',
  );
  @override
  late final GeneratedColumn<String> deviceKey = GeneratedColumn<String>(
    'device_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteStartMeta = const VerificationMeta(
    'minuteStart',
  );
  @override
  late final GeneratedColumn<DateTime> minuteStart = GeneratedColumn<DateTime>(
    'minute_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKwhMeta = const VerificationMeta(
    'energyKwh',
  );
  @override
  late final GeneratedColumn<double> energyKwh = GeneratedColumn<double>(
    'energy_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerSumMeta = const VerificationMeta(
    'powerSum',
  );
  @override
  late final GeneratedColumn<double> powerSum = GeneratedColumn<double>(
    'power_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerMinMeta = const VerificationMeta(
    'powerMin',
  );
  @override
  late final GeneratedColumn<double> powerMin = GeneratedColumn<double>(
    'power_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerMaxMeta = const VerificationMeta(
    'powerMax',
  );
  @override
  late final GeneratedColumn<double> powerMax = GeneratedColumn<double>(
    'power_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageSumMeta = const VerificationMeta(
    'voltageSum',
  );
  @override
  late final GeneratedColumn<double> voltageSum = GeneratedColumn<double>(
    'voltage_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voltageMinMeta = const VerificationMeta(
    'voltageMin',
  );
  @override
  late final GeneratedColumn<double> voltageMin = GeneratedColumn<double>(
    'voltage_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageMaxMeta = const VerificationMeta(
    'voltageMax',
  );
  @override
  late final GeneratedColumn<double> voltageMax = GeneratedColumn<double>(
    'voltage_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentSumMeta = const VerificationMeta(
    'currentSum',
  );
  @override
  late final GeneratedColumn<double> currentSum = GeneratedColumn<double>(
    'current_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentMaxMeta = const VerificationMeta(
    'currentMax',
  );
  @override
  late final GeneratedColumn<double> currentMax = GeneratedColumn<double>(
    'current_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencySumMeta = const VerificationMeta(
    'frequencySum',
  );
  @override
  late final GeneratedColumn<double> frequencySum = GeneratedColumn<double>(
    'frequency_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _frequencyMinMeta = const VerificationMeta(
    'frequencyMin',
  );
  @override
  late final GeneratedColumn<double> frequencyMin = GeneratedColumn<double>(
    'frequency_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMaxMeta = const VerificationMeta(
    'frequencyMax',
  );
  @override
  late final GeneratedColumn<double> frequencyMax = GeneratedColumn<double>(
    'frequency_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerFactorSumMeta = const VerificationMeta(
    'powerFactorSum',
  );
  @override
  late final GeneratedColumn<double> powerFactorSum = GeneratedColumn<double>(
    'power_factor_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerFactorMinMeta = const VerificationMeta(
    'powerFactorMin',
  );
  @override
  late final GeneratedColumn<double> powerFactorMin = GeneratedColumn<double>(
    'power_factor_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _observedSecondsMeta = const VerificationMeta(
    'observedSeconds',
  );
  @override
  late final GeneratedColumn<double> observedSeconds = GeneratedColumn<double>(
    'observed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _estimatedIntervalsMeta =
      const VerificationMeta('estimatedIntervals');
  @override
  late final GeneratedColumn<int> estimatedIntervals = GeneratedColumn<int>(
    'estimated_intervals',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceKey,
    minuteStart,
    energyKwh,
    powerSum,
    powerMin,
    powerMax,
    voltageSum,
    voltageMin,
    voltageMax,
    currentSum,
    currentMax,
    frequencySum,
    frequencyMin,
    frequencyMax,
    powerFactorSum,
    powerFactorMin,
    sampleCount,
    observedSeconds,
    estimatedIntervals,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'minute_aggregates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MinuteAggregateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_key')) {
      context.handle(
        _deviceKeyMeta,
        deviceKey.isAcceptableOrUnknown(data['device_key']!, _deviceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceKeyMeta);
    }
    if (data.containsKey('minute_start')) {
      context.handle(
        _minuteStartMeta,
        minuteStart.isAcceptableOrUnknown(
          data['minute_start']!,
          _minuteStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minuteStartMeta);
    }
    if (data.containsKey('energy_kwh')) {
      context.handle(
        _energyKwhMeta,
        energyKwh.isAcceptableOrUnknown(data['energy_kwh']!, _energyKwhMeta),
      );
    }
    if (data.containsKey('power_sum')) {
      context.handle(
        _powerSumMeta,
        powerSum.isAcceptableOrUnknown(data['power_sum']!, _powerSumMeta),
      );
    }
    if (data.containsKey('power_min')) {
      context.handle(
        _powerMinMeta,
        powerMin.isAcceptableOrUnknown(data['power_min']!, _powerMinMeta),
      );
    }
    if (data.containsKey('power_max')) {
      context.handle(
        _powerMaxMeta,
        powerMax.isAcceptableOrUnknown(data['power_max']!, _powerMaxMeta),
      );
    }
    if (data.containsKey('voltage_sum')) {
      context.handle(
        _voltageSumMeta,
        voltageSum.isAcceptableOrUnknown(data['voltage_sum']!, _voltageSumMeta),
      );
    }
    if (data.containsKey('voltage_min')) {
      context.handle(
        _voltageMinMeta,
        voltageMin.isAcceptableOrUnknown(data['voltage_min']!, _voltageMinMeta),
      );
    }
    if (data.containsKey('voltage_max')) {
      context.handle(
        _voltageMaxMeta,
        voltageMax.isAcceptableOrUnknown(data['voltage_max']!, _voltageMaxMeta),
      );
    }
    if (data.containsKey('current_sum')) {
      context.handle(
        _currentSumMeta,
        currentSum.isAcceptableOrUnknown(data['current_sum']!, _currentSumMeta),
      );
    }
    if (data.containsKey('current_max')) {
      context.handle(
        _currentMaxMeta,
        currentMax.isAcceptableOrUnknown(data['current_max']!, _currentMaxMeta),
      );
    }
    if (data.containsKey('frequency_sum')) {
      context.handle(
        _frequencySumMeta,
        frequencySum.isAcceptableOrUnknown(
          data['frequency_sum']!,
          _frequencySumMeta,
        ),
      );
    }
    if (data.containsKey('frequency_min')) {
      context.handle(
        _frequencyMinMeta,
        frequencyMin.isAcceptableOrUnknown(
          data['frequency_min']!,
          _frequencyMinMeta,
        ),
      );
    }
    if (data.containsKey('frequency_max')) {
      context.handle(
        _frequencyMaxMeta,
        frequencyMax.isAcceptableOrUnknown(
          data['frequency_max']!,
          _frequencyMaxMeta,
        ),
      );
    }
    if (data.containsKey('power_factor_sum')) {
      context.handle(
        _powerFactorSumMeta,
        powerFactorSum.isAcceptableOrUnknown(
          data['power_factor_sum']!,
          _powerFactorSumMeta,
        ),
      );
    }
    if (data.containsKey('power_factor_min')) {
      context.handle(
        _powerFactorMinMeta,
        powerFactorMin.isAcceptableOrUnknown(
          data['power_factor_min']!,
          _powerFactorMinMeta,
        ),
      );
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('observed_seconds')) {
      context.handle(
        _observedSecondsMeta,
        observedSeconds.isAcceptableOrUnknown(
          data['observed_seconds']!,
          _observedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('estimated_intervals')) {
      context.handle(
        _estimatedIntervalsMeta,
        estimatedIntervals.isAcceptableOrUnknown(
          data['estimated_intervals']!,
          _estimatedIntervalsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceKey, minuteStart};
  @override
  MinuteAggregateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MinuteAggregateRow(
      deviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_key'],
      )!,
      minuteStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}minute_start'],
      )!,
      energyKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kwh'],
      )!,
      powerSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_sum'],
      )!,
      powerMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_min'],
      ),
      powerMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_max'],
      ),
      voltageSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_sum'],
      )!,
      voltageMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_min'],
      ),
      voltageMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_max'],
      ),
      currentSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_sum'],
      )!,
      currentMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_max'],
      ),
      frequencySum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_sum'],
      )!,
      frequencyMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_min'],
      ),
      frequencyMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_max'],
      ),
      powerFactorSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_factor_sum'],
      )!,
      powerFactorMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_factor_min'],
      ),
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      observedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}observed_seconds'],
      )!,
      estimatedIntervals: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_intervals'],
      )!,
    );
  }

  @override
  $MinuteAggregatesTable createAlias(String alias) {
    return $MinuteAggregatesTable(attachedDatabase, alias);
  }
}

class MinuteAggregateRow extends DataClass
    implements Insertable<MinuteAggregateRow> {
  final String deviceKey;
  final DateTime minuteStart;
  final double energyKwh;
  final double powerSum;
  final double? powerMin;
  final double? powerMax;
  final double voltageSum;
  final double? voltageMin;
  final double? voltageMax;
  final double currentSum;
  final double? currentMax;
  final double frequencySum;
  final double? frequencyMin;
  final double? frequencyMax;
  final double powerFactorSum;
  final double? powerFactorMin;
  final int sampleCount;
  final double observedSeconds;
  final int estimatedIntervals;
  const MinuteAggregateRow({
    required this.deviceKey,
    required this.minuteStart,
    required this.energyKwh,
    required this.powerSum,
    this.powerMin,
    this.powerMax,
    required this.voltageSum,
    this.voltageMin,
    this.voltageMax,
    required this.currentSum,
    this.currentMax,
    required this.frequencySum,
    this.frequencyMin,
    this.frequencyMax,
    required this.powerFactorSum,
    this.powerFactorMin,
    required this.sampleCount,
    required this.observedSeconds,
    required this.estimatedIntervals,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_key'] = Variable<String>(deviceKey);
    map['minute_start'] = Variable<DateTime>(minuteStart);
    map['energy_kwh'] = Variable<double>(energyKwh);
    map['power_sum'] = Variable<double>(powerSum);
    if (!nullToAbsent || powerMin != null) {
      map['power_min'] = Variable<double>(powerMin);
    }
    if (!nullToAbsent || powerMax != null) {
      map['power_max'] = Variable<double>(powerMax);
    }
    map['voltage_sum'] = Variable<double>(voltageSum);
    if (!nullToAbsent || voltageMin != null) {
      map['voltage_min'] = Variable<double>(voltageMin);
    }
    if (!nullToAbsent || voltageMax != null) {
      map['voltage_max'] = Variable<double>(voltageMax);
    }
    map['current_sum'] = Variable<double>(currentSum);
    if (!nullToAbsent || currentMax != null) {
      map['current_max'] = Variable<double>(currentMax);
    }
    map['frequency_sum'] = Variable<double>(frequencySum);
    if (!nullToAbsent || frequencyMin != null) {
      map['frequency_min'] = Variable<double>(frequencyMin);
    }
    if (!nullToAbsent || frequencyMax != null) {
      map['frequency_max'] = Variable<double>(frequencyMax);
    }
    map['power_factor_sum'] = Variable<double>(powerFactorSum);
    if (!nullToAbsent || powerFactorMin != null) {
      map['power_factor_min'] = Variable<double>(powerFactorMin);
    }
    map['sample_count'] = Variable<int>(sampleCount);
    map['observed_seconds'] = Variable<double>(observedSeconds);
    map['estimated_intervals'] = Variable<int>(estimatedIntervals);
    return map;
  }

  MinuteAggregatesCompanion toCompanion(bool nullToAbsent) {
    return MinuteAggregatesCompanion(
      deviceKey: Value(deviceKey),
      minuteStart: Value(minuteStart),
      energyKwh: Value(energyKwh),
      powerSum: Value(powerSum),
      powerMin: powerMin == null && nullToAbsent
          ? const Value.absent()
          : Value(powerMin),
      powerMax: powerMax == null && nullToAbsent
          ? const Value.absent()
          : Value(powerMax),
      voltageSum: Value(voltageSum),
      voltageMin: voltageMin == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageMin),
      voltageMax: voltageMax == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageMax),
      currentSum: Value(currentSum),
      currentMax: currentMax == null && nullToAbsent
          ? const Value.absent()
          : Value(currentMax),
      frequencySum: Value(frequencySum),
      frequencyMin: frequencyMin == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMin),
      frequencyMax: frequencyMax == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMax),
      powerFactorSum: Value(powerFactorSum),
      powerFactorMin: powerFactorMin == null && nullToAbsent
          ? const Value.absent()
          : Value(powerFactorMin),
      sampleCount: Value(sampleCount),
      observedSeconds: Value(observedSeconds),
      estimatedIntervals: Value(estimatedIntervals),
    );
  }

  factory MinuteAggregateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MinuteAggregateRow(
      deviceKey: serializer.fromJson<String>(json['deviceKey']),
      minuteStart: serializer.fromJson<DateTime>(json['minuteStart']),
      energyKwh: serializer.fromJson<double>(json['energyKwh']),
      powerSum: serializer.fromJson<double>(json['powerSum']),
      powerMin: serializer.fromJson<double?>(json['powerMin']),
      powerMax: serializer.fromJson<double?>(json['powerMax']),
      voltageSum: serializer.fromJson<double>(json['voltageSum']),
      voltageMin: serializer.fromJson<double?>(json['voltageMin']),
      voltageMax: serializer.fromJson<double?>(json['voltageMax']),
      currentSum: serializer.fromJson<double>(json['currentSum']),
      currentMax: serializer.fromJson<double?>(json['currentMax']),
      frequencySum: serializer.fromJson<double>(json['frequencySum']),
      frequencyMin: serializer.fromJson<double?>(json['frequencyMin']),
      frequencyMax: serializer.fromJson<double?>(json['frequencyMax']),
      powerFactorSum: serializer.fromJson<double>(json['powerFactorSum']),
      powerFactorMin: serializer.fromJson<double?>(json['powerFactorMin']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      observedSeconds: serializer.fromJson<double>(json['observedSeconds']),
      estimatedIntervals: serializer.fromJson<int>(json['estimatedIntervals']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceKey': serializer.toJson<String>(deviceKey),
      'minuteStart': serializer.toJson<DateTime>(minuteStart),
      'energyKwh': serializer.toJson<double>(energyKwh),
      'powerSum': serializer.toJson<double>(powerSum),
      'powerMin': serializer.toJson<double?>(powerMin),
      'powerMax': serializer.toJson<double?>(powerMax),
      'voltageSum': serializer.toJson<double>(voltageSum),
      'voltageMin': serializer.toJson<double?>(voltageMin),
      'voltageMax': serializer.toJson<double?>(voltageMax),
      'currentSum': serializer.toJson<double>(currentSum),
      'currentMax': serializer.toJson<double?>(currentMax),
      'frequencySum': serializer.toJson<double>(frequencySum),
      'frequencyMin': serializer.toJson<double?>(frequencyMin),
      'frequencyMax': serializer.toJson<double?>(frequencyMax),
      'powerFactorSum': serializer.toJson<double>(powerFactorSum),
      'powerFactorMin': serializer.toJson<double?>(powerFactorMin),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'observedSeconds': serializer.toJson<double>(observedSeconds),
      'estimatedIntervals': serializer.toJson<int>(estimatedIntervals),
    };
  }

  MinuteAggregateRow copyWith({
    String? deviceKey,
    DateTime? minuteStart,
    double? energyKwh,
    double? powerSum,
    Value<double?> powerMin = const Value.absent(),
    Value<double?> powerMax = const Value.absent(),
    double? voltageSum,
    Value<double?> voltageMin = const Value.absent(),
    Value<double?> voltageMax = const Value.absent(),
    double? currentSum,
    Value<double?> currentMax = const Value.absent(),
    double? frequencySum,
    Value<double?> frequencyMin = const Value.absent(),
    Value<double?> frequencyMax = const Value.absent(),
    double? powerFactorSum,
    Value<double?> powerFactorMin = const Value.absent(),
    int? sampleCount,
    double? observedSeconds,
    int? estimatedIntervals,
  }) => MinuteAggregateRow(
    deviceKey: deviceKey ?? this.deviceKey,
    minuteStart: minuteStart ?? this.minuteStart,
    energyKwh: energyKwh ?? this.energyKwh,
    powerSum: powerSum ?? this.powerSum,
    powerMin: powerMin.present ? powerMin.value : this.powerMin,
    powerMax: powerMax.present ? powerMax.value : this.powerMax,
    voltageSum: voltageSum ?? this.voltageSum,
    voltageMin: voltageMin.present ? voltageMin.value : this.voltageMin,
    voltageMax: voltageMax.present ? voltageMax.value : this.voltageMax,
    currentSum: currentSum ?? this.currentSum,
    currentMax: currentMax.present ? currentMax.value : this.currentMax,
    frequencySum: frequencySum ?? this.frequencySum,
    frequencyMin: frequencyMin.present ? frequencyMin.value : this.frequencyMin,
    frequencyMax: frequencyMax.present ? frequencyMax.value : this.frequencyMax,
    powerFactorSum: powerFactorSum ?? this.powerFactorSum,
    powerFactorMin: powerFactorMin.present
        ? powerFactorMin.value
        : this.powerFactorMin,
    sampleCount: sampleCount ?? this.sampleCount,
    observedSeconds: observedSeconds ?? this.observedSeconds,
    estimatedIntervals: estimatedIntervals ?? this.estimatedIntervals,
  );
  MinuteAggregateRow copyWithCompanion(MinuteAggregatesCompanion data) {
    return MinuteAggregateRow(
      deviceKey: data.deviceKey.present ? data.deviceKey.value : this.deviceKey,
      minuteStart: data.minuteStart.present
          ? data.minuteStart.value
          : this.minuteStart,
      energyKwh: data.energyKwh.present ? data.energyKwh.value : this.energyKwh,
      powerSum: data.powerSum.present ? data.powerSum.value : this.powerSum,
      powerMin: data.powerMin.present ? data.powerMin.value : this.powerMin,
      powerMax: data.powerMax.present ? data.powerMax.value : this.powerMax,
      voltageSum: data.voltageSum.present
          ? data.voltageSum.value
          : this.voltageSum,
      voltageMin: data.voltageMin.present
          ? data.voltageMin.value
          : this.voltageMin,
      voltageMax: data.voltageMax.present
          ? data.voltageMax.value
          : this.voltageMax,
      currentSum: data.currentSum.present
          ? data.currentSum.value
          : this.currentSum,
      currentMax: data.currentMax.present
          ? data.currentMax.value
          : this.currentMax,
      frequencySum: data.frequencySum.present
          ? data.frequencySum.value
          : this.frequencySum,
      frequencyMin: data.frequencyMin.present
          ? data.frequencyMin.value
          : this.frequencyMin,
      frequencyMax: data.frequencyMax.present
          ? data.frequencyMax.value
          : this.frequencyMax,
      powerFactorSum: data.powerFactorSum.present
          ? data.powerFactorSum.value
          : this.powerFactorSum,
      powerFactorMin: data.powerFactorMin.present
          ? data.powerFactorMin.value
          : this.powerFactorMin,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      observedSeconds: data.observedSeconds.present
          ? data.observedSeconds.value
          : this.observedSeconds,
      estimatedIntervals: data.estimatedIntervals.present
          ? data.estimatedIntervals.value
          : this.estimatedIntervals,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MinuteAggregateRow(')
          ..write('deviceKey: $deviceKey, ')
          ..write('minuteStart: $minuteStart, ')
          ..write('energyKwh: $energyKwh, ')
          ..write('powerSum: $powerSum, ')
          ..write('powerMin: $powerMin, ')
          ..write('powerMax: $powerMax, ')
          ..write('voltageSum: $voltageSum, ')
          ..write('voltageMin: $voltageMin, ')
          ..write('voltageMax: $voltageMax, ')
          ..write('currentSum: $currentSum, ')
          ..write('currentMax: $currentMax, ')
          ..write('frequencySum: $frequencySum, ')
          ..write('frequencyMin: $frequencyMin, ')
          ..write('frequencyMax: $frequencyMax, ')
          ..write('powerFactorSum: $powerFactorSum, ')
          ..write('powerFactorMin: $powerFactorMin, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('observedSeconds: $observedSeconds, ')
          ..write('estimatedIntervals: $estimatedIntervals')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceKey,
    minuteStart,
    energyKwh,
    powerSum,
    powerMin,
    powerMax,
    voltageSum,
    voltageMin,
    voltageMax,
    currentSum,
    currentMax,
    frequencySum,
    frequencyMin,
    frequencyMax,
    powerFactorSum,
    powerFactorMin,
    sampleCount,
    observedSeconds,
    estimatedIntervals,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MinuteAggregateRow &&
          other.deviceKey == this.deviceKey &&
          other.minuteStart == this.minuteStart &&
          other.energyKwh == this.energyKwh &&
          other.powerSum == this.powerSum &&
          other.powerMin == this.powerMin &&
          other.powerMax == this.powerMax &&
          other.voltageSum == this.voltageSum &&
          other.voltageMin == this.voltageMin &&
          other.voltageMax == this.voltageMax &&
          other.currentSum == this.currentSum &&
          other.currentMax == this.currentMax &&
          other.frequencySum == this.frequencySum &&
          other.frequencyMin == this.frequencyMin &&
          other.frequencyMax == this.frequencyMax &&
          other.powerFactorSum == this.powerFactorSum &&
          other.powerFactorMin == this.powerFactorMin &&
          other.sampleCount == this.sampleCount &&
          other.observedSeconds == this.observedSeconds &&
          other.estimatedIntervals == this.estimatedIntervals);
}

class MinuteAggregatesCompanion extends UpdateCompanion<MinuteAggregateRow> {
  final Value<String> deviceKey;
  final Value<DateTime> minuteStart;
  final Value<double> energyKwh;
  final Value<double> powerSum;
  final Value<double?> powerMin;
  final Value<double?> powerMax;
  final Value<double> voltageSum;
  final Value<double?> voltageMin;
  final Value<double?> voltageMax;
  final Value<double> currentSum;
  final Value<double?> currentMax;
  final Value<double> frequencySum;
  final Value<double?> frequencyMin;
  final Value<double?> frequencyMax;
  final Value<double> powerFactorSum;
  final Value<double?> powerFactorMin;
  final Value<int> sampleCount;
  final Value<double> observedSeconds;
  final Value<int> estimatedIntervals;
  final Value<int> rowid;
  const MinuteAggregatesCompanion({
    this.deviceKey = const Value.absent(),
    this.minuteStart = const Value.absent(),
    this.energyKwh = const Value.absent(),
    this.powerSum = const Value.absent(),
    this.powerMin = const Value.absent(),
    this.powerMax = const Value.absent(),
    this.voltageSum = const Value.absent(),
    this.voltageMin = const Value.absent(),
    this.voltageMax = const Value.absent(),
    this.currentSum = const Value.absent(),
    this.currentMax = const Value.absent(),
    this.frequencySum = const Value.absent(),
    this.frequencyMin = const Value.absent(),
    this.frequencyMax = const Value.absent(),
    this.powerFactorSum = const Value.absent(),
    this.powerFactorMin = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.observedSeconds = const Value.absent(),
    this.estimatedIntervals = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MinuteAggregatesCompanion.insert({
    required String deviceKey,
    required DateTime minuteStart,
    this.energyKwh = const Value.absent(),
    this.powerSum = const Value.absent(),
    this.powerMin = const Value.absent(),
    this.powerMax = const Value.absent(),
    this.voltageSum = const Value.absent(),
    this.voltageMin = const Value.absent(),
    this.voltageMax = const Value.absent(),
    this.currentSum = const Value.absent(),
    this.currentMax = const Value.absent(),
    this.frequencySum = const Value.absent(),
    this.frequencyMin = const Value.absent(),
    this.frequencyMax = const Value.absent(),
    this.powerFactorSum = const Value.absent(),
    this.powerFactorMin = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.observedSeconds = const Value.absent(),
    this.estimatedIntervals = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceKey = Value(deviceKey),
       minuteStart = Value(minuteStart);
  static Insertable<MinuteAggregateRow> custom({
    Expression<String>? deviceKey,
    Expression<DateTime>? minuteStart,
    Expression<double>? energyKwh,
    Expression<double>? powerSum,
    Expression<double>? powerMin,
    Expression<double>? powerMax,
    Expression<double>? voltageSum,
    Expression<double>? voltageMin,
    Expression<double>? voltageMax,
    Expression<double>? currentSum,
    Expression<double>? currentMax,
    Expression<double>? frequencySum,
    Expression<double>? frequencyMin,
    Expression<double>? frequencyMax,
    Expression<double>? powerFactorSum,
    Expression<double>? powerFactorMin,
    Expression<int>? sampleCount,
    Expression<double>? observedSeconds,
    Expression<int>? estimatedIntervals,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceKey != null) 'device_key': deviceKey,
      if (minuteStart != null) 'minute_start': minuteStart,
      if (energyKwh != null) 'energy_kwh': energyKwh,
      if (powerSum != null) 'power_sum': powerSum,
      if (powerMin != null) 'power_min': powerMin,
      if (powerMax != null) 'power_max': powerMax,
      if (voltageSum != null) 'voltage_sum': voltageSum,
      if (voltageMin != null) 'voltage_min': voltageMin,
      if (voltageMax != null) 'voltage_max': voltageMax,
      if (currentSum != null) 'current_sum': currentSum,
      if (currentMax != null) 'current_max': currentMax,
      if (frequencySum != null) 'frequency_sum': frequencySum,
      if (frequencyMin != null) 'frequency_min': frequencyMin,
      if (frequencyMax != null) 'frequency_max': frequencyMax,
      if (powerFactorSum != null) 'power_factor_sum': powerFactorSum,
      if (powerFactorMin != null) 'power_factor_min': powerFactorMin,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (observedSeconds != null) 'observed_seconds': observedSeconds,
      if (estimatedIntervals != null) 'estimated_intervals': estimatedIntervals,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MinuteAggregatesCompanion copyWith({
    Value<String>? deviceKey,
    Value<DateTime>? minuteStart,
    Value<double>? energyKwh,
    Value<double>? powerSum,
    Value<double?>? powerMin,
    Value<double?>? powerMax,
    Value<double>? voltageSum,
    Value<double?>? voltageMin,
    Value<double?>? voltageMax,
    Value<double>? currentSum,
    Value<double?>? currentMax,
    Value<double>? frequencySum,
    Value<double?>? frequencyMin,
    Value<double?>? frequencyMax,
    Value<double>? powerFactorSum,
    Value<double?>? powerFactorMin,
    Value<int>? sampleCount,
    Value<double>? observedSeconds,
    Value<int>? estimatedIntervals,
    Value<int>? rowid,
  }) {
    return MinuteAggregatesCompanion(
      deviceKey: deviceKey ?? this.deviceKey,
      minuteStart: minuteStart ?? this.minuteStart,
      energyKwh: energyKwh ?? this.energyKwh,
      powerSum: powerSum ?? this.powerSum,
      powerMin: powerMin ?? this.powerMin,
      powerMax: powerMax ?? this.powerMax,
      voltageSum: voltageSum ?? this.voltageSum,
      voltageMin: voltageMin ?? this.voltageMin,
      voltageMax: voltageMax ?? this.voltageMax,
      currentSum: currentSum ?? this.currentSum,
      currentMax: currentMax ?? this.currentMax,
      frequencySum: frequencySum ?? this.frequencySum,
      frequencyMin: frequencyMin ?? this.frequencyMin,
      frequencyMax: frequencyMax ?? this.frequencyMax,
      powerFactorSum: powerFactorSum ?? this.powerFactorSum,
      powerFactorMin: powerFactorMin ?? this.powerFactorMin,
      sampleCount: sampleCount ?? this.sampleCount,
      observedSeconds: observedSeconds ?? this.observedSeconds,
      estimatedIntervals: estimatedIntervals ?? this.estimatedIntervals,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceKey.present) {
      map['device_key'] = Variable<String>(deviceKey.value);
    }
    if (minuteStart.present) {
      map['minute_start'] = Variable<DateTime>(minuteStart.value);
    }
    if (energyKwh.present) {
      map['energy_kwh'] = Variable<double>(energyKwh.value);
    }
    if (powerSum.present) {
      map['power_sum'] = Variable<double>(powerSum.value);
    }
    if (powerMin.present) {
      map['power_min'] = Variable<double>(powerMin.value);
    }
    if (powerMax.present) {
      map['power_max'] = Variable<double>(powerMax.value);
    }
    if (voltageSum.present) {
      map['voltage_sum'] = Variable<double>(voltageSum.value);
    }
    if (voltageMin.present) {
      map['voltage_min'] = Variable<double>(voltageMin.value);
    }
    if (voltageMax.present) {
      map['voltage_max'] = Variable<double>(voltageMax.value);
    }
    if (currentSum.present) {
      map['current_sum'] = Variable<double>(currentSum.value);
    }
    if (currentMax.present) {
      map['current_max'] = Variable<double>(currentMax.value);
    }
    if (frequencySum.present) {
      map['frequency_sum'] = Variable<double>(frequencySum.value);
    }
    if (frequencyMin.present) {
      map['frequency_min'] = Variable<double>(frequencyMin.value);
    }
    if (frequencyMax.present) {
      map['frequency_max'] = Variable<double>(frequencyMax.value);
    }
    if (powerFactorSum.present) {
      map['power_factor_sum'] = Variable<double>(powerFactorSum.value);
    }
    if (powerFactorMin.present) {
      map['power_factor_min'] = Variable<double>(powerFactorMin.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (observedSeconds.present) {
      map['observed_seconds'] = Variable<double>(observedSeconds.value);
    }
    if (estimatedIntervals.present) {
      map['estimated_intervals'] = Variable<int>(estimatedIntervals.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MinuteAggregatesCompanion(')
          ..write('deviceKey: $deviceKey, ')
          ..write('minuteStart: $minuteStart, ')
          ..write('energyKwh: $energyKwh, ')
          ..write('powerSum: $powerSum, ')
          ..write('powerMin: $powerMin, ')
          ..write('powerMax: $powerMax, ')
          ..write('voltageSum: $voltageSum, ')
          ..write('voltageMin: $voltageMin, ')
          ..write('voltageMax: $voltageMax, ')
          ..write('currentSum: $currentSum, ')
          ..write('currentMax: $currentMax, ')
          ..write('frequencySum: $frequencySum, ')
          ..write('frequencyMin: $frequencyMin, ')
          ..write('frequencyMax: $frequencyMax, ')
          ..write('powerFactorSum: $powerFactorSum, ')
          ..write('powerFactorMin: $powerFactorMin, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('observedSeconds: $observedSeconds, ')
          ..write('estimatedIntervals: $estimatedIntervals, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HourlyHistoryTable extends HourlyHistory
    with TableInfo<$HourlyHistoryTable, HourlyHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HourlyHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceKeyMeta = const VerificationMeta(
    'deviceKey',
  );
  @override
  late final GeneratedColumn<String> deviceKey = GeneratedColumn<String>(
    'device_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourStartMeta = const VerificationMeta(
    'hourStart',
  );
  @override
  late final GeneratedColumn<DateTime> hourStart = GeneratedColumn<DateTime>(
    'hour_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKwhMeta = const VerificationMeta(
    'energyKwh',
  );
  @override
  late final GeneratedColumn<double> energyKwh = GeneratedColumn<double>(
    'energy_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerSumMeta = const VerificationMeta(
    'powerSum',
  );
  @override
  late final GeneratedColumn<double> powerSum = GeneratedColumn<double>(
    'power_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerMinMeta = const VerificationMeta(
    'powerMin',
  );
  @override
  late final GeneratedColumn<double> powerMin = GeneratedColumn<double>(
    'power_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerMaxMeta = const VerificationMeta(
    'powerMax',
  );
  @override
  late final GeneratedColumn<double> powerMax = GeneratedColumn<double>(
    'power_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageSumMeta = const VerificationMeta(
    'voltageSum',
  );
  @override
  late final GeneratedColumn<double> voltageSum = GeneratedColumn<double>(
    'voltage_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voltageMinMeta = const VerificationMeta(
    'voltageMin',
  );
  @override
  late final GeneratedColumn<double> voltageMin = GeneratedColumn<double>(
    'voltage_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageMaxMeta = const VerificationMeta(
    'voltageMax',
  );
  @override
  late final GeneratedColumn<double> voltageMax = GeneratedColumn<double>(
    'voltage_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentSumMeta = const VerificationMeta(
    'currentSum',
  );
  @override
  late final GeneratedColumn<double> currentSum = GeneratedColumn<double>(
    'current_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentMaxMeta = const VerificationMeta(
    'currentMax',
  );
  @override
  late final GeneratedColumn<double> currentMax = GeneratedColumn<double>(
    'current_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencySumMeta = const VerificationMeta(
    'frequencySum',
  );
  @override
  late final GeneratedColumn<double> frequencySum = GeneratedColumn<double>(
    'frequency_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _frequencyMinMeta = const VerificationMeta(
    'frequencyMin',
  );
  @override
  late final GeneratedColumn<double> frequencyMin = GeneratedColumn<double>(
    'frequency_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMaxMeta = const VerificationMeta(
    'frequencyMax',
  );
  @override
  late final GeneratedColumn<double> frequencyMax = GeneratedColumn<double>(
    'frequency_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerFactorSumMeta = const VerificationMeta(
    'powerFactorSum',
  );
  @override
  late final GeneratedColumn<double> powerFactorSum = GeneratedColumn<double>(
    'power_factor_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerFactorMinMeta = const VerificationMeta(
    'powerFactorMin',
  );
  @override
  late final GeneratedColumn<double> powerFactorMin = GeneratedColumn<double>(
    'power_factor_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _observedSecondsMeta = const VerificationMeta(
    'observedSeconds',
  );
  @override
  late final GeneratedColumn<double> observedSeconds = GeneratedColumn<double>(
    'observed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _estimatedIntervalsMeta =
      const VerificationMeta('estimatedIntervals');
  @override
  late final GeneratedColumn<int> estimatedIntervals = GeneratedColumn<int>(
    'estimated_intervals',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coveragePctMeta = const VerificationMeta(
    'coveragePct',
  );
  @override
  late final GeneratedColumn<double> coveragePct = GeneratedColumn<double>(
    'coverage_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dataQualityMeta = const VerificationMeta(
    'dataQuality',
  );
  @override
  late final GeneratedColumn<String> dataQuality = GeneratedColumn<String>(
    'data_quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('partial'),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceKey,
    hourStart,
    energyKwh,
    powerSum,
    powerMin,
    powerMax,
    voltageSum,
    voltageMin,
    voltageMax,
    currentSum,
    currentMax,
    frequencySum,
    frequencyMin,
    frequencyMax,
    powerFactorSum,
    powerFactorMin,
    sampleCount,
    observedSeconds,
    estimatedIntervals,
    coveragePct,
    dataQuality,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hourly_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HourlyHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_key')) {
      context.handle(
        _deviceKeyMeta,
        deviceKey.isAcceptableOrUnknown(data['device_key']!, _deviceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceKeyMeta);
    }
    if (data.containsKey('hour_start')) {
      context.handle(
        _hourStartMeta,
        hourStart.isAcceptableOrUnknown(data['hour_start']!, _hourStartMeta),
      );
    } else if (isInserting) {
      context.missing(_hourStartMeta);
    }
    if (data.containsKey('energy_kwh')) {
      context.handle(
        _energyKwhMeta,
        energyKwh.isAcceptableOrUnknown(data['energy_kwh']!, _energyKwhMeta),
      );
    }
    if (data.containsKey('power_sum')) {
      context.handle(
        _powerSumMeta,
        powerSum.isAcceptableOrUnknown(data['power_sum']!, _powerSumMeta),
      );
    }
    if (data.containsKey('power_min')) {
      context.handle(
        _powerMinMeta,
        powerMin.isAcceptableOrUnknown(data['power_min']!, _powerMinMeta),
      );
    }
    if (data.containsKey('power_max')) {
      context.handle(
        _powerMaxMeta,
        powerMax.isAcceptableOrUnknown(data['power_max']!, _powerMaxMeta),
      );
    }
    if (data.containsKey('voltage_sum')) {
      context.handle(
        _voltageSumMeta,
        voltageSum.isAcceptableOrUnknown(data['voltage_sum']!, _voltageSumMeta),
      );
    }
    if (data.containsKey('voltage_min')) {
      context.handle(
        _voltageMinMeta,
        voltageMin.isAcceptableOrUnknown(data['voltage_min']!, _voltageMinMeta),
      );
    }
    if (data.containsKey('voltage_max')) {
      context.handle(
        _voltageMaxMeta,
        voltageMax.isAcceptableOrUnknown(data['voltage_max']!, _voltageMaxMeta),
      );
    }
    if (data.containsKey('current_sum')) {
      context.handle(
        _currentSumMeta,
        currentSum.isAcceptableOrUnknown(data['current_sum']!, _currentSumMeta),
      );
    }
    if (data.containsKey('current_max')) {
      context.handle(
        _currentMaxMeta,
        currentMax.isAcceptableOrUnknown(data['current_max']!, _currentMaxMeta),
      );
    }
    if (data.containsKey('frequency_sum')) {
      context.handle(
        _frequencySumMeta,
        frequencySum.isAcceptableOrUnknown(
          data['frequency_sum']!,
          _frequencySumMeta,
        ),
      );
    }
    if (data.containsKey('frequency_min')) {
      context.handle(
        _frequencyMinMeta,
        frequencyMin.isAcceptableOrUnknown(
          data['frequency_min']!,
          _frequencyMinMeta,
        ),
      );
    }
    if (data.containsKey('frequency_max')) {
      context.handle(
        _frequencyMaxMeta,
        frequencyMax.isAcceptableOrUnknown(
          data['frequency_max']!,
          _frequencyMaxMeta,
        ),
      );
    }
    if (data.containsKey('power_factor_sum')) {
      context.handle(
        _powerFactorSumMeta,
        powerFactorSum.isAcceptableOrUnknown(
          data['power_factor_sum']!,
          _powerFactorSumMeta,
        ),
      );
    }
    if (data.containsKey('power_factor_min')) {
      context.handle(
        _powerFactorMinMeta,
        powerFactorMin.isAcceptableOrUnknown(
          data['power_factor_min']!,
          _powerFactorMinMeta,
        ),
      );
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('observed_seconds')) {
      context.handle(
        _observedSecondsMeta,
        observedSeconds.isAcceptableOrUnknown(
          data['observed_seconds']!,
          _observedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('estimated_intervals')) {
      context.handle(
        _estimatedIntervalsMeta,
        estimatedIntervals.isAcceptableOrUnknown(
          data['estimated_intervals']!,
          _estimatedIntervalsMeta,
        ),
      );
    }
    if (data.containsKey('coverage_pct')) {
      context.handle(
        _coveragePctMeta,
        coveragePct.isAcceptableOrUnknown(
          data['coverage_pct']!,
          _coveragePctMeta,
        ),
      );
    }
    if (data.containsKey('data_quality')) {
      context.handle(
        _dataQualityMeta,
        dataQuality.isAcceptableOrUnknown(
          data['data_quality']!,
          _dataQualityMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceKey, hourStart};
  @override
  HourlyHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HourlyHistoryRow(
      deviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_key'],
      )!,
      hourStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hour_start'],
      )!,
      energyKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kwh'],
      )!,
      powerSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_sum'],
      )!,
      powerMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_min'],
      ),
      powerMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_max'],
      ),
      voltageSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_sum'],
      )!,
      voltageMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_min'],
      ),
      voltageMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_max'],
      ),
      currentSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_sum'],
      )!,
      currentMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_max'],
      ),
      frequencySum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_sum'],
      )!,
      frequencyMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_min'],
      ),
      frequencyMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_max'],
      ),
      powerFactorSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_factor_sum'],
      )!,
      powerFactorMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_factor_min'],
      ),
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      observedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}observed_seconds'],
      )!,
      estimatedIntervals: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_intervals'],
      )!,
      coveragePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage_pct'],
      )!,
      dataQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_quality'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $HourlyHistoryTable createAlias(String alias) {
    return $HourlyHistoryTable(attachedDatabase, alias);
  }
}

class HourlyHistoryRow extends DataClass
    implements Insertable<HourlyHistoryRow> {
  final String deviceKey;
  final DateTime hourStart;
  final double energyKwh;
  final double powerSum;
  final double? powerMin;
  final double? powerMax;
  final double voltageSum;
  final double? voltageMin;
  final double? voltageMax;
  final double currentSum;
  final double? currentMax;
  final double frequencySum;
  final double? frequencyMin;
  final double? frequencyMax;
  final double powerFactorSum;
  final double? powerFactorMin;
  final int sampleCount;
  final double observedSeconds;
  final int estimatedIntervals;
  final double coveragePct;
  final String dataQuality;
  final DateTime recordedAt;
  const HourlyHistoryRow({
    required this.deviceKey,
    required this.hourStart,
    required this.energyKwh,
    required this.powerSum,
    this.powerMin,
    this.powerMax,
    required this.voltageSum,
    this.voltageMin,
    this.voltageMax,
    required this.currentSum,
    this.currentMax,
    required this.frequencySum,
    this.frequencyMin,
    this.frequencyMax,
    required this.powerFactorSum,
    this.powerFactorMin,
    required this.sampleCount,
    required this.observedSeconds,
    required this.estimatedIntervals,
    required this.coveragePct,
    required this.dataQuality,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_key'] = Variable<String>(deviceKey);
    map['hour_start'] = Variable<DateTime>(hourStart);
    map['energy_kwh'] = Variable<double>(energyKwh);
    map['power_sum'] = Variable<double>(powerSum);
    if (!nullToAbsent || powerMin != null) {
      map['power_min'] = Variable<double>(powerMin);
    }
    if (!nullToAbsent || powerMax != null) {
      map['power_max'] = Variable<double>(powerMax);
    }
    map['voltage_sum'] = Variable<double>(voltageSum);
    if (!nullToAbsent || voltageMin != null) {
      map['voltage_min'] = Variable<double>(voltageMin);
    }
    if (!nullToAbsent || voltageMax != null) {
      map['voltage_max'] = Variable<double>(voltageMax);
    }
    map['current_sum'] = Variable<double>(currentSum);
    if (!nullToAbsent || currentMax != null) {
      map['current_max'] = Variable<double>(currentMax);
    }
    map['frequency_sum'] = Variable<double>(frequencySum);
    if (!nullToAbsent || frequencyMin != null) {
      map['frequency_min'] = Variable<double>(frequencyMin);
    }
    if (!nullToAbsent || frequencyMax != null) {
      map['frequency_max'] = Variable<double>(frequencyMax);
    }
    map['power_factor_sum'] = Variable<double>(powerFactorSum);
    if (!nullToAbsent || powerFactorMin != null) {
      map['power_factor_min'] = Variable<double>(powerFactorMin);
    }
    map['sample_count'] = Variable<int>(sampleCount);
    map['observed_seconds'] = Variable<double>(observedSeconds);
    map['estimated_intervals'] = Variable<int>(estimatedIntervals);
    map['coverage_pct'] = Variable<double>(coveragePct);
    map['data_quality'] = Variable<String>(dataQuality);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  HourlyHistoryCompanion toCompanion(bool nullToAbsent) {
    return HourlyHistoryCompanion(
      deviceKey: Value(deviceKey),
      hourStart: Value(hourStart),
      energyKwh: Value(energyKwh),
      powerSum: Value(powerSum),
      powerMin: powerMin == null && nullToAbsent
          ? const Value.absent()
          : Value(powerMin),
      powerMax: powerMax == null && nullToAbsent
          ? const Value.absent()
          : Value(powerMax),
      voltageSum: Value(voltageSum),
      voltageMin: voltageMin == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageMin),
      voltageMax: voltageMax == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageMax),
      currentSum: Value(currentSum),
      currentMax: currentMax == null && nullToAbsent
          ? const Value.absent()
          : Value(currentMax),
      frequencySum: Value(frequencySum),
      frequencyMin: frequencyMin == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMin),
      frequencyMax: frequencyMax == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMax),
      powerFactorSum: Value(powerFactorSum),
      powerFactorMin: powerFactorMin == null && nullToAbsent
          ? const Value.absent()
          : Value(powerFactorMin),
      sampleCount: Value(sampleCount),
      observedSeconds: Value(observedSeconds),
      estimatedIntervals: Value(estimatedIntervals),
      coveragePct: Value(coveragePct),
      dataQuality: Value(dataQuality),
      recordedAt: Value(recordedAt),
    );
  }

  factory HourlyHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HourlyHistoryRow(
      deviceKey: serializer.fromJson<String>(json['deviceKey']),
      hourStart: serializer.fromJson<DateTime>(json['hourStart']),
      energyKwh: serializer.fromJson<double>(json['energyKwh']),
      powerSum: serializer.fromJson<double>(json['powerSum']),
      powerMin: serializer.fromJson<double?>(json['powerMin']),
      powerMax: serializer.fromJson<double?>(json['powerMax']),
      voltageSum: serializer.fromJson<double>(json['voltageSum']),
      voltageMin: serializer.fromJson<double?>(json['voltageMin']),
      voltageMax: serializer.fromJson<double?>(json['voltageMax']),
      currentSum: serializer.fromJson<double>(json['currentSum']),
      currentMax: serializer.fromJson<double?>(json['currentMax']),
      frequencySum: serializer.fromJson<double>(json['frequencySum']),
      frequencyMin: serializer.fromJson<double?>(json['frequencyMin']),
      frequencyMax: serializer.fromJson<double?>(json['frequencyMax']),
      powerFactorSum: serializer.fromJson<double>(json['powerFactorSum']),
      powerFactorMin: serializer.fromJson<double?>(json['powerFactorMin']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      observedSeconds: serializer.fromJson<double>(json['observedSeconds']),
      estimatedIntervals: serializer.fromJson<int>(json['estimatedIntervals']),
      coveragePct: serializer.fromJson<double>(json['coveragePct']),
      dataQuality: serializer.fromJson<String>(json['dataQuality']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceKey': serializer.toJson<String>(deviceKey),
      'hourStart': serializer.toJson<DateTime>(hourStart),
      'energyKwh': serializer.toJson<double>(energyKwh),
      'powerSum': serializer.toJson<double>(powerSum),
      'powerMin': serializer.toJson<double?>(powerMin),
      'powerMax': serializer.toJson<double?>(powerMax),
      'voltageSum': serializer.toJson<double>(voltageSum),
      'voltageMin': serializer.toJson<double?>(voltageMin),
      'voltageMax': serializer.toJson<double?>(voltageMax),
      'currentSum': serializer.toJson<double>(currentSum),
      'currentMax': serializer.toJson<double?>(currentMax),
      'frequencySum': serializer.toJson<double>(frequencySum),
      'frequencyMin': serializer.toJson<double?>(frequencyMin),
      'frequencyMax': serializer.toJson<double?>(frequencyMax),
      'powerFactorSum': serializer.toJson<double>(powerFactorSum),
      'powerFactorMin': serializer.toJson<double?>(powerFactorMin),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'observedSeconds': serializer.toJson<double>(observedSeconds),
      'estimatedIntervals': serializer.toJson<int>(estimatedIntervals),
      'coveragePct': serializer.toJson<double>(coveragePct),
      'dataQuality': serializer.toJson<String>(dataQuality),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  HourlyHistoryRow copyWith({
    String? deviceKey,
    DateTime? hourStart,
    double? energyKwh,
    double? powerSum,
    Value<double?> powerMin = const Value.absent(),
    Value<double?> powerMax = const Value.absent(),
    double? voltageSum,
    Value<double?> voltageMin = const Value.absent(),
    Value<double?> voltageMax = const Value.absent(),
    double? currentSum,
    Value<double?> currentMax = const Value.absent(),
    double? frequencySum,
    Value<double?> frequencyMin = const Value.absent(),
    Value<double?> frequencyMax = const Value.absent(),
    double? powerFactorSum,
    Value<double?> powerFactorMin = const Value.absent(),
    int? sampleCount,
    double? observedSeconds,
    int? estimatedIntervals,
    double? coveragePct,
    String? dataQuality,
    DateTime? recordedAt,
  }) => HourlyHistoryRow(
    deviceKey: deviceKey ?? this.deviceKey,
    hourStart: hourStart ?? this.hourStart,
    energyKwh: energyKwh ?? this.energyKwh,
    powerSum: powerSum ?? this.powerSum,
    powerMin: powerMin.present ? powerMin.value : this.powerMin,
    powerMax: powerMax.present ? powerMax.value : this.powerMax,
    voltageSum: voltageSum ?? this.voltageSum,
    voltageMin: voltageMin.present ? voltageMin.value : this.voltageMin,
    voltageMax: voltageMax.present ? voltageMax.value : this.voltageMax,
    currentSum: currentSum ?? this.currentSum,
    currentMax: currentMax.present ? currentMax.value : this.currentMax,
    frequencySum: frequencySum ?? this.frequencySum,
    frequencyMin: frequencyMin.present ? frequencyMin.value : this.frequencyMin,
    frequencyMax: frequencyMax.present ? frequencyMax.value : this.frequencyMax,
    powerFactorSum: powerFactorSum ?? this.powerFactorSum,
    powerFactorMin: powerFactorMin.present
        ? powerFactorMin.value
        : this.powerFactorMin,
    sampleCount: sampleCount ?? this.sampleCount,
    observedSeconds: observedSeconds ?? this.observedSeconds,
    estimatedIntervals: estimatedIntervals ?? this.estimatedIntervals,
    coveragePct: coveragePct ?? this.coveragePct,
    dataQuality: dataQuality ?? this.dataQuality,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  HourlyHistoryRow copyWithCompanion(HourlyHistoryCompanion data) {
    return HourlyHistoryRow(
      deviceKey: data.deviceKey.present ? data.deviceKey.value : this.deviceKey,
      hourStart: data.hourStart.present ? data.hourStart.value : this.hourStart,
      energyKwh: data.energyKwh.present ? data.energyKwh.value : this.energyKwh,
      powerSum: data.powerSum.present ? data.powerSum.value : this.powerSum,
      powerMin: data.powerMin.present ? data.powerMin.value : this.powerMin,
      powerMax: data.powerMax.present ? data.powerMax.value : this.powerMax,
      voltageSum: data.voltageSum.present
          ? data.voltageSum.value
          : this.voltageSum,
      voltageMin: data.voltageMin.present
          ? data.voltageMin.value
          : this.voltageMin,
      voltageMax: data.voltageMax.present
          ? data.voltageMax.value
          : this.voltageMax,
      currentSum: data.currentSum.present
          ? data.currentSum.value
          : this.currentSum,
      currentMax: data.currentMax.present
          ? data.currentMax.value
          : this.currentMax,
      frequencySum: data.frequencySum.present
          ? data.frequencySum.value
          : this.frequencySum,
      frequencyMin: data.frequencyMin.present
          ? data.frequencyMin.value
          : this.frequencyMin,
      frequencyMax: data.frequencyMax.present
          ? data.frequencyMax.value
          : this.frequencyMax,
      powerFactorSum: data.powerFactorSum.present
          ? data.powerFactorSum.value
          : this.powerFactorSum,
      powerFactorMin: data.powerFactorMin.present
          ? data.powerFactorMin.value
          : this.powerFactorMin,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      observedSeconds: data.observedSeconds.present
          ? data.observedSeconds.value
          : this.observedSeconds,
      estimatedIntervals: data.estimatedIntervals.present
          ? data.estimatedIntervals.value
          : this.estimatedIntervals,
      coveragePct: data.coveragePct.present
          ? data.coveragePct.value
          : this.coveragePct,
      dataQuality: data.dataQuality.present
          ? data.dataQuality.value
          : this.dataQuality,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HourlyHistoryRow(')
          ..write('deviceKey: $deviceKey, ')
          ..write('hourStart: $hourStart, ')
          ..write('energyKwh: $energyKwh, ')
          ..write('powerSum: $powerSum, ')
          ..write('powerMin: $powerMin, ')
          ..write('powerMax: $powerMax, ')
          ..write('voltageSum: $voltageSum, ')
          ..write('voltageMin: $voltageMin, ')
          ..write('voltageMax: $voltageMax, ')
          ..write('currentSum: $currentSum, ')
          ..write('currentMax: $currentMax, ')
          ..write('frequencySum: $frequencySum, ')
          ..write('frequencyMin: $frequencyMin, ')
          ..write('frequencyMax: $frequencyMax, ')
          ..write('powerFactorSum: $powerFactorSum, ')
          ..write('powerFactorMin: $powerFactorMin, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('observedSeconds: $observedSeconds, ')
          ..write('estimatedIntervals: $estimatedIntervals, ')
          ..write('coveragePct: $coveragePct, ')
          ..write('dataQuality: $dataQuality, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    deviceKey,
    hourStart,
    energyKwh,
    powerSum,
    powerMin,
    powerMax,
    voltageSum,
    voltageMin,
    voltageMax,
    currentSum,
    currentMax,
    frequencySum,
    frequencyMin,
    frequencyMax,
    powerFactorSum,
    powerFactorMin,
    sampleCount,
    observedSeconds,
    estimatedIntervals,
    coveragePct,
    dataQuality,
    recordedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HourlyHistoryRow &&
          other.deviceKey == this.deviceKey &&
          other.hourStart == this.hourStart &&
          other.energyKwh == this.energyKwh &&
          other.powerSum == this.powerSum &&
          other.powerMin == this.powerMin &&
          other.powerMax == this.powerMax &&
          other.voltageSum == this.voltageSum &&
          other.voltageMin == this.voltageMin &&
          other.voltageMax == this.voltageMax &&
          other.currentSum == this.currentSum &&
          other.currentMax == this.currentMax &&
          other.frequencySum == this.frequencySum &&
          other.frequencyMin == this.frequencyMin &&
          other.frequencyMax == this.frequencyMax &&
          other.powerFactorSum == this.powerFactorSum &&
          other.powerFactorMin == this.powerFactorMin &&
          other.sampleCount == this.sampleCount &&
          other.observedSeconds == this.observedSeconds &&
          other.estimatedIntervals == this.estimatedIntervals &&
          other.coveragePct == this.coveragePct &&
          other.dataQuality == this.dataQuality &&
          other.recordedAt == this.recordedAt);
}

class HourlyHistoryCompanion extends UpdateCompanion<HourlyHistoryRow> {
  final Value<String> deviceKey;
  final Value<DateTime> hourStart;
  final Value<double> energyKwh;
  final Value<double> powerSum;
  final Value<double?> powerMin;
  final Value<double?> powerMax;
  final Value<double> voltageSum;
  final Value<double?> voltageMin;
  final Value<double?> voltageMax;
  final Value<double> currentSum;
  final Value<double?> currentMax;
  final Value<double> frequencySum;
  final Value<double?> frequencyMin;
  final Value<double?> frequencyMax;
  final Value<double> powerFactorSum;
  final Value<double?> powerFactorMin;
  final Value<int> sampleCount;
  final Value<double> observedSeconds;
  final Value<int> estimatedIntervals;
  final Value<double> coveragePct;
  final Value<String> dataQuality;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const HourlyHistoryCompanion({
    this.deviceKey = const Value.absent(),
    this.hourStart = const Value.absent(),
    this.energyKwh = const Value.absent(),
    this.powerSum = const Value.absent(),
    this.powerMin = const Value.absent(),
    this.powerMax = const Value.absent(),
    this.voltageSum = const Value.absent(),
    this.voltageMin = const Value.absent(),
    this.voltageMax = const Value.absent(),
    this.currentSum = const Value.absent(),
    this.currentMax = const Value.absent(),
    this.frequencySum = const Value.absent(),
    this.frequencyMin = const Value.absent(),
    this.frequencyMax = const Value.absent(),
    this.powerFactorSum = const Value.absent(),
    this.powerFactorMin = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.observedSeconds = const Value.absent(),
    this.estimatedIntervals = const Value.absent(),
    this.coveragePct = const Value.absent(),
    this.dataQuality = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HourlyHistoryCompanion.insert({
    required String deviceKey,
    required DateTime hourStart,
    this.energyKwh = const Value.absent(),
    this.powerSum = const Value.absent(),
    this.powerMin = const Value.absent(),
    this.powerMax = const Value.absent(),
    this.voltageSum = const Value.absent(),
    this.voltageMin = const Value.absent(),
    this.voltageMax = const Value.absent(),
    this.currentSum = const Value.absent(),
    this.currentMax = const Value.absent(),
    this.frequencySum = const Value.absent(),
    this.frequencyMin = const Value.absent(),
    this.frequencyMax = const Value.absent(),
    this.powerFactorSum = const Value.absent(),
    this.powerFactorMin = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.observedSeconds = const Value.absent(),
    this.estimatedIntervals = const Value.absent(),
    this.coveragePct = const Value.absent(),
    this.dataQuality = const Value.absent(),
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : deviceKey = Value(deviceKey),
       hourStart = Value(hourStart),
       recordedAt = Value(recordedAt);
  static Insertable<HourlyHistoryRow> custom({
    Expression<String>? deviceKey,
    Expression<DateTime>? hourStart,
    Expression<double>? energyKwh,
    Expression<double>? powerSum,
    Expression<double>? powerMin,
    Expression<double>? powerMax,
    Expression<double>? voltageSum,
    Expression<double>? voltageMin,
    Expression<double>? voltageMax,
    Expression<double>? currentSum,
    Expression<double>? currentMax,
    Expression<double>? frequencySum,
    Expression<double>? frequencyMin,
    Expression<double>? frequencyMax,
    Expression<double>? powerFactorSum,
    Expression<double>? powerFactorMin,
    Expression<int>? sampleCount,
    Expression<double>? observedSeconds,
    Expression<int>? estimatedIntervals,
    Expression<double>? coveragePct,
    Expression<String>? dataQuality,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceKey != null) 'device_key': deviceKey,
      if (hourStart != null) 'hour_start': hourStart,
      if (energyKwh != null) 'energy_kwh': energyKwh,
      if (powerSum != null) 'power_sum': powerSum,
      if (powerMin != null) 'power_min': powerMin,
      if (powerMax != null) 'power_max': powerMax,
      if (voltageSum != null) 'voltage_sum': voltageSum,
      if (voltageMin != null) 'voltage_min': voltageMin,
      if (voltageMax != null) 'voltage_max': voltageMax,
      if (currentSum != null) 'current_sum': currentSum,
      if (currentMax != null) 'current_max': currentMax,
      if (frequencySum != null) 'frequency_sum': frequencySum,
      if (frequencyMin != null) 'frequency_min': frequencyMin,
      if (frequencyMax != null) 'frequency_max': frequencyMax,
      if (powerFactorSum != null) 'power_factor_sum': powerFactorSum,
      if (powerFactorMin != null) 'power_factor_min': powerFactorMin,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (observedSeconds != null) 'observed_seconds': observedSeconds,
      if (estimatedIntervals != null) 'estimated_intervals': estimatedIntervals,
      if (coveragePct != null) 'coverage_pct': coveragePct,
      if (dataQuality != null) 'data_quality': dataQuality,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HourlyHistoryCompanion copyWith({
    Value<String>? deviceKey,
    Value<DateTime>? hourStart,
    Value<double>? energyKwh,
    Value<double>? powerSum,
    Value<double?>? powerMin,
    Value<double?>? powerMax,
    Value<double>? voltageSum,
    Value<double?>? voltageMin,
    Value<double?>? voltageMax,
    Value<double>? currentSum,
    Value<double?>? currentMax,
    Value<double>? frequencySum,
    Value<double?>? frequencyMin,
    Value<double?>? frequencyMax,
    Value<double>? powerFactorSum,
    Value<double?>? powerFactorMin,
    Value<int>? sampleCount,
    Value<double>? observedSeconds,
    Value<int>? estimatedIntervals,
    Value<double>? coveragePct,
    Value<String>? dataQuality,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return HourlyHistoryCompanion(
      deviceKey: deviceKey ?? this.deviceKey,
      hourStart: hourStart ?? this.hourStart,
      energyKwh: energyKwh ?? this.energyKwh,
      powerSum: powerSum ?? this.powerSum,
      powerMin: powerMin ?? this.powerMin,
      powerMax: powerMax ?? this.powerMax,
      voltageSum: voltageSum ?? this.voltageSum,
      voltageMin: voltageMin ?? this.voltageMin,
      voltageMax: voltageMax ?? this.voltageMax,
      currentSum: currentSum ?? this.currentSum,
      currentMax: currentMax ?? this.currentMax,
      frequencySum: frequencySum ?? this.frequencySum,
      frequencyMin: frequencyMin ?? this.frequencyMin,
      frequencyMax: frequencyMax ?? this.frequencyMax,
      powerFactorSum: powerFactorSum ?? this.powerFactorSum,
      powerFactorMin: powerFactorMin ?? this.powerFactorMin,
      sampleCount: sampleCount ?? this.sampleCount,
      observedSeconds: observedSeconds ?? this.observedSeconds,
      estimatedIntervals: estimatedIntervals ?? this.estimatedIntervals,
      coveragePct: coveragePct ?? this.coveragePct,
      dataQuality: dataQuality ?? this.dataQuality,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceKey.present) {
      map['device_key'] = Variable<String>(deviceKey.value);
    }
    if (hourStart.present) {
      map['hour_start'] = Variable<DateTime>(hourStart.value);
    }
    if (energyKwh.present) {
      map['energy_kwh'] = Variable<double>(energyKwh.value);
    }
    if (powerSum.present) {
      map['power_sum'] = Variable<double>(powerSum.value);
    }
    if (powerMin.present) {
      map['power_min'] = Variable<double>(powerMin.value);
    }
    if (powerMax.present) {
      map['power_max'] = Variable<double>(powerMax.value);
    }
    if (voltageSum.present) {
      map['voltage_sum'] = Variable<double>(voltageSum.value);
    }
    if (voltageMin.present) {
      map['voltage_min'] = Variable<double>(voltageMin.value);
    }
    if (voltageMax.present) {
      map['voltage_max'] = Variable<double>(voltageMax.value);
    }
    if (currentSum.present) {
      map['current_sum'] = Variable<double>(currentSum.value);
    }
    if (currentMax.present) {
      map['current_max'] = Variable<double>(currentMax.value);
    }
    if (frequencySum.present) {
      map['frequency_sum'] = Variable<double>(frequencySum.value);
    }
    if (frequencyMin.present) {
      map['frequency_min'] = Variable<double>(frequencyMin.value);
    }
    if (frequencyMax.present) {
      map['frequency_max'] = Variable<double>(frequencyMax.value);
    }
    if (powerFactorSum.present) {
      map['power_factor_sum'] = Variable<double>(powerFactorSum.value);
    }
    if (powerFactorMin.present) {
      map['power_factor_min'] = Variable<double>(powerFactorMin.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (observedSeconds.present) {
      map['observed_seconds'] = Variable<double>(observedSeconds.value);
    }
    if (estimatedIntervals.present) {
      map['estimated_intervals'] = Variable<int>(estimatedIntervals.value);
    }
    if (coveragePct.present) {
      map['coverage_pct'] = Variable<double>(coveragePct.value);
    }
    if (dataQuality.present) {
      map['data_quality'] = Variable<String>(dataQuality.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HourlyHistoryCompanion(')
          ..write('deviceKey: $deviceKey, ')
          ..write('hourStart: $hourStart, ')
          ..write('energyKwh: $energyKwh, ')
          ..write('powerSum: $powerSum, ')
          ..write('powerMin: $powerMin, ')
          ..write('powerMax: $powerMax, ')
          ..write('voltageSum: $voltageSum, ')
          ..write('voltageMin: $voltageMin, ')
          ..write('voltageMax: $voltageMax, ')
          ..write('currentSum: $currentSum, ')
          ..write('currentMax: $currentMax, ')
          ..write('frequencySum: $frequencySum, ')
          ..write('frequencyMin: $frequencyMin, ')
          ..write('frequencyMax: $frequencyMax, ')
          ..write('powerFactorSum: $powerFactorSum, ')
          ..write('powerFactorMin: $powerFactorMin, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('observedSeconds: $observedSeconds, ')
          ..write('estimatedIntervals: $estimatedIntervals, ')
          ..write('coveragePct: $coveragePct, ')
          ..write('dataQuality: $dataQuality, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HourlyQueueTable extends HourlyQueue
    with TableInfo<$HourlyQueueTable, HourlyQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HourlyQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceKeyMeta = const VerificationMeta(
    'deviceKey',
  );
  @override
  late final GeneratedColumn<String> deviceKey = GeneratedColumn<String>(
    'device_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourStartMeta = const VerificationMeta(
    'hourStart',
  );
  @override
  late final GeneratedColumn<DateTime> hourStart = GeneratedColumn<DateTime>(
    'hour_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyKwhMeta = const VerificationMeta(
    'energyKwh',
  );
  @override
  late final GeneratedColumn<double> energyKwh = GeneratedColumn<double>(
    'energy_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerSumMeta = const VerificationMeta(
    'powerSum',
  );
  @override
  late final GeneratedColumn<double> powerSum = GeneratedColumn<double>(
    'power_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerMinMeta = const VerificationMeta(
    'powerMin',
  );
  @override
  late final GeneratedColumn<double> powerMin = GeneratedColumn<double>(
    'power_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerMaxMeta = const VerificationMeta(
    'powerMax',
  );
  @override
  late final GeneratedColumn<double> powerMax = GeneratedColumn<double>(
    'power_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageSumMeta = const VerificationMeta(
    'voltageSum',
  );
  @override
  late final GeneratedColumn<double> voltageSum = GeneratedColumn<double>(
    'voltage_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voltageMinMeta = const VerificationMeta(
    'voltageMin',
  );
  @override
  late final GeneratedColumn<double> voltageMin = GeneratedColumn<double>(
    'voltage_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageMaxMeta = const VerificationMeta(
    'voltageMax',
  );
  @override
  late final GeneratedColumn<double> voltageMax = GeneratedColumn<double>(
    'voltage_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentSumMeta = const VerificationMeta(
    'currentSum',
  );
  @override
  late final GeneratedColumn<double> currentSum = GeneratedColumn<double>(
    'current_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentMaxMeta = const VerificationMeta(
    'currentMax',
  );
  @override
  late final GeneratedColumn<double> currentMax = GeneratedColumn<double>(
    'current_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencySumMeta = const VerificationMeta(
    'frequencySum',
  );
  @override
  late final GeneratedColumn<double> frequencySum = GeneratedColumn<double>(
    'frequency_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _frequencyMinMeta = const VerificationMeta(
    'frequencyMin',
  );
  @override
  late final GeneratedColumn<double> frequencyMin = GeneratedColumn<double>(
    'frequency_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMaxMeta = const VerificationMeta(
    'frequencyMax',
  );
  @override
  late final GeneratedColumn<double> frequencyMax = GeneratedColumn<double>(
    'frequency_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _powerFactorSumMeta = const VerificationMeta(
    'powerFactorSum',
  );
  @override
  late final GeneratedColumn<double> powerFactorSum = GeneratedColumn<double>(
    'power_factor_sum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _powerFactorMinMeta = const VerificationMeta(
    'powerFactorMin',
  );
  @override
  late final GeneratedColumn<double> powerFactorMin = GeneratedColumn<double>(
    'power_factor_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _observedSecondsMeta = const VerificationMeta(
    'observedSeconds',
  );
  @override
  late final GeneratedColumn<double> observedSeconds = GeneratedColumn<double>(
    'observed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _estimatedIntervalsMeta =
      const VerificationMeta('estimatedIntervals');
  @override
  late final GeneratedColumn<int> estimatedIntervals = GeneratedColumn<int>(
    'estimated_intervals',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coveragePctMeta = const VerificationMeta(
    'coveragePct',
  );
  @override
  late final GeneratedColumn<double> coveragePct = GeneratedColumn<double>(
    'coverage_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dataQualityMeta = const VerificationMeta(
    'dataQuality',
  );
  @override
  late final GeneratedColumn<String> dataQuality = GeneratedColumn<String>(
    'data_quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('partial'),
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceKey,
    hourStart,
    energyKwh,
    powerSum,
    powerMin,
    powerMax,
    voltageSum,
    voltageMin,
    voltageMax,
    currentSum,
    currentMax,
    frequencySum,
    frequencyMin,
    frequencyMax,
    powerFactorSum,
    powerFactorMin,
    sampleCount,
    observedSeconds,
    estimatedIntervals,
    coveragePct,
    dataQuality,
    syncState,
    attempts,
    lastError,
    syncedAt,
    nextAttemptAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hourly_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<HourlyQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_key')) {
      context.handle(
        _deviceKeyMeta,
        deviceKey.isAcceptableOrUnknown(data['device_key']!, _deviceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceKeyMeta);
    }
    if (data.containsKey('hour_start')) {
      context.handle(
        _hourStartMeta,
        hourStart.isAcceptableOrUnknown(data['hour_start']!, _hourStartMeta),
      );
    } else if (isInserting) {
      context.missing(_hourStartMeta);
    }
    if (data.containsKey('energy_kwh')) {
      context.handle(
        _energyKwhMeta,
        energyKwh.isAcceptableOrUnknown(data['energy_kwh']!, _energyKwhMeta),
      );
    }
    if (data.containsKey('power_sum')) {
      context.handle(
        _powerSumMeta,
        powerSum.isAcceptableOrUnknown(data['power_sum']!, _powerSumMeta),
      );
    }
    if (data.containsKey('power_min')) {
      context.handle(
        _powerMinMeta,
        powerMin.isAcceptableOrUnknown(data['power_min']!, _powerMinMeta),
      );
    }
    if (data.containsKey('power_max')) {
      context.handle(
        _powerMaxMeta,
        powerMax.isAcceptableOrUnknown(data['power_max']!, _powerMaxMeta),
      );
    }
    if (data.containsKey('voltage_sum')) {
      context.handle(
        _voltageSumMeta,
        voltageSum.isAcceptableOrUnknown(data['voltage_sum']!, _voltageSumMeta),
      );
    }
    if (data.containsKey('voltage_min')) {
      context.handle(
        _voltageMinMeta,
        voltageMin.isAcceptableOrUnknown(data['voltage_min']!, _voltageMinMeta),
      );
    }
    if (data.containsKey('voltage_max')) {
      context.handle(
        _voltageMaxMeta,
        voltageMax.isAcceptableOrUnknown(data['voltage_max']!, _voltageMaxMeta),
      );
    }
    if (data.containsKey('current_sum')) {
      context.handle(
        _currentSumMeta,
        currentSum.isAcceptableOrUnknown(data['current_sum']!, _currentSumMeta),
      );
    }
    if (data.containsKey('current_max')) {
      context.handle(
        _currentMaxMeta,
        currentMax.isAcceptableOrUnknown(data['current_max']!, _currentMaxMeta),
      );
    }
    if (data.containsKey('frequency_sum')) {
      context.handle(
        _frequencySumMeta,
        frequencySum.isAcceptableOrUnknown(
          data['frequency_sum']!,
          _frequencySumMeta,
        ),
      );
    }
    if (data.containsKey('frequency_min')) {
      context.handle(
        _frequencyMinMeta,
        frequencyMin.isAcceptableOrUnknown(
          data['frequency_min']!,
          _frequencyMinMeta,
        ),
      );
    }
    if (data.containsKey('frequency_max')) {
      context.handle(
        _frequencyMaxMeta,
        frequencyMax.isAcceptableOrUnknown(
          data['frequency_max']!,
          _frequencyMaxMeta,
        ),
      );
    }
    if (data.containsKey('power_factor_sum')) {
      context.handle(
        _powerFactorSumMeta,
        powerFactorSum.isAcceptableOrUnknown(
          data['power_factor_sum']!,
          _powerFactorSumMeta,
        ),
      );
    }
    if (data.containsKey('power_factor_min')) {
      context.handle(
        _powerFactorMinMeta,
        powerFactorMin.isAcceptableOrUnknown(
          data['power_factor_min']!,
          _powerFactorMinMeta,
        ),
      );
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    }
    if (data.containsKey('observed_seconds')) {
      context.handle(
        _observedSecondsMeta,
        observedSeconds.isAcceptableOrUnknown(
          data['observed_seconds']!,
          _observedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('estimated_intervals')) {
      context.handle(
        _estimatedIntervalsMeta,
        estimatedIntervals.isAcceptableOrUnknown(
          data['estimated_intervals']!,
          _estimatedIntervalsMeta,
        ),
      );
    }
    if (data.containsKey('coverage_pct')) {
      context.handle(
        _coveragePctMeta,
        coveragePct.isAcceptableOrUnknown(
          data['coverage_pct']!,
          _coveragePctMeta,
        ),
      );
    }
    if (data.containsKey('data_quality')) {
      context.handle(
        _dataQualityMeta,
        dataQuality.isAcceptableOrUnknown(
          data['data_quality']!,
          _dataQualityMeta,
        ),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
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
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceKey, hourStart};
  @override
  HourlyQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HourlyQueueRow(
      deviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_key'],
      )!,
      hourStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hour_start'],
      )!,
      energyKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kwh'],
      )!,
      powerSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_sum'],
      )!,
      powerMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_min'],
      ),
      powerMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_max'],
      ),
      voltageSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_sum'],
      )!,
      voltageMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_min'],
      ),
      voltageMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage_max'],
      ),
      currentSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_sum'],
      )!,
      currentMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_max'],
      ),
      frequencySum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_sum'],
      )!,
      frequencyMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_min'],
      ),
      frequencyMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frequency_max'],
      ),
      powerFactorSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_factor_sum'],
      )!,
      powerFactorMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}power_factor_min'],
      ),
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      observedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}observed_seconds'],
      )!,
      estimatedIntervals: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_intervals'],
      )!,
      coveragePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage_pct'],
      )!,
      dataQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_quality'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HourlyQueueTable createAlias(String alias) {
    return $HourlyQueueTable(attachedDatabase, alias);
  }
}

class HourlyQueueRow extends DataClass implements Insertable<HourlyQueueRow> {
  final String deviceKey;
  final DateTime hourStart;
  final double energyKwh;
  final double powerSum;
  final double? powerMin;
  final double? powerMax;
  final double voltageSum;
  final double? voltageMin;
  final double? voltageMax;
  final double currentSum;
  final double? currentMax;
  final double frequencySum;
  final double? frequencyMin;
  final double? frequencyMax;
  final double powerFactorSum;
  final double? powerFactorMin;
  final int sampleCount;
  final double observedSeconds;
  final int estimatedIntervals;
  final double coveragePct;
  final String dataQuality;
  final String syncState;
  final int attempts;
  final String? lastError;
  final DateTime? syncedAt;

  /// Kapan baris ini boleh dicoba upload lagi. Null berarti sekarang juga.
  /// Dipakai untuk menerapkan backoff setelah kegagalan.
  final DateTime? nextAttemptAt;
  final DateTime updatedAt;
  const HourlyQueueRow({
    required this.deviceKey,
    required this.hourStart,
    required this.energyKwh,
    required this.powerSum,
    this.powerMin,
    this.powerMax,
    required this.voltageSum,
    this.voltageMin,
    this.voltageMax,
    required this.currentSum,
    this.currentMax,
    required this.frequencySum,
    this.frequencyMin,
    this.frequencyMax,
    required this.powerFactorSum,
    this.powerFactorMin,
    required this.sampleCount,
    required this.observedSeconds,
    required this.estimatedIntervals,
    required this.coveragePct,
    required this.dataQuality,
    required this.syncState,
    required this.attempts,
    this.lastError,
    this.syncedAt,
    this.nextAttemptAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_key'] = Variable<String>(deviceKey);
    map['hour_start'] = Variable<DateTime>(hourStart);
    map['energy_kwh'] = Variable<double>(energyKwh);
    map['power_sum'] = Variable<double>(powerSum);
    if (!nullToAbsent || powerMin != null) {
      map['power_min'] = Variable<double>(powerMin);
    }
    if (!nullToAbsent || powerMax != null) {
      map['power_max'] = Variable<double>(powerMax);
    }
    map['voltage_sum'] = Variable<double>(voltageSum);
    if (!nullToAbsent || voltageMin != null) {
      map['voltage_min'] = Variable<double>(voltageMin);
    }
    if (!nullToAbsent || voltageMax != null) {
      map['voltage_max'] = Variable<double>(voltageMax);
    }
    map['current_sum'] = Variable<double>(currentSum);
    if (!nullToAbsent || currentMax != null) {
      map['current_max'] = Variable<double>(currentMax);
    }
    map['frequency_sum'] = Variable<double>(frequencySum);
    if (!nullToAbsent || frequencyMin != null) {
      map['frequency_min'] = Variable<double>(frequencyMin);
    }
    if (!nullToAbsent || frequencyMax != null) {
      map['frequency_max'] = Variable<double>(frequencyMax);
    }
    map['power_factor_sum'] = Variable<double>(powerFactorSum);
    if (!nullToAbsent || powerFactorMin != null) {
      map['power_factor_min'] = Variable<double>(powerFactorMin);
    }
    map['sample_count'] = Variable<int>(sampleCount);
    map['observed_seconds'] = Variable<double>(observedSeconds);
    map['estimated_intervals'] = Variable<int>(estimatedIntervals);
    map['coverage_pct'] = Variable<double>(coveragePct);
    map['data_quality'] = Variable<String>(dataQuality);
    map['sync_state'] = Variable<String>(syncState);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HourlyQueueCompanion toCompanion(bool nullToAbsent) {
    return HourlyQueueCompanion(
      deviceKey: Value(deviceKey),
      hourStart: Value(hourStart),
      energyKwh: Value(energyKwh),
      powerSum: Value(powerSum),
      powerMin: powerMin == null && nullToAbsent
          ? const Value.absent()
          : Value(powerMin),
      powerMax: powerMax == null && nullToAbsent
          ? const Value.absent()
          : Value(powerMax),
      voltageSum: Value(voltageSum),
      voltageMin: voltageMin == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageMin),
      voltageMax: voltageMax == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageMax),
      currentSum: Value(currentSum),
      currentMax: currentMax == null && nullToAbsent
          ? const Value.absent()
          : Value(currentMax),
      frequencySum: Value(frequencySum),
      frequencyMin: frequencyMin == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMin),
      frequencyMax: frequencyMax == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMax),
      powerFactorSum: Value(powerFactorSum),
      powerFactorMin: powerFactorMin == null && nullToAbsent
          ? const Value.absent()
          : Value(powerFactorMin),
      sampleCount: Value(sampleCount),
      observedSeconds: Value(observedSeconds),
      estimatedIntervals: Value(estimatedIntervals),
      coveragePct: Value(coveragePct),
      dataQuality: Value(dataQuality),
      syncState: Value(syncState),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HourlyQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HourlyQueueRow(
      deviceKey: serializer.fromJson<String>(json['deviceKey']),
      hourStart: serializer.fromJson<DateTime>(json['hourStart']),
      energyKwh: serializer.fromJson<double>(json['energyKwh']),
      powerSum: serializer.fromJson<double>(json['powerSum']),
      powerMin: serializer.fromJson<double?>(json['powerMin']),
      powerMax: serializer.fromJson<double?>(json['powerMax']),
      voltageSum: serializer.fromJson<double>(json['voltageSum']),
      voltageMin: serializer.fromJson<double?>(json['voltageMin']),
      voltageMax: serializer.fromJson<double?>(json['voltageMax']),
      currentSum: serializer.fromJson<double>(json['currentSum']),
      currentMax: serializer.fromJson<double?>(json['currentMax']),
      frequencySum: serializer.fromJson<double>(json['frequencySum']),
      frequencyMin: serializer.fromJson<double?>(json['frequencyMin']),
      frequencyMax: serializer.fromJson<double?>(json['frequencyMax']),
      powerFactorSum: serializer.fromJson<double>(json['powerFactorSum']),
      powerFactorMin: serializer.fromJson<double?>(json['powerFactorMin']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      observedSeconds: serializer.fromJson<double>(json['observedSeconds']),
      estimatedIntervals: serializer.fromJson<int>(json['estimatedIntervals']),
      coveragePct: serializer.fromJson<double>(json['coveragePct']),
      dataQuality: serializer.fromJson<String>(json['dataQuality']),
      syncState: serializer.fromJson<String>(json['syncState']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceKey': serializer.toJson<String>(deviceKey),
      'hourStart': serializer.toJson<DateTime>(hourStart),
      'energyKwh': serializer.toJson<double>(energyKwh),
      'powerSum': serializer.toJson<double>(powerSum),
      'powerMin': serializer.toJson<double?>(powerMin),
      'powerMax': serializer.toJson<double?>(powerMax),
      'voltageSum': serializer.toJson<double>(voltageSum),
      'voltageMin': serializer.toJson<double?>(voltageMin),
      'voltageMax': serializer.toJson<double?>(voltageMax),
      'currentSum': serializer.toJson<double>(currentSum),
      'currentMax': serializer.toJson<double?>(currentMax),
      'frequencySum': serializer.toJson<double>(frequencySum),
      'frequencyMin': serializer.toJson<double?>(frequencyMin),
      'frequencyMax': serializer.toJson<double?>(frequencyMax),
      'powerFactorSum': serializer.toJson<double>(powerFactorSum),
      'powerFactorMin': serializer.toJson<double?>(powerFactorMin),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'observedSeconds': serializer.toJson<double>(observedSeconds),
      'estimatedIntervals': serializer.toJson<int>(estimatedIntervals),
      'coveragePct': serializer.toJson<double>(coveragePct),
      'dataQuality': serializer.toJson<String>(dataQuality),
      'syncState': serializer.toJson<String>(syncState),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HourlyQueueRow copyWith({
    String? deviceKey,
    DateTime? hourStart,
    double? energyKwh,
    double? powerSum,
    Value<double?> powerMin = const Value.absent(),
    Value<double?> powerMax = const Value.absent(),
    double? voltageSum,
    Value<double?> voltageMin = const Value.absent(),
    Value<double?> voltageMax = const Value.absent(),
    double? currentSum,
    Value<double?> currentMax = const Value.absent(),
    double? frequencySum,
    Value<double?> frequencyMin = const Value.absent(),
    Value<double?> frequencyMax = const Value.absent(),
    double? powerFactorSum,
    Value<double?> powerFactorMin = const Value.absent(),
    int? sampleCount,
    double? observedSeconds,
    int? estimatedIntervals,
    double? coveragePct,
    String? dataQuality,
    String? syncState,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    DateTime? updatedAt,
  }) => HourlyQueueRow(
    deviceKey: deviceKey ?? this.deviceKey,
    hourStart: hourStart ?? this.hourStart,
    energyKwh: energyKwh ?? this.energyKwh,
    powerSum: powerSum ?? this.powerSum,
    powerMin: powerMin.present ? powerMin.value : this.powerMin,
    powerMax: powerMax.present ? powerMax.value : this.powerMax,
    voltageSum: voltageSum ?? this.voltageSum,
    voltageMin: voltageMin.present ? voltageMin.value : this.voltageMin,
    voltageMax: voltageMax.present ? voltageMax.value : this.voltageMax,
    currentSum: currentSum ?? this.currentSum,
    currentMax: currentMax.present ? currentMax.value : this.currentMax,
    frequencySum: frequencySum ?? this.frequencySum,
    frequencyMin: frequencyMin.present ? frequencyMin.value : this.frequencyMin,
    frequencyMax: frequencyMax.present ? frequencyMax.value : this.frequencyMax,
    powerFactorSum: powerFactorSum ?? this.powerFactorSum,
    powerFactorMin: powerFactorMin.present
        ? powerFactorMin.value
        : this.powerFactorMin,
    sampleCount: sampleCount ?? this.sampleCount,
    observedSeconds: observedSeconds ?? this.observedSeconds,
    estimatedIntervals: estimatedIntervals ?? this.estimatedIntervals,
    coveragePct: coveragePct ?? this.coveragePct,
    dataQuality: dataQuality ?? this.dataQuality,
    syncState: syncState ?? this.syncState,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HourlyQueueRow copyWithCompanion(HourlyQueueCompanion data) {
    return HourlyQueueRow(
      deviceKey: data.deviceKey.present ? data.deviceKey.value : this.deviceKey,
      hourStart: data.hourStart.present ? data.hourStart.value : this.hourStart,
      energyKwh: data.energyKwh.present ? data.energyKwh.value : this.energyKwh,
      powerSum: data.powerSum.present ? data.powerSum.value : this.powerSum,
      powerMin: data.powerMin.present ? data.powerMin.value : this.powerMin,
      powerMax: data.powerMax.present ? data.powerMax.value : this.powerMax,
      voltageSum: data.voltageSum.present
          ? data.voltageSum.value
          : this.voltageSum,
      voltageMin: data.voltageMin.present
          ? data.voltageMin.value
          : this.voltageMin,
      voltageMax: data.voltageMax.present
          ? data.voltageMax.value
          : this.voltageMax,
      currentSum: data.currentSum.present
          ? data.currentSum.value
          : this.currentSum,
      currentMax: data.currentMax.present
          ? data.currentMax.value
          : this.currentMax,
      frequencySum: data.frequencySum.present
          ? data.frequencySum.value
          : this.frequencySum,
      frequencyMin: data.frequencyMin.present
          ? data.frequencyMin.value
          : this.frequencyMin,
      frequencyMax: data.frequencyMax.present
          ? data.frequencyMax.value
          : this.frequencyMax,
      powerFactorSum: data.powerFactorSum.present
          ? data.powerFactorSum.value
          : this.powerFactorSum,
      powerFactorMin: data.powerFactorMin.present
          ? data.powerFactorMin.value
          : this.powerFactorMin,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      observedSeconds: data.observedSeconds.present
          ? data.observedSeconds.value
          : this.observedSeconds,
      estimatedIntervals: data.estimatedIntervals.present
          ? data.estimatedIntervals.value
          : this.estimatedIntervals,
      coveragePct: data.coveragePct.present
          ? data.coveragePct.value
          : this.coveragePct,
      dataQuality: data.dataQuality.present
          ? data.dataQuality.value
          : this.dataQuality,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HourlyQueueRow(')
          ..write('deviceKey: $deviceKey, ')
          ..write('hourStart: $hourStart, ')
          ..write('energyKwh: $energyKwh, ')
          ..write('powerSum: $powerSum, ')
          ..write('powerMin: $powerMin, ')
          ..write('powerMax: $powerMax, ')
          ..write('voltageSum: $voltageSum, ')
          ..write('voltageMin: $voltageMin, ')
          ..write('voltageMax: $voltageMax, ')
          ..write('currentSum: $currentSum, ')
          ..write('currentMax: $currentMax, ')
          ..write('frequencySum: $frequencySum, ')
          ..write('frequencyMin: $frequencyMin, ')
          ..write('frequencyMax: $frequencyMax, ')
          ..write('powerFactorSum: $powerFactorSum, ')
          ..write('powerFactorMin: $powerFactorMin, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('observedSeconds: $observedSeconds, ')
          ..write('estimatedIntervals: $estimatedIntervals, ')
          ..write('coveragePct: $coveragePct, ')
          ..write('dataQuality: $dataQuality, ')
          ..write('syncState: $syncState, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    deviceKey,
    hourStart,
    energyKwh,
    powerSum,
    powerMin,
    powerMax,
    voltageSum,
    voltageMin,
    voltageMax,
    currentSum,
    currentMax,
    frequencySum,
    frequencyMin,
    frequencyMax,
    powerFactorSum,
    powerFactorMin,
    sampleCount,
    observedSeconds,
    estimatedIntervals,
    coveragePct,
    dataQuality,
    syncState,
    attempts,
    lastError,
    syncedAt,
    nextAttemptAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HourlyQueueRow &&
          other.deviceKey == this.deviceKey &&
          other.hourStart == this.hourStart &&
          other.energyKwh == this.energyKwh &&
          other.powerSum == this.powerSum &&
          other.powerMin == this.powerMin &&
          other.powerMax == this.powerMax &&
          other.voltageSum == this.voltageSum &&
          other.voltageMin == this.voltageMin &&
          other.voltageMax == this.voltageMax &&
          other.currentSum == this.currentSum &&
          other.currentMax == this.currentMax &&
          other.frequencySum == this.frequencySum &&
          other.frequencyMin == this.frequencyMin &&
          other.frequencyMax == this.frequencyMax &&
          other.powerFactorSum == this.powerFactorSum &&
          other.powerFactorMin == this.powerFactorMin &&
          other.sampleCount == this.sampleCount &&
          other.observedSeconds == this.observedSeconds &&
          other.estimatedIntervals == this.estimatedIntervals &&
          other.coveragePct == this.coveragePct &&
          other.dataQuality == this.dataQuality &&
          other.syncState == this.syncState &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.syncedAt == this.syncedAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.updatedAt == this.updatedAt);
}

class HourlyQueueCompanion extends UpdateCompanion<HourlyQueueRow> {
  final Value<String> deviceKey;
  final Value<DateTime> hourStart;
  final Value<double> energyKwh;
  final Value<double> powerSum;
  final Value<double?> powerMin;
  final Value<double?> powerMax;
  final Value<double> voltageSum;
  final Value<double?> voltageMin;
  final Value<double?> voltageMax;
  final Value<double> currentSum;
  final Value<double?> currentMax;
  final Value<double> frequencySum;
  final Value<double?> frequencyMin;
  final Value<double?> frequencyMax;
  final Value<double> powerFactorSum;
  final Value<double?> powerFactorMin;
  final Value<int> sampleCount;
  final Value<double> observedSeconds;
  final Value<int> estimatedIntervals;
  final Value<double> coveragePct;
  final Value<String> dataQuality;
  final Value<String> syncState;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HourlyQueueCompanion({
    this.deviceKey = const Value.absent(),
    this.hourStart = const Value.absent(),
    this.energyKwh = const Value.absent(),
    this.powerSum = const Value.absent(),
    this.powerMin = const Value.absent(),
    this.powerMax = const Value.absent(),
    this.voltageSum = const Value.absent(),
    this.voltageMin = const Value.absent(),
    this.voltageMax = const Value.absent(),
    this.currentSum = const Value.absent(),
    this.currentMax = const Value.absent(),
    this.frequencySum = const Value.absent(),
    this.frequencyMin = const Value.absent(),
    this.frequencyMax = const Value.absent(),
    this.powerFactorSum = const Value.absent(),
    this.powerFactorMin = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.observedSeconds = const Value.absent(),
    this.estimatedIntervals = const Value.absent(),
    this.coveragePct = const Value.absent(),
    this.dataQuality = const Value.absent(),
    this.syncState = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HourlyQueueCompanion.insert({
    required String deviceKey,
    required DateTime hourStart,
    this.energyKwh = const Value.absent(),
    this.powerSum = const Value.absent(),
    this.powerMin = const Value.absent(),
    this.powerMax = const Value.absent(),
    this.voltageSum = const Value.absent(),
    this.voltageMin = const Value.absent(),
    this.voltageMax = const Value.absent(),
    this.currentSum = const Value.absent(),
    this.currentMax = const Value.absent(),
    this.frequencySum = const Value.absent(),
    this.frequencyMin = const Value.absent(),
    this.frequencyMax = const Value.absent(),
    this.powerFactorSum = const Value.absent(),
    this.powerFactorMin = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.observedSeconds = const Value.absent(),
    this.estimatedIntervals = const Value.absent(),
    this.coveragePct = const Value.absent(),
    this.dataQuality = const Value.absent(),
    this.syncState = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : deviceKey = Value(deviceKey),
       hourStart = Value(hourStart),
       updatedAt = Value(updatedAt);
  static Insertable<HourlyQueueRow> custom({
    Expression<String>? deviceKey,
    Expression<DateTime>? hourStart,
    Expression<double>? energyKwh,
    Expression<double>? powerSum,
    Expression<double>? powerMin,
    Expression<double>? powerMax,
    Expression<double>? voltageSum,
    Expression<double>? voltageMin,
    Expression<double>? voltageMax,
    Expression<double>? currentSum,
    Expression<double>? currentMax,
    Expression<double>? frequencySum,
    Expression<double>? frequencyMin,
    Expression<double>? frequencyMax,
    Expression<double>? powerFactorSum,
    Expression<double>? powerFactorMin,
    Expression<int>? sampleCount,
    Expression<double>? observedSeconds,
    Expression<int>? estimatedIntervals,
    Expression<double>? coveragePct,
    Expression<String>? dataQuality,
    Expression<String>? syncState,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceKey != null) 'device_key': deviceKey,
      if (hourStart != null) 'hour_start': hourStart,
      if (energyKwh != null) 'energy_kwh': energyKwh,
      if (powerSum != null) 'power_sum': powerSum,
      if (powerMin != null) 'power_min': powerMin,
      if (powerMax != null) 'power_max': powerMax,
      if (voltageSum != null) 'voltage_sum': voltageSum,
      if (voltageMin != null) 'voltage_min': voltageMin,
      if (voltageMax != null) 'voltage_max': voltageMax,
      if (currentSum != null) 'current_sum': currentSum,
      if (currentMax != null) 'current_max': currentMax,
      if (frequencySum != null) 'frequency_sum': frequencySum,
      if (frequencyMin != null) 'frequency_min': frequencyMin,
      if (frequencyMax != null) 'frequency_max': frequencyMax,
      if (powerFactorSum != null) 'power_factor_sum': powerFactorSum,
      if (powerFactorMin != null) 'power_factor_min': powerFactorMin,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (observedSeconds != null) 'observed_seconds': observedSeconds,
      if (estimatedIntervals != null) 'estimated_intervals': estimatedIntervals,
      if (coveragePct != null) 'coverage_pct': coveragePct,
      if (dataQuality != null) 'data_quality': dataQuality,
      if (syncState != null) 'sync_state': syncState,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HourlyQueueCompanion copyWith({
    Value<String>? deviceKey,
    Value<DateTime>? hourStart,
    Value<double>? energyKwh,
    Value<double>? powerSum,
    Value<double?>? powerMin,
    Value<double?>? powerMax,
    Value<double>? voltageSum,
    Value<double?>? voltageMin,
    Value<double?>? voltageMax,
    Value<double>? currentSum,
    Value<double?>? currentMax,
    Value<double>? frequencySum,
    Value<double?>? frequencyMin,
    Value<double?>? frequencyMax,
    Value<double>? powerFactorSum,
    Value<double?>? powerFactorMin,
    Value<int>? sampleCount,
    Value<double>? observedSeconds,
    Value<int>? estimatedIntervals,
    Value<double>? coveragePct,
    Value<String>? dataQuality,
    Value<String>? syncState,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? nextAttemptAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HourlyQueueCompanion(
      deviceKey: deviceKey ?? this.deviceKey,
      hourStart: hourStart ?? this.hourStart,
      energyKwh: energyKwh ?? this.energyKwh,
      powerSum: powerSum ?? this.powerSum,
      powerMin: powerMin ?? this.powerMin,
      powerMax: powerMax ?? this.powerMax,
      voltageSum: voltageSum ?? this.voltageSum,
      voltageMin: voltageMin ?? this.voltageMin,
      voltageMax: voltageMax ?? this.voltageMax,
      currentSum: currentSum ?? this.currentSum,
      currentMax: currentMax ?? this.currentMax,
      frequencySum: frequencySum ?? this.frequencySum,
      frequencyMin: frequencyMin ?? this.frequencyMin,
      frequencyMax: frequencyMax ?? this.frequencyMax,
      powerFactorSum: powerFactorSum ?? this.powerFactorSum,
      powerFactorMin: powerFactorMin ?? this.powerFactorMin,
      sampleCount: sampleCount ?? this.sampleCount,
      observedSeconds: observedSeconds ?? this.observedSeconds,
      estimatedIntervals: estimatedIntervals ?? this.estimatedIntervals,
      coveragePct: coveragePct ?? this.coveragePct,
      dataQuality: dataQuality ?? this.dataQuality,
      syncState: syncState ?? this.syncState,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      syncedAt: syncedAt ?? this.syncedAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceKey.present) {
      map['device_key'] = Variable<String>(deviceKey.value);
    }
    if (hourStart.present) {
      map['hour_start'] = Variable<DateTime>(hourStart.value);
    }
    if (energyKwh.present) {
      map['energy_kwh'] = Variable<double>(energyKwh.value);
    }
    if (powerSum.present) {
      map['power_sum'] = Variable<double>(powerSum.value);
    }
    if (powerMin.present) {
      map['power_min'] = Variable<double>(powerMin.value);
    }
    if (powerMax.present) {
      map['power_max'] = Variable<double>(powerMax.value);
    }
    if (voltageSum.present) {
      map['voltage_sum'] = Variable<double>(voltageSum.value);
    }
    if (voltageMin.present) {
      map['voltage_min'] = Variable<double>(voltageMin.value);
    }
    if (voltageMax.present) {
      map['voltage_max'] = Variable<double>(voltageMax.value);
    }
    if (currentSum.present) {
      map['current_sum'] = Variable<double>(currentSum.value);
    }
    if (currentMax.present) {
      map['current_max'] = Variable<double>(currentMax.value);
    }
    if (frequencySum.present) {
      map['frequency_sum'] = Variable<double>(frequencySum.value);
    }
    if (frequencyMin.present) {
      map['frequency_min'] = Variable<double>(frequencyMin.value);
    }
    if (frequencyMax.present) {
      map['frequency_max'] = Variable<double>(frequencyMax.value);
    }
    if (powerFactorSum.present) {
      map['power_factor_sum'] = Variable<double>(powerFactorSum.value);
    }
    if (powerFactorMin.present) {
      map['power_factor_min'] = Variable<double>(powerFactorMin.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (observedSeconds.present) {
      map['observed_seconds'] = Variable<double>(observedSeconds.value);
    }
    if (estimatedIntervals.present) {
      map['estimated_intervals'] = Variable<int>(estimatedIntervals.value);
    }
    if (coveragePct.present) {
      map['coverage_pct'] = Variable<double>(coveragePct.value);
    }
    if (dataQuality.present) {
      map['data_quality'] = Variable<String>(dataQuality.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
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
    return (StringBuffer('HourlyQueueCompanion(')
          ..write('deviceKey: $deviceKey, ')
          ..write('hourStart: $hourStart, ')
          ..write('energyKwh: $energyKwh, ')
          ..write('powerSum: $powerSum, ')
          ..write('powerMin: $powerMin, ')
          ..write('powerMax: $powerMax, ')
          ..write('voltageSum: $voltageSum, ')
          ..write('voltageMin: $voltageMin, ')
          ..write('voltageMax: $voltageMax, ')
          ..write('currentSum: $currentSum, ')
          ..write('currentMax: $currentMax, ')
          ..write('frequencySum: $frequencySum, ')
          ..write('frequencyMin: $frequencyMin, ')
          ..write('frequencyMax: $frequencyMax, ')
          ..write('powerFactorSum: $powerFactorSum, ')
          ..write('powerFactorMin: $powerFactorMin, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('observedSeconds: $observedSeconds, ')
          ..write('estimatedIntervals: $estimatedIntervals, ')
          ..write('coveragePct: $coveragePct, ')
          ..write('dataQuality: $dataQuality, ')
          ..write('syncState: $syncState, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EnergyDatabase extends GeneratedDatabase {
  _$EnergyDatabase(QueryExecutor e) : super(e);
  $EnergyDatabaseManager get managers => $EnergyDatabaseManager(this);
  late final $LocalDevicesTable localDevices = $LocalDevicesTable(this);
  late final $MinuteAggregatesTable minuteAggregates = $MinuteAggregatesTable(
    this,
  );
  late final $HourlyHistoryTable hourlyHistory = $HourlyHistoryTable(this);
  late final $HourlyQueueTable hourlyQueue = $HourlyQueueTable(this);
  late final Index hourlyHistoryBucketIdx = Index(
    'hourly_history_bucket_idx',
    'CREATE INDEX hourly_history_bucket_idx ON hourly_history (device_key, hour_start)',
  );
  late final Index hourlyQueueDueIdx = Index(
    'hourly_queue_due_idx',
    'CREATE INDEX hourly_queue_due_idx ON hourly_queue (device_key, sync_state, next_attempt_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localDevices,
    minuteAggregates,
    hourlyHistory,
    hourlyQueue,
    hourlyHistoryBucketIdx,
    hourlyQueueDueIdx,
  ];
}

typedef $$LocalDevicesTableCreateCompanionBuilder =
    LocalDevicesCompanion Function({
      required String localId,
      Value<String> name,
      Value<String?> endpoint,
      Value<String> timezone,
      Value<double> tariffPerKwh,
      Value<double> gridCo2KgPerKwh,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalDevicesTableUpdateCompanionBuilder =
    LocalDevicesCompanion Function({
      Value<String> localId,
      Value<String> name,
      Value<String?> endpoint,
      Value<String> timezone,
      Value<double> tariffPerKwh,
      Value<double> gridCo2KgPerKwh,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalDevicesTableFilterComposer
    extends Composer<_$EnergyDatabase, $LocalDevicesTable> {
  $$LocalDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tariffPerKwh => $composableBuilder(
    column: $table.tariffPerKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gridCo2KgPerKwh => $composableBuilder(
    column: $table.gridCo2KgPerKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDevicesTableOrderingComposer
    extends Composer<_$EnergyDatabase, $LocalDevicesTable> {
  $$LocalDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tariffPerKwh => $composableBuilder(
    column: $table.tariffPerKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gridCo2KgPerKwh => $composableBuilder(
    column: $table.gridCo2KgPerKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDevicesTableAnnotationComposer
    extends Composer<_$EnergyDatabase, $LocalDevicesTable> {
  $$LocalDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<double> get tariffPerKwh => $composableBuilder(
    column: $table.tariffPerKwh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gridCo2KgPerKwh => $composableBuilder(
    column: $table.gridCo2KgPerKwh,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalDevicesTableTableManager
    extends
        RootTableManager<
          _$EnergyDatabase,
          $LocalDevicesTable,
          LocalDeviceRow,
          $$LocalDevicesTableFilterComposer,
          $$LocalDevicesTableOrderingComposer,
          $$LocalDevicesTableAnnotationComposer,
          $$LocalDevicesTableCreateCompanionBuilder,
          $$LocalDevicesTableUpdateCompanionBuilder,
          (
            LocalDeviceRow,
            BaseReferences<
              _$EnergyDatabase,
              $LocalDevicesTable,
              LocalDeviceRow
            >,
          ),
          LocalDeviceRow,
          PrefetchHooks Function()
        > {
  $$LocalDevicesTableTableManager(_$EnergyDatabase db, $LocalDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> endpoint = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<double> tariffPerKwh = const Value.absent(),
                Value<double> gridCo2KgPerKwh = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDevicesCompanion(
                localId: localId,
                name: name,
                endpoint: endpoint,
                timezone: timezone,
                tariffPerKwh: tariffPerKwh,
                gridCo2KgPerKwh: gridCo2KgPerKwh,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String> name = const Value.absent(),
                Value<String?> endpoint = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<double> tariffPerKwh = const Value.absent(),
                Value<double> gridCo2KgPerKwh = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalDevicesCompanion.insert(
                localId: localId,
                name: name,
                endpoint: endpoint,
                timezone: timezone,
                tariffPerKwh: tariffPerKwh,
                gridCo2KgPerKwh: gridCo2KgPerKwh,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDevicesTable, LocalDeviceRow>(table),
                  BaseReferences<
                    _$EnergyDatabase,
                    $LocalDevicesTable,
                    LocalDeviceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$EnergyDatabase,
      $LocalDevicesTable,
      LocalDeviceRow,
      $$LocalDevicesTableFilterComposer,
      $$LocalDevicesTableOrderingComposer,
      $$LocalDevicesTableAnnotationComposer,
      $$LocalDevicesTableCreateCompanionBuilder,
      $$LocalDevicesTableUpdateCompanionBuilder,
      (
        LocalDeviceRow,
        BaseReferences<_$EnergyDatabase, $LocalDevicesTable, LocalDeviceRow>,
      ),
      LocalDeviceRow,
      PrefetchHooks Function()
    >;
typedef $$MinuteAggregatesTableCreateCompanionBuilder =
    MinuteAggregatesCompanion Function({
      required String deviceKey,
      required DateTime minuteStart,
      Value<double> energyKwh,
      Value<double> powerSum,
      Value<double?> powerMin,
      Value<double?> powerMax,
      Value<double> voltageSum,
      Value<double?> voltageMin,
      Value<double?> voltageMax,
      Value<double> currentSum,
      Value<double?> currentMax,
      Value<double> frequencySum,
      Value<double?> frequencyMin,
      Value<double?> frequencyMax,
      Value<double> powerFactorSum,
      Value<double?> powerFactorMin,
      Value<int> sampleCount,
      Value<double> observedSeconds,
      Value<int> estimatedIntervals,
      Value<int> rowid,
    });
typedef $$MinuteAggregatesTableUpdateCompanionBuilder =
    MinuteAggregatesCompanion Function({
      Value<String> deviceKey,
      Value<DateTime> minuteStart,
      Value<double> energyKwh,
      Value<double> powerSum,
      Value<double?> powerMin,
      Value<double?> powerMax,
      Value<double> voltageSum,
      Value<double?> voltageMin,
      Value<double?> voltageMax,
      Value<double> currentSum,
      Value<double?> currentMax,
      Value<double> frequencySum,
      Value<double?> frequencyMin,
      Value<double?> frequencyMax,
      Value<double> powerFactorSum,
      Value<double?> powerFactorMin,
      Value<int> sampleCount,
      Value<double> observedSeconds,
      Value<int> estimatedIntervals,
      Value<int> rowid,
    });

class $$MinuteAggregatesTableFilterComposer
    extends Composer<_$EnergyDatabase, $MinuteAggregatesTable> {
  $$MinuteAggregatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get minuteStart => $composableBuilder(
    column: $table.minuteStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKwh => $composableBuilder(
    column: $table.energyKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerSum => $composableBuilder(
    column: $table.powerSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerMin => $composableBuilder(
    column: $table.powerMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerMax => $composableBuilder(
    column: $table.powerMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MinuteAggregatesTableOrderingComposer
    extends Composer<_$EnergyDatabase, $MinuteAggregatesTable> {
  $$MinuteAggregatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get minuteStart => $composableBuilder(
    column: $table.minuteStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKwh => $composableBuilder(
    column: $table.energyKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerSum => $composableBuilder(
    column: $table.powerSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerMin => $composableBuilder(
    column: $table.powerMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerMax => $composableBuilder(
    column: $table.powerMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MinuteAggregatesTableAnnotationComposer
    extends Composer<_$EnergyDatabase, $MinuteAggregatesTable> {
  $$MinuteAggregatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceKey =>
      $composableBuilder(column: $table.deviceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get minuteStart => $composableBuilder(
    column: $table.minuteStart,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKwh =>
      $composableBuilder(column: $table.energyKwh, builder: (column) => column);

  GeneratedColumn<double> get powerSum =>
      $composableBuilder(column: $table.powerSum, builder: (column) => column);

  GeneratedColumn<double> get powerMin =>
      $composableBuilder(column: $table.powerMin, builder: (column) => column);

  GeneratedColumn<double> get powerMax =>
      $composableBuilder(column: $table.powerMax, builder: (column) => column);

  GeneratedColumn<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => column,
  );
}

class $$MinuteAggregatesTableTableManager
    extends
        RootTableManager<
          _$EnergyDatabase,
          $MinuteAggregatesTable,
          MinuteAggregateRow,
          $$MinuteAggregatesTableFilterComposer,
          $$MinuteAggregatesTableOrderingComposer,
          $$MinuteAggregatesTableAnnotationComposer,
          $$MinuteAggregatesTableCreateCompanionBuilder,
          $$MinuteAggregatesTableUpdateCompanionBuilder,
          (
            MinuteAggregateRow,
            BaseReferences<
              _$EnergyDatabase,
              $MinuteAggregatesTable,
              MinuteAggregateRow
            >,
          ),
          MinuteAggregateRow,
          PrefetchHooks Function()
        > {
  $$MinuteAggregatesTableTableManager(
    _$EnergyDatabase db,
    $MinuteAggregatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MinuteAggregatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MinuteAggregatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MinuteAggregatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceKey = const Value.absent(),
                Value<DateTime> minuteStart = const Value.absent(),
                Value<double> energyKwh = const Value.absent(),
                Value<double> powerSum = const Value.absent(),
                Value<double?> powerMin = const Value.absent(),
                Value<double?> powerMax = const Value.absent(),
                Value<double> voltageSum = const Value.absent(),
                Value<double?> voltageMin = const Value.absent(),
                Value<double?> voltageMax = const Value.absent(),
                Value<double> currentSum = const Value.absent(),
                Value<double?> currentMax = const Value.absent(),
                Value<double> frequencySum = const Value.absent(),
                Value<double?> frequencyMin = const Value.absent(),
                Value<double?> frequencyMax = const Value.absent(),
                Value<double> powerFactorSum = const Value.absent(),
                Value<double?> powerFactorMin = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> observedSeconds = const Value.absent(),
                Value<int> estimatedIntervals = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MinuteAggregatesCompanion(
                deviceKey: deviceKey,
                minuteStart: minuteStart,
                energyKwh: energyKwh,
                powerSum: powerSum,
                powerMin: powerMin,
                powerMax: powerMax,
                voltageSum: voltageSum,
                voltageMin: voltageMin,
                voltageMax: voltageMax,
                currentSum: currentSum,
                currentMax: currentMax,
                frequencySum: frequencySum,
                frequencyMin: frequencyMin,
                frequencyMax: frequencyMax,
                powerFactorSum: powerFactorSum,
                powerFactorMin: powerFactorMin,
                sampleCount: sampleCount,
                observedSeconds: observedSeconds,
                estimatedIntervals: estimatedIntervals,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceKey,
                required DateTime minuteStart,
                Value<double> energyKwh = const Value.absent(),
                Value<double> powerSum = const Value.absent(),
                Value<double?> powerMin = const Value.absent(),
                Value<double?> powerMax = const Value.absent(),
                Value<double> voltageSum = const Value.absent(),
                Value<double?> voltageMin = const Value.absent(),
                Value<double?> voltageMax = const Value.absent(),
                Value<double> currentSum = const Value.absent(),
                Value<double?> currentMax = const Value.absent(),
                Value<double> frequencySum = const Value.absent(),
                Value<double?> frequencyMin = const Value.absent(),
                Value<double?> frequencyMax = const Value.absent(),
                Value<double> powerFactorSum = const Value.absent(),
                Value<double?> powerFactorMin = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> observedSeconds = const Value.absent(),
                Value<int> estimatedIntervals = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MinuteAggregatesCompanion.insert(
                deviceKey: deviceKey,
                minuteStart: minuteStart,
                energyKwh: energyKwh,
                powerSum: powerSum,
                powerMin: powerMin,
                powerMax: powerMax,
                voltageSum: voltageSum,
                voltageMin: voltageMin,
                voltageMax: voltageMax,
                currentSum: currentSum,
                currentMax: currentMax,
                frequencySum: frequencySum,
                frequencyMin: frequencyMin,
                frequencyMax: frequencyMax,
                powerFactorSum: powerFactorSum,
                powerFactorMin: powerFactorMin,
                sampleCount: sampleCount,
                observedSeconds: observedSeconds,
                estimatedIntervals: estimatedIntervals,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MinuteAggregatesTable, MinuteAggregateRow>(
                    table,
                  ),
                  BaseReferences<
                    _$EnergyDatabase,
                    $MinuteAggregatesTable,
                    MinuteAggregateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MinuteAggregatesTableProcessedTableManager =
    ProcessedTableManager<
      _$EnergyDatabase,
      $MinuteAggregatesTable,
      MinuteAggregateRow,
      $$MinuteAggregatesTableFilterComposer,
      $$MinuteAggregatesTableOrderingComposer,
      $$MinuteAggregatesTableAnnotationComposer,
      $$MinuteAggregatesTableCreateCompanionBuilder,
      $$MinuteAggregatesTableUpdateCompanionBuilder,
      (
        MinuteAggregateRow,
        BaseReferences<
          _$EnergyDatabase,
          $MinuteAggregatesTable,
          MinuteAggregateRow
        >,
      ),
      MinuteAggregateRow,
      PrefetchHooks Function()
    >;
typedef $$HourlyHistoryTableCreateCompanionBuilder =
    HourlyHistoryCompanion Function({
      required String deviceKey,
      required DateTime hourStart,
      Value<double> energyKwh,
      Value<double> powerSum,
      Value<double?> powerMin,
      Value<double?> powerMax,
      Value<double> voltageSum,
      Value<double?> voltageMin,
      Value<double?> voltageMax,
      Value<double> currentSum,
      Value<double?> currentMax,
      Value<double> frequencySum,
      Value<double?> frequencyMin,
      Value<double?> frequencyMax,
      Value<double> powerFactorSum,
      Value<double?> powerFactorMin,
      Value<int> sampleCount,
      Value<double> observedSeconds,
      Value<int> estimatedIntervals,
      Value<double> coveragePct,
      Value<String> dataQuality,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$HourlyHistoryTableUpdateCompanionBuilder =
    HourlyHistoryCompanion Function({
      Value<String> deviceKey,
      Value<DateTime> hourStart,
      Value<double> energyKwh,
      Value<double> powerSum,
      Value<double?> powerMin,
      Value<double?> powerMax,
      Value<double> voltageSum,
      Value<double?> voltageMin,
      Value<double?> voltageMax,
      Value<double> currentSum,
      Value<double?> currentMax,
      Value<double> frequencySum,
      Value<double?> frequencyMin,
      Value<double?> frequencyMax,
      Value<double> powerFactorSum,
      Value<double?> powerFactorMin,
      Value<int> sampleCount,
      Value<double> observedSeconds,
      Value<int> estimatedIntervals,
      Value<double> coveragePct,
      Value<String> dataQuality,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

class $$HourlyHistoryTableFilterComposer
    extends Composer<_$EnergyDatabase, $HourlyHistoryTable> {
  $$HourlyHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hourStart => $composableBuilder(
    column: $table.hourStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKwh => $composableBuilder(
    column: $table.energyKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerSum => $composableBuilder(
    column: $table.powerSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerMin => $composableBuilder(
    column: $table.powerMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerMax => $composableBuilder(
    column: $table.powerMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coveragePct => $composableBuilder(
    column: $table.coveragePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HourlyHistoryTableOrderingComposer
    extends Composer<_$EnergyDatabase, $HourlyHistoryTable> {
  $$HourlyHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hourStart => $composableBuilder(
    column: $table.hourStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKwh => $composableBuilder(
    column: $table.energyKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerSum => $composableBuilder(
    column: $table.powerSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerMin => $composableBuilder(
    column: $table.powerMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerMax => $composableBuilder(
    column: $table.powerMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coveragePct => $composableBuilder(
    column: $table.coveragePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HourlyHistoryTableAnnotationComposer
    extends Composer<_$EnergyDatabase, $HourlyHistoryTable> {
  $$HourlyHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceKey =>
      $composableBuilder(column: $table.deviceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get hourStart =>
      $composableBuilder(column: $table.hourStart, builder: (column) => column);

  GeneratedColumn<double> get energyKwh =>
      $composableBuilder(column: $table.energyKwh, builder: (column) => column);

  GeneratedColumn<double> get powerSum =>
      $composableBuilder(column: $table.powerSum, builder: (column) => column);

  GeneratedColumn<double> get powerMin =>
      $composableBuilder(column: $table.powerMin, builder: (column) => column);

  GeneratedColumn<double> get powerMax =>
      $composableBuilder(column: $table.powerMax, builder: (column) => column);

  GeneratedColumn<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => column,
  );

  GeneratedColumn<double> get coveragePct => $composableBuilder(
    column: $table.coveragePct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$HourlyHistoryTableTableManager
    extends
        RootTableManager<
          _$EnergyDatabase,
          $HourlyHistoryTable,
          HourlyHistoryRow,
          $$HourlyHistoryTableFilterComposer,
          $$HourlyHistoryTableOrderingComposer,
          $$HourlyHistoryTableAnnotationComposer,
          $$HourlyHistoryTableCreateCompanionBuilder,
          $$HourlyHistoryTableUpdateCompanionBuilder,
          (
            HourlyHistoryRow,
            BaseReferences<
              _$EnergyDatabase,
              $HourlyHistoryTable,
              HourlyHistoryRow
            >,
          ),
          HourlyHistoryRow,
          PrefetchHooks Function()
        > {
  $$HourlyHistoryTableTableManager(
    _$EnergyDatabase db,
    $HourlyHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HourlyHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HourlyHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HourlyHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceKey = const Value.absent(),
                Value<DateTime> hourStart = const Value.absent(),
                Value<double> energyKwh = const Value.absent(),
                Value<double> powerSum = const Value.absent(),
                Value<double?> powerMin = const Value.absent(),
                Value<double?> powerMax = const Value.absent(),
                Value<double> voltageSum = const Value.absent(),
                Value<double?> voltageMin = const Value.absent(),
                Value<double?> voltageMax = const Value.absent(),
                Value<double> currentSum = const Value.absent(),
                Value<double?> currentMax = const Value.absent(),
                Value<double> frequencySum = const Value.absent(),
                Value<double?> frequencyMin = const Value.absent(),
                Value<double?> frequencyMax = const Value.absent(),
                Value<double> powerFactorSum = const Value.absent(),
                Value<double?> powerFactorMin = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> observedSeconds = const Value.absent(),
                Value<int> estimatedIntervals = const Value.absent(),
                Value<double> coveragePct = const Value.absent(),
                Value<String> dataQuality = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HourlyHistoryCompanion(
                deviceKey: deviceKey,
                hourStart: hourStart,
                energyKwh: energyKwh,
                powerSum: powerSum,
                powerMin: powerMin,
                powerMax: powerMax,
                voltageSum: voltageSum,
                voltageMin: voltageMin,
                voltageMax: voltageMax,
                currentSum: currentSum,
                currentMax: currentMax,
                frequencySum: frequencySum,
                frequencyMin: frequencyMin,
                frequencyMax: frequencyMax,
                powerFactorSum: powerFactorSum,
                powerFactorMin: powerFactorMin,
                sampleCount: sampleCount,
                observedSeconds: observedSeconds,
                estimatedIntervals: estimatedIntervals,
                coveragePct: coveragePct,
                dataQuality: dataQuality,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceKey,
                required DateTime hourStart,
                Value<double> energyKwh = const Value.absent(),
                Value<double> powerSum = const Value.absent(),
                Value<double?> powerMin = const Value.absent(),
                Value<double?> powerMax = const Value.absent(),
                Value<double> voltageSum = const Value.absent(),
                Value<double?> voltageMin = const Value.absent(),
                Value<double?> voltageMax = const Value.absent(),
                Value<double> currentSum = const Value.absent(),
                Value<double?> currentMax = const Value.absent(),
                Value<double> frequencySum = const Value.absent(),
                Value<double?> frequencyMin = const Value.absent(),
                Value<double?> frequencyMax = const Value.absent(),
                Value<double> powerFactorSum = const Value.absent(),
                Value<double?> powerFactorMin = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> observedSeconds = const Value.absent(),
                Value<int> estimatedIntervals = const Value.absent(),
                Value<double> coveragePct = const Value.absent(),
                Value<String> dataQuality = const Value.absent(),
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => HourlyHistoryCompanion.insert(
                deviceKey: deviceKey,
                hourStart: hourStart,
                energyKwh: energyKwh,
                powerSum: powerSum,
                powerMin: powerMin,
                powerMax: powerMax,
                voltageSum: voltageSum,
                voltageMin: voltageMin,
                voltageMax: voltageMax,
                currentSum: currentSum,
                currentMax: currentMax,
                frequencySum: frequencySum,
                frequencyMin: frequencyMin,
                frequencyMax: frequencyMax,
                powerFactorSum: powerFactorSum,
                powerFactorMin: powerFactorMin,
                sampleCount: sampleCount,
                observedSeconds: observedSeconds,
                estimatedIntervals: estimatedIntervals,
                coveragePct: coveragePct,
                dataQuality: dataQuality,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HourlyHistoryTable, HourlyHistoryRow>(table),
                  BaseReferences<
                    _$EnergyDatabase,
                    $HourlyHistoryTable,
                    HourlyHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HourlyHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$EnergyDatabase,
      $HourlyHistoryTable,
      HourlyHistoryRow,
      $$HourlyHistoryTableFilterComposer,
      $$HourlyHistoryTableOrderingComposer,
      $$HourlyHistoryTableAnnotationComposer,
      $$HourlyHistoryTableCreateCompanionBuilder,
      $$HourlyHistoryTableUpdateCompanionBuilder,
      (
        HourlyHistoryRow,
        BaseReferences<_$EnergyDatabase, $HourlyHistoryTable, HourlyHistoryRow>,
      ),
      HourlyHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$HourlyQueueTableCreateCompanionBuilder =
    HourlyQueueCompanion Function({
      required String deviceKey,
      required DateTime hourStart,
      Value<double> energyKwh,
      Value<double> powerSum,
      Value<double?> powerMin,
      Value<double?> powerMax,
      Value<double> voltageSum,
      Value<double?> voltageMin,
      Value<double?> voltageMax,
      Value<double> currentSum,
      Value<double?> currentMax,
      Value<double> frequencySum,
      Value<double?> frequencyMin,
      Value<double?> frequencyMax,
      Value<double> powerFactorSum,
      Value<double?> powerFactorMin,
      Value<int> sampleCount,
      Value<double> observedSeconds,
      Value<int> estimatedIntervals,
      Value<double> coveragePct,
      Value<String> dataQuality,
      Value<String> syncState,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> syncedAt,
      Value<DateTime?> nextAttemptAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HourlyQueueTableUpdateCompanionBuilder =
    HourlyQueueCompanion Function({
      Value<String> deviceKey,
      Value<DateTime> hourStart,
      Value<double> energyKwh,
      Value<double> powerSum,
      Value<double?> powerMin,
      Value<double?> powerMax,
      Value<double> voltageSum,
      Value<double?> voltageMin,
      Value<double?> voltageMax,
      Value<double> currentSum,
      Value<double?> currentMax,
      Value<double> frequencySum,
      Value<double?> frequencyMin,
      Value<double?> frequencyMax,
      Value<double> powerFactorSum,
      Value<double?> powerFactorMin,
      Value<int> sampleCount,
      Value<double> observedSeconds,
      Value<int> estimatedIntervals,
      Value<double> coveragePct,
      Value<String> dataQuality,
      Value<String> syncState,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> syncedAt,
      Value<DateTime?> nextAttemptAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HourlyQueueTableFilterComposer
    extends Composer<_$EnergyDatabase, $HourlyQueueTable> {
  $$HourlyQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hourStart => $composableBuilder(
    column: $table.hourStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKwh => $composableBuilder(
    column: $table.energyKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerSum => $composableBuilder(
    column: $table.powerSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerMin => $composableBuilder(
    column: $table.powerMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerMax => $composableBuilder(
    column: $table.powerMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coveragePct => $composableBuilder(
    column: $table.coveragePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HourlyQueueTableOrderingComposer
    extends Composer<_$EnergyDatabase, $HourlyQueueTable> {
  $$HourlyQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceKey => $composableBuilder(
    column: $table.deviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hourStart => $composableBuilder(
    column: $table.hourStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKwh => $composableBuilder(
    column: $table.energyKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerSum => $composableBuilder(
    column: $table.powerSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerMin => $composableBuilder(
    column: $table.powerMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerMax => $composableBuilder(
    column: $table.powerMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coveragePct => $composableBuilder(
    column: $table.coveragePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HourlyQueueTableAnnotationComposer
    extends Composer<_$EnergyDatabase, $HourlyQueueTable> {
  $$HourlyQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceKey =>
      $composableBuilder(column: $table.deviceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get hourStart =>
      $composableBuilder(column: $table.hourStart, builder: (column) => column);

  GeneratedColumn<double> get energyKwh =>
      $composableBuilder(column: $table.energyKwh, builder: (column) => column);

  GeneratedColumn<double> get powerSum =>
      $composableBuilder(column: $table.powerSum, builder: (column) => column);

  GeneratedColumn<double> get powerMin =>
      $composableBuilder(column: $table.powerMin, builder: (column) => column);

  GeneratedColumn<double> get powerMax =>
      $composableBuilder(column: $table.powerMax, builder: (column) => column);

  GeneratedColumn<double> get voltageSum => $composableBuilder(
    column: $table.voltageSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltageMin => $composableBuilder(
    column: $table.voltageMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltageMax => $composableBuilder(
    column: $table.voltageMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentSum => $composableBuilder(
    column: $table.currentSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentMax => $composableBuilder(
    column: $table.currentMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencySum => $composableBuilder(
    column: $table.frequencySum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencyMin => $composableBuilder(
    column: $table.frequencyMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get frequencyMax => $composableBuilder(
    column: $table.frequencyMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerFactorSum => $composableBuilder(
    column: $table.powerFactorSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get powerFactorMin => $composableBuilder(
    column: $table.powerFactorMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get observedSeconds => $composableBuilder(
    column: $table.observedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedIntervals => $composableBuilder(
    column: $table.estimatedIntervals,
    builder: (column) => column,
  );

  GeneratedColumn<double> get coveragePct => $composableBuilder(
    column: $table.coveragePct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HourlyQueueTableTableManager
    extends
        RootTableManager<
          _$EnergyDatabase,
          $HourlyQueueTable,
          HourlyQueueRow,
          $$HourlyQueueTableFilterComposer,
          $$HourlyQueueTableOrderingComposer,
          $$HourlyQueueTableAnnotationComposer,
          $$HourlyQueueTableCreateCompanionBuilder,
          $$HourlyQueueTableUpdateCompanionBuilder,
          (
            HourlyQueueRow,
            BaseReferences<_$EnergyDatabase, $HourlyQueueTable, HourlyQueueRow>,
          ),
          HourlyQueueRow,
          PrefetchHooks Function()
        > {
  $$HourlyQueueTableTableManager(_$EnergyDatabase db, $HourlyQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HourlyQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HourlyQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HourlyQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceKey = const Value.absent(),
                Value<DateTime> hourStart = const Value.absent(),
                Value<double> energyKwh = const Value.absent(),
                Value<double> powerSum = const Value.absent(),
                Value<double?> powerMin = const Value.absent(),
                Value<double?> powerMax = const Value.absent(),
                Value<double> voltageSum = const Value.absent(),
                Value<double?> voltageMin = const Value.absent(),
                Value<double?> voltageMax = const Value.absent(),
                Value<double> currentSum = const Value.absent(),
                Value<double?> currentMax = const Value.absent(),
                Value<double> frequencySum = const Value.absent(),
                Value<double?> frequencyMin = const Value.absent(),
                Value<double?> frequencyMax = const Value.absent(),
                Value<double> powerFactorSum = const Value.absent(),
                Value<double?> powerFactorMin = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> observedSeconds = const Value.absent(),
                Value<int> estimatedIntervals = const Value.absent(),
                Value<double> coveragePct = const Value.absent(),
                Value<String> dataQuality = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HourlyQueueCompanion(
                deviceKey: deviceKey,
                hourStart: hourStart,
                energyKwh: energyKwh,
                powerSum: powerSum,
                powerMin: powerMin,
                powerMax: powerMax,
                voltageSum: voltageSum,
                voltageMin: voltageMin,
                voltageMax: voltageMax,
                currentSum: currentSum,
                currentMax: currentMax,
                frequencySum: frequencySum,
                frequencyMin: frequencyMin,
                frequencyMax: frequencyMax,
                powerFactorSum: powerFactorSum,
                powerFactorMin: powerFactorMin,
                sampleCount: sampleCount,
                observedSeconds: observedSeconds,
                estimatedIntervals: estimatedIntervals,
                coveragePct: coveragePct,
                dataQuality: dataQuality,
                syncState: syncState,
                attempts: attempts,
                lastError: lastError,
                syncedAt: syncedAt,
                nextAttemptAt: nextAttemptAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceKey,
                required DateTime hourStart,
                Value<double> energyKwh = const Value.absent(),
                Value<double> powerSum = const Value.absent(),
                Value<double?> powerMin = const Value.absent(),
                Value<double?> powerMax = const Value.absent(),
                Value<double> voltageSum = const Value.absent(),
                Value<double?> voltageMin = const Value.absent(),
                Value<double?> voltageMax = const Value.absent(),
                Value<double> currentSum = const Value.absent(),
                Value<double?> currentMax = const Value.absent(),
                Value<double> frequencySum = const Value.absent(),
                Value<double?> frequencyMin = const Value.absent(),
                Value<double?> frequencyMax = const Value.absent(),
                Value<double> powerFactorSum = const Value.absent(),
                Value<double?> powerFactorMin = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<double> observedSeconds = const Value.absent(),
                Value<int> estimatedIntervals = const Value.absent(),
                Value<double> coveragePct = const Value.absent(),
                Value<String> dataQuality = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HourlyQueueCompanion.insert(
                deviceKey: deviceKey,
                hourStart: hourStart,
                energyKwh: energyKwh,
                powerSum: powerSum,
                powerMin: powerMin,
                powerMax: powerMax,
                voltageSum: voltageSum,
                voltageMin: voltageMin,
                voltageMax: voltageMax,
                currentSum: currentSum,
                currentMax: currentMax,
                frequencySum: frequencySum,
                frequencyMin: frequencyMin,
                frequencyMax: frequencyMax,
                powerFactorSum: powerFactorSum,
                powerFactorMin: powerFactorMin,
                sampleCount: sampleCount,
                observedSeconds: observedSeconds,
                estimatedIntervals: estimatedIntervals,
                coveragePct: coveragePct,
                dataQuality: dataQuality,
                syncState: syncState,
                attempts: attempts,
                lastError: lastError,
                syncedAt: syncedAt,
                nextAttemptAt: nextAttemptAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HourlyQueueTable, HourlyQueueRow>(table),
                  BaseReferences<
                    _$EnergyDatabase,
                    $HourlyQueueTable,
                    HourlyQueueRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HourlyQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$EnergyDatabase,
      $HourlyQueueTable,
      HourlyQueueRow,
      $$HourlyQueueTableFilterComposer,
      $$HourlyQueueTableOrderingComposer,
      $$HourlyQueueTableAnnotationComposer,
      $$HourlyQueueTableCreateCompanionBuilder,
      $$HourlyQueueTableUpdateCompanionBuilder,
      (
        HourlyQueueRow,
        BaseReferences<_$EnergyDatabase, $HourlyQueueTable, HourlyQueueRow>,
      ),
      HourlyQueueRow,
      PrefetchHooks Function()
    >;

class $EnergyDatabaseManager {
  final _$EnergyDatabase _db;
  $EnergyDatabaseManager(this._db);
  $$LocalDevicesTableTableManager get localDevices =>
      $$LocalDevicesTableTableManager(_db, _db.localDevices);
  $$MinuteAggregatesTableTableManager get minuteAggregates =>
      $$MinuteAggregatesTableTableManager(_db, _db.minuteAggregates);
  $$HourlyHistoryTableTableManager get hourlyHistory =>
      $$HourlyHistoryTableTableManager(_db, _db.hourlyHistory);
  $$HourlyQueueTableTableManager get hourlyQueue =>
      $$HourlyQueueTableTableManager(_db, _db.hourlyQueue);
}
