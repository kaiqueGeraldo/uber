import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uber/src/components/custom_button.dart';
import 'package:uber/src/models/usuario.dart';
import 'package:uber/src/utils/colors.dart';
import 'package:uber/src/utils/status_requisicao.dart';
import 'package:uber/src/utils/usuario_firebase.dart';

class AtividadePage extends StatefulWidget {
  final String? tipoUsuario;
  const AtividadePage(this.tipoUsuario, {super.key});

  @override
  State<AtividadePage> createState() => _AtividadePageState();
}

class _AtividadePageState extends State<AtividadePage> {
  String tipoUsuario = '';

  @override
  void initState() {
    tipoUsuario = widget.tipoUsuario!;
    super.initState();
  }

  Map<String, String?> _filtrosSelecionados = {
    'Perfil': null,
    'Opções': null,
  };

  void _exibirFiltros() {
    _filtrosSelecionados["Perfil"] ??= "Pessoal";
    _filtrosSelecionados["Opções"] ??= "Todos";
    Map<String, String?> filtrosTemp = Map.from(_filtrosSelecionados);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secundaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filtrar por...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _filtros((categoria, valor) {
                      setModalState(() => filtrosTemp[categoria] = valor);
                    }, filtrosTemp),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: _botaoAplicar(filtrosTemp),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Divider(thickness: 1, color: AppColors.textColor),
      );

  Widget _botaoAplicar(Map<String, String?> filtrosTemp) => CustomButton(
        text: 'Aplicar',
        funtion: () {
          setState(() => _filtrosSelecionados = Map.from(filtrosTemp));
          Navigator.pop(context);
        },
        isLoading: false,
        enabled: true,
      );

