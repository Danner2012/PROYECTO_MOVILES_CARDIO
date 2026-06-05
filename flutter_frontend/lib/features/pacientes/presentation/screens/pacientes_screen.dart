// lib/features/pacientes/presentation/screens/pacientes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/logic/auth_provider.dart';
import '../../../dashboard/logic/menu_app_controller.dart';
import '../../logic/pacientes_provider.dart';
import 'expediente_screen.dart';
import 'registrar_paciente_screen.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  static const _bg     = Color(0xFF0D1117);
  static const _teal   = Color(0xFF00BFA5);
  static const _surface= Color(0xFF161B22);
  static const _border = Color(0xFF30363D);

  @override
  void initState() {
    super.initState();
    // ✅ Carga la lista al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final prov  = Provider.of<PacientesProvider>(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Mis Pacientes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () =>
              Provider.of<MenuAppController>(context, listen: false).setSelectedPage("dashboard"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
            tooltip: 'Actualizar',
            onPressed: () =>
                Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5))
          : prov.pacientes.isEmpty
              ? _EmptyState(onAdd: () => _irARegistrar(context, token))
              : RefreshIndicator(
                  color: _teal,
                  backgroundColor: _surface,
                  onRefresh: () =>
                      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: prov.pacientes.length,
                    itemBuilder: (context, i) {
                      final p = prov.pacientes[i];
                      return _PacienteTile(
                        paciente: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ExpedienteScreen(paciente: p)),
                        ).then((_) {
                          // Recarga al volver del expediente
                          Provider.of<PacientesProvider>(context, listen: false)
                              .cargarPacientes(token);
                        }),
                      );
                    },
                  ),
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
      MaterialPageRoute(builder: (_) => RegistrarPacienteScreen(token: token)),
    ).then((_) {
      // Recarga la lista al volver de registrar
      Provider.of<PacientesProvider>(context, listen: false).cargarPacientes(token);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          const Text(
            'No hay pacientes registrados',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa + para vincular tu primer paciente',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Color(0xFF00BFA5)),
            label: const Text('Vincular paciente',
                style: TextStyle(color: Color(0xFF00BFA5))),
          ),
        ],
      ),
    );
  }
}

class _PacienteTile extends StatelessWidget {
  final dynamic paciente;
  final VoidCallback onTap;
  const _PacienteTile({required this.paciente, required this.onTap});

  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);
  static const _teal    = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _teal.withValues(alpha: 0.15),
          child: Text(
            (p.nombre.isNotEmpty ? p.nombre[0] : '?').toUpperCase(),
            style: const TextStyle(
                color: _teal, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(
          p.nombre,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          p.email,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _teal, size: 22),
        onTap: onTap,
      ),
    );
  }
}
