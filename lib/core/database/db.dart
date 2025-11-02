import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Db {
  static final Db _instance = Db._internal();
  static Database? _database;

  Db._internal();

  factory Db() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "veterinary.db");
    
    return await openDatabase(
      path,
      version: 2, // Incrementado para soportar migración
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Agregado para manejar migraciones
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Species table
    await db.execute('''
      CREATE TABLE species(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Create Breeds table
    await db.execute('''
      CREATE TABLE breeds(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        species_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (species_id) REFERENCES species (id) ON DELETE RESTRICT,
        UNIQUE (species_id, name)
      )
    ''');

    // Create Animals table
    await db.execute('''
      CREATE TABLE animals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        species_id INTEGER NOT NULL,
        breed_id INTEGER,
        birth_date TEXT,
        gender TEXT,
        coat TEXT,
        purpose TEXT,
        description TEXT,
        location TEXT,
        is_pregnant INTEGER DEFAULT 0,
        pregnant_date TEXT,
        is_sterilized INTEGER DEFAULT 0,
        in_treatment INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0, 
        creation_date TEXT NOT NULL,
        FOREIGN KEY (species_id) REFERENCES species (id) ON DELETE RESTRICT,
        FOREIGN KEY (breed_id) REFERENCES breeds (id) ON DELETE SET NULL
      )
    ''');

    // Create Weights table
    await db.execute('''
      CREATE TABLE weights(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Images table
    await db.execute('''
      CREATE TABLE images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Notes table
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Events table
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        event_date TEXT NOT NULL,
        notes TEXT,
        is_recurring_instance INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        creation_date TEXT NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Vaccines table
    await db.execute('''
      CREATE TABLE vaccines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        expiration_date TEXT,
        lot_number TEXT,
        application_date TEXT NOT NULL,
        veterinary_clinic TEXT,
        veterinarian_name TEXT,
        professional_card_number TEXT,
        vaccine_photo TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Medications table
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        expiration_date TEXT,
        lot_number TEXT,
        application_date TEXT NOT NULL,
        veterinarian_name TEXT,
        medication_name TEXT NOT NULL,
        medication_photo TEXT,
        dosage TEXT,
        next_application TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Records table
    await db.execute('''
      CREATE TABLE records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        comment TEXT,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Chats table
    await db.execute('''
      CREATE TABLE chats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        creation_date TEXT NOT NULL,
        is_ai_chat INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    // Create Messages table
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        is_from_user INTEGER NOT NULL,
        creation_date TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats (id) ON DELETE CASCADE
      )
    ''');

    // Create Heat Cycles table
    await db.execute('''
      CREATE TABLE heat_cycles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        duration_days INTEGER,
        notes TEXT,
        creation_date TEXT NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar tabla heat_cycles para bases de datos existentes
      await db.execute('''
        CREATE TABLE heat_cycles(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          animal_id INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          duration_days INTEGER,
          notes TEXT,
          creation_date TEXT NOT NULL,
          FOREIGN KEY (animal_id) REFERENCES animals (id) ON DELETE CASCADE
        )
      ''');

      // Agregar índices para heat_cycles
      await db.execute('CREATE INDEX idx_heat_cycles_animal ON heat_cycles(animal_id)');
      await db.execute('CREATE INDEX idx_heat_cycles_start_date ON heat_cycles(start_date)');
    }
  }

  Future<void> _createIndexes(Database db) async {
    // Indexes for foreign keys
    await db.execute('CREATE INDEX idx_animals_owner ON animals(owner_id)');
    await db.execute('CREATE INDEX idx_animals_species ON animals(species_id)');
    await db.execute('CREATE INDEX idx_animals_breed ON animals(breed_id)');
    await db.execute('CREATE INDEX idx_breeds_species ON breeds(species_id)');
    await db.execute('CREATE INDEX idx_weights_animal ON weights(animal_id)');
    await db.execute('CREATE INDEX idx_images_animal ON images(animal_id)');
    await db.execute('CREATE INDEX idx_notes_animal ON notes(animal_id)');
    await db.execute('CREATE INDEX idx_events_animal ON events(animal_id)');
    await db.execute('CREATE INDEX idx_vaccines_animal ON vaccines(animal_id)');
    await db.execute('CREATE INDEX idx_medications_animal ON medications(animal_id)');
    await db.execute('CREATE INDEX idx_records_animal ON records(animal_id)');
    await db.execute('CREATE INDEX idx_chats_animal ON chats(animal_id)');
    await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id)');
    await db.execute('CREATE INDEX idx_heat_cycles_animal ON heat_cycles(animal_id)'); // Nuevo
    await db.execute('CREATE INDEX idx_heat_cycles_start_date ON heat_cycles(start_date)'); // Nuevo
    
    // Indexes for dates
    await db.execute('CREATE INDEX idx_events_date ON events(event_date)');
    await db.execute('CREATE INDEX idx_weights_date ON weights(date)');
    await db.execute('CREATE INDEX idx_vaccines_date ON vaccines(application_date)');
    await db.execute('CREATE INDEX idx_medications_date ON medications(application_date)');
    await db.execute('CREATE INDEX idx_notes_date ON notes(date)');
    await db.execute('CREATE INDEX idx_records_date ON records(date)');
    await db.execute('CREATE INDEX idx_chats_date ON chats(creation_date)');
    await db.execute('CREATE INDEX idx_messages_date ON messages(creation_date)');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "veterinary.db");
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}