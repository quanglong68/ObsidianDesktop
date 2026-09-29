import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/deadline_dialog.dart';
import '../dialogs/flm_sync_dialog.dart';
import '../dialogs/webview_login_dialog.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppProvider>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FPTU SE",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF26F21),
                      ),
                    ),
                    Text(
                      "SECOND BRAIN",
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 3,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: "Cài đặt hệ thống",
                child: InkWell(
                  onTap: () => showSettingsDialog(context, provider),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.cyanAccent,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFFF26F21)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.event_note, color: Color(0xFFF26F21)),
              label: const Text(
                "XEM DEADLINE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              onPressed: () => showDeadlineDialog(context, provider),
            ),
          ),

          const SizedBox(height: 15),

          // NÚT: FLM AUTO-SYNC
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFF8B5CF6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.public, color: Color(0xFF8B5CF6)),
              label: const Text(
                "FLM AUTO-SYNC",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              onPressed: () => showWebViewLoginDialog(context, provider),
            ),
          ),

          const SizedBox(height: 15),

          // NÚT: SYNC VAULT
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF26F21),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => provider.scanObsidianVault(),
              child: Consumer<AppProvider>(
                builder: (context, kho, child) {
                  return kho.isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "SYNC VAULT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        );
                },
              ),
            ),
          ),

          const SizedBox(height: 15),

          // NÚT MỚI: HARD RESET AI
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.delete_forever,
                color: Colors.redAccent,
                size: 16,
              ),
              label: const Text(
                "HARD RESET AI",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                // Hiển thị hộp thoại xác nhận trước khi xóa
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Cảnh báo",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "Hành động này sẽ xóa toàn bộ bộ nhớ Vector của AI. Các file .md trên ổ cứng vẫn an toàn.\n\nBạn có chắc chắn muốn dọn sạch não AI?",
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Hủy bỏ",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.hardResetDatabase();
                        },
                        child: const Text(
                          "Xóa sạch",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Consumer<AppProvider>(
            builder: (context, kho, child) {
              return Text(
                "> ${kho.statusMessage}",
                style: TextStyle(
                  fontFamily: 'Consolas',
                  color: kho.isScanning ? Colors.yellow : Colors.greenAccent,
                  fontSize: 13,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
