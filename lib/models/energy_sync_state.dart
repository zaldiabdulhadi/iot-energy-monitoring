enum EnergySyncState {
  pending('pending'),
  synced('synced'),
  failed('failed');

  const EnergySyncState(this.wireName);

  final String wireName;

  static EnergySyncState fromWire(String? value) {
    return EnergySyncState.values.firstWhere(
      (state) => state.wireName == value,
      orElse: () => EnergySyncState.pending,
    );
  }
}
