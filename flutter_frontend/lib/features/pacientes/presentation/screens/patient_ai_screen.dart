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
    final ollamaProvider = Provider.of<PatientOllamaProvider>(context);

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          const Header(),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PANEL IZQUIERDO: MIS REGISTROS
                Expanded(
                  flex: 3,
                  child: _buildRecordsPanel(pacientesProvider),
                ),
                const SizedBox(width: defaultPadding),
                // PANEL DERECHO: MI ASISTENTE IA
                Expanded(
                  flex: 2,
                  child: _buildChatPanel(ollamaProvider),
                ),
              ],
            ),
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
            "Mi Historial Cardológico",
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
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fecha: ${control.fecha}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
              Text(
                "Ritmo: ${control.frecuenciaCardiaca} BPM",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          Text("Presión: ${control.presionSistolica}/${control.presionDiastolica} mmHg"),
          Text("Saturación O2: ${control.saturacionOxigeno}%"),
          const SizedBox(height: 5),
          Text("Diagnóstico ECG: ${control.diagnosticoEcg}", 
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildChatPanel(PatientOllamaProvider ollama) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                "Asistente AI",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Pregúntame sobre tus datos...",
              fillColor: bgColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: primaryColor),
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

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: isUser ? null : Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
