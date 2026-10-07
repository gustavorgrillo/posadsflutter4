import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Organiza(),
    );
  }
}

class Organiza extends StatefulWidget {
  const Organiza({super.key});

  @override
  State<Organiza> createState() => _OrganizaState();
}

class _OrganizaState extends State<Organiza> {
  TextEditingController controlador = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarArquivo();
  }

  Future<File> pegarArquivo() async {
    final pasta = await getApplicationDocumentsDirectory();

    return File('${pasta.path}/organiza.md');
  }

  void carregarArquivo() async {
    final arquivo = await pegarArquivo();

    if (await arquivo.exists()) {
      final texto = await arquivo.readAsString();

      setState(() {
        controlador.text = texto;
      });
    }
  }

  void salvar() async {
    final arquivo = await pegarArquivo();

    await arquivo.writeAsString(controlador.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arquivo salvo!'),
      ),
    );
  }

  void apagar() async {
    final arquivo = await pegarArquivo();

    if (await arquivo.exists()) {
      await arquivo.delete();
    }

    setState(() {
      controlador.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arquivo apagado!'),
      ),
    );
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('organiza.md'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: controlador,
              maxLines: 15,
              decoration: const InputDecoration(
                hintText: 'Digite seu Markdown aqui...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: salvar,
                  child: const Text('Salvar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: apagar,
                  child: const Text('Apagar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
