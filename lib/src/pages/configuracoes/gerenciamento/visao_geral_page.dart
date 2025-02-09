import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';

class VisaoGeralPage extends StatefulWidget {
  final Usuario? usuario;
  const VisaoGeralPage(this.usuario, {super.key});

  @override
  State<VisaoGeralPage> createState() => _VisaoGeralPageState();
}

class _VisaoGeralPageState extends State<VisaoGeralPage> {
  Usuario? usuario;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  String _formatarNome(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.isEmpty) return 'Perfil';

    List<String> nomes = nomeCompleto.split(' ');
    return nomes.length > 1 ? '${nomes[0]}.' : nomes[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${_formatarNome(usuario!.nome)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          Text(
            'Gerencie suas informações, segurança e dados para que a plataformada Uber funcione melhor para você.',
            style: TextStyle(color: AppColors.secundarytextColor),
          ),
          const SizedBox(height: 15),
          Card(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: AppColors.secundaryColor,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Faça a verificação da sua conta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Icon(
                          Icons.discount_rounded,
                          color: AppColors.secundarytextColor,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                      'Faça a verificação da sua conta para que a plataforma da Uber Funcione melhor para você e ajude a manter sua segurança.'),
                  const SizedBox(height: 15),
                  CustomButton(
                    width: MediaQuery.of(context).size.width * 0.6,
                    backgroundColor: AppColors.secundarytextColor,
                    text: 'Começar a verificação',
                    funtion: () {},
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
