import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/header.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';
import 'package:flutter_frontend/features/ollama/logic/ollama_provider.dart';

class OllamaScreen extends StatefulWidget {
  const OllamaScreen({Key? key}) : super(key: key);

  @override
  _OllamaScreenState createState() => _OllamaScreenState();
}

class _OllamaScreenState extends State<OllamaScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
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
    final ollamaProvider = Provider.of<OllamaProvider>(context);

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          const Header(),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ollama Chat (Admin)",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white54),
                        onPressed: () => ollamaProvider.clearChat(),
                        tooltip: "Limpiar chat",
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding),
                  // Chat Messages Area
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: ollamaProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = ollamaProvider.messages[index];
                        final isUser = message['role'] == 'user';
                        return _buildChatBubble(message['content'] ?? "", isUser);
                      },
                    ),
                  ),
                  if (ollamaProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Text("Ollama está respondiendo...", 
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                        ],
                      ),
                    ),
                  const SizedBox(height: defaultPadding),
                  // Input Area - Refactored for stability
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Escribe tu consulta...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              fillColor: bgColor,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty && !ollamaProvider.isLoading) {
                                ollamaProvider.sendMessage(value, onDone: _scrollToBottom);
                                _controller.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: ElevatedButton(
                            onPressed: ollamaProvider.isLoading
                                ? null
                                : () {
                                    if (_controller.text.isNotEmpty) {
                                      ollamaProvider.sendMessage(_controller.text, onDone: _scrollToBottom);
                                      _controller.clear();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
          color: isUser ? primaryColor : bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15),
          ),
          border: isUser ? null : Border.all(color: Colors.white10),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
