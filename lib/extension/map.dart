extension PutOrAdd<T extends String, K extends dynamic> on Map<T, Set<K>> {
  void putOrAdd(T key, K value) {
    if (!containsKey(key)) {
      this[key] = Set<K>();
    }

    this[key]!.add(value);
  }
}

extension PutOrAddList<T extends String, K extends dynamic> on Map<T, List<K>> {
   void putOrAdd(T key, K value) {
    if (!containsKey(key)) {
      this[key] = [];
    }

    this[key]!.add(value);
  }
}