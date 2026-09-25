import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/energy_hourly.dart';
import '../../models/energy_sync_state.dart';
import '../../utils/bucket_time.dart';
import 'app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalDevices, MinuteAggregates, HourlyQueue])
class EnergyDatabase extends _$EnergyDatabase {
  EnergyDatabase() : super(driftDatabase(name: 'smart_energy'));

  EnergyDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<LocalDeviceRow> ensureLocalDevice() async {
    final existing = await select(localDevices).get();
    if (existing.isNotEmpty) return existing.first;

    await into(localDevices).insert(
      LocalDevicesCompanion.insert(
        localId: generateLocalId(),
        createdAt: toStorage(DateTime.now()),
      ),
    );
    return select(localDevices).getSingle();
  }

  Future<void> updateLocalDevice({
    required String localId,
    String? name,
    String? endpoint,
    double? tariffPerKwh,
    double? gridCo2KgPerKwh,
  }) async {
    await (update(localDevices)..where((t) => t.localId.equals(localId))).write(
      LocalDevicesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        endpoint: endpoint == null ? const Value.absent() : Value(endpoint),
        tariffPerKwh: tariffPerKwh == null
            ? const Value.absent()
            : Value(tariffPerKwh),
        gridCo2KgPerKwh: gridCo2KgPerKwh == null
            ? const Value.absent()
            : Value(gridCo2KgPerKwh),
      ),
    );
  }

  Future<void> upsertMinute(MinuteAggregateRow row) async {
    await into(minuteAggregates).insertOnConflictUpdate(
      MinuteAggregatesCompanion(
        deviceKey: Value(row.deviceKey),
        minuteStart: Value(toStorage(row.minuteStart)),
        energyKwh: Value(row.energyKwh),
        powerSum: Value(row.powerSum),
        powerMin: Value(row.powerMin),
        powerMax: Value(row.powerMax),
        voltageSum: Value(row.voltageSum),
        voltageMin: Value(row.voltageMin),
        voltageMax: Value(row.voltageMax),
        currentSum: Value(row.currentSum),
        currentMax: Value(row.currentMax),
        frequencySum: Value(row.frequencySum),
        frequencyMin: Value(row.frequencyMin),
        frequencyMax: Value(row.frequencyMax),
        powerFactorSum: Value(row.powerFactorSum),
        powerFactorMin: Value(row.powerFactorMin),
        sampleCount: Value(row.sampleCount),
        observedSeconds: Value(row.observedSeconds),
        estimatedIntervals: Value(row.estimatedIntervals),
      ),
    );
  }

  Future<List<MinuteAggregateRow>> minutesForHour(
    String deviceKey,
    DateTime hourStart,
  ) async {
    final start = toStorage(hourStart);
    final end = toStorage(hourStart.add(const Duration(hours: 1)));
    return (select(minuteAggregates)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.minuteStart.isBiggerOrEqualValue(start) &
                t.minuteStart.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.minuteStart)]))
        .get();
  }

  Future<List<DateTime>> hourBucketsBefore(
    String deviceKey,
    DateTime before,
  ) async {
    final query = select(minuteAggregates)
      ..where(
        (t) =>
            t.deviceKey.equals(deviceKey) &
            t.minuteStart.isSmallerThanValue(toStorage(before)),
      );

    final rows = await query.get();
    final buckets = rows
        .map((row) => floorToHour(fromStorage(row.minuteStart)))
        .toSet()
        .toList()
      ..sort();
    return buckets;
  }

  Future<void> upsertHourly({
    required EnergyHourly hourly,
    required DateTime now,
  }) async {
    await into(hourlyQueue).insertOnConflictUpdate(
      HourlyQueueCompanion(
        deviceKey: Value(hourly.deviceKey),
        hourStart: Value(toStorage(hourly.hourStart)),
        energyKwh: Value(hourly.energyKwh),
        powerSum: Value(hourly.powerSum),
        powerMin: Value(hourly.powerMin),
        powerMax: Value(hourly.powerMax),
        voltageSum: Value(hourly.voltageSum),
        voltageMin: Value(hourly.voltageMin),
        voltageMax: Value(hourly.voltageMax),
        currentSum: Value(hourly.currentSum),
        currentMax: Value(hourly.currentMax),
        frequencySum: Value(hourly.frequencySum),
        frequencyMin: Value(hourly.frequencyMin),
        frequencyMax: Value(hourly.frequencyMax),
        powerFactorSum: Value(hourly.powerFactorSum),
        powerFactorMin: Value(hourly.powerFactorMin),
        sampleCount: Value(hourly.sampleCount),
        observedSeconds: Value(hourly.observedSeconds),
        estimatedIntervals: Value(hourly.estimatedIntervals),
        coveragePct: Value(hourly.coveragePct),
        dataQuality: Value(hourly.quality.wireName),
        syncState: const Value('pending'),
        updatedAt: Value(toStorage(now)),
      ),
    );
  }

  Future<void> deleteMinutesForHour(String deviceKey, DateTime hourStart) async {
    final start = toStorage(hourStart);
    final end = toStorage(hourStart.add(const Duration(hours: 1)));
    await (delete(minuteAggregates)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.minuteStart.isBiggerOrEqualValue(start) &
              t.minuteStart.isSmallerThanValue(end),
        ))
        .go();
  }

  Future<List<EnergyHourly>> hourlyBetween(
    String deviceKey,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await (select(hourlyQueue)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.hourStart.isBiggerOrEqualValue(toStorage(from)) &
                t.hourStart.isSmallerThanValue(toStorage(to)),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.hourStart)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<List<HourlyQueueRow>> pendingHours(
    String deviceKey, {
    int limit = 50,
  }) async {
    return (select(hourlyQueue)
          ..where(
            (t) =>
                t.deviceKey.equals(deviceKey) &
                t.syncState.isIn(const ['pending', 'failed']),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.hourStart)])
          ..limit(limit))
        .get();
  }

  Future<int> countPending(String deviceKey) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM hourly_queue '
      'WHERE device_key = ? AND sync_state IN (?, ?)',
      variables: [
        Variable<String>(deviceKey),
        const Variable<String>('pending'),
        const Variable<String>('failed'),
      ],
      readsFrom: {hourlyQueue},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> markSynced(
    String deviceKey,
    DateTime hourStart, {
    required DateTime now,
  }) async {
    await (update(hourlyQueue)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.hourStart.equals(toStorage(hourStart)),
        ))
        .write(
      HourlyQueueCompanion(
        syncState: const Value('synced'),
        syncedAt: Value(toStorage(now)),
        lastError: const Value(null),
        updatedAt: Value(toStorage(now)),
      ),
    );
  }

  Future<void> markFailed(
    String deviceKey,
    DateTime hourStart, {
    required String error,
    required DateTime now,
  }) async {
    final current = await (select(hourlyQueue)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.hourStart.equals(toStorage(hourStart)),
        ))
        .getSingleOrNull();

    await (update(hourlyQueue)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.hourStart.equals(toStorage(hourStart)),
        ))
        .write(
      HourlyQueueCompanion(
        syncState: const Value('failed'),
        attempts: Value((current?.attempts ?? 0) + 1),
        lastError: Value(error),
        updatedAt: Value(toStorage(now)),
      ),
    );
  }

  Future<void> pruneSynced({
    required String deviceKey,
    required DateTime syncedBefore,
  }) async {
    await (delete(hourlyQueue)..where(
          (t) =>
              t.deviceKey.equals(deviceKey) &
              t.syncState.equals('synced') &
              t.syncedAt.isSmallerThanValue(toStorage(syncedBefore)),
        ))
        .go();
  }
}

String generateLocalId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

extension HourlyQueueRowMapper on HourlyQueueRow {
  EnergyHourly toDomain() => EnergyHourly(
        deviceKey: deviceKey,
        hourStart: fromStorage(hourStart),
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
        quality: EnergyDataQuality.fromWire(dataQuality),
      );

  EnergySyncState get syncStateValue => EnergySyncState.fromWire(syncState);
}
