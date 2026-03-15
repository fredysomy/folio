import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
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
      sqflite_ffi.sqfliteFfiInit();
      databaseFactory = sqflite_ffi.databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'portfolio.db');
    return await openDatabase(
      path,
      version: 4,
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
    await db.execute('''
      CREATE TABLE net_worth_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        totalValue REAL NOT NULL,
        dayChange REAL,
        type TEXT,
        mfValue REAL,
        stockValue REAL
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
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS net_worth_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          totalValue REAL NOT NULL,
          dayChange REAL,
          type TEXT,
          mfValue REAL,
          stockValue REAL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE net_worth_history ADD COLUMN mfValue REAL;',
      );
      await db.execute(
        'ALTER TABLE net_worth_history ADD COLUMN stockValue REAL;',
      );
    }
  }

  Future<List<Holding>> getHoldings() async {
    final db = await database;
    final maps = await db.query(
      'holdings',
      orderBy: 'schemeName COLLATE NOCASE',
    );
    return maps.map((m) => Holding.fromMap(m)).toList();
  }

  Future<void> clearHoldings() async {
    final db = await database;
    await db.delete('holdings');
  }

  Future<int> insertHolding(Holding holding) async {
    final db = await database;
    final map = Map<String, dynamic>.from(holding.toMap())..remove('id');
    return await db.insert('holdings', map);
  }

  Future<int> updateHolding(Holding holding) async {
    if (holding.id == null) {
      throw ArgumentError('Cannot update holding without an id');
    }
    final db = await database;
    final map = Map<String, dynamic>.from(holding.toMap())..remove('id');
    return await db.update(
      'holdings',
      map,
      where: 'id = ?',
      whereArgs: [holding.id],
    );
  }

  Future<List<StockHolding>> getStockHoldings() async {
    final db = await database;
    final maps = await db.query(
      'stock_holdings',
      orderBy: 'companyName COLLATE NOCASE',
    );
    return maps.map((m) => StockHolding.fromMap(m)).toList();
  }

  Future<void> clearStockHoldings() async {
    final db = await database;
    await db.delete('stock_holdings');
  }

  Future<int> insertStockHolding(StockHolding holding) async {
    final db = await database;
    final map = Map<String, dynamic>.from(holding.toMap())..remove('id');
    return await db.insert('stock_holdings', map);
  }

  Future<int> updateStockHolding(StockHolding holding) async {
    if (holding.id == null) {
      throw ArgumentError('Cannot update stock holding without an id');
    }
    final db = await database;
    final map = Map<String, dynamic>.from(holding.toMap())..remove('id');
    return await db.update(
      'stock_holdings',
      map,
      where: 'id = ?',
      whereArgs: [holding.id],
    );
  }

  Future<int> insertNetWorthRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('net_worth_history', record);
  }

  Future<Map<String, dynamic>?> getLastNetWorthRecord() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'net_worth_history',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }
}
