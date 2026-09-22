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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.description,
                        color: Colors.cyanAccent,
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
