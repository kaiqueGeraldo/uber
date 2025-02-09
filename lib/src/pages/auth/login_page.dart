import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_input_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/utils/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _isPassword = true;
  bool _isLoading = false;
  bool _hasError = false;

  /// Realiza o login e busca os dados do usuário
  Future<void> login(String email, String senha) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;

      UserCredential userCredential =
          await auth.signInWithEmailAndPassword(email: email, password: senha);

      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await db.collection('usuarios').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        throw Exception("Usuário não encontrado no banco de dados!");
      }

      _redirecionarUsuario(userDoc.data()?['tipoUsuario']);
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      CustomSnackbar.show(context,
          'Erro ao autenticar usuário. Verifique o email e a senha e tente novamente!');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirecionarUsuario(String? tipoUsuario) {
    if (tipoUsuario == 'motorista' || tipoUsuario == 'passageiro') {
      Navigator.pushNamedAndRemoveUntil(context, '/initial', (_) => false);
    } else {
      CustomSnackbar.show(context, "Tipo de usuário inválido!");
    }
  }

  void _navigatorEsqueciSenha() {
    Navigator.pushNamed(context, '/esqueci-senha');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/logo_text.png')),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomInputText(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        isLoading: _isLoading,
                        errorText:
                            _hasError ? 'Email ou senha incorretos' : null,
                        onChanged: (value) {
                          setState(() {
                            _hasError = false;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Este campo é obrigatório!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomInputText(
                        controller: _senhaController,
                        hintText: 'Senha',
                        keyboardType: TextInputType.text,
                        isLoading: _isLoading,
                        isPassword: true,
                        obscureText: _isPassword,
                        errorText:
                            _hasError ? 'Email ou senha incorretos' : null,
                        onChanged: (value) {
                          setState(() {
                            _hasError = false;
                          });
                        },
                        onSuffixIconPressed: () {
                          setState(() {
                            _isPassword = !_isPassword;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Este campo é obrigatório!';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _navigatorEsqueciSenha,
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(color: AppColors.textColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Entrar',
                        funtion: () {
                          login(
                            _emailController.text,
                            _senhaController.text,
                          );
                        },
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        backgroundColor: AppColors.secundaryColor,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Não tem uma conta?',
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      child: Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: AppColors.secundarytextColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/cadastro');
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
