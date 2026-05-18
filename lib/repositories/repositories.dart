import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/models.dart';

class ClientRepo {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> insert(Client c) async => (await _db).insert('clients', c.toMap()..remove('id'));
  Future<int> update(Client c) async =>
      (await _db).update('clients', c.toMap(), where: 'id=?', whereArgs: [c.id]);
  Future<int> delete(int id) async => (await _db).delete('clients', where: 'id=?', whereArgs: [id]);
  Future<List<Client>> all() async {
    final r = await (await _db).query('clients', orderBy: 'name COLLATE NOCASE');
    return r.map(Client.fromMap).toList();
  }
  Future<int> count() async {
    final r = await (await _db).rawQuery('SELECT COUNT(*) c FROM clients');
    return (r.first['c'] as int?) ?? 0;
  }
  Future<Client?> byId(int id) async {
    final r = await (await _db).query('clients', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Client.fromMap(r.first);
  }
}

class StaffRepo {
  Future<Database> get _db async => DatabaseHelper.instance.database;
  Future<int> insert(Staff s) async => (await _db).insert('staff', s.toMap()..remove('id'));
  Future<int> update(Staff s) async =>
      (await _db).update('staff', s.toMap(), where: 'id=?', whereArgs: [s.id]);
  Future<int> delete(int id) async => (await _db).delete('staff', where: 'id=?', whereArgs: [id]);
  Future<List<Staff>> all({bool onlyActive = false}) async {
    final r = await (await _db).query('staff',
        where: onlyActive ? 'active=1' : null, orderBy: 'name COLLATE NOCASE');
    return r.map(Staff.fromMap).toList();
  }
  Future<int> count() async {
    final r = await (await _db).rawQuery('SELECT COUNT(*) c FROM staff WHERE active=1');
    return (r.first['c'] as int?) ?? 0;
  }
  Future<Staff?> byId(int id) async {
    final r = await (await _db).query('staff', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Staff.fromMap(r.first);
  }
}

class ServiceRepo {
  Future<Database> get _db async => DatabaseHelper.instance.database;
  Future<int> insert(Service s) async => (await _db).insert('services', s.toMap()..remove('id'));
  Future<int> update(Service s) async =>
      (await _db).update('services', s.toMap(), where: 'id=?', whereArgs: [s.id]);
  Future<int> delete(int id) async => (await _db).delete('services', where: 'id=?', whereArgs: [id]);
  Future<List<Service>> all({bool onlyActive = false}) async {
    final r = await (await _db).query('services',
        where: onlyActive ? 'active=1' : null, orderBy: 'name COLLATE NOCASE');
    return r.map(Service.fromMap).toList();
  }
  Future<Service?> byId(int id) async {
    final r = await (await _db).query('services', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Service.fromMap(r.first);
  }
}

class ItemRepo {
  Future<Database> get _db async => DatabaseHelper.instance.database;
  Future<int> insert(Item i) async => (await _db).insert('items', i.toMap()..remove('id'));
  Future<int> update(Item i) async =>
      (await _db).update('items', i.toMap(), where: 'id=?', whereArgs: [i.id]);
  Future<int> delete(int id) async => (await _db).delete('items', where: 'id=?', whereArgs: [id]);
  Future<List<Item>> all() async {
    final r = await (await _db).query('items', orderBy: 'name COLLATE NOCASE');
    return r.map(Item.fromMap).toList();
  }
  Future<void> decrementStock(int id, int qty) async {
    final db = await _db;
    await db.rawUpdate('UPDATE items SET stock = MAX(0, stock - ?) WHERE id=?', [qty, id]);
  }
}

class AppointmentRepo {
  Future<Database> get _db async => DatabaseHelper.instance.database;
  Future<int> insert(Appointment a) async => (await _db).insert('appointments', a.toMap()..remove('id'));
  Future<int> update(Appointment a) async => (await _db)
      .update('appointments', a.toMap(), where: 'id=?', whereArgs: [a.id]);
  Future<int> delete(int id) async => (await _db).delete('appointments', where: 'id=?', whereArgs: [id]);

  Future<List<Appointment>> all() async {
    final r = await (await _db).query('appointments', orderBy: 'start_at DESC');
    return r.map(Appointment.fromMap).toList();
  }
  Future<List<Appointment>> upcoming() async {
    final now = DateTime.now().toIso8601String();
    final r = await (await _db).query('appointments',
        where: "start_at >= ? AND status='scheduled'",
        whereArgs: [now],
        orderBy: 'start_at ASC');
    return r.map(Appointment.fromMap).toList();
  }
  Future<List<Appointment>> history() async {
    final now = DateTime.now().toIso8601String();
    final r = await (await _db).query('appointments',
        where: "start_at < ? OR status IN ('completed','cancelled','noShow')",
        whereArgs: [now],
        orderBy: 'start_at DESC');
    return r.map(Appointment.fromMap).toList();
  }
  Future<int> todayCount() async {
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final r = await (await _db).rawQuery(
      'SELECT COUNT(*) c FROM appointments WHERE start_at >= ? AND start_at < ?',
      [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );
    return (r.first['c'] as int?) ?? 0;
  }
}

class SaleRepo {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> createWithLines(Sale sale, List<SaleLine> lines) async {
    final db = await _db;
    return db.transaction((txn) async {
      final saleId =
          await txn.insert('sales', sale.toMap()..remove('id'));
      for (final l in lines) {
        await txn.insert('sale_lines',
            l.toMap()..remove('id')..['sale_id'] = saleId);
        if (l.refType == 'item') {
          await txn.rawUpdate(
              'UPDATE items SET stock = MAX(0, stock - ?) WHERE id=?',
              [l.qty, l.refId]);
        }
      }
      return saleId;
    });
  }

  Future<List<Sale>> inRange(DateTime start, DateTime end) async {
    final r = await (await _db).query('sales',
        where: 'paid_at >= ? AND paid_at < ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'paid_at DESC');
    return r.map(Sale.fromMap).toList();
  }
  Future<List<SaleLine>> linesFor(int saleId) async {
    final r = await (await _db)
        .query('sale_lines', where: 'sale_id=?', whereArgs: [saleId]);
    return r.map(SaleLine.fromMap).toList();
  }

  Future<double> totalInRange(DateTime start, DateTime end) async {
    final r = await (await _db).rawQuery(
      'SELECT COALESCE(SUM(total),0) t FROM sales WHERE paid_at >= ? AND paid_at < ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (r.first['t'] as num?)?.toDouble() ?? 0.0;
  }

  /// Returns last 7 days (inclusive of today) sales totals.
  Future<List<MapEntry<DateTime, double>>> last7Days() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<MapEntry<DateTime, double>> out = [];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final t = await totalInRange(d, d.add(const Duration(days: 1)));
      out.add(MapEntry(d, t));
    }
    return out;
  }
}
