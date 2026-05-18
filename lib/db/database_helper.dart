import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, 'gensalon.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'Stylist',
        phone TEXT,
        photo_path TEXT,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE services(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        duration_min INTEGER NOT NULL DEFAULT 30,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        photo_path TEXT,
        low_stock_threshold INTEGER NOT NULL DEFAULT 5
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        staff_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        start_at TEXT NOT NULL,
        end_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'scheduled',
        notes TEXT,
        FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE CASCADE,
        FOREIGN KEY(staff_id) REFERENCES staff(id),
        FOREIGN KEY(service_id) REFERENCES services(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_appt_start ON appointments(start_at)');
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id INTEGER,
        staff_id INTEGER,
        total REAL NOT NULL,
        paid_at TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        notes TEXT,
        FOREIGN KEY(appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
        FOREIGN KEY(staff_id) REFERENCES staff(id)
      )
    ''');
    await db.execute('CREATE INDEX idx_sales_paid ON sales(paid_at)');
    await db.execute('''
      CREATE TABLE sale_lines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        ref_type TEXT NOT NULL,
        ref_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL,
        FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    // Seed a few common services
    final batch = db.batch();
    for (final s in [
      ['Haircut', 250.0, 30],
      ['Hair Color', 1200.0, 90],
      ['Manicure', 200.0, 30],
      ['Pedicure', 300.0, 45],
      ['Hair Spa', 800.0, 60],
    ]) {
      batch.insert('services', {
        'name': s[0],
        'price': s[1],
        'duration_min': s[2],
        'active': 1,
      });
    }
    await batch.commit(noResult: true);
  }
}
