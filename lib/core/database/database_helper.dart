import 'package:path/path.dart';

import 'package:sqflite/sqflite.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



// 1. Riverpod Provider for Dependency Injection

final databaseProvider = FutureProvider<Database>((ref) async {

  return DatabaseHelper.instance.database;

});



class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;



  DatabaseHelper._init();



  Future<Database> get database async {

    if (_database != null) return _database!;

    _database = await _initDB('finance_app.db');

    return _database!;

  }



  Future<Database> _initDB(String filePath) async {

    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);



    return await openDatabase(

      path,

      version: 1,

      onConfigure: _onConfigure,

      onCreate: _createDB,

    );

  }



  // 2. Enforce Referential Integrity

  Future _onConfigure(Database db) async {

    await db.execute('PRAGMA foreign_keys = ON');

  }



  // 3. Schema Execution (Modified for Precision & Soft Delete)

  Future _createDB(Database db, int version) async {

    await db.execute('''

      CREATE TABLE accounts (

          id INTEGER PRIMARY KEY AUTOINCREMENT,

          name TEXT NOT NULL,

          type TEXT NOT NULL,

          balance INTEGER NOT NULL DEFAULT 0, -- Changed to INTEGER (Cents/Kurush)

          is_deleted INTEGER NOT NULL DEFAULT 0 -- Soft delete

      )

    ''');



    await db.execute('''

      CREATE TABLE categories (

          id INTEGER PRIMARY KEY AUTOINCREMENT,

          name TEXT NOT NULL,

          type TEXT NOT NULL,

          icon TEXT,

          color TEXT,

          is_deleted INTEGER NOT NULL DEFAULT 0 -- Soft delete

      )

    ''');



    await db.execute('''

      CREATE TABLE transactions (

          id INTEGER PRIMARY KEY AUTOINCREMENT,

          account_id INTEGER NOT NULL,

          category_id INTEGER NOT NULL,

          amount INTEGER NOT NULL, -- Changed to INTEGER

          date TEXT NOT NULL,

          receiver TEXT,

          note TEXT,

          is_automated INTEGER NOT NULL DEFAULT 0,

          FOREIGN KEY (account_id) REFERENCES accounts (id),

          FOREIGN KEY (category_id) REFERENCES categories (id)

      )

    ''');



    await db.execute('''

      CREATE TABLE budgets (

          id INTEGER PRIMARY KEY AUTOINCREMENT,

          category_id INTEGER,

          limit_amount INTEGER NOT NULL, -- Changed to INTEGER

          period TEXT NOT NULL,

          start_date TEXT NOT NULL,

          end_date TEXT,

          FOREIGN KEY (category_id) REFERENCES categories (id)

      )

    ''');

    

    // Performance indexes

    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');

    await db.execute('CREATE INDEX idx_transactions_account ON transactions(account_id)');



    await _seedInitialData(db);

  }



  // 4. Initial Seed Data

  Future _seedInitialData(Database db) async {

    // Seed default Cash account

    await db.insert('accounts', {

      'name': 'Cash Wallet',

      'type': 'CASH',

      'balance': 0 // Stored as integer

    });



    // Seed basic categories

    await db.insert('categories', {

      'name': 'Food & Groceries',

      'type': 'EXPENSE',

      'icon': 'restaurant',

      'color': '#FF5722'

    });

    

    await db.insert('categories', {

      'name': 'Salary',

      'type': 'INCOME',

      'icon': 'work',

      'color': '#4CAF50'

    });

  }



  Future close() async {

    final db = await instance.database;

    db.close();

  }

}