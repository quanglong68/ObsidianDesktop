import 'package:flutter/material.dart';

import '../../providers/app_provider.dart';
import 'editor_dialog.dart';

void showFileActionDialog(
  BuildContext context,
  String subjectCode,
  List<String> fileList,
  AppProvider provider,
) {
  showDialog(
    context: context,
    builder: (contextDialog) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
        ),
        title: Text(
          "Danh sách File (#$subjectCode)",
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: fileList.length,
                itemBuilder: (context, index) {
                  String fileName = fileList[index];

                  // KIỂM TRA PHÂN LOẠI FILE ĐỂ GẮN NHÃN MÀU
                  bool isFLM = provider.flmFiles.contains(fileName);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFLM
                            ? Colors.cyanAccent.withOpacity(0.2)
                            : const Color(0xFF8B5CF6).withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isFLM ? Icons.school : Icons.edit_note,
                        color: isFLM
                            ? Colors.cyanAccent
                            : const Color(0xFF8B5CF6),
                        size: 30,
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isFLM
                                  ? Colors.cyanAccent.withOpacity(0.1)
                                  : const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isFLM
                                    ? Colors.cyanAccent
                                    : const Color(0xFF8B5CF6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isFLM ? "FLM SYNC" : "USER NOTE",
                              style: TextStyle(
                                color: isFLM
                                    ? Colors.cyanAccent
                                    : const Color(0xFF8B5CF6),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.amberAccent,
                            ),
                            tooltip: "Sửa bằng App",
                            onPressed: () {
                              Navigator.pop(contextDialog);
                              showEditorDialog(context, subjectCode, fileName);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.open_in_new,
                              color: Colors.grey,
                            ),
                            tooltip: "Mở trong Obsidian",
                            onPressed: () {
                              Navigator.pop(contextDialog);
                              provider.openObsidianFile(fileName);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                ),
                icon: const Icon(Icons.add, color: Colors.cyanAccent),
                label: const Text(
                  "Tạo thêm File mới cho môn này",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(contextDialog);
                  showEditorDialog(context, subjectCode, null);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
