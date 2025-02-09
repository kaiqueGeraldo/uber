// ignore_for_file: unused_field
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_show_dialog.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/components/custom_text_area.dart';
import 'package:uber/src/utils/colors.dart';

class DetalheCorridaPage extends StatefulWidget {
  final String? idCorrida;
  final String? tipoUsuario;
  final String? idUsuario;
  const DetalheCorridaPage(this.idCorrida, this.tipoUsuario, this.idUsuario,
      {super.key});

  @override
  State<DetalheCorridaPage> createState() => _DetalheCorridaPageState();
}

class _DetalheCorridaPageState extends State<DetalheCorridaPage> {
  Map<String, dynamic>? _dadosCorrida;
  Map<String, dynamic>? _dadosReclamacao;
  bool _isLoading = true;
  late final Completer<GoogleMapController> _controller;
  final TextEditingController _reclamacaoController = TextEditingController();
  GoogleMapController? _mapController;
  Set<Marker> _marcadores = {};
  LatLng? origem;
  LatLng? destino;
  String _textoBotao = 'Fazer Reclamação';
  String _textoBotaoAvaliacao = 'Avaliar';
  String _tituloAvaliacao = 'Não se esqueça de avaliar o';
  bool _reclamacaoFeita = false;
  bool _avaliacaoFeita = false;
  double _notaAvaliacao = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = Completer<GoogleMapController>();
    _tituloAvaliacao =
        'Não se esqueça de avaliar o ${widget.tipoUsuario == 'passageiro' ? 'motorista' : 'passageiro'}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarDados();
    _verificarReclamacao();
    _verificarAvaliacao();
  }

  Future<void> _carregarDados() async {
    final String? idCorrida = widget.idCorrida;
    if (idCorrida == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('requisicoes')
          .doc(idCorrida)
          .get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final dados = doc.data() as Map<String, dynamic>;

      if (!dados.containsKey('origem') ||
          !dados.containsKey('destino') ||
          !dados.containsKey('motorista')) {
        setState(() => _isLoading = false);
        return;
      }

      origem =
          LatLng(dados['origem']['latitude'], dados['origem']['longitude']);
      destino =
          LatLng(dados['destino']['latitude'], dados['destino']['longitude']);

      String motoristaId = dados['motorista']['id_usuario'];
      String dataFimAtual = dados['data_fim'];

      // Buscar a contagem de viagens do motorista
      int viagensAnteriores =
          await _contarViagensAnteriores(motoristaId, dataFimAtual);

      setState(() {
        _dadosCorrida = {
          ...dados,
          'motorista': {
            ...dados['motorista'],
            'viagens_realizadas': viagensAnteriores,
          }
        };
      });

      await _exibirDoisMarcadores(origem!, destino!);
      _movimentarCameraBounds();
    } catch (e) {
      print('Erro ao buscar dados: $e');
      CustomSnackbar.show(context, 'Erro ao carregar dados da corrida.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _contarViagensAnteriores(
      String motoristaId, String dataFimAtual) async {
    try {
      DateTime dataFimConvertida = DateTime.parse(dataFimAtual);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('requisicoes')
          .where('motorista.id_usuario', isEqualTo: motoristaId)
          .get();

      int count = querySnapshot.docs.where((doc) {
        if (doc['data_fim'] != null) {
          DateTime dataCorrida = DateTime.parse(doc['data_fim']);
          return dataCorrida.isBefore(dataFimConvertida);
        }
        return false;
      }).length;

      return count;
    } catch (e) {
      print('Erro ao contar viagens: $e');
      return 0;
    }
  }

  Future<void> _exibirDoisMarcadores(LatLng latlng1, LatLng latlng2) async {
    setState(() {
      _marcadores = {
        Marker(
          markerId: const MarkerId('marcador-inicio'),
          position: latlng1,
          infoWindow: const InfoWindow(title: 'Local início'),
          icon: BitmapDescriptor.defaultMarker,
        ),
        Marker(
          markerId: const MarkerId('marcador-final'),
          position: latlng2,
          infoWindow: const InfoWindow(title: 'Local Final'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  void _movimentarCameraBounds() async {
    if (origem == null || destino == null) return;

    // ignore: unnecessary_nullable_for_final_variable_declarations
    final GoogleMapController? mapController = await _controller.future;
    if (mapController == null) return;

    try {
      LatLngBounds bounds = LatLngBounds(
        northeast: LatLng(max(origem!.latitude, destino!.latitude),
            max(origem!.longitude, destino!.longitude)),
        southwest: LatLng(min(origem!.latitude, destino!.latitude),
            min(origem!.longitude, destino!.longitude)),
      );
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } catch (e) {
      print('Erro ao movimentar câmera: $e');
    }
  }

  Widget _buildMapa() {
    if (origem == null || destino == null) {
      return const Center(child: Text('Localização não disponível'));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: origem!, zoom: 20),
      markers: _marcadores,
      onMapCreated: (controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
        setState(() => _mapController = controller);
      },
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildDetalhes(String titulo, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  String _formatarPeriodoCorrida(String? dataInicio, String? dataFim) {
    if (dataInicio == null || dataFim == null) return 'N/A';

    DateTime inicio = DateTime.parse(dataInicio);
    DateTime fim = DateTime.parse(dataFim);

    String dataFormatada = DateFormat('dd/MM/yyyy').format(inicio);
    String horaInicio = DateFormat('HH:mm').format(inicio);
    String horaFim = DateFormat('HH:mm').format(fim);

    return '$dataFormatada • $horaInicio - $horaFim';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'N/A';

    var formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  String _formatarDestino(Map<String, dynamic>? destino) {
    if (destino == null) return 'N/A';

    return '${destino['rua'] ?? 'N/A'}, ${destino['numero'] ?? 'N/A'} - '
        '${destino['bairro'] ?? 'N/A'} - ${destino['cep'] ?? 'N/A'}';
  }

  String _capitalizarPrimeiraLetra(String? texto) {
    if (texto == null || texto.isEmpty) return 'N/A';
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Widget _fazerReclamacao() {
    return CustomTextArea(
      controller: _reclamacaoController,
      hintText: 'Nos conte o que aconteceu...',
      hintStyle: TextStyle(color: AppColors.textColor, fontSize: 12),
      isLoading: _isLoading,
      textColor: AppColors.textColor,
      cursorColor: AppColors.textColor,
      maxLength: 500,
    );
  }

  void _exibirFazerReclamacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secundaryColor,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fazer Reclamação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _fazerReclamacao(),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Enviar Reclamação',
                funtion: () {
                  _enviarReclamacao();
                },
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enviarReclamacao() async {
    if (_reclamacaoController.text.isEmpty) {
      CustomSnackbar.show(
          context, 'Por favor, escreva sua reclamação antes de enviar.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String descricaoKey = widget.tipoUsuario == 'passageiro'
          ? 'descricao_passageiro'
          : 'descricao_motorista';
      String dataKey = widget.tipoUsuario == 'passageiro'
          ? 'data_reclamacao_passageiro'
          : 'data_reclamacao_motorista';

      await FirebaseFirestore.instance
          .collection('reclamacoes')
          .doc(widget.idCorrida)
          .set({
        descricaoKey: _reclamacaoController.text,
        dataKey: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      CustomSnackbar.show(context, 'Reclamação enviada com sucesso!',
          backgroundColor: Colors.green);

      Navigator.pop(context);
      _reclamacaoController.clear();

      await _verificarReclamacao();
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao enviar reclamação: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verificarReclamacao() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('reclamacoes')
          .doc(widget.idCorrida)
          .get();

      if (snapshot.exists) {
        String descricaoKey = widget.tipoUsuario == 'passageiro'
            ? 'descricao_passageiro'
            : 'descricao_motorista';

        if (snapshot.data()![descricaoKey] != null) {
          if (mounted) {
            setState(() {
              _textoBotao = 'Ver Reclamação';
              _reclamacaoFeita = true;
              _dadosReclamacao = {
                ...snapshot.data()!,
                'docId': snapshot.id,
              };
            });
          }
        }
      }
    } catch (e) {
      print("Erro ao buscar reclamação: $e");
    }
  }

  void _onBotaoPressionado() {
    if (_reclamacaoFeita) {
      _mostrarReclamacao();
    } else {
      _exibirFazerReclamacao();
    }
  }

  void _mostrarReclamacao() async {
    String descricaoKey = widget.tipoUsuario == 'passageiro'
        ? 'descricao_passageiro'
        : 'descricao_motorista';

    String textoReclamacao = _dadosReclamacao![descricaoKey] ?? '';

    if (textoReclamacao.isEmpty) {
      CustomSnackbar.show(context, 'Nenhuma reclamação encontrada.');
      return;
    }

    int linhasCalculadas = (textoReclamacao.length / 30).ceil().clamp(1, 15);
    int minLines = linhasCalculadas;
    int maxLines = linhasCalculadas >= minLines ? linhasCalculadas : minLines;

    customShowDialog(
      context: context,
      title: 'Reclamação',
      content: CustomTextArea(
        controller: _reclamacaoController,
        readOnly: true,
        hintText: textoReclamacao,
        hintStyle: TextStyle(color: AppColors.textColor, fontSize: 12),
        maxLines: maxLines,
        minLines: minLines,
      ),
      cancelText: 'Sair',
      onCancel: () => Navigator.pop(context),
      confirmText: 'Excluir Reclamação',
      confirmTextColor: Colors.red,
      onConfirm: _excluirReclamacao,
    );
  }

  void _excluirReclamacao() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    customShowDialog(
      context: context,
      title: 'Excluir Reclamação',
      content: const Text(
        'Tem certeza que deseja excluir a reclamação? Não será possível reverter posteriormente.',
      ),
      cancelText: 'Cancelar',
      onCancel: () => Navigator.pop(context),
      confirmTextColor: Colors.red,
      confirmText: 'Excluir',
      onConfirm: () async {
        try {
          String descricaoKey = widget.tipoUsuario == 'passageiro'
              ? 'descricao_passageiro'
              : 'descricao_motorista';
          String dataKey = widget.tipoUsuario == 'passageiro'
              ? 'data_reclamacao_passageiro'
              : 'data_reclamacao_motorista';

          DocumentReference docRef =
              db.collection('reclamacoes').doc(widget.idCorrida);
          DocumentSnapshot docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            return;
          }

          Map<String, dynamic>? data =
              docSnapshot.data() as Map<String, dynamic>?;
          if (data == null) {
            return;
          }

          await docRef.update({
            descricaoKey: FieldValue.delete(),
            dataKey: FieldValue.delete(),
          });

          // Verifica se o outro tipo de usuário ainda tem uma reclamação no documento
          bool existeOutraReclamacao = data.containsKey(
              widget.tipoUsuario == 'passageiro'
                  ? 'descricao_motorista'
                  : 'descricao_passageiro');

          // Se não houver outra reclamação, exclui o documento
          if (!existeOutraReclamacao) {
            await docRef.delete();
          }

          setState(() {
            _textoBotao = 'Fazer Reclamação';
            _reclamacaoFeita = false;
          });

          Navigator.pop(context);
          Navigator.pop(context);

          CustomSnackbar.show(
            context,
            'Reclamação excluída com sucesso!',
            backgroundColor: Colors.green,
          );
        } catch (e) {
          CustomSnackbar.show(
            context,
            'Erro ao excluir reclamação: $e',
          );
        }
      },
    );
  }

  void _avaliacao() {
    if (_avaliacaoFeita) {
      _mostrarAvaliacao(
        _notaAvaliacao,
        widget.tipoUsuario == 'passageiro' ? 'motorista' : 'passageiro',
      );
    } else {
      _exibirFazerAvaliacao();
    }
  }

  Future<void> _verificarAvaliacao() async {
    try {
      String? tipoUsuario = widget.tipoUsuario;
      String campoAvaliacao = tipoUsuario == 'passageiro'
          ? 'avaliacao-motorista'
          : 'avaliacao-passageiro';

      var requisicaoRef = FirebaseFirestore.instance
          .collection('requisicoes')
          .doc(widget.idCorrida);

      var requisicaoSnapshot = await requisicaoRef.get();

      if (!requisicaoSnapshot.exists) {
        throw Exception("Requisição não encontrada");
      }

      var requisicaoData = requisicaoSnapshot.data();

      // Verifica se o usuário faz parte da corrida
      if (!(requisicaoData!.containsKey(tipoUsuario) &&
          requisicaoData[tipoUsuario] is Map &&
          requisicaoData[tipoUsuario]['id_usuario'] == widget.idUsuario)) {
        throw Exception("Usuário não faz parte desta corrida");
      }

      // Verifica se a avaliação já foi feita (AGORA NO NÍVEL PRINCIPAL)
      if (requisicaoData.containsKey(campoAvaliacao)) {
        double nota = (requisicaoData[campoAvaliacao] as num).toDouble();

        if (mounted) {
          setState(() {
            _textoBotaoAvaliacao = 'Ver Avaliação';
            _avaliacaoFeita = true;
            _notaAvaliacao = nota;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _textoBotaoAvaliacao = 'Avaliar';
            _avaliacaoFeita = false;
          });
        }
      }
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao buscar avaliação: $e');
    }
  }

  void _mostrarAvaliacao(double notaAvaliacao, String tipoAvaliado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secundaryColor,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sua avaliação deixada para o $tipoAvaliado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _exibirAvaliacao(notaAvaliacao),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _exibirAvaliacao(double nota) {
    return RatingBarIndicator(
      rating: nota,
      itemCount: 5,
      itemSize: 40.0,
      direction: Axis.horizontal,
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
    );
  }

  void _exibirFazerAvaliacao() {
    String tipoAvaliado =
        widget.tipoUsuario == 'passageiro' ? 'Motorista' : 'Passageiro';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secundaryColor,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Avaliar $tipoAvaliado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _fazerAvaliacao(),
              const SizedBox(height: 15),
              CustomButton(
                text: 'Enviar Avalliação',
                funtion: () {
                  _enviarAvaliacao();
                },
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _fazerAvaliacao() {
    return RatingBar.builder(
      initialRating: 0,
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        setState(() {
          _notaAvaliacao = rating;
        });
      },
    );
  }

  Future<void> _enviarAvaliacao() async {
    if (_notaAvaliacao == 0) {
      CustomSnackbar.show(
        context,
        'Por favor, selecione uma nota antes de enviar.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String idUsuarioAvaliado = widget.tipoUsuario == 'passageiro'
          ? _dadosCorrida!['motorista']['id_usuario']
          : _dadosCorrida!['passageiro']['id_usuario'];

      // Atualizar a média de avaliações do usuário avaliado
      await _atualizarMediaAvaliacao(idUsuarioAvaliado);

      if (mounted) {
        setState(() {
          _avaliacaoFeita = true;
          _textoBotaoAvaliacao = 'Ver Avaliação';
          _isLoading = false;
        });

        Navigator.pop(context); // Fechar o modal após o envio

        CustomSnackbar.show(context, 'Avaliação realizada com sucesso!',
            backgroundColor: Colors.green);
      }
    } catch (e) {
      print("Erro ao enviar avaliação: $e");
      CustomSnackbar.show(context, 'Erro ao enviar avaliação: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _atualizarMediaAvaliacao(String idUsuarioAvaliado) async {
    try {
      var usuarioRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuarioAvaliado);
      var usuarioSnapshot = await usuarioRef.get();

      double avaliacaoAtual = usuarioSnapshot.exists &&
              usuarioSnapshot.data()!.containsKey('avaliacao')
          ? (usuarioSnapshot.data()!['avaliacao'] as num).toDouble()
          : 0;
      int quantidadeAvaliacoes = usuarioSnapshot.exists &&
              usuarioSnapshot.data()!.containsKey('quantidade_avaliacoes')
          ? usuarioSnapshot.data()!['quantidade_avaliacoes'] as int
          : 0;

      double novaMedia =
          ((avaliacaoAtual * quantidadeAvaliacoes) + _notaAvaliacao) /
              (quantidadeAvaliacoes + 1);
      await usuarioRef.update({
        'avaliacao': novaMedia,
        'quantidade_avaliacoes': quantidadeAvaliacoes + 1,
      });
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao atualizar média de avaliação: $e');
      print("Erro ao atualizar média de avaliação: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Corrida')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dadosCorrida == null
              ? const Center(child: Text('Corrida não encontrada'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 250, child: _buildMapa()),
                            const SizedBox(height: 10),
                            Text(_formatarPeriodoCorrida(
                                _dadosCorrida!['data_inicio'],
                                _dadosCorrida!['data_fim'])),
                            Text(
                                '${_formatarValor(_dadosCorrida!['valor_corrida'])} • ${_capitalizarPrimeiraLetra(_dadosCorrida!['status'])}'),
                          ],
                        ),
                      ),
                      _buildDetalhes('Dados da Corrida', [
                        Text(
                            'Destino: ${_formatarDestino(_dadosCorrida!['destino'])}'),
                      ]),
                      _buildDetalhes('Dados do Passageiro', [
                        Text(
                            'Nome: ${_dadosCorrida!['passageiro']['nome'] ?? 'N/A'}'),
                        Text(
                            'Email: ${_dadosCorrida!['passageiro']['email'] ?? 'N/A'}'),
                      ]),
                      _buildDetalhes('Dados do Motorista', [
                        Text(
                            'Nome: ${_dadosCorrida!['motorista']['nome'] ?? 'N/A'}'),
                        Text(
                            'Email: ${_dadosCorrida!['motorista']['email'] ?? 'N/A'}'),
                        Text(
                          _dadosCorrida!['motorista']['viagens_realizadas'] == 0
                              ? 'Essa foi a primeira viagem de ${_dadosCorrida!['motorista']['nome']}'
                              : 'Viagens Realizadas: ${_dadosCorrida!['motorista']['viagens_realizadas']}',
                        ),
                      ]),
                      _buildDetalhes('Algo aconteceu?', [
                        Center(
                          child: CustomButton(
                            text: _textoBotao,
                            funtion: _onBotaoPressionado,
                            isLoading: _isLoading,
                            enabled: !_isLoading,
                            backgroundColor: AppColors.secundaryColor,
                          ),
                        ),
                      ]),
                      _buildDetalhes(_tituloAvaliacao, [
                        Center(
                          child: CustomButton(
                            text: _textoBotaoAvaliacao,
                            funtion: _avaliacao,
                            isLoading: _isLoading,
                            enabled: !_isLoading,
                            backgroundColor: AppColors.secundaryColor,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
    );
  }
}
