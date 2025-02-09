import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_input_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/utils/colors.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final FocusNode _senhaFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPassword = true;
  bool _tipoUsuario = false;

  bool hasUpperCase = false;
  bool hasLowerCase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool showPasswordCriteria = false;

  @override
  void initState() {
    super.initState();
    _senhaFocusNode.addListener(() {
      setState(() {
        showPasswordCriteria = _senhaFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _validarSenha(String value) {
    setState(() {
      hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
      hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
      hasNumber = RegExp(r'\d').hasMatch(value);
      hasSpecialChar = RegExp(r'[!@#\$&*~]').hasMatch(value);
      hasMinLength = value.length >= 8;
    });

    _formKey.currentState?.validate();
  }

  /// Função para cadastrar o usuário
  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String nome = _nomeController.text.trim();
      String email = _emailController.text.trim();
      String senha = _senhaController.text.trim();
      String tipoUsuario = _tipoUsuario ? "motorista" : "passageiro";

      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;

      UserCredential firebaseUser = await auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      await db.collection('usuarios').doc(firebaseUser.user!.uid).set({
        "nome": nome,
        "email": email,
        "tipoUsuario": tipoUsuario,
        "foto_url": '',
        "avaliacao": 0.00,
      });

      _redirecionarUsuario(tipoUsuario);
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao cadastrar usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Redireciona o usuário para a tela correta
  void _redirecionarUsuario(String tipoUsuario) {
    Navigator.pushNamedAndRemoveUntil(context, '/initial', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
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
                      image: AssetImage('assets/images/logo_text.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomInputText(
                        controller: _nomeController,
                        hintText: 'Nome',
                        keyboardType: TextInputType.name,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Este campo é obrigatório!'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      CustomInputText(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo é obrigatório!';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          return emailRegex.hasMatch(value)
                              ? null
                              : 'Informe um email válido!';
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomInputText(
                        controller: _senhaController,
                        hintText: 'Senha',
                        keyboardType: TextInputType.text,
                        isPassword: true,
                        obscureText: _isPassword,
                        focusNode: _senhaFocusNode,
                        onSuffixIconPressed: () {
                          setState(() => _isPassword = !_isPassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo é obrigatório!';
                          }
                          if (hasUpperCase &&
                              hasLowerCase &&
                              hasNumber &&
                              hasSpecialChar &&
                              hasMinLength) {
                            return null;
                          }
                          return 'A senha não atende todos os critérios!';
                        },
                        onChanged: _validarSenha,
                      ),
                      const SizedBox(height: 5),

                      // Mostrar critérios apenas se o campo senha estiver focado
                      if (showPasswordCriteria)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPasswordCriteria(
                                  'Pelo menos 8 caracteres', hasMinLength),
                              _buildPasswordCriteria(
                                  'Uma letra maiúscula', hasUpperCase),
                              _buildPasswordCriteria(
                                  'Uma letra minúscula', hasLowerCase),
                              _buildPasswordCriteria('Um número', hasNumber),
                              _buildPasswordCriteria(
                                  'Um caractere especial (!@#\$&*~)',
                                  hasSpecialChar),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Text('Passageiro'),
                          Switch(
                            value: _tipoUsuario,
                            onChanged: (value) {
                              if (_tipoUsuario != value) {
                                setState(() => _tipoUsuario = value);
                              }
                            },
                            activeColor: AppColors.textColor,
                            inactiveTrackColor: Colors.grey,
                          ),
                          const Text('Motorista'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Cadastrar',
                        funtion: _cadastrar,
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        backgroundColor: AppColors.secundaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCriteria(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red[800],
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red[800],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
