import 'package:flutter/material.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';

class PrivacidadeDadosPage extends StatefulWidget {
  final Usuario? usuario;
  const PrivacidadeDadosPage(this.usuario, {super.key});

  @override
  State<PrivacidadeDadosPage> createState() => _PrivacidadeDadosPageState();
}

class _PrivacidadeDadosPageState extends State<PrivacidadeDadosPage> {
  Usuario? usuario;
  //final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  Widget _divider() => Divider(thickness: 1, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacidade e Dados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          const Text(
            'Privacidade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            onTap: () {},
            contentPadding: const EdgeInsets.only(right: 10),
            title: Text(
              'Central de privacidade',
              style: TextStyle(color: AppColors.textColor),
            ),
            subtitle: Text(
              'Controle a privacidade dos seus dados pessoais e descubra como os protegemos.',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.secundaryColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 15),
            child: _divider(),
          ),
          const Text(
            'Apps de terceiros com acesso à conta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Os apps de terceiros com permissão de acesso à sua conta aparecem aqui. Saiba mais.',
            style: TextStyle(color: AppColors.secundarytextColor),
          ),
        ],
      ),
    );
  }
}
