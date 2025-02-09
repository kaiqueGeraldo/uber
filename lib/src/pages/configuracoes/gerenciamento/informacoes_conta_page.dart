import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uber/src/components/custom_snackbar.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';

class InformacoesContaPage extends StatefulWidget {
  final Usuario? usuario;
  const InformacoesContaPage(this.usuario, {super.key});

  @override
  State<InformacoesContaPage> createState() => _InformacoesContaPageState();
}

class _InformacoesContaPageState extends State<InformacoesContaPage> {
  Usuario? usuario;
  Uint8List? _userImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  static const String imgbbApiKey = "7cc8f508cdde60681f32b0e9c07e5cfa";

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  Future<String?> _uploadParaImgBB(Uint8List imageBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.imgbb.com/1/upload?key=$imgbbApiKey"),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );

      var response = await request.send();

      var responseBody = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        CustomSnackbar.show(
            context, 'Erro no upload: ${jsonData['error']['message']}');
        return null;
      }
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao enviar imagem para ImgBB: $e');
      return null;
    }
  }

  Future<void> _atualizarFoto(Uint8List imageBytes) async {
    setState(() => _isLoading = true);

    try {
      Navigator.pop(context);
      String? imageUrl = await _uploadParaImgBB(imageBytes);
      if (imageUrl == null) {
        return;
      }

      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference userDoc = db.collection('usuarios').doc(usuario!.id);

      await userDoc.update({'foto_url': imageUrl}).then((_) {
        setState(() {
          _userImageBytes = imageBytes;
          usuario!.fotoUrl = imageUrl;
        });
      });

      CustomSnackbar.show(
        context,
        'Imagem atualizada com sucesso!',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      CustomSnackbar.show(context, 'Erro ao atualizar a foto no Firestore: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) {
      return;
    }

    Uint8List imageBytes = await image.readAsBytes();

    await _atualizarFoto(imageBytes);
  }

  Widget _buildUserAvatar(Usuario? usuario) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _mostrarImagemAmpliada(usuario),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.secundaryColor,
            backgroundImage: usuario?.fotoUrl?.isNotEmpty == true
                ? NetworkImage(usuario!.fotoUrl!)
                : (_userImageBytes != null
                    ? MemoryImage(_userImageBytes!)
                    : null),
            child: (_userImageBytes == null &&
                    (usuario?.fotoUrl?.isEmpty ?? true))
                ? Text(
                    usuario?.nome?.isNotEmpty == true
                        ? usuario!.nome![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 25),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _mostrarModalSelecao,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.edit, color: AppColors.secundaryColor),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarImagemAmpliada(Usuario? usuario) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 3.0,
            child: usuario?.fotoUrl?.isNotEmpty == true
                ? Image.network(usuario!.fotoUrl!)
                : (_userImageBytes != null
                    ? Image.memory(_userImageBytes!)
                    : Container(
                        alignment: Alignment.center,
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.secundaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          usuario?.nome?.isNotEmpty == true
                              ? usuario!.nome![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
          ),
        );
      },
    );
  }

  void _mostrarModalSelecao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secundaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 5,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecionar imagem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Divider(thickness: 1, color: AppColors.textColor),
              ),
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.white),
                title:
                    const Text('Câmera', style: TextStyle(color: Colors.white)),
                onTap: () => _selecionarImagem(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text('Galeria',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _selecionarImagem(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
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
            'Informações da Conta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: CircularProgressIndicator(),
                )
              : _buildUserAvatar(usuario),
          const SizedBox(height: 20),
          const Text(
            'Informações básicas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            onTap: () {
              _alterarInfo('Nome');
            },
            contentPadding: const EdgeInsets.only(right: 10),
            title: Text(
              'Nome',
              style: TextStyle(color: AppColors.textColor),
            ),
            subtitle: Text(
              usuario?.nome ?? 'N/A',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.secundaryColor,
            ),
          ),
          _divider(),
          ListTile(
            onTap: () {
              _alterarInfo('Email');
            },
            contentPadding: const EdgeInsets.only(right: 10),
            title: Text(
              'Email',
              style: TextStyle(color: AppColors.textColor),
            ),
            subtitle: Text(
              usuario?.email ?? 'N/A',
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
