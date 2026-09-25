import 'package:drift/drift.dart';

@DataClassName('LocalDeviceRow')
class LocalDevices extends Table {
  TextColumn get localId => text()();
  TextColumn get name => text().withDefault(const Constant('ESP Smart Energy'))();
  TextColumn get endpoint => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Jakarta'))();
  RealColumn get tariffPerKwh => real().withDefault(const Constant(1650))();
  RealColumn get gridCo2KgPerKwh => real().withDefault(const Constant(0.42))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

@DataClassName('MinuteAggregateRow')
class MinuteAggregates extends Table {
  TextColumn get deviceKey => text()();
  DateTimeColumn get minuteStart => dateTime()();
  RealColumn get energyKwh => real().withDefault(const Constant(0))();
  RealColumn get powerSum => real().withDefault(const Constant(0))();
  RealColumn get powerMin => real().nullable()();
  RealColumn get powerMax => real().nullable()();
  RealColumn get voltageSum => real().withDefault(const Constant(0))();
  RealColumn get voltageMin => real().nullable()();
  RealColumn get voltageMax => real().nullable()();
  RealColumn get currentSum => real().withDefault(const Constant(0))();
  RealColumn get currentMax => real().nullable()();
  RealColumn get frequencySum => real().withDefault(const Constant(0))();
  RealColumn get frequencyMin => real().nullable()();
  RealColumn get frequencyMax => real().nullable()();
  RealColumn get powerFactorSum => real().withDefault(const Constant(0))();
  RealColumn get powerFactorMin => real().nullable()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
  RealColumn get observedSeconds => real().withDefault(const Constant(0))();
  IntColumn get estimatedIntervals => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {deviceKey, minuteStart};
}

@DataClassName('HourlyQueueRow')
class HourlyQueue extends Table {
  TextColumn get deviceKey => text()();
  DateTimeColumn get hourStart => dateTime()();
  RealColumn get energyKwh => real().withDefault(const Constant(0))();
  RealColumn get powerSum => real().withDefault(const Constant(0))();
  RealColumn get powerMin => real().nullable()();
  RealColumn get powerMax => real().nullable()();
  RealColumn get voltageSum => real().withDefault(const Constant(0))();
  RealColumn get voltageMin => real().nullable()();
  RealColumn get voltageMax => real().nullable()();
  RealColumn get currentSum => real().withDefault(const Constant(0))();
  RealColumn get currentMax => real().nullable()();
  RealColumn get frequencySum => real().withDefault(const Constant(0))();
  RealColumn get frequencyMin => real().nullable()();
  RealColumn get frequencyMax => real().nullable()();
  RealColumn get powerFactorSum => real().withDefault(const Constant(0))();
  RealColumn get powerFactorMin => real().nullable()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
  RealColumn get observedSeconds => real().withDefault(const Constant(0))();
  IntColumn get estimatedIntervals => integer().withDefault(const Constant(0))();
  RealColumn get coveragePct => real().withDefault(const Constant(0))();
  TextColumn get dataQuality => text().withDefault(const Constant('partial'))();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceKey, hourStart};
}
