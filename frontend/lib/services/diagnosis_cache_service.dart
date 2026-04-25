import 'package:hive/hive.dart';
import '../models/pending_diagnosis.dart';

class DiagnosisCacheService {
  static const _boxName = 'pending_diagnoses';
  static Box<PendingDiagnosis>? _box;

  /// Call once in main.dart after Hive.initFlutter()
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<PendingDiagnosis>(_boxName);
    } else {
      _box = Hive.box<PendingDiagnosis>(_boxName);
    }
  }

  static Future<void> save(PendingDiagnosis entry) async {
    await _box?.put(entry.id, entry);
  }

  static List<PendingDiagnosis> getPending() {
    if (_box == null) return [];
    return _box!.values
        .where((d) => d.syncStatus == 'pending')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static List<PendingDiagnosis> getAll() {
    if (_box == null) return [];
    return _box!.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Remove synced entries to keep storage clean
  static Future<void> deleteSynced() async {
    if (_box == null) return;
    final synced = _box!.values
        .where((d) => d.syncStatus == 'synced')
        .map((d) => d.key)
        .toList();
    await _box!.deleteAll(synced);
  }
}