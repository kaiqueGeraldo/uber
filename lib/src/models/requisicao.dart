import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/src/models/destino.dart';
import 'package:uber/src/models/usuario.dart';

class Requisicao {
  String? id;
  String? status;
  Usuario? passageiro;
  Usuario? motorista;
  Destino? destino;

  Requisicao({
    this.id,
    this.status,
    this.passageiro,
    this.motorista,
    this.destino,
  }) {
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentReference ref = db.collection('requisicoes').doc();
    id = ref.id;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? dadosPassageiro = passageiro != null
        ? {
            "nome": passageiro!.nome,
            "email": passageiro!.email,
            "tipoUsuario": passageiro!.tipoUsuario,
            "id_usuario": passageiro!.id,
            "latitude": passageiro!.latitude,
            "longitude": passageiro!.longitude,
          }
        : null;

    Map<String, dynamic>? dadosDestino = destino != null
        ? {
            "rua": destino!.rua,
            "numero": destino!.numero,
            "bairro": destino!.bairro,
            "cep": destino!.cep,
            "latitude": destino!.latitude,
            "longitude": destino!.longitude,
          }
        : null;

    Map<String, dynamic> dadosRequisicao = {
      "id": id,
      "status": status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestino,
    };

    return dadosRequisicao;
  }
}
