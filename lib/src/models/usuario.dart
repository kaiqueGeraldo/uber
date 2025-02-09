class Usuario {
  String? id;
  String? nome;
  String? email;
  String? senha;
  String? tipoUsuario;
  double? latitude;
  double? longitude;
  String? fotoUrl;
  double? avaliacao;

  Usuario({
    this.id,
    this.nome,
    this.email,
    this.senha,
    this.tipoUsuario,
    this.latitude,
    this.longitude,
    this.fotoUrl,
    this.avaliacao,
  });

  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      nome: map["nome"] as String? ?? '',
      email: map["email"] as String? ?? '',
      tipoUsuario: map["tipoUsuario"] as String? ?? '',
      fotoUrl: map["foto_url"] as String?,
      avaliacao: (map["avaliacao"] as num?)?.toDouble() ?? 0.0,
      latitude: (map["latitude"] as num?)?.toDouble(),
      longitude: (map["longitude"] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id_usuario": id,
      "nome": nome,
      "email": email,
      "tipoUsuario": tipoUsuario,
      "latitude": latitude,
      "longitude": longitude,
      "foto_url": fotoUrl,
      "avaliacao": avaliacao,
    };
  }

  static String verificarTipoUsuario(bool tipoUsuario) {
    return tipoUsuario ? 'motorista' : 'passageiro';
  }
}
