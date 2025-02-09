import 'package:flutter/material.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';

class SegurancaPage extends StatefulWidget {
  final Usuario? usuario;
  const SegurancaPage(this.usuario, {super.key});

  @override
  State<SegurancaPage> createState() => _SegurancaPageState();
}

class _SegurancaPageState extends State<SegurancaPage> {
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  void _alterarInfo(String? info) {
    Navigator.pushNamed(context, '/alterar-info', arguments: info);
  }

  Widget _divider() => Divider(thickness: 1, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Segurança',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          const Text(
            'Fazer login na Uber',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            onTap: () {
              _alterarInfo('Senha');
            },
            contentPadding: const EdgeInsets.only(right: 10),
            title: Text(
              'Senha',
              style: TextStyle(color: AppColors.textColor),
            ),
            subtitle: Text(
              'Altere sua senha',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.secundaryColor,
            ),
          ),
          _divider(),
        ],
      ),
    );
  }
}
