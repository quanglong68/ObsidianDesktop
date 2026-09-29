import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class FLMScraper {
  static Future<List<Map<String, dynamic>>> fetchAndParseCurriculum(
    String curriculumCode,
    String cookie,
    int maxSemesters,
    Function(String) onProgress,
  ) async {
    Map<String, String> headers = {
      'Cookie': cookie,
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };

    onProgress("Đang tìm chương trình $curriculumCode...");
    var searchUrl = Uri.parse(
      'https://flm.fpt.edu.vn/gui/role/student/ListCurriculum?searchOn=Code&keyword=$curriculumCode',
    );
    var searchRes = await http.get(searchUrl, headers: headers);

    if (searchRes.statusCode != 200) {
      throw Exception(
        "Lỗi kết nối FLM (Mã ${searchRes.statusCode}). Vui lòng đăng nhập lại.",
      );
    }

    var searchDoc = parser.parse(searchRes.body);
    var detailLink = searchDoc.querySelector(
      'a[href^="/gui/role/student/CurriculumDetails?curid="]',
    );
    if (detailLink == null) {
      throw Exception(
        "Không tìm thấy mã chương trình $curriculumCode. Kiểm tra lại mã!",
      );
    }

    String curidHref = detailLink.attributes['href']!;
    onProgress("Đang phân tích cấu trúc $maxSemesters kỳ học...");

    var detailRes = await http.get(
      Uri.parse('https://flm.fpt.edu.vn$curidHref'),
      headers: headers,
    );
    var detailDoc = parser.parse(detailRes.body);

    var table = detailDoc.querySelector('#gvSubs');
    if (table == null) {
      throw Exception("Không tìm thấy bảng môn học trong mã chương trình này.");
    }

    List<Map<String, dynamic>> semesters = List.generate(
      10,
      (index) => {"ky": "Kỳ $index", "mon": []},
    );
    List<Map<String, dynamic>> flatSubjects = [];

    var rows = table.querySelectorAll('tbody tr');
    for (var row in rows) {
      var cells = row.querySelectorAll('td');
      if (cells.length >= 5) {
        String subCode = cells[0].text.trim();
        String subNameRaw = cells[1].text.trim();
        String subName = subNameRaw.split('_').first.trim();
        String semesterStr = cells[2].text.trim();

        var aTag = cells[1].querySelector('a');
        String? subLink = aTag?.attributes['href'];

        int? semIndex = int.tryParse(semesterStr);
        if (semIndex != null && semIndex >= 1 && semIndex <= maxSemesters) {
          var subjectData = {
            "ma": subCode,
            "ten": subName,
            "link": subLink,
            "materials": "",
            "los": "",
            "cqs": "",
            "assessments": "",
            "schedule": "",
            "totalSlots": 0, // Tổng kết số slot
            "asmList": "", // Tổng kết các bài thi
          };
          semesters[semIndex]['mon'].add(subjectData);
          if (subLink != null) {
            flatSubjects.add(subjectData);
          }
        }
      }
    }

    int total = flatSubjects.length;
    int current = 0;

    for (var sub in flatSubjects) {
      current++;
      onProgress("Đang cào dữ liệu: ${sub['ma']} ($current/$total môn)...");

      try {
        var sylListRes = await http.get(
          Uri.parse('https://flm.fpt.edu.vn${sub['link']}'),
          headers: headers,
        );
        var sylListDoc = parser.parse(sylListRes.body);
        var sylDetailLink = sylListDoc.querySelector(
          'a[href^="/gui/role/student/SyllabusDetails?sylID="]',
        );

        if (sylDetailLink != null) {
          var sylDetailRes = await http.get(
            Uri.parse(
              'https://flm.fpt.edu.vn${sylDetailLink.attributes['href']}',
            ),
            headers: headers,
          );
          var sylDetailDoc = parser.parse(sylDetailRes.body);

          // 1. CÀO BẢNG MATERIALS
          var matTable = sylDetailDoc.querySelector('#gvMaterial');
          String materialsMd = "";
          if (matTable != null) {
            var mRows = matTable.querySelectorAll('tbody tr');
            for (var mRow in mRows) {
              var mCells = mRow.querySelectorAll('td');
              if (mCells.length >= 8) {
                String desc = mCells[1].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  ' ',
                );
                String author = mCells[2].text.trim();
                String isMain = mCells[7].text.trim().toLowerCase() == 'true'
                    ? "Có"
                    : "Không";
                materialsMd +=
                    "- **$desc**\n  - *Tác giả:* $author\n  - *Giáo trình chính:* $isMain\n";
              }
            }
          }
          sub['materials'] = materialsMd.isNotEmpty
              ? materialsMd
              : "_Không có dữ liệu_\n";

          // 2. CÀO BẢNG LEARNING OUTCOMES (LOs)
          var loTable = sylDetailDoc.querySelector('#gvLO');
          String losMd = "";
          if (loTable != null) {
            var loRows = loTable.querySelectorAll('tbody tr');
            for (var loRow in loRows) {
              var loCells = loRow.querySelectorAll('td');
              if (loCells.length >= 3) {
                String name = loCells[1].text.trim();
                String desc = loCells[2].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  ' ',
                );
                losMd += "- **$name:** $desc\n";
              }
            }
          }
          sub['los'] = losMd.isNotEmpty ? losMd : "_Không có dữ liệu_\n";

          // 3. CÀO BẢNG ASSESSMENTS VÀ LƯU TỔNG KẾT
          var asmTable = sylDetailDoc.querySelector('#gvAssessment');
          String asmMd = "";
          List<String> asmNames = []; // Mảng chứa tên bài kiểm tra
          if (asmTable != null) {
            var asmRows = asmTable.querySelectorAll('tbody tr');
            for (var asmRow in asmRows) {
              var asmCells = asmRow.querySelectorAll('td');
              if (asmCells.length >= 12) {
                String cat = asmCells[1].text.trim();
                String weight = asmCells[4].text.trim();
                String duration = asmCells[6].text.trim();
                String grading = asmCells[11].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  '<br>',
                );

                asmNames.add(cat); // Đưa tên bài thi vào mảng tóm tắt

                asmMd += "### $cat ($weight)\n";
                if (duration.isNotEmpty)
                  asmMd += "- **Thời gian:** $duration\n";
                if (grading.isNotEmpty)
                  asmMd += "- **Hướng dẫn/Tiêu chí:** $grading\n";
                asmMd += "\n";
              }
            }
          }
          sub['assessments'] = asmMd.isNotEmpty
              ? asmMd
              : "_Không có dữ liệu_\n";
          sub['asmList'] = asmNames.isNotEmpty
              ? asmNames.join(', ')
              : "Không có";

          // 4. CÀO BẢNG CONSTRUCTIVIST QUESTIONS
          var cqTable = sylDetailDoc.querySelector('#gvCQ');
          String cqsMd = "";
          if (cqTable != null) {
            var cqRows = cqTable.querySelectorAll('tbody tr');
            for (var cqRow in cqRows) {
              var cqCells = cqRow.querySelectorAll('td');
              if (cqCells.length >= 4) {
                String session = cqCells[1].text.trim();
                String name = cqCells[2].text.trim();
                String desc = cqCells[3].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  ' ',
                );
                cqsMd += "- **Slot $session - $name:** $desc\n";
              }
            }
          }
          sub['cqs'] = cqsMd.isNotEmpty ? cqsMd : "_Không có dữ liệu_\n";

          // 5. CÀO BẢNG SCHEDULE VÀ ĐẾM SỐ SLOT
          var scheduleTable = sylDetailDoc.querySelector('#gvSchedule');
          int slotCount = 0; // Biến đếm tổng số slot
          if (scheduleTable != null) {
            String scheduleMd = "";
            var sRows = scheduleTable.querySelectorAll('tbody tr');

            for (var sRow in sRows) {
              var sCells = sRow.querySelectorAll('td');
              if (sCells.length >= 8) {
                slotCount++; // Tăng biến đếm mỗi khi đọc 1 slot
                String slot = sCells[0].text.trim();
                String topic = sCells[1].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  '<br>',
                );
                String materials = sCells[5].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  '<br>',
                );
                String tasks = sCells[7].text.trim().replaceAll(
                  RegExp(r'\r\n|\n|\r'),
                  '<br>',
                );

                scheduleMd += "### Slot $slot\n";
                scheduleMd += "- **Topic:** $topic\n";
                if (materials.isNotEmpty)
                  scheduleMd += "- **Materials:** $materials\n";
                if (tasks.isNotEmpty) scheduleMd += "- **Tasks:** $tasks\n";
                scheduleMd += "\n";
              }
            }
            sub['schedule'] = scheduleMd.isNotEmpty
                ? scheduleMd
                : "_Không có lịch trình chi tiết_\n";
            sub['totalSlots'] = slotCount;
          } else {
            sub['schedule'] =
                "_Môn này chưa có lịch trình học cụ thể trên FLM._\n";
            sub['totalSlots'] = 0;
          }
        } else {
          sub['schedule'] = "_Chưa có Syllabus cho môn này._\n";
          sub['totalSlots'] = 0;
        }
      } catch (e) {
        sub['schedule'] = "_Lỗi khi tải chi tiết đề cương._\n";
        sub['totalSlots'] = 0;
      }
    }

    return semesters.where((s) => (s['mon'] as List).isNotEmpty).toList();
  }
}
