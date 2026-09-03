import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OfflineActionType {
  feeding,
  biometry,
  mortality,
  waterQuality,
}

/// Elemento de la cola de sincronización offline
class OfflineSyncItem {
  final String id;
  final OfflineActionType type;
  final String table;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  OfflineSyncItem({
    required this.id,
    required this.type,
    required this.table,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'table': table,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory OfflineSyncItem.fromJson(Map<String, dynamic> json) => OfflineSyncItem(
        id: json['id'] as String,
        type: OfflineActionType.values.byName(json['type'] as String),
        table: json['table'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

/// Gestor de Cola de Sincronización Offline (Local-First Resilience)
class OfflineSyncQueue {
  static const _storageKey = 'fishbit_offline_sync_queue_v1';

  /// Encola una acción para ser sincronizada con Supabase cuando haya red
  static Future<void> enqueue({
    required OfflineActionType type,
    required String table,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentQueue = await getPendingItems();

      final newItem = OfflineSyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        table: table,
        payload: payload,
        createdAt: DateTime.now(),
      );

      currentQueue.add(newItem);

      final encoded = jsonEncode(currentQueue.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      debugPrint('[OfflineSync] Acción ${type.name} encolada exitosamente. Total pendientes: ${currentQueue.length}');
    } catch (e) {
      debugPrint('[OfflineSync] Error al encolar: $e');
    }
  }

  /// Obtiene los elementos pendientes en cola
  static Future<List<OfflineSyncItem>> getPendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List;
      return list.map((e) => OfflineSyncItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Vacía y sincroniza la cola contra Supabase
  static Future<int> flushQueue(SupabaseClient supabase) async {
    final items = await getPendingItems();
    if (items.isEmpty) return 0;

    int syncedCount = 0;
    final failedItems = <OfflineSyncItem>[];

    for (final item in items) {
      try {
        await supabase.from(item.table).insert(item.payload);
        syncedCount++;
      } catch (e) {
        debugPrint('[OfflineSync] Error sincronizando elemento ${item.id} en ${item.table}: $e');
        if (item.retryCount < 5) {
          failedItems.add(OfflineSyncItem(
            id: item.id,
            type: item.type,
            table: item.table,
            payload: item.payload,
            createdAt: item.createdAt,
            retryCount: item.retryCount + 1,
          ));
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (failedItems.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, jsonEncode(failedItems.map((e) => e.toJson()).toList()));
    }

    return syncedCount;
  }
}
