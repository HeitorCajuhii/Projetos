import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DataBaseHelper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEP Localizador',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CepSearch(),
    );
  }
}

class CepSearch extends StatefulWidget {
  @override
  _CepSearchState createState() => _CepSearchState();
}

class _CepSearchState extends State<CepSearch> {
  final TextEditingController _cepController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  Future<void> _searchCep() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final cep = _cepController.text.replaceAll('-', '');
    final url = 'https://viacep.com.br/ws/$cep/json/';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _result = 'CEP: ${data['cep']}\n'
              'Logradouro: ${data['logradouro']}\n'
              'Complemento: ${data['complemento']}\n'
              'Bairro: ${data['bairro']}\n'
              'Cidade: ${data['localidade']}\n'
              'Estado: ${data['uf']}\n';
        });
      } else {
        setState(() {
          _result = 'CEP não encontrado';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erro ao buscar CEP';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CEP Localizador'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Digite o CEP (apenas números)',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _searchCep,
              child: Text('Buscar CEP'),
            ),
            SizedBox(height: 20.0),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _result,
                    style: TextStyle(fontSize: 16.0),
                  ),
          ],
        ),
      ),
    );
  }
}