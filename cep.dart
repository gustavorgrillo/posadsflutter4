import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Endereco> buscaCep(String cep) async {
  final resposta = await http.get(
    Uri.parse('https://viacep.com.br/ws/$cep/json/'),
    headers: {'Accept': 'application/json'},
  );

  if (resposta.statusCode == 200) {
    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;

    if (dados['erro'] == true) {
      throw Exception('CEP não encontrado.');
    }

    return Endereco.fromJson(dados);
  } else {
    throw Exception('Falha ao consultar o CEP.');
  }
}

class Endereco {
  final String rua;
  final String bairro;
  final String cidade;
  final String estado;

  const Endereco({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      rua: json['logradouro'] ?? '',
      bairro: json['bairro'] ?? '',
      cidade: json['localidade'] ?? '',
      estado: json['uf'] ?? '',
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController cepController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();

  Endereco? endereco;
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  // Carrega os dados salvos quando o app inicia
  void carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final cep = prefs.getString('cep') ?? '';
    final numero = prefs.getString('numero') ?? '';
    final rua = prefs.getString('rua') ?? '';
    final bairro = prefs.getString('bairro') ?? '';
    final cidade = prefs.getString('cidade') ?? '';
    final estado = prefs.getString('estado') ?? '';

    if (cep.isNotEmpty) {
      cepController.text = cep;
    }

    if (numero.isNotEmpty) {
      numeroController.text = numero;
    }

    if (rua.isNotEmpty) {
      setState(() {
        endereco = Endereco(
          rua: rua,
          bairro: bairro,
          cidade: cidade,
          estado: estado,
        );
      });
    }
  }

  // Consulta o CEP e salva os dados
  void consultarCep() async {
    final cep = cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final numero = numeroController.text;

    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um CEP válido com 8 números.'),
        ),
      );
      return;
    }

    if (numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o número da casa.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final resultado = await buscaCep(cep);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('cep', cep);
      await prefs.setString('numero', numero);
      await prefs.setString('rua', resultado.rua);
      await prefs.setString('bairro', resultado.bairro);
      await prefs.setString('cidade', resultado.cidade);
      await prefs.setString('estado', resultado.estado);

      setState(() {
        endereco = resultado;
        carregando = false;
      });
    } catch (erro) {
      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$erro'),
        ),
      );
    }
  }

  // Apaga todos os dados salvos
  void apagarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('cep');
    await prefs.remove('numero');
    await prefs.remove('rua');
    await prefs.remove('bairro');
    await prefs.remove('cidade');
    await prefs.remove('estado');

    setState(() {
      cepController.clear();
      numeroController.clear();
      endereco = null;
    });
  }

  @override
  void dispose() {
    cepController.dispose();
    numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Endereço',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Meu endereço'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: cepController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CEP',
                  hintText: 'Ex.: 01001000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número da casa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: carregando ? null : consultarCep,
                child: const Text('Consultar e salvar'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: apagarDados,
                child: const Text('Apagar dados'),
              ),
              const SizedBox(height: 30),
              if (carregando) const CircularProgressIndicator(),
              if (endereco != null && !carregando)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CEP: ${cepController.text}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rua: ${endereco!.rua}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Número: ${numeroController.text}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bairro: ${endereco!.bairro}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Cidade: ${endereco!.cidade}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Estado: ${endereco!.estado}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
