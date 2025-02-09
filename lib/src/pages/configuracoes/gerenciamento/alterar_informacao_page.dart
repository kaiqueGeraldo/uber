import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/components/custom_input_text.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class AlterarInformacaoPage extends StatefulWidget {
  final String? info;
  const AlterarInformacaoPage(this.info, {super.key});

  @override
  State<AlterarInformacaoPage> createState() => _AlterarInformacaoPageState();
}

class _AlterarInformacaoPageState extends State<AlterarInformacaoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  String mensagemInput = '';
  String mensagemTitle = '';
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void initState() {
    super.initState();
    _setMensagens();
  }

  void _setMensagens() async {
    Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();
    if (usuario == null) return;

    setState(() {
      mensagemInput = widget.info == 'Senha'
          ? '••••••••'
          : (usuario.toMap()[widget.info!.toLowerCase()] ?? '');
      mensagemTitle = widget.info == 'Senha'
          ? 'Informe sua nova ${widget.info}'
          : 'Informe seu novo ${widget.info}';
    });
  }

  Future<void> _alterarInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Usuario? usuario = await UsuarioFirebase.getDadosUsuarioLogado();
      if (usuario == null) return Navigator.pop(context);

      widget.info == 'Senha'
          ? await _alterarSenha()
          : await _alterarDadoFirebase(usuario);

      CustomSnackbar.show(
        context,
        '${widget.info} alterado com sucesso!',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context);
    } catch (e) {
      CustomSnackbar.show(
        context,
        'Erro ao alterar ${widget.info!.toLowerCase()}. Tente novamente!',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _alterarSenha() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Navigator.pop(context);

    try {
      await user.updatePassword(_confirmarSenhaController.text);
    } catch (e) {
      CustomSnackbar.show(context, 'Não foi possível alterar a senha: $e');
    }
  }

  Future<void> _alterarDadoFirebase(Usuario usuario) async {
    FirebaseFirestore.instance.collection('usuarios').doc(usuario.id).update({
      widget.info!.toLowerCase(): _infoController.text.trim(),
    });
  }

  String? _validator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '${widget.info} não pode estar vazio';
    }

    if (widget.info == 'Email') {
      final regex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|outlook\.com|yahoo\.com)$');
      if (!regex.hasMatch(text.trim())) {
        return 'Informe um email válido (@gmail.com, @hotmail.com, etc.)';
      }
    } else if (widget.info == 'Senha') {
      final regex =
          RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
      if (!regex.hasMatch(text.trim())) {
        return 'A senha deve ter no mínimo 8 caracteres, incluindo pelo menos uma letra maiúscula, uma letra minúscula, um número e um caractere especial.';
      } else if (_infoController.text != _confirmarSenhaController.text) {
        return 'As senhas não coincidem';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    TextInputType keyboardType = {
          'Nome': TextInputType.name,
          'Email': TextInputType.emailAddress,
          'Senha': TextInputType.visiblePassword,
        }[widget.info] ??
        TextInputType.text;

    return Scaffold(
      appBar: AppBar(title: Text('Alterar ${widget.info}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(mensagemTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 15),
                if (widget.info == 'Senha') ...[
                  CustomInputText(
                    controller: _infoController,
                    hintText: 'Nova senha',
                    isPassword: true,
                    obscureText: _obscureText,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    iconColor: AppColors.textColor,
                    enable: !_isLoading,
                    isLoading: _isLoading,
                    keyboardType: keyboardType,
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
                  const SizedBox(height: 15),
                  CustomInputText(
                    controller: _confirmarSenhaController,
                    hintText: 'Confirmar senha',
                    isPassword: true,
                    obscureText: _obscureConfirmText,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureConfirmText = !_obscureConfirmText;
                      });
                    },
                    iconColor: AppColors.textColor,
                    enable: !_isLoading,
                    isLoading: _isLoading,
                    keyboardType: keyboardType,
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
                    validator: (text) => text != _infoController.text
                        ? 'As senhas não coincidem'
                        : null,
                  ),
                ] else
                  CustomInputText(
                    controller: _infoController,
                    hintText: mensagemInput,
                    hintStyle: TextStyle(
                      color: AppColors.secundarytextColor,
                      fontSize: 15,
                    ),
                    textColor: AppColors.textColor,
                    cursorColor: AppColors.textColor,
                    keyboardType: keyboardType,
                    maxLength: 50,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.secundaryColor),
                    ),
                    validator: _validator,
                  ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.center,
                  child: CustomButton(
                    text: 'Alterar',
                    funtion: _alterarInfo,
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                    backgroundColor: AppColors.secundaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
