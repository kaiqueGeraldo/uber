import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_overlay.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/pages/menu_pages/atividade_page.dart';
import 'package:uber/src/pages/menu_pages/conta_page.dart';
import 'package:uber/src/pages/menu_pages/home_page.dart';
import 'package:uber/src/pages/painel_motorista.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  String? tipoUsuario;

  int _selectedIndex = 0;
  bool _isCurrentPage = true;

  @override
  void initState() {
    super.initState();
    _isCurrentPage = true;
    _getTipoUsuario();
  }

  @override
  void dispose() {
    _isCurrentPage = false;
    super.dispose();
  }

  Future<void> _getTipoUsuario() async {
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    if (firebaseUser == null) return;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await db.collection('usuarios').doc(firebaseUser.uid).get();

    if (snapshot.exists) {
      setState(() {
        tipoUsuario = snapshot.data()?['tipoUsuario'];
      });

      print("Tipo de usuário: $tipoUsuario");

      _verificarRequisicaoAtiva();
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      print("Usuário não encontrado no banco de dados.");
    }
  }

  Future<void> _verificarRequisicaoAtiva() async {
    if (tipoUsuario == null || !_isCurrentPage) return;

    Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();
    if (usuario == null) return;

    FirebaseFirestore db = FirebaseFirestore.instance;
    String colecaoRequisicao = tipoUsuario == 'passageiro'
        ? 'requisicao-ativa'
        : 'requisicao-ativa-motorista';

    DocumentSnapshot<Map<String, dynamic>> requisicao =
        await db.collection(colecaoRequisicao).doc(usuario.id).get();

    if (requisicao.exists && mounted && _isCurrentPage) {
      CustomSnackbar.show(
        context,
        'Você está em uma corrida! Clique para voltar ao painel',
        backgroundColor: AppColors.secundaryColor,
        duration: const Duration(hours: 1),
        actionLabel: 'Painel',
        onAction: () {
          _redirecionarParaPainel();
        },
        showCloseButton: false,
      );
    }
  }

  void _redirecionarParaPainel() {
    if (!mounted || tipoUsuario == null) return;

    String rota = tipoUsuario == 'passageiro'
        ? '/painel-passageiro'
        : '/painel-motorista';

    Navigator.pushReplacementNamed(context, rota);
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      HomePage(tipoUsuario, atualizarIndex: _onItemTapped),
      AtividadePage(tipoUsuario),
      ContaPage(tipoUsuario, atualizarIndex: _onItemTapped),
    ];

    if (tipoUsuario == 'motorista') {
      pages.insert(1, const PainelMotorista());
    }

    return pages;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _bottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.secundaryColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Início'),
          if (tipoUsuario == 'motorista')
            const BottomNavigationBarItem(
                icon: Icon(Icons.car_crash_rounded), label: 'Chamadas'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.library_books_rounded), label: 'Atividade'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Conta'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      toolbarHeight: (_selectedIndex == 3 ||
              (tipoUsuario == 'passageiro' && _selectedIndex == 2))
          ? 100
          : kToolbarHeight,
      title: FutureBuilder<Usuario?>(
        future: UsuarioFirebase.getDadosUsuarioLogado(),
        builder: (context, snapshot) {
          return _buildTitle(snapshot.data);
        },
      ),
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      actions: [
        FutureBuilder<Usuario?>(
          future: UsuarioFirebase.getDadosUsuarioLogado(),
          builder: (context, snapshot) {
            return ((_selectedIndex == 3 && tipoUsuario == 'motorista') ||
                    (_selectedIndex == 2 && tipoUsuario == 'passageiro'))
                ? Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: _buildUserAvatar(snapshot.data),
                  )
                : Container();
          },
        ),
      ],
    );
  }

  Widget _buildTitle(Usuario? usuario) {
    String title = 'Uber';

    if (tipoUsuario == 'motorista') {
      if (_selectedIndex == 1) {
        title = 'Painel Motorista';
      } else if (_selectedIndex == 2) {
        title = 'Atividade';
      } else if (_selectedIndex == 3) {
        title = _formatarNome(usuario?.nome);
      }
    } else {
      if (_selectedIndex == 1) {
        title = 'Atividade';
      } else if (_selectedIndex == 2) {
        title = _formatarNome(usuario?.nome);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if ((tipoUsuario == 'motorista' && _selectedIndex == 3) ||
            (tipoUsuario == 'passageiro' && _selectedIndex == 2))
          _buildUserRating(usuario),
      ],
    );
  }

  String _formatarNome(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.isEmpty) return 'Perfil';

    List<String> nomes = nomeCompleto.split(' ');
    return nomes.length > 1 ? '${nomes[0]} ${nomes[1][0]}.' : nomes[0];
  }

  Widget _buildUserRating(Usuario? usuario) {
    double avaliacao = usuario?.avaliacao ?? 0.0;

    return GestureDetector(
      onTap: () {
        CustomOverlay.show(
          context,
          texto: "Esta avaliação é baseada na média de feedbacks recebidos.",
          top: MediaQuery.of(context).size.height * 0.18,
          left: 80,
          right: 20,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              avaliacao.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Usuario? usuario) {
    String? fotoUrl = usuario?.fotoUrl;
    String inicial = (usuario?.nome != null && usuario!.nome!.isNotEmpty)
        ? usuario.nome![0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: _atualizarFoto,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.secundaryColor,
        backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
            ? NetworkImage(fotoUrl)
            : null,
        child: (fotoUrl == null || fotoUrl.isEmpty)
            ? Text(
                inicial,
                style: const TextStyle(color: Colors.white, fontSize: 25),
              )
            : null,
      ),
    );
  }

  void _atualizarFoto() {
    Navigator.pushNamed(context, '/gerenciamento');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: tipoUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPages()[_selectedIndex],
            ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }
}
