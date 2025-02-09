import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/utils/colors.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  List<double> opacities = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _iniciarVerificacao();
  }

  void _iniciarVerificacao() async {
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < opacities.length; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          opacities[i] = 1.0;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    _verificarUsuarioLogado();
  }

  Future<void> _verificarUsuarioLogado() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;

      User? usuarioLogado = auth.currentUser;
      if (usuarioLogado != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await db.collection('usuarios').doc(usuarioLogado.uid).get();

        if (userDoc.exists) {
          String? tipoUsuario = userDoc.data()?['tipoUsuario'];
          _verificarRequisicaoAtiva(usuarioLogado.uid, tipoUsuario);
          return;
        } else {
          CustomSnackbar.show(
              context, "Usuário não encontrado no banco de dados!");
        }
      }
      _redirecionarParaLogin();
    } catch (e) {
      CustomSnackbar.show(context, "Erro ao verificar usuário logado: $e");
      _redirecionarParaLogin();
    }
  }

  Future<void> _verificarRequisicaoAtiva(
      String uid, String? tipoUsuario) async {
    if (tipoUsuario == null) {
      CustomSnackbar.show(context, "Erro ao identificar o tipo de usuário.");
      _redirecionarParaLogin();
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    String colecaoRequisicao = tipoUsuario == 'passageiro'
        ? 'requisicao-ativa'
        : 'requisicao-ativa-motorista';

    DocumentSnapshot<Map<String, dynamic>> requisicao =
        await db.collection(colecaoRequisicao).doc(uid).get();

    if (requisicao.exists) {
      _redirecionarParaPainel(tipoUsuario);
    } else {
      _redirecionarUsuario(tipoUsuario);
    }
  }

  void _redirecionarParaPainel(String tipoUsuario) {
    if (!mounted) return;

    String rota = tipoUsuario == 'passageiro'
        ? '/painel-passageiro'
        : '/painel-motorista';

    Navigator.pushReplacementNamed(context, rota);
  }

  void _redirecionarUsuario(String tipoUsuario) {
    if (!mounted) return;

    if (tipoUsuario == 'motorista' || tipoUsuario == 'passageiro') {
      Navigator.pushReplacementNamed(context, '/initial');
    } else {
      CustomSnackbar.show(context, "Tipo de usuário inválido!");
      _redirecionarParaLogin();
    }
  }

  void _redirecionarParaLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: opacities[index],
              child: Text(
                "Uber"[index],
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
