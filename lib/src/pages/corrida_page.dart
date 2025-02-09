import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/status_requisicao.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class CorridaPage extends StatefulWidget {
  final String? idRequisicao;
  const CorridaPage(this.idRequisicao, {super.key});

  @override
  State<CorridaPage> createState() => _CorridaPageState();
}

class _CorridaPageState extends State<CorridaPage> {
  bool _isLoading = false;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(-22.24773416549846, -49.92616103366711),
  );

  late StreamSubscription<Position> _positionStream;
  Set<Marker> _marcadores = {};
  Map<String, dynamic>? _dadosRequisicao;
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _requisicaoStream;
  LatLng? _ultimaPosicaoCamera;
  String _mensagemStatus = '';
  String _idRequisicao = '';
  Position? _localMotorista;
  String _statusRequisicao = StatusRequisicao.AGUARDANDO;
  double _notaAvaliacao = 0.0;

  @override
  void initState() {
    super.initState();
    _idRequisicao = widget.idRequisicao!;
    _adicionarListenerRequisicao();
    _locationListener();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _requisicaoStream.cancel();
    super.dispose();
  }

  // ** Funções relacionadas à localização **

  void _locationListener() {
    var locationOptions = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationOptions).listen(
      (Position position) async {
        if (_idRequisicao.isNotEmpty) {
          if (_statusRequisicao != StatusRequisicao.AGUARDANDO) {
            UsuarioFirebase.atualizarDadosLocalizacao(
              _idRequisicao,
              position.latitude,
              position.longitude,
              'motorista',
            );
          } else {
            setState(() {
              _localMotorista = position;
            });
            _statusUberAguardando();
          }
        }
      },
      onError: (error) {
        CustomSnackbar.show(
            context, 'Erro no rastreamento de localização: $error');
      },
    );
  }

  void _movimentarCamera(CameraPosition cameraPosition) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  void _exibirMarcador(Position local, String icone, String infoWindow) async {
    Marker marcador = Marker(
      markerId: MarkerId(icone),
      position: LatLng(local.latitude, local.longitude),
      infoWindow: InfoWindow(title: infoWindow),
      icon: BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _marcadores.add(marcador);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  // ** Controlers de Exibição **
  String _textoBotao = 'Aceitar Corrida';
  Color _corBotao = Colors.black;
  VoidCallback _funcaoBotao = () {};

  void _alterarBotaoPrincipal(String text, Color color, VoidCallback function) {
    setState(() {
      _textoBotao = text;
      _corBotao = color;
      _funcaoBotao = function;
    });
  }

  void _adicionarListenerRequisicao() {
    FirebaseFirestore db = FirebaseFirestore.instance;

    _requisicaoStream = db
        .collection('requisicoes')
        .doc(_idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        _dadosRequisicao = snapshot.data();

        Map<String, dynamic>? dados = snapshot.data();
        _statusRequisicao = dados?['status'];

        switch (_statusRequisicao) {
          case StatusRequisicao.AGUARDANDO:
            _statusUberAguardando();
            break;
          case StatusRequisicao.A_CAMINHO:
            _statusUberACaminho();
            break;
          case StatusRequisicao.VIAGEM:
            _statusUberEmViagem();
            break;
          case StatusRequisicao.FINALIZADA:
            _statusUberFinalizada();
            break;
          case StatusRequisicao.CONFIRMADA:
            _statusFinalizacaoConfirmada();
            break;
          default:
        }
      }
    }, onError: (error) {
      CustomSnackbar.show(context, 'Erro no listener da requisição: $error');
    });
  }

  void _statusUberAguardando() {
    _alterarBotaoPrincipal(
      'Aceitar Corrida',
      Colors.black,
      () {
        _aceitarCorrida();
      },
    );

    if (_localMotorista != null) {
      double motoristaLat = _localMotorista!.latitude;
      double motoristaLon = _localMotorista!.longitude;

      Position position = Position(
        longitude: motoristaLon,
        latitude: motoristaLat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      LatLng novaPosicao = LatLng(position.latitude, position.longitude);

      if (_ultimaPosicaoCamera == null || _ultimaPosicaoCamera != novaPosicao) {
        setState(() {
          _exibirMarcador(
            position,
            'assets/images/motorista.png',
            'Motorista',
          );
          CameraPosition cameraPosition = CameraPosition(
            target: novaPosicao,
            zoom: 16,
          );
          _movimentarCamera(cameraPosition);
        });
      }
    }
  }

  void _statusUberACaminho() async {
    _exibirLoading();

    // Verificar se _dadosRequisicao não é nulo
    while (_dadosRequisicao == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    _esconderLoading();

    setState(() {
      _mensagemStatus = '- A caminho do passageiro';
    });

    // Atualizar botão principal
    _alterarBotaoPrincipal(
      'Iniciar corrida',
      Colors.black,
      () {
        _iniciarCorrida();
      },
    );

    // Obter coordenadas
    double latitudePassageiro = _dadosRequisicao!['passageiro']['latitude'];
    double longitudePassageiro = _dadosRequisicao!['passageiro']['longitude'];
    double latitudeMotorista = _dadosRequisicao!['motorista']['latitude'];
    double longitudeMotorista = _dadosRequisicao!['motorista']['longitude'];

    // Exibir os dois marcadores
    await _exibirDoisMarcadores(
      LatLng(latitudeMotorista, longitudeMotorista),
      LatLng(latitudePassageiro, longitudePassageiro),
    );

    // Calcular limites para movimentar a câmera
    double nLat =
        [latitudeMotorista, latitudePassageiro].reduce((a, b) => a > b ? a : b);
    double sLat =
        [latitudeMotorista, latitudePassageiro].reduce((a, b) => a < b ? a : b);
    double nLon = [longitudeMotorista, longitudePassageiro]
        .reduce((a, b) => a > b ? a : b);
    double sLon = [longitudeMotorista, longitudePassageiro]
        .reduce((a, b) => a < b ? a : b);

    _movimentarCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon),
    ));
  }

  void _statusUberEmViagem() async {
    _exibirLoading();

    while (_dadosRequisicao == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    _esconderLoading();

    setState(() {
      _mensagemStatus = '- Em viagem';
    });

    // Atualizar botão principal
    _alterarBotaoPrincipal(
      'Finalizar corrida',
      Colors.black,
      () {
        _finalizarCorrida();
      },
    );

    // Obter coordenadas
    double latitudeDestino = _dadosRequisicao!['destino']['latitude'];
    double longitudeDestino = _dadosRequisicao!['destino']['longitude'];
    double latitudeOrigem = _dadosRequisicao!['motorista']['latitude'];
    double longitudeOrigem = _dadosRequisicao!['motorista']['longitude'];

    // Exibir os dois marcadores
    await _exibirDoisMarcadores(
      LatLng(latitudeOrigem, longitudeOrigem),
      LatLng(latitudeDestino, longitudeDestino),
    );

    // Calcular limites para movimentar a câmera
    double nLat =
        [latitudeOrigem, latitudeDestino].reduce((a, b) => a > b ? a : b);
    double sLat =
        [latitudeOrigem, latitudeDestino].reduce((a, b) => a < b ? a : b);
    double nLon =
        [longitudeOrigem, longitudeDestino].reduce((a, b) => a > b ? a : b);
    double sLon =
        [longitudeOrigem, longitudeDestino].reduce((a, b) => a < b ? a : b);

    _movimentarCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon),
    ));
  }

  void _exibirLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _esconderLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _movimentarCameraBounds(LatLngBounds latlngBounds) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(
      latlngBounds,
      100,
    ));
  }

  Future<void> _exibirDoisMarcadores(LatLng latlng1, LatLng latlng2) async {
    Set<Marker> listaMarcadores = {};

    Marker marcador1 = Marker(
      markerId: const MarkerId('marcador-motorista'),
      position: LatLng(latlng1.latitude, latlng1.longitude),
      infoWindow: const InfoWindow(title: 'Local Motorista'),
      icon: BitmapDescriptor.defaultMarker,
    );

    listaMarcadores.add(marcador1);

    Marker marcador2 = Marker(
      markerId: const MarkerId('marcador-passageiro'),
      position: LatLng(latlng2.latitude, latlng2.longitude),
      infoWindow: const InfoWindow(title: 'Local Passageiro'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    listaMarcadores.add(marcador2);

    setState(() {
      _marcadores.clear();
      _marcadores = listaMarcadores;
    });
  }

  void _aceitarCorrida() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Usuario? motorista = await UsuarioFirebase.getDadosUsuarioLogado();
      motorista?.latitude = _localMotorista!.latitude;
      motorista?.longitude = _localMotorista!.longitude;

      String idRequisicao = _dadosRequisicao?['id'];
      FirebaseFirestore db = FirebaseFirestore.instance;

      await db.collection('requisicoes').doc(idRequisicao).update({
        'motorista': motorista?.toMap(),
        'status': StatusRequisicao.A_CAMINHO,
        'data_inicio': DateTime.now().toIso8601String(),
      });

      String idPassageiro = _dadosRequisicao?['passageiro']['id_usuario'];
      String? idMotorista = motorista?.id;

      await db.collection('requisicao-ativa').doc(idPassageiro).update({
        'status': StatusRequisicao.A_CAMINHO,
      });

      await db.collection('requisicao-ativa-motorista').doc(idMotorista).set({
        'id_requisicao': idRequisicao,
        'id_motorista': idMotorista,
        'status': StatusRequisicao.A_CAMINHO,
      });
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao aceitar corrida: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _iniciarCorrida() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    await db.collection('requisicoes').doc(_idRequisicao).update({
      'origem': {
        'latitude': _dadosRequisicao?['motorista']['latitude'],
        'longitude': _dadosRequisicao?['motorista']['longitude'],
      },
      'status': StatusRequisicao.VIAGEM,
    });

    String idPassageiro = _dadosRequisicao?['passageiro']['id_usuario'];
    await db.collection('requisicao-ativa').doc(idPassageiro).update({
      'status': StatusRequisicao.VIAGEM,
    });

    String idMotorista = _dadosRequisicao?['motorista']['id_usuario'];
    await db.collection('requisicao-ativa-motorista').doc(idMotorista).update({
      'status': StatusRequisicao.VIAGEM,
    });
  }

  void _finalizarCorrida() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection('requisicoes').doc(_idRequisicao).update({
      'status': StatusRequisicao.FINALIZADA,
    });

    String idPassageiro = _dadosRequisicao?['passageiro']['id_usuario'];
    await db.collection('requisicao-ativa').doc(idPassageiro).update({
      'status': StatusRequisicao.FINALIZADA,
    });

    String idMotorista = _dadosRequisicao?['motorista']['id_usuario'];
    await db.collection('requisicao-ativa-motorista').doc(idMotorista).update({
      'status': StatusRequisicao.FINALIZADA,
    });
  }

  void _confirmarCorridaFinalizada() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    double latitudeDestino = _dadosRequisicao!['destino']['latitude'];
    double longitudeDestino = _dadosRequisicao!['destino']['longitude'];
    double latitudeOrigem = _dadosRequisicao!['origem']['latitude'];
    double longitudeOrigem = _dadosRequisicao!['origem']['longitude'];

    double distanciaEmMetros = Geolocator.distanceBetween(
      latitudeOrigem,
      longitudeOrigem,
      latitudeDestino,
      longitudeDestino,
    );

    double distanciaKM = distanciaEmMetros / 1000;
    double valorViagem = distanciaKM * 8;

    await db.collection('requisicoes').doc(_idRequisicao).update({
      'status': StatusRequisicao.CONFIRMADA,
      'valor_corrida': valorViagem,
      'data_fim': DateTime.now().toIso8601String(),
    });

    String idPassageiro = _dadosRequisicao?['passageiro']['id_usuario'];
    await db.collection('requisicao-ativa').doc(idPassageiro).delete();

    String idMotorista = _dadosRequisicao?['motorista']['id_usuario'];
    await db.collection('requisicao-ativa-motorista').doc(idMotorista).delete();

    DocumentReference motoristaRef = db.collection('usuarios').doc(idMotorista);

    try {
      await db.runTransaction((transaction) async {
        DocumentSnapshot motoristaDoc = await transaction.get(motoristaRef);

        if (!motoristaDoc.exists) {
          throw Exception("Motorista não encontrado!");
        }

        var data = motoristaDoc.data() as Map<String, dynamic>;
        double saldoRetirar =
            (data['saldo_retirar'] as num?)?.toDouble() ?? 0.00;
        double saldoTotal = (data['saldo_total'] as num?)?.toDouble() ?? 0.00;

        transaction.update(motoristaRef, {
          'saldo_retirar': saldoRetirar + valorViagem,
          'saldo_total': saldoTotal + valorViagem,
        });
      });

      print("Saldo atualizado com sucesso.");
    } catch (e) {
      print("Erro ao atualizar saldo: $e");
    }
  }

  void _statusUberFinalizada() async {
    double latitudeDestino = _dadosRequisicao!['destino']['latitude'];
    double longitudeDestino = _dadosRequisicao!['destino']['longitude'];
    double latitudeOrigem = _dadosRequisicao!['origem']['latitude'];
    double longitudeOrigem = _dadosRequisicao!['origem']['longitude'];

    double distanciaEmMetros = Geolocator.distanceBetween(
      latitudeOrigem,
      longitudeOrigem,
      latitudeDestino,
      longitudeDestino,
    );

    double distanciaKM = distanciaEmMetros / 1000;
    double valorViagem = distanciaKM * 8;

    var f = NumberFormat("#,##0.00", "pt_BR");
    var valorViagemFormatado = f.format(valorViagem);

    setState(() {
      _mensagemStatus = '- Viagem Finalizada';
    });

    // Atualizar botão principal
    _alterarBotaoPrincipal(
      'Confirmar ${'- R\$$valorViagemFormatado'}',
      Colors.black,
      () {
        _confirmarCorridaFinalizada();
      },
    );

    Position position = Position(
      longitude: longitudeDestino,
      latitude: latitudeDestino,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    setState(() {
      _marcadores.clear();
    });

    _exibirMarcador(
      position,
      'assets/images/destino.png',
      'Destino',
    );
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 19,
    );
    _movimentarCamera(cameraPosition);
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
      var requisicaoRef = FirebaseFirestore.instance
          .collection('requisicoes')
          .doc(_idRequisicao);
      var requisicaoSnapshot = await requisicaoRef.get();

      if (!requisicaoSnapshot.exists) {
        throw Exception("Requisição não encontrada");
      }

      var requisicaoData = requisicaoSnapshot.data()!;

      if (!requisicaoData.containsKey('passageiro') ||
          requisicaoData['passageiro'] == null ||
          !requisicaoData['passageiro'].containsKey('id_usuario')) {
        throw Exception("Dados da requisição incompletos ou mal formatados");
      }

      String idUsuarioAvaliado = requisicaoData['passageiro']['id_usuario'];
      String campoAvaliacao = 'avaliacao-passageiro';

      await requisicaoRef.update({
        campoAvaliacao: _notaAvaliacao,
      });

      await _atualizarMediaAvaliacao(idUsuarioAvaliado);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pushNamedAndRemoveUntil(context, '/initial', (_) => false);

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

      double avaliacaoAtual = 0;
      int quantidadeAvaliacoes = 0;

      if (usuarioSnapshot.exists &&
          usuarioSnapshot.data()!.containsKey('avaliacao')) {
        avaliacaoAtual =
            (usuarioSnapshot.data()!['avaliacao'] as num).toDouble();
      }
      if (usuarioSnapshot.exists &&
          usuarioSnapshot.data()!.containsKey('quantidade_avaliacoes')) {
        quantidadeAvaliacoes =
            usuarioSnapshot.data()!['quantidade_avaliacoes'] as int;
      }

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

  void _statusFinalizacaoConfirmada() {
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
                  'Corrida finalizada. Deseja avaliar o passageiro?',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomButton(
                      text: 'Fechar',
                      funtion: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/initial', (_) => false);
                      },
                      isLoading: false,
                      enabled: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Enviar Avaliação',
                      funtion: () {
                        _enviarAvaliacao();
                      },
                      isLoading: _isLoading,
                      enabled: !_isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel de Corrida $_mensagemStatus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/initial',
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _defaultPosition,
            onMapCreated: _onMapCreated,
            myLocationButtonEnabled: false,
            markers: _marcadores,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomButton(
                funtion: _funcaoBotao,
                text: _textoBotao,
                backgroundColor: _corBotao,
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
