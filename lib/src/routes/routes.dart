// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:uber/src/pages/auth/cadastro_page.dart';
import 'package:uber/src/pages/auth/redefinir_senha_page.dart';
import 'package:uber/src/pages/configuracoes/ajuda_page.dart';
import 'package:uber/src/pages/configuracoes/carteira_page.dart';
import 'package:uber/src/pages/configuracoes/configuracoes_page.dart';
import 'package:uber/src/pages/configuracoes/gerenciamento/alterar_informacao_page.dart';
import 'package:uber/src/pages/configuracoes/gerenciamento/gerenciamento_page.dart';
import 'package:uber/src/pages/corrida_page.dart';
import 'package:uber/src/pages/menu_pages/atividade_page.dart';
import 'package:uber/src/pages/menu_pages/conta_page.dart';
import 'package:uber/src/pages/menu_pages/detalhe_corrida_page.dart';
import 'package:uber/src/pages/menu_pages/home_page.dart';
import 'package:uber/src/pages/menu_pages/initial_page.dart';
import 'package:uber/src/pages/auth/login_page.dart';
import 'package:uber/src/pages/painel_motorista.dart';
import 'package:uber/src/pages/painel_passageiro.dart';
import 'package:uber/src/pages/splash_screen_page.dart';

class Routes {
  static Route<dynamic> generateRoutes(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreenPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/cadastro':
        return MaterialPageRoute(builder: (_) => const CadastroPage());
      case '/esqueci-senha':
        return MaterialPageRoute(builder: (_) => const RedefinirSenhaPage());
      case '/initial':
        return MaterialPageRoute(builder: (_) => const InitialPage());
      case '/home':
        return MaterialPageRoute(
          builder: (_) =>
              HomePage(args as String? ?? '', atualizarIndex: (int) {}),
        );
      case '/atividade':
        return MaterialPageRoute(
          builder: (_) => AtividadePage(args as String? ?? ''),
        );
      case '/conta':
        return MaterialPageRoute(
          builder: (_) =>
              ContaPage(args as String? ?? '', atualizarIndex: (int) {}),
        );
      case '/painel-motorista':
        return MaterialPageRoute(builder: (_) => const PainelMotorista());
      case '/painel-passageiro':
        return MaterialPageRoute(builder: (_) => const PainelPassageiro());
      case '/corrida':
        return MaterialPageRoute(
          builder: (_) => CorridaPage(args as String? ?? ''),
        );
      case '/detalhes-corrida':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => DetalheCorridaPage(
              args['idCorrida'] ?? '',
              args['tipoUsuario'] ?? '',
              args['idUsuario'] ?? '',
            ),
          );
        } else {
          return _routeError();
        }
      case '/configuracoes':
        return MaterialPageRoute(builder: (_) => const ConfiguracoesPage());
      case '/gerenciamento':
        return MaterialPageRoute(builder: (_) => const GerenciamentoPage());
      case '/carteira':
        return MaterialPageRoute(builder: (_) => const CarteiraPage());
      case '/ajuda':
        return MaterialPageRoute(builder: (_) => const AjudaPage());
      case '/alterar-info':
        return MaterialPageRoute(
          builder: (_) => AlterarInformacaoPage(args as String? ?? ''),
        );
      default:
        return _routeError();
    }
  }

  static Route<dynamic> _routeError() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Tela não encontrada'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Tela não encontrada! '),
        ),
      ),
    );
  }
}
