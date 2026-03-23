import 'package:buy_management_project/data/implementations/local/password_hasher.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'mvvm_project.db');

    return await openDatabase(
      dbPath,
      version: 8,
      onCreate: (db, version) async {
        // Bảng users: lưu số điện thoại + password_hash
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL DEFAULT '',
            phone_number TEXT NOT NULL DEFAULT '',
            email TEXT,
            address TEXT NOT NULL DEFAULT '',
            password_hash TEXT NOT NULL DEFAULT '',
            google_uid TEXT,
            avatar_path TEXT
          );
        ''');

        // Bảng session: chỉ lưu 1 session đang đăng nhập (id = 1)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            user_id INTEGER NOT NULL,
            token TEXT NOT NULL,
            created_at TEXT NOT NULL
          );
        ''');

        // Seed tài khoản admin mặc định
        await db.insert('users', {
          'name': 'Admin',
          'phone_number': '0936751968',
          'address': 'Hà Nội',
          'password_hash': PasswordHasher.sha256Hash('HE180516@'),
        });

        // Bảng shopping_items
        await db.execute('''
          CREATE TABLE IF NOT EXISTS shopping_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL DEFAULT 0,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            unit TEXT NOT NULL DEFAULT 'cái',
            category TEXT NOT NULL DEFAULT 'Khác',
            estimated_price REAL NOT NULL DEFAULT 0,
            is_purchased INTEGER NOT NULL DEFAULT 0,
            actual_price REAL
          );
        ''');

        // Bảng budget
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budget (
            user_id INTEGER PRIMARY KEY,
            amount REAL NOT NULL DEFAULT 0
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE users ADD COLUMN name TEXT NOT NULL DEFAULT ''");
          await db.execute("ALTER TABLE users ADD COLUMN address TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS shopping_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL DEFAULT 0,
              name TEXT NOT NULL,
              quantity INTEGER NOT NULL DEFAULT 1,
              unit TEXT NOT NULL DEFAULT 'cái',
              category TEXT NOT NULL DEFAULT 'Khác',
              estimated_price REAL NOT NULL DEFAULT 0,
              is_purchased INTEGER NOT NULL DEFAULT 0,
              actual_price REAL
            );
          ''');
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE shopping_items ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0");
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budget (
              user_id INTEGER PRIMARY KEY,
              amount REAL NOT NULL DEFAULT 0
            );
          ''');
        }
        if (oldVersion < 6) {
          await db.execute("ALTER TABLE users ADD COLUMN google_uid TEXT");
        }
        if (oldVersion < 7) {
          await db.execute("ALTER TABLE users ADD COLUMN email TEXT");
        }
        if (oldVersion < 8) {
          await db.execute("ALTER TABLE users ADD COLUMN avatar_path TEXT");
        }
      },
    );
  }
}
