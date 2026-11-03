
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MarketplaceApp());
}

class LocalDB {
  static Future<Database> get db async {
    return openDatabase(
      p.join(await getDatabasesPath(), 'marketplace_pro.db'),
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE historico (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            produto TEXT,
            plataforma TEXT,
            custo REAL,
            venda REAL,
            lucro REAL,
            margem REAL,
            data TEXT
          )
        ''');
      },
    );
  }

  static Future<void> salvar(Map<String, dynamic> dados) async {
    final database = await db;
    await database.insert('historico', dados);
  }

  static Future<List<Map<String, dynamic>>> listar() async {
    final database = await db;
    return database.query('historico', orderBy: 'id DESC');
  }
}

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Marketplace PRO',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137A55),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pagina = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: pagina,
        children: const [
          CalculatorPage(),
          HistoryPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pagina,
        onDestinationSelected: (value) {
          setState(() => pagina = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final produto = TextEditingController();
  final custo = TextEditingController();
  final venda = TextEditingController();
  final taxa = TextEditingController(text: '15');
  final tarifa = TextEditingController(text: '4');
  final frete = TextEditingController(text: '0');
  final embalagem = TextEditingController(text: '0');

  String plataforma = 'Mercado Livre';
  double lucro = 0;
  double margem = 0;
  double comissao = 0;
  bool calculado = false;

  double numero(TextEditingController c) {
    return double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void calcular() {
    final c = numero(custo);
    final v = numero(venda);
    final t = numero(taxa);
    final f = numero(tarifa);
    final fr = numero(frete);
    final e = numero(embalagem);

    if (produto.text.trim().isEmpty ||
        c < 0 || v <= 0 || t < 0 || t >= 100 ||
        f < 0 || fr < 0 || e < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confira o produto e os valores informados.'),
        ),
      );
      return;
    }

    setState(() {
      comissao = v * t / 100;
      lucro = v - c - comissao - f - fr - e;
      margem = lucro / v * 100;
      calculado = true;
    });
  }

  Future<void> salvar() async {
    await LocalDB.salvar({
      'produto': produto.text,
      'plataforma': plataforma,
      'custo': numero(custo),
      'venda': numero(venda),
      'lucro': lucro,
      'margem': margem,
      'data': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulação salva no celular!'),
      ),
    );
  }

  Widget campo(String titulo, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: titulo,
          prefixText: 'R\$ ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (_) => setState(() => calculado = false),
      ),
    );
  }

  @override
  void dispose() {
    produto.dispose();
    custo.dispose();
    venda.dispose();
    taxa.dispose();
    tarifa.dispose();
    frete.dispose();
    embalagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Marketplace PRO',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF137A55),
            ),
          ),
          const Text(
            'Controle seus custos e descubra seu lucro.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 22),
          const Text(
            'CALCULADORA DE VENDAS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: produto,
            decoration: const InputDecoration(
              labelText: 'Nome do produto',
              prefixIcon: Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            value: plataforma,
            decoration: const InputDecoration(
              labelText: 'Marketplace',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Mercado Livre',
                child: Text('Mercado Livre'),
              ),
              DropdownMenuItem(
                value: 'Shopee',
                child: Text('Shopee'),
              ),
              DropdownMenuItem(
                value: 'TikTok Shop',
                child: Text('TikTok Shop'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                plataforma = value!;
                calculado = false;
              });
            },
          ),
          const SizedBox(height: 13),
          campo('Custo de compra do produto', custo),
          campo('Preço de venda', venda),
          campo('Comissão da plataforma (%)', taxa),
          campo('Tarifa fixa', tarifa),
          campo('Frete pago por você', frete),
          campo('Embalagem', embalagem),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: calcular,
              icon: const Icon(Icons.calculate),
              label: const Text('CALCULAR MEU LUCRO'),
            ),
          ),
          if (calculado) ...[
            const SizedBox(height: 20),
            Card(
              color: lucro >= 0
                  ? const Color(0xFFE1F3E9)
                  : const Color(0xFFFFE5E5),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESULTADO DA VENDA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dinheiro(lucro),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: lucro >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const Text('Lucro líquido estimado'),
                    const Divider(),
                    Text('Comissão: ${dinheiro(comissao)}'),
                    Text('Margem de lucro: ${margem.toStringAsFixed(2)}%'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: salvar,
                        icon: const Icon(Icons.save),
                        label: const Text('SALVAR SIMULAÇÃO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Cálculos realizados localmente no aparelho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de vendas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: LocalDB.listar(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itens = snapshot.data!;

          if (itens.isEmpty) {
            return const Center(
              child: Text('Nenhuma simulação salva ainda.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final item = itens[index];
              final valorLucro = (item['lucro'] as num).toDouble();

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.shopping_bag),
                  ),
                  title: Text(item['produto'].toString()),
                  subtitle: Text(
                    '${item['plataforma']}\n'
                    'Margem: ${(item['margem'] as num).toStringAsFixed(2)}%',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    'R\$ ${valorLucro.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: valorLucro >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
