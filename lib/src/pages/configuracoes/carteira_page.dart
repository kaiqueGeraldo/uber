import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/utils/colors.dart';

class CarteiraPage extends StatefulWidget {
  const CarteiraPage({super.key});

  @override
  State<CarteiraPage> createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  final List<Map<String, dynamic>> listFormasPagamento = [
    {'icon': Icons.credit_card, 'title': 'Cartão de Crédito'},
    {'icon': Icons.attach_money_outlined, 'title': 'Dinheiro'},
    {'icon': Icons.account_balance_wallet, 'title': 'Carteira Uber'},
  ];

  Widget _cardCartao() {
    double tamanhoCard = MediaQuery.of(context).size.width;

    return Container(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uber credits',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R\$ 0,00',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info, color: AppColors.textColor),
                  const SizedBox(width: 5),
                  Expanded(
                      child: Text('A recarga automática está desativada',
                          style: TextStyle(color: AppColors.textColor))),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: tamanhoCard * 0.6,
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStatePropertyAll(AppColors.textColor),
                    foregroundColor:
                        WidgetStatePropertyAll(AppColors.primaryColor),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                  ),
                  onPressed: () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 5),
                      Text('Adicionar saldo'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardEnviarPresente() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Card(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.secundaryColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Enviar Presente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                trailing: Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.secundarytextColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Agora você pode enviar um Gift Card instantâneo para ser usado no app da Uber.',
                style: TextStyle(color: AppColors.secundarytextColor),
              ),
              const SizedBox(height: 15),
              CustomButton(
                width: MediaQuery.of(context).size.width * 0.6,
                backgroundColor: AppColors.secundaryColor,
                text: 'Enviar Presente',
                funtion: () {},
                isLoading: false,
                enabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formasPagamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Formas de Pagamento',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listFormasPagamento.length,
          itemBuilder: (context, index) {
            final item = listFormasPagamento[index];
            return ListTile(
              leading: Icon(
                item['icon'],
                color: AppColors.textColor,
              ),
              title: Text(
                item['title'],
                style: TextStyle(color: AppColors.textColor),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.secundaryColor),
              onTap: () {},
            );
          },
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.secundaryColor),
              foregroundColor: WidgetStatePropertyAll(AppColors.textColor),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              )),
            ),
            onPressed: () {},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                SizedBox(width: 5),
                Text('Adicionar forma de pagamento'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardCartao(),
            _cardEnviarPresente(),
            _formasPagamento(),
          ],
        ),
      ),
    );
  }
}
