import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_input_text.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/status_requisicao.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class HomePage extends StatefulWidget {
  final String? tipoUsuario;
  final Function(int) atualizarIndex;

  const HomePage(
    this.tipoUsuario, {
    super.key,
    required this.atualizarIndex,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String tipoUsuario = '';
  final TextEditingController _destinoController = TextEditingController();
  late List<Map<String, dynamic>> _itensSugestoes;
  bool _emAtividade = false;
  Color _corEstado = Colors.red;
  String _imagemSugestao = '';
  String _textoSugestao = '';

  @override
  void initState() {
    super.initState();
    _verificarStatusAtividade();
    tipoUsuario = widget.tipoUsuario!;
    _imagemSugestao = tipoUsuario == 'passageiro'
        ? 'assets/images/mapa.png'
        : 'assets/images/carro.png';
    _textoSugestao =
        tipoUsuario == 'passageiro' ? 'Abrir Mapa' : 'Abrir Chamados';
    _itensSugestoes = [
      {
        'nome': _textoSugestao,
        'imagem': _imagemSugestao,
        'funcao': _abrirMapa,
      },
      {
        'nome': 'Atividade',
        'imagem': Icons.library_books_rounded,
        'funcao': _navegarAtividade,
      },
      {
        'nome': 'Configurações',
        'imagem': Icons.settings,
        'funcao': _navegarConfiguracoes
      },
    ];
  }

  void _abrirMapa() {
    if (tipoUsuario == 'passageiro') {
      Navigator.pushNamed(context, '/painel-passageiro');
    } else if (tipoUsuario == 'motorista') {
      widget.atualizarIndex(1);
    } else {
      CustomSnackbar.show(context, 'Não foi possível acessar o mapa');
    }
  }

  void _navegarAtividade() {
    if (tipoUsuario == 'passageiro') {
      setState(() {
        widget.atualizarIndex(1);
      });
    } else {
      widget.atualizarIndex(2);
    }
  }

  void _navegarConfiguracoes() {
    Navigator.pushNamed(context, '/configuracoes');
  }

  Future<void> _verificarStatusAtividade() async {
    try {
      Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();

      if (usuario != null) {
        DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
            .instance
            .collection('usuarios')
            .doc(usuario.id)
            .get();

        bool statusAtividade = doc.data()?['status_atividade'] ?? false;

        setState(() {
          _emAtividade = statusAtividade;
          _corEstado = _emAtividade ? Colors.green : Colors.red;
        });
      }
    } catch (e) {
      print("Erro ao verificar status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tipoUsuario == "passageiro" ? _telaPassageiro() : _telaMotorista(),
    );
  }

  Widget _telaPassageiro() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.secundaryColor,
                borderRadius: BorderRadius.circular(20)),
            child: CustomInputText(
              controller: _destinoController,
              hintText: 'Para onde?',
              hintStyle:
                  TextStyle(color: AppColors.secundarytextColor, fontSize: 15),
              textColor: AppColors.textColor,
              keyboardType: TextInputType.text,
              cursorColor: AppColors.textColor,
              preffixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.secundarytextColor,
              ),
              onTap: () {
                Navigator.pushNamed(context, '/painel-passageiro');
              },
              suffixIcon: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/painel-passageiro');
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.primaryColor,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Agendar',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                  ),
                ),
              ),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder:
                  const OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          _ultimasCorridas(),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sugestões',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sugestoes(context),
        ],
      ),
    );
  }

  Widget _ultimasCorridas() {
    return FutureBuilder<Usuario?>(
      future: UsuarioFirebase.getDadosUsuarioLogado(),
      builder: (context, usuarioSnapshot) {
        if (usuarioSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!usuarioSnapshot.hasData || usuarioSnapshot.data == null) {
          return const Center(child: Text('Erro ao carregar usuário'));
        }

        String? idUsuario = usuarioSnapshot.data!.id;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('requisicoes')
              .where('$tipoUsuario.id_usuario', isEqualTo: idUsuario)
              .where('status', isEqualTo: StatusRequisicao.CONFIRMADA)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('Você ainda não realizou nenhuma corrida'));
            }

            // Converter os documentos para lista ordenada manualmente
            List<QueryDocumentSnapshot> corridas = snapshot.data!.docs;

            corridas.sort((a, b) {
              DateTime dataA = DateTime.parse(a['data_inicio']);
              DateTime dataB = DateTime.parse(b['data_inicio']);
              return dataB.compareTo(dataA);
            });

            // Pega no máximo 2 registros
            corridas = corridas.take(2).toList();

            return Column(
              children: corridas.map((doc) {
                var dados = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/detalhes-corrida',
                      arguments: {
                        'idCorrida': dados['id'].toString(),
                        'tipoUsuario': widget.tipoUsuario.toString(),
                        'idUsuario': idUsuario.toString(),
                      },
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                          BorderSide(color: AppColors.secundaryColor, width: 2),
                    ),
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secundaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.access_time_sharp,
                              color: AppColors.secundarytextColor,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text(
                                  '${dados['destino']['rua']}, ${dados['destino']['numero']}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  '${dados['destino']['bairro']} - ${dados['destino']['cep']}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.secundarytextColor,
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _modeloCard(String nome, dynamic imagemOuIcone, VoidCallback funcao,
      BuildContext context) {
    double tamanhoTela = MediaQuery.of(context).size.width;
    double fontSize = tamanhoTela > 600 ? 14 : (tamanhoTela > 400 ? 12 : 10);

    return GestureDetector(
      onTap: funcao,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.secundaryColor, width: 1.5),
        ),
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              imagemOuIcone is String
                  ? Image.asset(imagemOuIcone, height: 50, width: 50)
                  : Icon(
                      imagemOuIcone,
                      size: 40,
                      color: AppColors.secundarytextColor,
                    ),
              Text(
                nome,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sugestoes(BuildContext context) {
    double tamanhoTela = MediaQuery.of(context).size.width;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itensSugestoes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: tamanhoTela > 600
            ? 5
            : tamanhoTela > 400
                ? 4
                : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = _itensSugestoes[index];
        return _modeloCard(
            item['nome'], item['imagem'], item['funcao'], context);
      },
    );
  }

  Widget _telaMotorista() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.secundaryColor,
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Em Atividade',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.circle_rounded,
                    color: _corEstado,
                  ),
                  Transform.scale(
                    scale: 1.25,
                    child: Switch(
                      value: _emAtividade,
                      activeColor: AppColors.textColor,
                      inactiveTrackColor: AppColors.textColor,
                      inactiveThumbColor: Colors.grey[800],
                      trackOutlineWidth: const WidgetStatePropertyAll(0),
                      trackOutlineColor:
                          const WidgetStatePropertyAll(Colors.transparent),
                      onChanged: (value) async {
                        setState(() {
                          _emAtividade = value;
                          if (_emAtividade) {
                            _corEstado = Colors.green;
                          } else {
                            _corEstado = Colors.red;
                          }
                        });

                        await _atualizarStatusAtividade(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ultimasCorridas(),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sugestões',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sugestoes(context),
        ],
      ),
    );
  }

  Future<void> _atualizarStatusAtividade(bool status) async {
    try {
      Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();

      if (usuario != null && usuario.tipoUsuario == "motorista") {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.id)
            .update({'status_atividade': status});
      }
    } catch (e) {
      print("Erro ao atualizar status: $e");
    }
  }
}
