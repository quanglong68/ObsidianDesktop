import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/syllabus_tree_widget.dart';
import '../widgets/chatbot_widget.dart';
import '../dialogs/editor_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF000000)],
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: SidebarWidget()),
                Expanded(flex: 8, child: SyllabusTreeWidget()),
              ],
            ),
          ),
          Consumer<AppProvider>(
            builder: (context, kho, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutBack,
                top: 0,
                bottom: 0,
                right: kho.isChatWindowOpen ? 0 : -450,
                width: 450,
                child: const ChatbotWidget(),
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: InkWell(
                    onTap: () => showEditorDialog(context, null, null),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF26F21).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFF26F21).withOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF26F21).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "QUICK NOTE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Consumer<AppProvider>(
            builder: (context, kho, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutBack,
                bottom: 30,
                right: kho.isChatWindowOpen ? 470 : 30,
                child: FloatingActionButton(
                  onPressed: () => kho.toggleChatWindow(),
                  backgroundColor: kho.isChatWindowOpen
                      ? const Color(0xFF1E293B)
                      : Colors.cyanAccent,
                  elevation: 15,
                  child: Icon(
                    kho.isChatWindowOpen ? Icons.close : Icons.smart_toy,
                    color: kho.isChatWindowOpen ? Colors.white : Colors.black,
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
