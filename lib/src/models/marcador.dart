import 'package:google_maps_flutter/google_maps_flutter.dart';

class Marcador {
  LatLng local;
  BitmapDescriptor caminhoImagem;
  String titulo;

  Marcador({
    required this.local,
    required this.caminhoImagem,
    required this.titulo,
  });
}
