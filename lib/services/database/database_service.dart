// Database Service — v1.0.0
// SQLite-based persistence for Void Scriptor data.

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class VoidDatabase {
  static Database? _instance;
  final String _dbPath;

  VoidDatabase(this._dbPath);

  Future<Database> get database async {
    _instance ??= await _init();
    return _instance!;
  }

  Future<Database> _init() async {
    final dir = Directory(p.dirname(_dbPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return openDatabase(
      _dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE characters (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            backstory TEXT,
            attributes TEXT,
            relationships TEXT,
            tags TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE worlds (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            geography TEXT,
            rules TEXT,
            factions TEXT,
            tags TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE stories (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT,
            chapters TEXT,
            tags TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE timeline_events (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT,
            category TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE assets (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT,
            path TEXT,
            thumbnail_path TEXT,
            metadata TEXT,
            tags TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}
