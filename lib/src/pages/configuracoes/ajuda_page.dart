import 'package:flutter/material.dart';
import 'package:uber/src/utils/colors.dart';

class AjudaPage extends StatefulWidget {
  const AjudaPage({super.key});

  @override
  State<AjudaPage> createState() => _AjudaPageState();
}

class _AjudaPageState extends State<AjudaPage> {
  final List<String> listItems = [
    'Conta',
    'Acessibilidade',
    'Reportar um problema no mapa',
    'Problema em uma viagem específica e reembolsos',
  ];

  Widget _modeloListTile(String title) {
    return ListTile(
      leading: Icon(
        Icons.list_outlined,
        color: AppColors.textColor,
        size: 25,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.secundaryColor,
      ),
      onTap: () {},
    );
  }

  Widget _divider() => Divider(thickness: 1, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Todos os tópicos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.separated(
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  return _modeloListTile(listItems[index]);
                },
                separatorBuilder: (context, index) => _divider(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
