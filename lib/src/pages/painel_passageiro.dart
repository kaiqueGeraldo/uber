import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber/src/components/custom_show_dialog.dart';
import 'package:uber/src/models/destino.dart';
import 'package:uber/src/models/requisicao.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_input_text.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/status_requisicao.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({super.key});

  @override
  State<PainelPassageiro> createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  final TextEditingController _meuLocalController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  bool _isLoading = false;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(-22.24107528364154, -49.927157894975515),
    zoom: 16,
  );

  late StreamSubscription<Position> _positionStream;
  Position? _localPassageiro;
  Map<String, dynamic>? _dadosRequisicao;
  Set<Marker> _marcadores = {};
  String _idRequisicao = '';
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionRequisicoes;
  double _notaAvaliacao = 0.0;

  @override
  void initState() {
    super.initState();
    _recuperarRequisicaoAtiva();
    _locationListener();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _destinoController.dispose();
    _meuLocalController.dispose();
    _streamSubscriptionRequisicoes?.cancel();
    _streamSubscriptionRequisicoes = null;
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
          UsuarioFirebase.atualizarDadosLocalizacao(
            _idRequisicao,
            position.latitude,
            position.longitude,
            'passageiro',
          );
        } else {
          setState(() {
            _localPassageiro = position;
          });
          _statusUberNaoChamado();
        }
      },
      onError: (error) {
        CustomSnackbar.show(
            context, 'Erro no rastreamento de localização: $error');
      },
    );
  }

  void _exibirMarcadorPassageiro(Position local) async {
    Marker marcadorPassageiro = Marker(
      markerId: const MarkerId('marcador-passageiro'),
      position: LatLng(local.latitude, local.longitude),
      infoWindow: const InfoWindow(title: 'Meu Local'),
      icon: BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _marcadores.clear();
      _marcadores.add(marcadorPassageiro);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  void _chamarUber() async {
    String enderecoDestino = _destinoController.text;

    if (enderecoDestino.isNotEmpty) {
      try {
        print(enderecoDestino);

        setState(() {
          _isLoading = true;
        });

        List<Location> listaEnderecos =
            await locationFromAddress(enderecoDestino);

        if (listaEnderecos.isNotEmpty) {
          Location endereco = listaEnderecos[0];

          List<Placemark> placemarks = await placemarkFromCoordinates(
            endereco.latitude,
            endereco.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks[0];

            Destino destino = Destino(
              rua: placemark.street ?? '',
              numero: placemark.subThoroughfare ?? '',
              cidade: placemark.subAdministrativeArea ?? '',
              bairro: placemark.subLocality ?? '',
              cep: placemark.postalCode ?? '',
              latitude: endereco.latitude,
              longitude: endereco.longitude,
            );

            String enderecoConfirmacao =
                'Cidade: ${destino.cidade ?? 'Não disponível'}${'\n'}Rua: ${destino.rua ?? 'Não disponível'}, ${destino.numero ?? 'S/N'} ${'\n'}Bairro: ${destino.bairro ?? 'Não disponível'}${'\n'}CEP: ${destino.cep ?? 'Não disponível'}';

            customShowDialog(
              context: context,
              title: 'Confirme o Endereço',
              content: Text(enderecoConfirmacao),
              cancelText: 'Cancelar',
              cancelTextColor: Colors.red,
              onCancel: () => Navigator.pop(context),
              confirmText: 'Confirmar',
              confirmTextColor: Colors.green,
              onConfirm: () {
                _salvarRequisicao(destino);
                Navigator.pop(context);
              },
            );

            setState(() {});
          } else {
            CustomSnackbar.show(
                context, 'Não foi possível obter detalhes do endereço.');
          }
        }
      } catch (e, stackTrace) {
        print('Erro ao buscar destino: $e\n$stackTrace');
        CustomSnackbar.show(context, 'Erro ao buscar destino: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      CustomSnackbar.show(context, 'Por favor, digite um endereço válido.');
    }
  }

  Future<void> _salvarRequisicao(Destino destino) async {
    Usuario? passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    passageiro?.latitude = _localPassageiro!.latitude;
    passageiro?.longitude = _localPassageiro!.longitude;

    Requisicao requisicao = Requisicao(
      status: StatusRequisicao.AGUARDANDO,
      passageiro: passageiro!,
      destino: destino,
    );

    FirebaseFirestore db = FirebaseFirestore.instance;

    // salvar requisição
    await db
        .collection('requisicoes')
        .doc(requisicao.id)
        .set(requisicao.toMap());

    // salvar requisição-ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva['id_requisicao'] = requisicao.id;
    dadosRequisicaoAtiva['id_usuario'] = passageiro.id;
    dadosRequisicaoAtiva['status'] = StatusRequisicao.AGUARDANDO;

    await db
        .collection('requisicao-ativa')
        .doc(passageiro.id)
        .set(dadosRequisicaoAtiva);

    // adiconar listener requisicao
    if (_streamSubscriptionRequisicoes == null) {
      _adicionarListenerRequisicao(requisicao.id!);
    }
  }

// ** Controlers de Exibição **
  bool _exibirCaixaEnderecoDestino = true;
  String _textoBotao = 'Chamar Uber';
  Color _corBotao = Colors.black;
  VoidCallback _funcaoBotao = () {};

  void _alterarBotaoPrincipal(String text, Color color, VoidCallback function) {
    setState(() {
      _textoBotao = text;
      _corBotao = color;
      _funcaoBotao = function;
    });
  }

  void _statusUberNaoChamado() async {
    setState(() {
      _exibirCaixaEnderecoDestino = true;
    });

    _alterarBotaoPrincipal(
      'Chamar Uber',
      Colors.black,
      () {
        _chamarUber();
      },
    );

    if (_localPassageiro != null) {
      Position position = Position(
        longitude: _localPassageiro!.longitude,
        latitude: _localPassageiro!.latitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      _exibirMarcadorPassageiro(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 25,
      );

      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  void _statusUberAguardando() async {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
    });

    _alterarBotaoPrincipal(
      'Cancelar',
      Colors.red[400]!,
      () {
        _cancelarUber();
      },
    );

    double passageiroLat = _dadosRequisicao!['passageiro']['latitude'];
    double passageiroLon = _dadosRequisicao!['passageiro']['longitude'];

    Position position = Position(
      longitude: passageiroLon,
      latitude: passageiroLat,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    _exibirMarcadorPassageiro(position);
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16,
    );

    _movimentarCamera(cameraPosition);
  }

  void _statusUberACaminho() async {
    setState(() {
      _exibirCaixaEnderecoDestino = false;
    });

    _alterarBotaoPrincipal(
      'Motorista a caminho',
      Colors.grey,
      () {},
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

    // Atualizar botão principal
    _alterarBotaoPrincipal(
      'Em viagem',
      Colors.grey,
      () {},
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

    // Atualizar botão principal
    _alterarBotaoPrincipal(
      'Total ${'- R\$$valorViagemFormatado'}',
      Colors.green,
      () {},
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

      if (!requisicaoData.containsKey('motorista') ||
          requisicaoData['motorista'] == null ||
          !requisicaoData['motorista'].containsKey('id_usuario')) {
        throw Exception("Dados da requisição incompletos ou mal formatados");
      }

      String idUsuarioAvaliado = requisicaoData['motorista']['id_usuario'];
      String campoAvaliacao = 'avaliacao-motorista';

      await requisicaoRef.update({
        campoAvaliacao: _notaAvaliacao,
      });

      await _atualizarMediaAvaliacao(idUsuarioAvaliado);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pop(context);

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
    if (_streamSubscriptionRequisicoes != null) {
      setState(() {
        _streamSubscriptionRequisicoes!.cancel();
        _streamSubscriptionRequisicoes = null;
        _exibirCaixaEnderecoDestino = true;
      });

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
                    'Corrida finalizada. Deseja avaliar o motorista?',
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
                          Navigator.pop(context);
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

      _alterarBotaoPrincipal(
        'Chamar Uber',
        Colors.black,
        () {
          _chamarUber();
        },
      );

      double passageiroLat = _dadosRequisicao!['passageiro']['latitude'];
      double passageiroLon = _dadosRequisicao!['passageiro']['longitude'];

      Position position = Position(
        longitude: passageiroLon,
        latitude: passageiroLat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      _exibirMarcadorPassageiro(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );

      _movimentarCamera(cameraPosition);

      _dadosRequisicao!.clear();
      _dadosRequisicao = null;
    }
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

  void _cancelarUber() async {
    setState(() {
      _isLoading = true;
    });

    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection('requisicoes').doc(_idRequisicao).update({
      'status': StatusRequisicao.CANCELADA,
    }).then((_) {
      db.collection('requisicao-ativa').doc(firebaseUser?.uid).delete();
    });

    _statusUberNaoChamado();
    if (_streamSubscriptionRequisicoes != null) {
      setState(() {
        _streamSubscriptionRequisicoes!.cancel();
        _streamSubscriptionRequisicoes = null;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _recuperarRequisicaoAtiva() async {
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot documentSnapshot =
        await db.collection('requisicao-ativa').doc(firebaseUser!.uid).get();

    if (documentSnapshot.data() != null) {
      Map<String, dynamic>? dados =
          documentSnapshot.data() as Map<String, dynamic>?;
      _idRequisicao = await dados!['id_requisicao'];
      _adicionarListenerRequisicao(_idRequisicao);
    } else {
      _statusUberNaoChamado();
    }
  }

  void _adicionarListenerRequisicao(String idRequisicao) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    _streamSubscriptionRequisicoes = db
        .collection('requisicoes')
        .doc(idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        Map<String, dynamic>? dados = snapshot.data();
        _dadosRequisicao = dados;
        String status = dados!['status'];
        _idRequisicao = dados['id'];

        switch (status) {
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
            _statusUberNaoChamado();
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Passageiro'),
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
            //myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _marcadores,
          ),
          Visibility(
              visible: _exibirCaixaEnderecoDestino,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Container(
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            child: CustomInputText(
                              controller: _meuLocalController,
                              hintText: 'Meu Local - Automático',
                              keyboardType: TextInputType.text,
                              preffixIcon: const Icon(Icons.location_on),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            child: CustomInputText(
                              controller: _destinoController,
                              hintText: 'Digite o destino',
                              keyboardType: TextInputType.text,
                              preffixIcon: const Icon(Icons.car_crash),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
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
