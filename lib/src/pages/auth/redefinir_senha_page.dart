import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_input_text.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/utils/colors.dart';

class RedefinirSenhaPage extends StatefulWidget {
  const RedefinirSenhaPage({super.key});

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarRedefinicao() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text);

      CustomSnackbar.show(
        context,
        'E-mail de redefinição enviado!',
        backgroundColor: AppColors.secundaryColor,
        textColor: AppColors.textColor,
      );
      Navigator.pop(context);
    } catch (e) {
      CustomSnackbar.show(context, 'Erro: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  String? _validator(String? text) {
    final regex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|outlook\.com|yahoo\.com)$');
    if (text == null || text.trim().isEmpty) {
      return 'O campo não pode estar vazio';
    } else if (!regex.hasMatch(text.trim())) {
      return 'Informe um email válido (@gmail.com, @hotmail.com, etc.)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Redefinir Senha")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informe seu Email',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Digite seu email no campo abaixo para receber um link de redefinição de senha.',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            const SizedBox(height: 15),
            CustomInputText(
              controller: _emailController,
              hintText: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              enable: !_isLoading,
              isLoading: _isLoading,
              hintStyle: TextStyle(
                color: AppColors.secundarytextColor,
                fontSize: 15,
              ),
              textColor: AppColors.textColor,
              cursorColor: AppColors.textColor,
              maxLength: 50,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.secundaryColor),
              ),
              validator: _validator,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: CustomButton(
                text: 'Enviar e-mail de redefinição',
                funtion: _enviarRedefinicao,
                isLoading: _isLoading,
                enabled: !_isLoading,
                backgroundColor: AppColors.secundaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
