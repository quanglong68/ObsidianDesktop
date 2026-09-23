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
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26F21),
                  ),
                  icon: const Icon(
                    Icons.add_task,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "Tạo Task",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    showDialog(
                      context: dialogContext,
                      builder: (taskCtx) {
                        TextEditingController taskDetailController =
                            TextEditingController();
                        DateTime pickedDate = DateTime.now();

                        return StatefulBuilder(
                          builder: (context, setState) {
                            String dateStr =
                                "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";

                            return AlertDialog(
                              backgroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(
                                  color: Color(0xFFF26F21),
                                ),
                              ),
                              title: const Text(
                                "Tạo Task Mới",
                                style: TextStyle(
                                  color: Color(0xFFF26F21),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: taskDetailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText:
                                          "Nội dung Deadline (VD: Làm bài PT1)",
                                      labelStyle: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Hạn chót:",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.calendar_month,
                                          color: Colors.cyanAccent,
                                        ),
                                        label: Text(
                                          dateStr,
                                          style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onPressed: () async {
                                          DateTime? d = await showDatePicker(
                                            context: context,
                                            initialDate: pickedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2050),
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.dark(
                                                        primary: Color(
                                                          0xFFF26F21,
                                                        ),
                                                        onPrimary: Colors.white,
                                                        surface: Color(
                                                          0xFF1E293B,
                                                        ),
                                                        onSurface: Colors.white,
                                                      ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (d != null) {
                                            setState(() => pickedDate = d);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(taskCtx),
                                  child: const Text(
                                    "Hủy",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF26F21),
                                  ),
                                  onPressed: () {
                                    if (taskDetailController.text
                                        .trim()
                                        .isEmpty)
                                      return;
                                    String taskStr =
                                        "\n- [ ] ${taskDetailController.text.trim()} @due $dateStr\n";
                                    int cursorPosition =
                                        contentController.selection.base.offset;
                                    if (cursorPosition < 0)
                                      cursorPosition =
                                          contentController.text.length;
                                    String currentText = contentController.text;
                                    contentController.text =
                                        currentText.substring(
                                          0,
                                          cursorPosition,
                                        ) +
                                        taskStr +
                                        currentText.substring(cursorPosition);
                                    contentController
                                        .selection = TextSelection.collapsed(
                                      offset: cursorPosition + taskStr.length,
                                    );
                                    Navigator.pop(taskCtx);
                                  },
                                  child: const Text(
                                    "Chèn Task",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 10),
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
                  hintText: "Nội dung kiến thức...\nSử dụng nút 'Tạo Task' hoặc 'Tạo Liên Kết' ở trên để chèn nhanh.",
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
