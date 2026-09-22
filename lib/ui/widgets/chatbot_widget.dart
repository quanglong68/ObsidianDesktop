import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../providers/app_provider.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppProvider>(context, listen: false);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              left: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.cyanAccent),
                    SizedBox(width: 10),
                    Text(
                      "AI TUTOR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, kho, child) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount:
                          kho.chatHistory.length + (kho.isChatting ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == kho.chatHistory.length && kho.isChatting) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 15,
                                top: 10,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.2),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.cyanAccent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "AI đang chạy Vector Search...",
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        var message = kho.chatHistory[index];
                        bool isUser = message['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.25,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFFF26F21).withOpacity(0.2)
                                  : Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isUser
                                    ? const Color(0xFFF26F21).withOpacity(0.5)
                                    : Colors.cyanAccent.withOpacity(0.3),
                              ),
                              boxShadow: isUser
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFF26F21)
                                            .withOpacity(0.2),
                                        blurRadius: 15,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withOpacity(
                                          0.1,
                                        ),
                                        blurRadius: 15,
                                      ),
                                    ],
                            ),
                            child: isUser
                                ? Text(
                                    message['text']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: message['text']!,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: TextStyle(
                                        color: Colors.cyan[50],
                                        height: 1.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.cyanAccent
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      strong: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent,
                                      ),
                                      code: const TextStyle(
                                        backgroundColor: Colors.black54,
                                        color: Colors.greenAccent,
                                        fontFamily: 'Consolas',
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Hỏi AI về kiến thức đã học...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Colors.cyanAccent),
                        onPressed: () {
                          provider.sendChatMessage(controller.text);
                          controller.clear();
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Colors.cyanAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (text) {
                      provider.sendChatMessage(text);
                      controller.clear();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
