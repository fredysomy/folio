import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/holding.dart';
import '../models/stock_holding.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'portfolio.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE holdings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schemeName TEXT NOT NULL,
        units REAL NOT NULL,
        investedValue REAL NOT NULL,
        folioNumber TEXT,
        mfapiCode TEXT,
        currentNav REAL,
        lastUpdated TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_holdings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        companyName TEXT NOT NULL,
        quantity REAL NOT NULL,
        avgBuyPrice REAL NOT NULL,
        isin TEXT,
        apiName TEXT,
        currentPrice REAL,
        percentChange REAL,
        lastUpdated TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_holdings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          companyName TEXT NOT NULL,
          quantity REAL NOT NULL,
          avgBuyPrice REAL NOT NULL,
          isin TEXT,
          apiName TEXT,
          currentPrice REAL,
          percentChange REAL,
          lastUpdated TEXT
        )
      ''');
    }
  }

  Future<int> insertHolding(Holding holding) async {
    final db = await database;
    return await db.insert(
      'holdings',
      holding.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Holding>> getHoldings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('holdings');
    return List.generate(maps.length, (i) {
      return Holding.fromMap(maps[i]);
    });
  }

  Future<int> updateHolding(Holding holding) async {
    final db = await database;
    return await db.update(
      'holdings',
      holding.toMap(),
      where: 'id = ?',
      whereArgs: [holding.id],
    );
  }

  Future<int> deleteHolding(int id) async {
    final db = await database;
    return await db.delete('holdings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHoldings() async {
    final db = await database;
    await db.delete('holdings');
  }

  // ── Stock Holdings ──────────────────────────────────────────────────────────

  Future<int> insertStockHolding(StockHolding h) async {
    final db = await database;
    return await db.insert('stock_holdings', h.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StockHolding>> getStockHoldings() async {
    final db = await database;
    final maps = await db.query('stock_holdings');
    return maps.map((m) => StockHolding.fromMap(m)).toList();
  }

  Future<int> updateStockHolding(StockHolding h) async {
    final db = await database;
    return await db.update('stock_holdings', h.toMap(),
        where: 'id = ?', whereArgs: [h.id]);
  }

  Future<void> clearStockHoldings() async {
    final db = await database;
    await db.delete('stock_holdings');
  }
}
