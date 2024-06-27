import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SqliteApp());
}

class SqliteApp extends StatefulWidget {
  const SqliteApp({Key? key}) : super(key: key);

  @override
  _SqliteAppState createState() => _SqliteAppState();
}

class _SqliteAppState extends State<SqliteApp> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textController,
          ),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _searchAndSaveCep(textController.text);
                  setState(() {
                    textController.clear();
                    selectedId = null;
                  });
                },
                child: Text('Buscar e Salvar CEP'),
              ),
              SizedBox(height: 20),
              Text('CEPs Salvos:'),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseHelper.instance.getCeplist(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: Text('Carregando ...'));
                    }
                    return snapshot.data!.isEmpty
                        ? Center(child: Text('Sem CEPs Salvos'))
                        : ListView(
                            children: snapshot.data!.map((cepData) {
                              return ListTile(
                                title: Text('CEP: ${cepData['cep']}'),
                                subtitle: Text(
                                    'Logradouro: ${cepData['logradouro']}\nCidade: ${cepData['cidade']}, ${cepData['estado']}'),
                              );
                            }).toList(),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchAndSaveCep(String cep) async {
    final url = 'https://viacep.com.br/ws/$cep/json/';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Salvar no banco de dados
        await DatabaseHelper.instance.addCep({
          'cep': data['cep'],
          'logradouro': data['logradouro'],
          'complemento': data['complemento'],
          'bairro': data['bairro'],
          'cidade': data['localidade'],
          'estado': data['uf'],
        });
      } else {
        print('Erro ao buscar CEP: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar CEP: $e');
    }
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'lista.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lista(
          id INTEGER PRIMARY KEY,
          name TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE cep(
          id INTEGER PRIMARY KEY,
          cep TEXT,
          logradouro TEXT,
          complemento TEXT,
          bairro TEXT,
          cidade TEXT,
          estado TEXT
      )
      ''');
  }

  Future<List<Map<String, dynamic>>> getCeplist() async {
    Database db = await instance.database;
    return await db.query('cep');
  }

  Future<int> addCep(Map<String, dynamic> cepData) async {
    Database db = await instance.database;
    return await db.insert('cep', cepData);
  }
}
