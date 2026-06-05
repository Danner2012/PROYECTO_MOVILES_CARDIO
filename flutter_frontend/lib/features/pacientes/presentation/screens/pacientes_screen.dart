// lib/features/pacientes/presentation/screens/pacientes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import '../../data/paciente_model.dart';
import 'expediente_screen.dart';
import 'registrar_paciente_screen.dart';
// ignore_for_file: use_build_context_synchronously

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  static const _bg      = Color(0xFF0D1117);
  static const _teal    = Color(0xFF00BFA5);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final token =
            Provider.of<AuthProvider>(context, listen: false).token ?? '';
        Provider.of<PacientesProvider>(context, listen: false)
            .cargarPacientes(token);
      }
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PacienteModel> _filtrar(List<PacienteModel> todos) {
    if (_query.isEmpty) return todos;
    return todos.where((p) {
      return p.nombre.toLowerCase().contains(_query) ||
          p.email.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final prov = Provider.of<PacientesProvider>(context);
    final filtrados = _filtrar(prov.pacientes);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Mis Pacientes',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () =>
              Provider.of<MenuAppController>(context, listen: false)
                  .setSelectedPage("dashboard"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white54, size: 20),
            tooltip: 'Actualizar',
            onPressed: () =>
                Provider.of<PacientesProvider>(context, listen: false)
                    .cargarPacientes(token),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: _teal,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: _surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _teal, width: 1.5),
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty && !prov.isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  filtrados.isEmpty
                      ? 'Sin resultados para "$_query"'
                      : '${filtrados.length} resultado${filtrados.length != 1 ? 's' : ''} para "$_query"',
                  style: TextStyle(
                    color: filtrados.isEmpty
                        ? Colors.redAccent
                        : _teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Expanded(
            child: prov.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _teal, strokeWidth: 2.5))
                : prov.pacientes.isEmpty
                    ? _EmptyState(
                        onAdd: () => _irARegistrar(context, token))
                    : filtrados.isEmpty
                        ? _SinResultados(query: _query)
                        : RefreshIndicator(
                            color: _teal,
                            backgroundColor: _surface,
                            onRefresh: () =>
                                Provider.of<PacientesProvider>(context,
                                        listen: false)
                                    .cargarPacientes(token),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: filtrados.length,
                              itemBuilder: (context, i) {
                                final p = filtrados[i];
                                return _PacienteTile(
                                  paciente: p,
                                  query: _query,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ExpedienteScreen(paciente: p)),
                                  ).then((_) {
                                    if (context.mounted) {
                                      Provider.of<PacientesProvider>(context,
                                              listen: false)
                                          .cargarPacientes(token);
                                    }
                                  }),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _teal,
        onPressed: () => _irARegistrar(context, token),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _irARegistrar(BuildContext context, String token) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RegistrarPacienteScreen(token: token)),
    ).then((_) {
      if (mounted) {
        Provider.of<PacientesProvider>(context, listen: false)
            .cargarPacientes(token);
      }
    });
  }
}

// ─── Celda de Paciente con highlight ─────────────────────────────────────────
class _PacienteTile extends StatelessWidget {
  final PacienteModel paciente;
  final String query;
  final VoidCallback onTap;

  const _PacienteTile({
    required this.paciente,
    required this.query,
    required this.onTap,
  });

  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);
  static const _teal    = Color(0xFF00BFA5);

  List<TextSpan> _highlight(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    int start = 0;
    int idx;
    while ((idx = lower.indexOf(query, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          color: _teal,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x1A00BFA5),
        ),
      ));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si hay foto de perfil disponible
    final tieneFoto = paciente.foto != null && paciente.foto!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _teal.withValues(alpha: 0.15),
          backgroundImage: tieneFoto ? NetworkImage(paciente.foto!) : null,
          child: tieneFoto
              ? null
              : Text(
                  (paciente.nombre.isNotEmpty ? paciente.nombre[0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14),
            children: _highlight(paciente.nombre, query),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
                children: _highlight(paciente.email, query),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined,
                    size: 11, color: Colors.white24),
                const SizedBox(width: 4),
                Text(
                  '${paciente.historialControles.length} control(es)',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: _teal, size: 22),
        onTap: onTap,
      ),
    );
  }
}

// ─── Sin resultados de búsqueda ───────────────────────────────────────────────
class _SinResultados extends StatelessWidget {
  final String query;
  const _SinResultados({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Sin resultados',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró ningún paciente\ncon "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado Vacío (sin pacientes) ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_outlined,
                size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No tienes pacientes asignados',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vincula un nuevo paciente para comenzar\nel seguimiento cardiológico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Vincular Paciente'),
            ),
          ],
        ),
      ),
    );
  }
}