  Widget _filtros(Function(String, String?) onSelectFiltro,
      Map<String, String?> filtrosTemp) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoria(
              onSelectFiltro,
              "Perfil",
              {
                "Pessoal": Icons.person,
                "Estabelecimento": Icons.store,
                "Família": Icons.family_restroom,
              },
              filtrosTemp),
          const SizedBox(height: 10),
          _buildCategoria(
              onSelectFiltro,
              "Opções",
              {
                "Todos": null,
                "Finalizadas": null,
                "Canceladas": null,
              },
              filtrosTemp),
        ],
      ),
    );
  }

  Widget _buildCategoria(
    Function(String, String?) onSelectFiltro,
    String titulo,
    Map<String, IconData?> opcoes,
    Map<String, String?> filtrosTemp,
  ) {
    filtrosTemp.putIfAbsent(titulo, () => opcoes.keys.first);

    Map<String, String> descricoes = {
      "Perfil": "Escolha um perfil para filtrar os resultados.",
      "Opções": "Selecione o status desejado.",
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: descricoes[titulo] ?? "",
              child:
                  Icon(Icons.info_outline_rounded, color: AppColors.textColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: opcoes.length,
            itemBuilder: (context, index) {
              String key = opcoes.keys.elementAt(index);
              return _itemFiltro(
                categoria: titulo,
                titulo: key,
                icon: opcoes[key],
                selecionado: filtrosTemp[titulo] == key,
                onTap: () => onSelectFiltro(titulo, key),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _itemFiltro({
    required String categoria,
    required String titulo,
    IconData? icon,
    required bool selecionado,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Container(
          decoration: BoxDecoration(
            color: selecionado
                ? AppColors.primaryColor
                : AppColors.secundarytextColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: selecionado ? Colors.white : AppColors.textColor),
                const SizedBox(width: 6),
              ],
              Text(
                titulo,
                style: TextStyle(
                  color: selecionado ? Colors.white : AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _filtrosAplicados() {
    switch (_filtrosSelecionados['Opções']) {
      case 'Finalizadas':
        return [StatusRequisicao.CONFIRMADA];
      case 'Canceladas':
        return [StatusRequisicao.CANCELADA];
      case 'Todos':
      default:
        return [StatusRequisicao.CONFIRMADA, StatusRequisicao.CANCELADA];
    }
  }

  Widget _corridas() {
    return FutureBuilder<Usuario?>(
      future: UsuarioFirebase.getDadosUsuarioLogado(),
      builder: (context, usuarioSnapshot) {
        if (usuarioSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!usuarioSnapshot.hasData || usuarioSnapshot.data == null) {
          return const Center(child: Text('Erro ao carregar usuário'));
        }

        String? idUsuario = usuarioSnapshot.data!.id;
        List<String> filtros = _filtrosAplicados();

        return _buscarCorridas(idUsuario, filtros);
      },
    );
  }

  Widget _buscarCorridas(String? idUsuario, List<String> filtros) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('requisicoes')
          .where('$tipoUsuario.id_usuario', isEqualTo: idUsuario)
          .where('status',
              whereIn: filtros.isNotEmpty
                  ? filtros
                  : [
                      StatusRequisicao.CONFIRMADA,
                      StatusRequisicao.CANCELADA,
                    ])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('Você ainda não realizou nenhuma corrida'));
        }

        List<QueryDocumentSnapshot> corridas =
            _ordenarCorridas(snapshot.data!.docs);
        return _construirListaCorridas(context, corridas, idUsuario);
      },
    );
  }

  List<QueryDocumentSnapshot> _ordenarCorridas(
      List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      try {
        DateTime dataA =
            DateTime.parse((a.data() as Map<String, dynamic>)['data_inicio']);
        DateTime dataB =
            DateTime.parse((b.data() as Map<String, dynamic>)['data_inicio']);
        return dataB.compareTo(dataA);
      } catch (e) {
        print("Erro ao converter data: $e");
        return 0;
      }
    });
    return docs;
  }

  Widget _construirListaCorridas(BuildContext context,
      List<QueryDocumentSnapshot> corridas, String? idUsuario) {
    return Column(
      children: corridas.map((doc) {
        var dados = doc.data() as Map<String, dynamic>;
        return _construirItemCorrida(context, dados, idUsuario);
      }).toList(),
    );
  }

  Widget _construirItemCorrida(
      BuildContext context, Map<String, dynamic> dados, String? idUsuario) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detalhes-corrida',
          arguments: {
            'idCorrida': dados['id'].toString(),
            'tipoUsuario': widget.tipoUsuario.toString(),
            'idUsuario': idUsuario.toString(),
          },
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.secundaryColor, width: 2),
        ),
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _construirIcone(),
              _construirInformacoesCorrida(dados),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.secundarytextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirIcone() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.secundaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.access_time_sharp,
        color: AppColors.secundarytextColor,
      ),
    );
  }

  Widget _construirInformacoesCorrida(Map<String, dynamic> dados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            '${dados['destino']['rua']}, ${dados['destino']['numero']}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: AppColors.textColor),
          ),
        ),
        SizedBox(
          width: 180,
          child: dados['status'] == StatusRequisicao.CANCELADA
              ? Text(
                  'Cancelada',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.secundarytextColor,
                    fontSize: 11,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatarPeriodoCorrida(
                          dados['data_inicio'], dados['data_fim']),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          color: AppColors.secundarytextColor, fontSize: 11),
                    ),
                    Text(
                      _formatarValor(dados['valor_corrida']),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          color: AppColors.secundarytextColor, fontSize: 11),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _formatarPeriodoCorrida(String? dataInicio, String? dataFim) {
    if (dataInicio == null || dataFim == null) return 'N/A';

    DateTime inicio = DateTime.parse(dataInicio);

    String dataFormatada = DateFormat('dd/MM/yyyy').format(inicio);
    String horaInicio = DateFormat('HH:mm').format(inicio);

    return '$dataFormatada • $horaInicio';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'N/A';

    var formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Anteriores',
                  style: TextStyle(fontSize: 16),
                ),
                GestureDetector(
                  onTap: _exibirFiltros,
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppColors.secundaryColor,
                        borderRadius: BorderRadius.circular(50)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.filter_alt_outlined,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            _corridas()
          ],
        ),
      ),
    );
  }
}
