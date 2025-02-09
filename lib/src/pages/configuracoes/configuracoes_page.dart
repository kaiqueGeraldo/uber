import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_show_dialog.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  Usuario? _usuario;
  bool _isLoading = false;
  late List<Map<String, dynamic>> _itensLista;

  @override
  void initState() {
    super.initState();
    _getUsuario();

    _itensLista = [
      {
        'nome': 'Casa',
        'subtitle': 'Não definida',
        'icon': Icons.home_filled,
      },
      {
        'nome': 'Privacidade',
        'subtitle': 'Controle as informações que você compartilha com a gente',
        'icon': Icons.lock_rounded,
      },
      {
        'nome': 'Acessibilidade',
        'subtitle': 'Gerencie suas configurações de acessibilidade',
        'icon': Icons.accessibility,
      },
    ];
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
        _usuario = Usuario.fromMap(snapshot.data()!, firebaseUser.uid);
      });
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      print("Usuário não encontrado no banco de dados.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildUserAvatar(Usuario? usuario) {
    String? fotoUrl = usuario?.fotoUrl;
    String inicial = usuario?.nome?.isNotEmpty == true
        ? usuario!.nome![0].toUpperCase()
        : 'U';

    return CircleAvatar(
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
    );
  }

  String _formatarNome(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.isEmpty) return 'Perfil';

    List<String> nomes = nomeCompleto.split(' ');
    return nomes.length > 1 ? '${nomes[0]} ${nomes[1][0]}.' : nomes[0];
  }

  void _deslogarUsuario() {
    _confirmarSairConta();
  }

  void _confirmarSairConta() {
    customShowDialog(
      context: context,
      title: 'Sair da Conta',
      content: const Text('Tem certeza que deseja sair da conta?'),
      cancelText: 'Cancelar',
      onCancel: () => Navigator.pop(context),
      confirmText: 'Sair',
      confirmTextColor: Colors.red,
      onConfirm: () async {
        try {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          if (mounted) {
            CustomSnackbar.show(context, 'Erro ao sair da conta: $e');
          }
        }
      },
    );
  }

  Widget _modeloListTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textColor,
        size: 25,
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.secundarytextColor),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.secundaryColor,
      ),
      onTap: () {},
    );
  }

  Widget _divider() => Divider(thickness: 4, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _isLoading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secundaryColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  onTap: () => Navigator.pushNamed(context, '/gerenciamento'),
                  leading: _buildUserAvatar(_usuario),
                  title: Text(
                    _formatarNome(_usuario?.nome),
                    style: TextStyle(color: AppColors.textColor),
                  ),
                  subtitle: Text(
                    _usuario?.email ?? 'Email não disponível',
                    style: TextStyle(color: AppColors.secundarytextColor),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.secundaryColor,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        'Informações básicas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: List.generate(
                    _itensLista.length,
                    (index) {
                      final item = _itensLista[index];
                      return _modeloListTile(
                          item['nome'], item['subtitle'], item['icon']);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 5),
                  child: _divider(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _deslogarUsuario,
                    child: const Text(
                      'Sair',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
