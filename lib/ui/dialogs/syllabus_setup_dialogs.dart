import 'package:flutter/material.dart';

import '../../providers/app_provider.dart';

void showCreateMajorDialog(BuildContext context, AppProvider provider) {
  TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.cyanAccent),
        ),
        title: const Text(
          "Tạo Ngành Học Mới",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Tên Ngành (VD: Thiết kế đồ họa, Quản trị...)",
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createNewMajor(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              "Tạo Ngành Học",
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

void showCreateTrackDialog(BuildContext context, AppProvider provider) {
  TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFFF26F21)),
        ),
        title: const Text(
          "Tạo Chuyên Ngành Mới",
          style: TextStyle(
            color: Color(0xFFF26F21),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Tên chuyên ngành (VD: AI Track, DevOps Track...)",
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF26F21),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createNewTrack(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              "Tạo Chuyên Ngành",
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
}

void showAddSemesterDialog(BuildContext context, AppProvider provider) {
  TextEditingController controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.cyanAccent),
        ),
        title: const Text(
          "Thêm Kỳ Học Mới",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Tên kỳ học (VD: Kỳ 1 - Nhập môn, Kỳ OJT...)",
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addNewSemester(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              "Thêm Kỳ",
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

void showAddSubjectDialog(
  BuildContext context,
  int semesterIndex,
  AppProvider provider,
) {
  TextEditingController codeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Thêm Môn Học Mới",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Mã môn (VD: PRN221)",
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Tên môn (VD: C# and .NET)",
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
              if (codeController.text.isNotEmpty) {
                provider.addSubjectToSemester(
                  semesterIndex,
                  codeController.text,
                  nameController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Lưu Môn Học",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
