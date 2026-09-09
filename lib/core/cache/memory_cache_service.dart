class MemoryCacheService {
  static final MemoryCacheService _instance = MemoryCacheService._internal();
  factory MemoryCacheService() => _instance;
  MemoryCacheService._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _expiry = {};

  void set<T>(
    String key,
    T value, {
    Duration ttl = const Duration(minutes: 10),
  }) {
    _cache[key] = value;
    _expiry[key] = DateTime.now().add(ttl);
  }

  T? get<T>(String key) {
    final exp = _expiry[key];
    if (exp == null || DateTime.now().isAfter(exp)) {
      _cache.remove(key);
      _expiry.remove(key);
      return null;
    }
    return _cache[key] as T?;
  }

  void invalidate(String key) {
    _cache.remove(key);
    _expiry.remove(key);
  }

  void clear() {
    _cache.clear();
    _expiry.clear();
  }
}
