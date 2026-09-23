import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/deadline_dialog.dart';

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
