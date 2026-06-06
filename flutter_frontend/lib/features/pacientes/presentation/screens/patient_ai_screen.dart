import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/header.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/patient_ollama_provider.dart';
import 'package:flutter_frontend/features/auth/logic/auth_provider.dart';
import 'package:flutter_frontend/features/pacientes/data/paciente_model.dart';

class PatientAiScreen extends StatefulWidget {
  const PatientAiScreen({Key? key}) : super(key: key);

  @override
  _PatientAiScreenState createState() => _PatientAiScreenState();
}

class _PatientAiScreenState extends State<PatientAiScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token != null) {
      final pacientesProvider = context.read<PacientesProvider>();
      await pacientesProvider.fetchMisControles(token);
      
      if (pacientesProvider.perfilPaciente != null) {
        context.read<PatientOllamaProvider>().setPatientName(pacientesProvider.perfilPaciente!.nombre);
      }
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pacientesProvider = Provider.of<PacientesProvider>(context);

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          const Header(),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: _buildRecordsPanel(pacientesProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsPanel(PacientesProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final paciente = provider.perfilPaciente;
    if (paciente == null) {
      return const Center(child: Text("No se pudo cargar tu información clínica."));
    }

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mis Datos Médicos",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: ListView.builder(
              itemCount: paciente.historialControles.length,
              itemBuilder: (context, index) {
                final control = paciente.historialControles[index];
                return _buildControlCard(control);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard(ControlCardioModel control) {
    const String serverUrl = "http://127.0.0.1:8000";
    String? imageUrl;
    if (control.archivoAdjunto != null) {
      imageUrl = control.archivoAdjunto!.startsWith('http') 
          ? control.archivoAdjunto 
          : serverUrl + control.archivoAdjunto!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
              color: primaryColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(control.fecha, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  _buildStatusChip(control.diagnosticoEcg),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricBox("Presión", "${control.presionSistolica}/${control.presionDiastolica}", "mmHg", Icons.speed, Colors.orangeAccent),
                      _buildMetricBox("Ritmo", "${control.frecuenciaCardiaca}", "BPM", Icons.favorite, Colors.redAccent),
                      _buildMetricBox("SatO2", "${control.saturacionOxigeno}", "%", Icons.air, Colors.cyanAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("SÍNTOMAS Y ALERTAS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(control.sintomas, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  if (control.dolorPecho || control.disnea || control.mareos || control.edema)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (control.dolorPecho) _buildModernBadge("DOLOR PECHO", Icons.warning_amber_rounded, Colors.red),
                          if (control.disnea) _buildModernBadge("DISNEA", Icons.air, Colors.orange),
                          if (control.mareos) _buildModernBadge("MAREOS", Icons.moped_rounded, Colors.amber),
                          if (control.edema) _buildModernBadge("EDEMA", Icons.water_drop, Colors.blue),
                        ],
                      ),
                    ),
                  const SizedBox(height: 15),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  _buildDetailSection("Evolución Clínica", control.evolucion, Icons.notes_rounded),
                  const SizedBox(height: 10),
                  _buildDetailSection("Plan y Medicación", control.planMedicacion, Icons.medical_services_outlined),
                  if (control.proximaCita != null)
                    _buildNextAppointment(control.proximaCita!),
                  if (imageUrl != null)
                    _buildAttachment(context, imageUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointment(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, size: 16, color: primaryColor),
            const SizedBox(width: 10),
            const Text("Próxima Cita: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(date, style: const TextStyle(fontSize: 12, color: primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachment(BuildContext context, String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ESTUDIO ADJUNTO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showImageDialog(context, url),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.5)]),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fullscreen, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text("Ver estudio completo", style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanelContent(PatientOllamaProvider ollama) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: ollama.messages.length,
              itemBuilder: (context, index) {
                final message = ollama.messages[index];
                final isUser = message['role'] == 'user';
                return _buildChatBubble(message['content'] ?? "", isUser);
              },
            ),
          ),
          if (ollama.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(backgroundColor: bgColor, color: primaryColor),
            ),
          const SizedBox(height: defaultPadding),
          TextField(
            controller: _chatController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Pregúntame algo...",
              hintStyle: const TextStyle(color: Colors.white38),
              fillColor: bgColor,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: primaryColor, size: 20),
                onPressed: () {
                  if (_chatController.text.isNotEmpty) {
                    ollama.sendMessage(_chatController.text, onDone: _scrollToBottom);
                    _chatController.clear();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.5)),
      ),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }

  Widget _buildMetricBox(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(unit, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildModernBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: primaryColor.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(content.isEmpty ? "No se registraron detalles adicionales." : content, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(panEnabled: true, minScale: 0.5, maxScale: 4, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, fit: BoxFit.contain))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isUser ? 15 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 15),
          ),
          border: isUser ? null : Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 13,
            height: 1.4, // Mejor espaciado entre líneas
          ),
        ),
      ),
    );
  }
}
