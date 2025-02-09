import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber/src/models/usuario.dart';

class UsuarioFirebase {
  static Future<User?> getUsuarioAtual() async {
    return FirebaseAuth.instance.currentUser;
  }

  static Future<Usuario?> getDadosUsuarioLogado() async {
    User? firebaseUser = await getUsuarioAtual();
    if (firebaseUser == null) return null;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await db.collection('usuarios').doc(firebaseUser.uid).get();

    if (!userDoc.exists) return null;

    return Usuario.fromMap(userDoc.data()!, userDoc.id);
  }

  static Future<void> atualizarDadosLocalizacao(
      String idRequisicao, double lat, double lon, String tipo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Usuario? usuario = await getDadosUsuarioLogado();

    if (usuario != null) {
      usuario.latitude = lat;
      usuario.longitude = lon;

      await db.collection('requisicoes').doc(idRequisicao).update({
        tipo: usuario.toMap(),
      });
    }
  }
}
