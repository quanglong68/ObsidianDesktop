import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../dialogs/syllabus_setup_dialogs.dart';
import '../dialogs/file_action_dialog.dart';
import '../dialogs/editor_dialog.dart';

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
    List<String> personalTags = provider.getPersonalTags();

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Ngành học",
                            border: InputBorder.none,
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          value: provider.currentMajor,
                          items: provider.activeSyllabus.keys
                              .map<DropdownMenuItem<String>>((String major) {
                                return DropdownMenuItem<String>(
                                  value: major,
                                  child: Text(major),
                                );
                              })
                              .toList(),
                          onChanged: (newMajor) {
                            if (newMajor != null) {
                              Map<String, dynamic> sub =
                                  provider.activeSyllabus[newMajor]
                                      as Map<String, dynamic>;
                              String firstTrack = sub.isNotEmpty
                                  ? sub.keys.first
                                  : "";
                              provider.changeMajorAndTrack(
                                newMajor,
                                firstTrack,
                              );
                            }
                          },
                        ),
                      ),
                      Tooltip(
                        message: "Tạo Ngành Học Mới (Tự nhập)",
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.cyanAccent,
                            size: 26,
                          ),
                          onPressed: () =>
                              showCreateMajorDialog(context, provider),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Chuyên ngành hẹp",
                            border: InputBorder.none,
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Color(0xFFF26F21),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          value: trackMap.containsKey(provider.currentTrack)
                              ? provider.currentTrack
                              : (trackMap.isNotEmpty
                                    ? trackMap.keys.first
                                    : null),
                          items: trackMap.keys.map<DropdownMenuItem<String>>((
                            String track,
                          ) {
                            return DropdownMenuItem<String>(
                              value: track,
                              child: Text(track),
                            );
                          }).toList(),
                          onChanged: (newTrack) {
                            if (newTrack != null) {
                              provider.changeMajorAndTrack(
                                provider.currentMajor,
                                newTrack,
                              );
                            }
                          },
                        ),
                      ),
                      Tooltip(
                        message: "Tạo Chuyên ngành mới (Tự nhập)",
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFFF26F21),
                            size: 26,
                          ),
                          onPressed: () =>
                              showCreateTrackDialog(context, provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 25),
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
                          "Chuyên ngành '${provider.currentTrack}' hiện đang trống.",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Bấm 'THÊM KỲ HỌC MỚI' ở góc phải để bắt đầu xây dựng lộ trình!",
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
                        if (personalTags.isEmpty) return const SizedBox();
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
                                children: personalTags
                                    .map(
                                      (tag) => _buildPersonalNode(
                                        context,
                                        tag,
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
                                        tooltip: "Thêm môn học vào kỳ này",
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

  Widget _buildPersonalNode(
    BuildContext context,
    String tag,
    AppProvider provider,
  ) {
    List<String> fileList = provider.tagFileMap[tag] ?? [];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showFileActionDialog(context, tag, fileList, provider);
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
                tag,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const Text(
                "User Note",
                style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11),
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
    String codeUpper = subjectCode.toUpperCase();
    List<String> fileList = provider.tagFileMap[codeUpper] ?? [];
    bool isCompleted = fileList.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isCompleted) {
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
            color: isCompleted
                ? const Color(0xFF064E3B).withOpacity(0.6)
                : const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? Colors.cyanAccent
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isCompleted
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
                  color: isCompleted ? Colors.white : Colors.grey[600],
                ),
              ),
              Text(
                subjectName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCompleted ? Colors.cyanAccent : Colors.grey[700],
                  fontSize: 11,
                ),
              ),
              if (isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.greenAccent,
                      ),
                      if (fileList.length > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          "(${fileList.length})",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.greenAccent,
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
