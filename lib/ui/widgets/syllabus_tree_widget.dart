import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../dialogs/syllabus_setup_dialogs.dart';
import '../dialogs/file_action_dialog.dart';
import '../dialogs/editor_dialog.dart';

class BlinkingUrgentContainer extends StatefulWidget {
  final Widget child;
  const BlinkingUrgentContainer({super.key, required this.child});

  @override
  State<BlinkingUrgentContainer> createState() =>
      _BlinkingUrgentContainerState();
}

class _BlinkingUrgentContainerState extends State<BlinkingUrgentContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 20, bottom: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(
              0.05 + (_controller.value * 0.05),
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.redAccent.withOpacity(
                0.3 + (_controller.value * 0.5),
              ),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(
                  0.1 + (_controller.value * 0.2),
                ),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class SyllabusTreeWidget extends StatelessWidget {
  const SyllabusTreeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppProvider>(context);
    Map<String, dynamic> trackMap =
        (provider.activeSyllabus[provider.currentMajor]
            as Map<String, dynamic>?) ??
        {};
    var currentSyllabusPath =
        (trackMap[provider.currentTrack] as List<dynamic>?) ?? [];

    // Lấy trực tiếp danh sách File User thay vì lấy Tag rác
    List<String> userNotes = provider.userFiles.toList();

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CHƯƠNG TRÌNH ĐANG HỌC",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  provider.currentMajor.isNotEmpty
                      ? provider.currentMajor
                      : "Chưa có dữ liệu",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          _buildUrgentDeadlines(context, provider),

          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TIẾN ĐỘ THU THẬP KIẾN THỨC",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "${(provider.learningProgress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.learningProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.learningProgress == 1.0
                    ? Colors.greenAccent
                    : const Color(0xFFF26F21),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildLegendItem(
                const Color(0xFF1E293B).withOpacity(0.5),
                Colors.grey.withOpacity(0.2),
                "Chưa tải",
              ),
              const SizedBox(width: 15),
              _buildLegendItem(
                const Color(0xFFF26F21).withOpacity(0.2),
                const Color(0xFFF26F21),
                "Đã có File (AI chưa quét)",
              ),
              const SizedBox(width: 15),
              _buildLegendItem(
                const Color(0xFF064E3B).withOpacity(0.6),
                Colors.cyanAccent,
                "AI đã đọc (Sẵn sàng hỏi đáp)",
              ),
            ],
          ),

          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Colors.cyanAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.cyanAccent, size: 18),
                label: const Text(
                  "THÊM KỲ HỌC MỚI",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => showAddSemesterDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: currentSyllabusPath.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Chương trình '${provider.currentMajor}' hiện đang trống.",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Bấm 'FLM AUTO-SYNC' ở bên trái để tải dữ liệu từ Web!",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: currentSyllabusPath.length + 1,
                    itemBuilder: (context, index) {
                      if (index == currentSyllabusPath.length) {
                        if (userNotes.isEmpty) return const SizedBox();
                        return Container(
                          margin: const EdgeInsets.only(top: 40, bottom: 80),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.folder_special,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "NỘI DUNG CỦA NGƯỜI DÙNG",
                                    style: TextStyle(
                                      color: Color(0xFF8B5CF6),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 15,
                                runSpacing: 15,
                                children: userNotes
                                    .map(
                                      (fileName) => _buildPersonalNode(
                                        context,
                                        fileName,
                                        provider,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        );
                      }

                      var semesterData = currentSyllabusPath[index];
                      var subjectList = (semesterData['mon'] as List<dynamic>);

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(top: 35),
                                  decoration: const BoxDecoration(
                                    color: Colors.cyanAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                if (index != currentSyllabusPath.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Colors.cyanAccent.withOpacity(0.3),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      Text(
                                        semesterData['ky'] ?? "",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () => showAddSubjectDialog(
                                          context,
                                          index,
                                          provider,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  subjectList.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Text(
                                            "Chưa có môn học trong kỳ này. Bấm dấu (+) để thêm môn.",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 15,
                                          runSpacing: 15,
                                          children: subjectList
                                              .map(
                                                (mon) => _buildNode(
                                                  context,
                                                  mon['ma'],
                                                  mon['ten'],
                                                  provider,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color bgColor, Color borderColor, String text) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildUrgentDeadlines(BuildContext context, AppProvider provider) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<TaskItem> urgentTasks = provider.getAllTasks().where((task) {
      if (task.isDone) return false;
      DateTime taskDay = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      int diffDays = taskDay.difference(today).inDays;
      return diffDays <= 3;
    }).toList();

    if (urgentTasks.isEmpty) return const SizedBox.shrink();

    return BlinkingUrgentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                "CẢNH BÁO DEADLINE GẤP KHÔNG THỂ BỎ QUA!",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: urgentTasks.length,
              itemBuilder: (context, index) {
                TaskItem task = urgentTasks[index];
                DateTime taskDay = DateTime(
                  task.dueDate.year,
                  task.dueDate.month,
                  task.dueDate.day,
                );
                int diffDays = taskDay.difference(today).inDays;

                String badgeText = diffDays < 0
                    ? "Quá hạn"
                    : (diffDays == 0 ? "Hôm nay" : "Còn $diffDays ngày");
                String dateStr =
                    "${task.dueDate.day.toString().padLeft(2, '0')}/${task.dueDate.month.toString().padLeft(2, '0')}/${task.dueDate.year}";

                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.5),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => provider.openObsidianFile(task.fileName),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          task.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              "Hạn: $dateStr",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Mở file: ${task.fileName}.md",
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalNode(
    BuildContext context,
    String fileName,
    AppProvider provider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Cho phép mở thẳng Note của người dùng khi ấn vào
        onTap: () {
          provider.openObsidianFile(fileName);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "USER NOTE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNode(
    BuildContext context,
    String subjectCode,
    String subjectName,
    AppProvider provider,
  ) {
    int status = provider.checkSubjectStatus(subjectCode);

    Color bgColor = const Color(0xFF1E293B).withOpacity(0.5);
    Color borderColor = Colors.grey.withOpacity(0.2);
    Color textColor = Colors.grey[600]!;
    Color subTextColor = Colors.grey[700]!;

    if (status == 1) {
      bgColor = const Color(0xFFF26F21).withOpacity(0.2);
      borderColor = const Color(0xFFF26F21);
      textColor = Colors.white;
      subTextColor = const Color(0xFFF26F21);
    } else if (status == 2) {
      bgColor = const Color(0xFF064E3B).withOpacity(0.6);
      borderColor = Colors.cyanAccent;
      textColor = Colors.white;
      subTextColor = Colors.cyanAccent;
    }

    String codeUpper = subjectCode.toUpperCase();
    String safeCode = codeUpper.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    List<String> fileList =
        provider.tagFileMap[codeUpper] ?? provider.tagFileMap[safeCode] ?? [];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (status > 0) {
            showFileActionDialog(context, codeUpper, fileList, provider);
          } else {
            showEditorDialog(context, codeUpper, null);
          }
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withOpacity(0.1),
        mouseCursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutExpo,
          width: 140,
          height: 80,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: status == 2
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subjectCode,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              Text(
                subjectName,
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 11),
              ),
              if (status > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status == 2 ? Icons.check_circle : Icons.edit_document,
                        size: 12,
                        color: status == 2
                            ? Colors.greenAccent
                            : const Color(0xFFF26F21),
                      ),
                      if (fileList.length > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          "(${fileList.length})",
                          style: TextStyle(
                            fontSize: 10,
                            color: status == 2
                                ? Colors.greenAccent
                                : const Color(0xFFF26F21),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
