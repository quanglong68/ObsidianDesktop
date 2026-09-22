import 'package:flutter/material.dart';

import '../../providers/app_provider.dart';

void showLinkPickerDialog(
  BuildContext context,
  AppProvider provider,
  TextEditingController contentController,
) {
  List<String> allFiles = provider.getAllFileNames();

  showDialog(
    context: context,
    builder: (contextLink) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
        ),
        title: const Text(
          "Chọn File để Liên Kết",
          style: TextStyle(
            color: Color(0xFF8B5CF6),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 350,
          height: 400,
          child: allFiles.isEmpty
              ? const Center(
                  child: Text(
                    "Chưa có file nào trong Vault.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allFiles.length,
                  itemBuilder: (context, index) {
                    String fileName = allFiles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.link,
                          color: Color(0xFF8B5CF6),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          int cursorPosition =
                              contentController.selection.base.offset;
                          if (cursorPosition < 0) {
                            cursorPosition = contentController.text.length;
                          }
                          String currentText = contentController.text;
                          String linkToInsert = " [[$fileName]] ";
                          contentController.text =
                              currentText.substring(0, cursorPosition) +
                              linkToInsert +
                              currentText.substring(cursorPosition);
                          contentController.selection = TextSelection.collapsed(
                            offset: cursorPosition + linkToInsert.length,
                          );
                          Navigator.pop(contextLink);
                        },
                      ),
                    );
                  },
                ),
        ),
      );
    },
  );
}
