import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/status_requisicao.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class PainelMotorista extends StatefulWidget {
  const PainelMotorista({super.key});

  @override
  State<PainelMotorista> createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {
  final _controller = StreamController<QuerySnapshot>.broadcast();
  FirebaseFirestore db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _requisicoesListener;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  bool _emAtividade = true;

  @override
  void initState() {
    super.initState();
    _verificarStatusAtividade();
    _recuperarRequisicaoAtivaMotorista();
  }

  @override
  void dispose() {
    _requisicoesListener?.cancel();
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }

  Stream<QuerySnapshot> _listenerRequisicoes() {
    final stream = db
        .collection('requisicoes')
        .where('status', isEqualTo: StatusRequisicao.AGUARDANDO)
        .snapshots();

    _requisicoesListener = stream.listen((dados) {
      if (mounted) {
        _controller.add(dados);
      }
    });

    return stream;
  }

  void _recuperarRequisicaoAtivaMotorista() async {
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();

    DocumentSnapshot documentSnapshot = await db
        .collection('requisicao-ativa-motorista')
        .doc(firebaseUser?.uid)
        .get();

    var dadosRequisicao = documentSnapshot.data() as Map<String, dynamic>?;

    if (dadosRequisicao == null) {
      _listenerRequisicoes();
    } else {
      String idRequisicao = dadosRequisicao['id_requisicao'];
      Navigator.pushReplacementNamed(
        context,
        '/corrida',
        arguments: idRequisicao,
      );
    }
  }

  // Verifica se o motorista está em atividade
  Future<void> _verificarStatusAtividade() async {
    if (!mounted) return;
    Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();

    if (mounted && usuario != null) {
      _subscription =
          db.collection('usuarios').doc(usuario.id).snapshots().listen((doc) {
        if (mounted) {
          // Garante que o widget ainda está na árvore de widgets
          setState(() {
            _emAtividade = doc.data()?['status_atividade'] ?? false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var mensagemErro = const Center(
      child: Text(
        'Erro ao carregar os dados!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    var mensagemCarregando = const Center(
      child: CircularProgressIndicator(),
    );

    var mensagemNaoTemDados = const Center(
      child: Text(
        'Você não tem nenhuma requisição!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    var mensagemForaDeAtividade = const Center(
      child: Text(
        'Você está fora de atividade! Para ver suas chamadas ative o status de atividade',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (!_emAtividade) {
      return Scaffold(
        body: mensagemForaDeAtividade,
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return mensagemErro;
              } else {
                QuerySnapshot? querySnapshot = snapshot.data;
                if (querySnapshot!.docs.isEmpty) {
                  return mensagemNaoTemDados;
                } else {
                  return ListView.separated(
                    itemCount: querySnapshot.docs.length,
                    itemBuilder: (context, index) {
                      List<DocumentSnapshot> requisicoes =
                          querySnapshot.docs.toList();
                      DocumentSnapshot item = requisicoes[index];

                      String idRequisicao = item['id'];
                      String nomePassageiro = item['passageiro']['nome'];
                      String destinoRua = item['destino']['rua'];
                      String destinoNumero = item['destino']['numero'];

                      // Pega coordenadas do Firebase
                      double latitudeDestino = item['destino']['latitude'];
                      double longitudeDestino = item['destino']['longitude'];
                      double latitudeOrigem = item['passageiro']['latitude'];
                      double longitudeOrigem = item['passageiro']['longitude'];

                      // Calcula distância entre origem e destino
                      double distanciaEmMetros = Geolocator.distanceBetween(
                        latitudeOrigem,
                        longitudeOrigem,
                        latitudeDestino,
                        longitudeDestino,
                      );

                      double distanciaKM = distanciaEmMetros / 1000;
                      String distanciaFormatada =
                          distanciaKM.toStringAsFixed(1);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Card(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppColors.secundaryColor,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.secundaryColor,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  '${distanciaFormatada}KM',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textColor),
                                ),
                              ),
                            ),
                            title: Text(
                              nomePassageiro,
                              style: TextStyle(color: AppColors.textColor),
                            ),
                            subtitle: Text(
                              'Destino: ${'$destinoRua, $destinoNumero'}',
                              style: TextStyle(
                                  color: AppColors.secundarytextColor),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/corrida',
                                arguments: idRequisicao,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(
                        height: 2,
                        color: Colors.grey,
                      );
                    },
                  );
                }
              }
            default:
              return Container();
          }
        },
      ),
    );
  }
}
