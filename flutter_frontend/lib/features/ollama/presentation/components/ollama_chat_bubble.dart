import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/patient_ollama_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';

class OllamaChatBubble extends StatefulWidget {
  const OllamaChatBubble({Key? key}) : super(key: key);

  @override
  State<OllamaChatBubble> createState() => _OllamaChatBubbleState();
}

class _OllamaChatBubbleState extends State<OllamaChatBubble> {
  bool _isChatOpen = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ollamaProvider = Provider.of<PatientOllamaProvider>(context);

    return Stack(
      children: [
        // VENTANA DE CHAT FLOTANTE
        if (_isChatOpen)
          Positioned(
            right: 20,
            bottom: 90,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 350,
                height: 500,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Barra superior de la ventana
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        color: primaryColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  "Asistente IA",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () => setState(() => _isChatOpen = false),
                            ),
                          ],
                        ),
                      ),
                      // Cuerpo del chat
                      Expanded(
                        child: _buildChatPanelContent(ollamaProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // BURBUJA FLOTANTE (BOTÓN)
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () {
              setState(() {
                _isChatOpen = !_isChatOpen;
              });
            },
            child: Icon(
              _isChatOpen ? Icons.close : Icons.auto_awesome,
              color: Colors.white,
            ),
          ),
        ),
      ],
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
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ollama.sendMessage(value, onDone: _scrollToBottom);
                _chatController.clear();
              }
            },
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
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
