import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/app_provider.dart';

void showSettingsDialog(BuildContext context, AppProvider provider) {
  TextEditingController pathController = TextEditingController(
    text: provider.vaultPath,
  );
  TextEditingController keyController = TextEditingController(
    text: provider.apiKey,
  );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Cấu Hình Hệ Thống",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pathController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Đường dẫn Obsidian Vault",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    readOnly: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Colors.cyanAccent),
                  onPressed: () async {
                    String? selectedDirectory = await FilePicker.platform
                        .getDirectoryPath();
                    if (selectedDirectory != null) {
                      pathController.text = selectedDirectory;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Gemini API Key",
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF26F21),
            ),
            onPressed: () {
              provider.saveSettings(pathController.text, keyController.text);
              Navigator.pop(context);
            },
            child: const Text(
              "Lưu Cài Đặt",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
