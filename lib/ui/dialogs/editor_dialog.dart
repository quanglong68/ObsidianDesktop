import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import 'link_picker_dialog.dart';

void showEditorDialog(
  BuildContext context,
  String? suggestedSubjectCode,
  String? fileToEdit,
) async {
  var provider = Provider.of<AppProvider>(context, listen: false);

  String initialContent = "";
  String initialFileName = suggestedSubjectCode ?? "";

  if (fileToEdit != null) {
    initialFileName = fileToEdit;
    initialContent = await provider.readFileContent(fileToEdit);
  }

  TextEditingController subjectController = TextEditingController(
    text: initialFileName,
  );
  TextEditingController contentController = TextEditingController(
    text: initialContent,
  );

  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  fileToEdit == null ? Icons.flash_on : Icons.edit_document,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  fileToEdit == null
                      ? "Ghi Chú Nhanh"
                      : "Sửa File: $fileToEdit",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              icon: const Icon(Icons.hub, color: Colors.white, size: 16),
              label: const Text(
                "Tạo Liên Kết",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                showLinkPickerDialog(
                  dialogContext,
                  provider,
                  contentController,
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "Tên File (Sẽ tự động thêm .md)",
                  labelStyle: const TextStyle(color: Colors.cyanAccent),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white, height: 1.5),
                maxLines: 15,
                decoration: InputDecoration(
                  hintText: "Nội dung kiến thức...\nBạn có thể tự gõ [[TênFile]] hoặc bấm nút 'Tạo Liên Kết' ở trên.",
                  hintStyle: const TextStyle(color: Colors.grey),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy Bỏ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
            ),
            onPressed: () {
              provider.saveNote(
                subjectController.text,
                contentController.text,
                suggestedSubjectCode ?? "",
              );
              Navigator.pop(dialogContext);
            },
            child: const Text(
              "LƯU VÀO OBSIDIAN",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
