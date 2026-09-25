DateTime toStorage(DateTime value) => value.toUtc();

DateTime fromStorage(DateTime value) => value.toLocal();

DateTime floorToMinute(DateTime value) =>
    DateTime(value.year, value.month, value.day, value.hour, value.minute);

DateTime floorToHour(DateTime value) =>
    DateTime(value.year, value.month, value.day, value.hour);
