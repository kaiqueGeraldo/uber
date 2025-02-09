import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class ContaPage extends StatefulWidget {
  final String? tipoUsuario;
  final Function(int) atualizarIndex;

  const ContaPage(
    this.tipoUsuario, {
    super.key,
    required this.atualizarIndex,
  });

  @override
  State<ContaPage> createState() => _ContaPageState();
}

class _ContaPageState extends State<ContaPage> {
  String tipoUsuario = '';
  double saldoRetirar = 0.00;
  double saldoTotal = 0.00;
  bool isLoading = true;
  bool transacaoOn = false;

  @override
  void initState() {
    super.initState();
    tipoUsuario = widget.tipoUsuario!;
    _buscarSaldo();
  }

  final List<Map<String, dynamic>> smallCardItems = [
    {'icon': Icons.sos_rounded, 'text': 'Ajuda'},
    {'icon': Icons.wallet, 'text': 'Carteira'},
    {'icon': Icons.my_library_books_rounded, 'text': 'Atividade'},
  ];

  final List<Map<String, dynamic>> bigCardItems = [
    {
      'icon': Icons.apps_rounded,
      'title': 'Conheça nosso app',
      'subtitle':
          'Faça um tour para ficar por dentro de todas as funcionalidades do app',
    },
    {
      'icon': Icons.privacy_tip_sharp,
      'title': 'Checagem de Segurança',
      'subtitle': 'Saiba como fazer viagens mais seguras'
    },
    {
      'icon': Icons.my_library_books_rounded,
      'title': 'Controle de privacidade',
      'subtitle':
          'Faça um tuor interativo pelas suas configurações de privacidade'
    },
  ];

  final List<Map<String, dynamic>> optionsItems = [
    {'icon': Icons.settings, 'title': 'Configurações'},
    {'icon': Icons.person, 'title': 'Gerenciar conta da Uber'},
  ];

  void _navigationNextPage(String title) {
    switch (title) {
      case 'Configurações':
        Navigator.pushNamed(context, '/configuracoes');
        break;
      case 'Atividade':
        if (tipoUsuario == 'passageiro') {
          widget.atualizarIndex(1);
        } else {
          widget.atualizarIndex(2);
        }
        break;
      case 'Carteira':
        Navigator.pushNamed(context, '/carteira');
        break;
      case 'Ajuda':
        Navigator.pushNamed(context, '/ajuda');
        break;
      case 'Gerenciar conta da Uber':
        Navigator.pushNamed(context, '/gerenciamento');
        break;
      default:
    }
  }

  Future<void> _buscarSaldo() async {
    Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();
    if (usuario == null || usuario.tipoUsuario != 'motorista') {
      setState(() => isLoading = false);
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await db.collection('usuarios').doc(usuario.id).get();

    setState(() {
      saldoRetirar = (userDoc.data()?['saldo_retirar'] ?? 0).toDouble();
      saldoTotal = (userDoc.data()?['saldo_total'] ?? 0).toDouble();
      isLoading = false;
    });
  }

  Future<void> _retirarSaldo() async {
    Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();
    if (usuario == null || usuario.tipoUsuario != 'motorista') return;

    if (saldoRetirar == 0) {
      CustomSnackbar.show(context, 'Não há valor à ser retirado');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool carregando = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double larguraAlert = MediaQuery.of(context).size.width;
            double alturaAlert = MediaQuery.of(context).size.height;
            return AlertDialog(
              backgroundColor: AppColors.secundaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                'Retirar Saldo',
                style: TextStyle(color: AppColors.textColor),
              ),
              content: carregando
                  ? SizedBox(
                      width: larguraAlert * 0.06,
                      height: alturaAlert * 0.06,
                      child: const Center(child: CircularProgressIndicator()))
                  : const Text(
                      'Tem certeza que deseja sacar seu saldo disponível?'),
              actions: [
                carregando
                    ? Container()
                    : TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                TextButton(
                  onPressed: carregando
                      ? null
                      : () async {
                          setStateDialog(() {
                            carregando = true;
                          });

                          try {
                            FirebaseFirestore db = FirebaseFirestore.instance;
                            await db
                                .collection('usuarios')
                                .doc(usuario.id)
                                .update({'saldo_retirar': 0});

                            await Future.delayed(
                                const Duration(milliseconds: 1500));

                            setState(() {
                              saldoRetirar = 0.00;
                            });

                            Navigator.pop(context);

                            CustomSnackbar.show(
                              context,
                              'Saldo transferido com sucesso!',
                              backgroundColor: Colors.green,
                            );
                          } catch (e) {
                            CustomSnackbar.show(
                              context,
                              'Erro ao realizar transação. Tente novamente mais tarde',
                            );

                            setStateDialog(() {
                              carregando = false;
                            });
                          }
                        },
                  child: Text(
                    'Sacar',
                    style: TextStyle(
                        color: carregando ? Colors.grey : Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _saldoMotorista() {
    double tamanhoCard = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secundaryColor, width: 1),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [AppColors.primaryColor, AppColors.secundaryColor],
          ),
        ),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saldo para retirar',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor)),
                const SizedBox(height: 8),
                isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('R\$ ${saldoRetirar.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor)),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.textColor),
                        ],
                      ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 10),
                  child: Text(
                      'Total já faturado: R\$ ${saldoTotal.toStringAsFixed(2)}',
                      style: TextStyle(color: AppColors.secundarytextColor)),
                ),
                SizedBox(
                  width: tamanhoCard * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(AppColors.textColor),
                      foregroundColor:
                          WidgetStatePropertyAll(AppColors.primaryColor),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    onPressed: _retirarSaldo,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Retirar saldo'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secundaryColor),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (tipoUsuario == 'motorista') _saldoMotorista(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      smallCardItems.length,
                      (index) => Padding(
                        padding:
                            smallCardItems[index]['text'] == 'Configurações'
                                ? const EdgeInsets.symmetric(horizontal: 5)
                                : const EdgeInsets.all(0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width /
                                  smallCardItems.length -
                              16.67,
                          child: GestureDetector(
                            onTap: () => _navigationNextPage(
                                smallCardItems[index]['text']),
                            child: SizedBox(
                              height: 100,
                              child: Card(
                                color: AppColors.secundaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        smallCardItems[index]['icon'],
                                        color: AppColors.textColor,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        smallCardItems[index]['text'],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      bigCardItems.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: GestureDetector(
                          onTap: () =>
                              _navigationNextPage(bigCardItems[index]['title']),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 100,
                            child: Card(
                              color: AppColors.secundaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bigCardItems[index]['title'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                          ),
                                          Text(
                                            bigCardItems[index]['subtitle'],
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: AppColors
                                                    .secundarytextColor,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Icon(
                                        bigCardItems[index]['icon'],
                                        size: 35,
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AppColors.secundaryColor, width: 3)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(
                      optionsItems.length,
                      (index) => GestureDetector(
                        onTap: () =>
                            _navigationNextPage(optionsItems[index]['title']),
                        child: ListTile(
                          leading: Icon(
                            optionsItems[index]['icon'],
                            size: 25,
                            color: AppColors.textColor,
                          ),
                          title: Text(
                            optionsItems[index]['title'],
                            style: TextStyle(color: AppColors.textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
