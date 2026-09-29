import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';

void showEditorDialog(
  BuildContext context,
  String subjectCode,
  String? existingFileName,
) {
  var provider = Provider.of<AppProvider>(context, listen: false);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (contextDialog) {
      return _EditorDialogContent(
        subjectCode: subjectCode,
        existingFileName: existingFileName,
        provider: provider,
      );
    },
  );
}

class _EditorDialogContent extends StatefulWidget {
  final String subjectCode;
  final String? existingFileName;
  final AppProvider provider;

  const _EditorDialogContent({
    required this.subjectCode,
    required this.existingFileName,
    required this.provider,
  });

  @override
  State<_EditorDialogContent> createState() => _EditorDialogContentState();
}

class _EditorDialogContentState extends State<_EditorDialogContent> {
  late TextEditingController nameController;
  late TextEditingController contentController;

  bool isContentLoading = false;
  bool isEditingMode = false;
  String errorMessage = ""; // Chứa thông báo lỗi khi trùng tên

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    contentController = TextEditingController();

    if (widget.existingFileName != null) {
      // Chế độ: Sửa file đã có
      isEditingMode = true;
      nameController.text = widget.existingFileName!;
      _loadExistingContent();
    } else {
      // Chế độ: Tạo file mới
      isEditingMode = false;
      _generateSafeFileName();
    }
  }

  // Tự động sinh tên an toàn (VD: CEA201_Note_1)
  void _generateSafeFileName() {
    String baseName = "${widget.subjectCode}_Note";
    int counter = 1;
    String finalName = "${baseName}_$counter";

    List<String> allFiles = widget.provider.getAllFileNames();

    // Tăng số đếm cho đến khi tìm được tên chưa từng tồn tại
    while (allFiles.contains(finalName)) {
      counter++;
      finalName = "${baseName}_$counter";
    }

    nameController.text = finalName;
  }

  Future<void> _loadExistingContent() async {
    setState(() {
      isContentLoading = true;
    });
    String data = await widget.provider.readFileContent(
      widget.existingFileName!,
    );
    setState(() {
      contentController.text = data;
      isContentLoading = false;
    });
  }

  // Kiểm tra tính hợp lệ của tên File trước khi Lưu
  bool _validateFileName(String newName) {
    String cleanName = newName.trim();

    if (cleanName.isEmpty) {
      setState(() => errorMessage = "Tên file không được để trống!");
      return false;
    }

    // Nếu tạo file mới MÀ trùng tên với file gốc của trường -> CẤM
    if (!isEditingMode &&
        cleanName.toUpperCase() == widget.subjectCode.toUpperCase()) {
      setState(
        () => errorMessage =
            "CẢNH BÁO: Tên này sẽ ghi đè lên dữ liệu gốc của trường. Vui lòng đặt tên khác (VD: ${widget.subjectCode}_Note_1)!",
      );
      return false;
    }

    // Nếu tạo file mới MÀ trùng với một file bất kỳ đã có -> CẤM
    if (!isEditingMode &&
        widget.provider.getAllFileNames().contains(cleanName)) {
      setState(
        () => errorMessage = "Tên file đã tồn tại! Vui lòng chọn tên khác.",
      );
      return false;
    }

    // Nếu đang sửa file MÀ cố tình đổi tên trùng với file khác (trừ chính nó) -> CẤM
    if (isEditingMode &&
        cleanName != widget.existingFileName &&
        widget.provider.getAllFileNames().contains(cleanName)) {
      setState(
        () => errorMessage = "Tên file đã tồn tại! Vui lòng chọn tên khác.",
      );
      return false;
    }

    // Nếu hợp lệ, xóa thông báo lỗi
    setState(() => errorMessage = "");
    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _insertText(String textToInsert) {
    final int cursorPos = contentController.selection.base.offset;
    if (cursorPos < 0) {
      contentController.text += textToInsert;
    } else {
      String prefix = contentController.text.substring(0, cursorPos);
      String suffix = contentController.text.substring(cursorPos);
      contentController.text = prefix + textToInsert + suffix;
      contentController.selection = TextSelection.collapsed(
        offset: cursorPos + textToInsert.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: isEditingMode ? Colors.cyanAccent : Colors.amberAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isEditingMode
                      ? "Sửa File: ${widget.existingFileName}"
                      : "Ghi Chú Nhanh",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26F21),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_box_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "Tạo Task",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: () {
                    DateTime tomorrow = DateTime.now().add(
                      const Duration(days: 1),
                    );
                    String dateStr =
                        "${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}";
                    _insertText("\n- [ ] Nhiệm vụ cần làm @due $dateStr \n");
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                  icon: const Icon(Icons.link, color: Colors.white, size: 16),
                  label: const Text(
                    "Tạo Liên kết",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onPressed: () {
                    _insertText("[[Tên File Khác]]");
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Trường nhập Tên File
            TextField(
              controller: nameController,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (value) =>
                  _validateFileName(value), // Kiểm tra lỗi liên tục khi gõ
              decoration: InputDecoration(
                labelText: "Tên File (Sẽ tự động thêm .md)",
                labelStyle: const TextStyle(color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),

            // Hiện cảnh báo ĐỎ nếu tên không hợp lệ
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 15),

            // Khung soạn thảo Markdown
            Expanded(
              child: isContentLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: contentController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: "Nhập nội dung Markdown ở đây...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 15),

            // Nút điều hướng
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Hủy Bỏ",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    String newName = nameController.text.trim();
                    String newContent = contentController.text;

                    // Chỉ cho phép lưu khi không có lỗi tên file
                    if (_validateFileName(newName)) {
                      widget.provider.saveNote(
                        newName,
                        newContent,
                        widget.subjectCode,
                      );
                      Navigator.pop(context);
                    }
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
            ),
          ],
        ),
      ),
    );
  }
}
