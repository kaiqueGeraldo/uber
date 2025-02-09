import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/pages/configuracoes/gerenciamento/informacoes_conta_page.dart';
import 'package:uber/src/pages/configuracoes/gerenciamento/privacidade_dados_page.dart';
import 'package:uber/src/pages/configuracoes/gerenciamento/seguranca_page.dart';
import 'package:uber/src/pages/configuracoes/gerenciamento/visao_geral_page.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class GerenciamentoPage extends StatefulWidget {
  const GerenciamentoPage({super.key});

  @override
  State<GerenciamentoPage> createState() => _GerenciamentoPageState();
}

class _GerenciamentoPageState extends State<GerenciamentoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Usuario? usuario;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getUsuario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getUsuario() async {
    setState(() {
      _isLoading = true;
    });
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    if (firebaseUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await db.collection('usuarios').doc(firebaseUser.uid).get();

    if (snapshot.exists && mounted) {
      setState(() {
        usuario = Usuario.fromMap(snapshot.data()!, firebaseUser.uid);
      });
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      print("Usuário não encontrado no banco de dados.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabPages = [
      VisaoGeralPage(usuario),
      InformacoesContaPage(usuario),
      SegurancaPage(usuario),
      PrivacidadeDadosPage(usuario),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conta da Uber'),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          dividerHeight: 3,
          dividerColor: AppColors.secundaryColor,
          indicatorColor: AppColors.textColor,
          labelColor: AppColors.textColor,
          indicatorSize: TabBarIndicatorSize.tab,
          unselectedLabelColor: AppColors.secundaryColor,
          splashBorderRadius: BorderRadius.circular(5),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Informações da Conta'),
            Tab(text: 'Segurança'),
            Tab(text: 'Privacidade e Dados'),
          ],
        ),
      ),
      body: _isLoading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secundaryColor),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: TabBarView(
                controller: _tabController,
                children: tabPages,
              ),
            ),
    );
  }
}
