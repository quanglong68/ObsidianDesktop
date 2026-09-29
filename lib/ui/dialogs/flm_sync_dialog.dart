import 'package:flutter/material.dart';

import '../../providers/app_provider.dart';

void showFlmSyncDialog(BuildContext context, AppProvider provider) {
  TextEditingController codeController = TextEditingController();

  showDialog(
    context: context,
    builder: (contextDialog) {
      bool hasHistory = provider.flmHistory.isNotEmpty;

      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.public, color: Color(0xFF8B5CF6)),
            SizedBox(width: 10),
            Text(
              "2. Chọn Chương Trình Học",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasHistory) ...[
                const Text(
                  "Chương trình đã lưu trên máy (Không cần cào lại):",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.flmHistory.length,
                    itemBuilder: (context, index) {
                      String historyCode = provider.flmHistory[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.folder_special,
                          color: Colors.amberAccent,
                        ),
                        title: Text(
                          historyCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                        ),
                        onTap: () {
                          provider.loadLocalCurriculum(historyCode);
                          Navigator.pop(contextDialog);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),
                const Text(
                  "Hoặc cào dữ liệu chương trình MỚI:",
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (!hasHistory)
                const Text(
                  "Bạn chưa có dữ liệu nào. Vui lòng nhập mã chương trình để tải về máy:",
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "Nhập mã (VD: BIT_SE_K19B)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialog),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(
              Icons.cloud_download,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              "TẢI DATA VỀ MÁY",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(contextDialog);
                provider.startFlmScraping(codeController.text);
              }
            },
          ),
        ],
      );
    },
  );
}
