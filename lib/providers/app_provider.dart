import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/constants.dart';
import '../core/flm_scraper.dart';

class TaskItem {
  final String fileName;
  final String content;
  final DateTime dueDate;
  final bool isDone;
  final String originalLine;

  TaskItem({
    required this.fileName,
    required this.content,
    required this.dueDate,
    required this.isDone,
    required this.originalLine,
  });
}

class AppProvider extends ChangeNotifier {
  Map<String, List<String>> tagFileMap = {};
  Map<String, List<TaskItem>> fileTasksMap = {};
  Set<String> vectorizedFiles = {};

  // PHÂN LOẠI FILE RÕ RÀNG
  Set<String> flmFiles = {};
  Set<String> userFiles = {};

  String statusMessage = "System is starting...";
  bool isScanning = false;
  List<Map<String, String>> chatHistory = [];
  bool isChatting = false;
  bool isChatWindowOpen = false;

  List<String> apiKeys = [];
  String get apiKey => apiKeys.isNotEmpty ? apiKeys.first : "";

  List<String> embeddingModels = [];
  List<String> chatModels = [];
  int _currentKeyIndex = 0;
  int _currentEmbModelIndex = 0;
  int _currentChatModelIndex = 0;

  String vaultPath = "";
  String flmCookie = "";
  String flmCurriculumCode = "";
  List<String> _flmHistory = [];

  List<String> get flmHistory {
    if (vaultPath.isEmpty) return [];
    return _flmHistory.where((code) {
      return Directory("$vaultPath${Platform.pathSeparator}$code").existsSync();
    }).toList();
  }

  Map<String, dynamic> activeSyllabus = {};

  String currentMajor = "Software Engineering";
  String currentTrack = "ReactJS Track";
  double learningProgress = 0.0;

  int maxSemestersToScrape = 2;

  late final int maxRetries;
  late final int retryDelaySeconds;
  late final int debounceMs;

  StreamSubscription? _directoryWatcher;
  Timer? _debounceTimer;
  Database? _database;

  AppProvider() {
    maxRetries = int.tryParse(dotenv.env['MAX_RETRIES'] ?? '3') ?? 3;
    retryDelaySeconds = int.tryParse(dotenv.env['RETRY_DELAY_SEC'] ?? '5') ?? 5;
    debounceMs = int.tryParse(dotenv.env['DEBOUNCE_MS'] ?? '2000') ?? 2000;
    _initializeSystem();
  }

  int checkSubjectStatus(String rawCode) {
    String codeUpper = rawCode.toUpperCase();
    String safeCode = codeUpper.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    List<String> files = tagFileMap[codeUpper] ?? tagFileMap[safeCode] ?? [];
    if (files.isEmpty) return 0;

    bool isVectorized = files.any(
      (fileName) => vectorizedFiles.contains(fileName),
    );
    if (isVectorized) return 2;

    return 1;
  }

  void toggleChatWindow() {
    isChatWindowOpen = !isChatWindowOpen;
    notifyListeners();
  }

  Future<void> _initializeSystem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String envKeys = dotenv.env['API_KEYS'] ?? dotenv.env['API_KEY'] ?? "";
    if (envKeys.isNotEmpty) {
      apiKeys = envKeys.split(',').map((e) => e.trim()).toList();
    } else {
      String savedKey = prefs.getString('apiKey') ?? "";
      if (savedKey.isNotEmpty) apiKeys = [savedKey];
    }

    String envEmb =
        dotenv.env['EMBEDDING_MODELS'] ??
        dotenv.env['EMBEDDING_MODEL'] ??
        "gemini-embedding-001";
    embeddingModels = envEmb.split(',').map((e) => e.trim()).toList();

    String envChat =
        dotenv.env['CHAT_MODELS'] ??
        dotenv.env['CHAT_MODEL'] ??
        "gemini-3.5-flash-lite";
    chatModels = envChat.split(',').map((e) => e.trim()).toList();

    vaultPath = prefs.getString('vaultPath') ?? "";
    flmCookie = prefs.getString('flmCookie') ?? "";
    flmCurriculumCode = prefs.getString('flmCurriculumCode') ?? "";
    _flmHistory = prefs.getStringList('flmHistory') ?? [];

    String? savedSyllabus = prefs.getString('custom_syllabus');
    if (savedSyllabus != null) {
      try {
        activeSyllabus = jsonDecode(savedSyllabus);
      } catch (e) {
        activeSyllabus = jsonDecode(jsonEncode(defaultSyllabus));
      }
    } else {
      activeSyllabus = jsonDecode(jsonEncode(defaultSyllabus));
    }

    String savedMajor =
        prefs.getString('currentMajor') ?? "Software Engineering";
    String savedTrack = prefs.getString('currentTrack') ?? "ReactJS Track";

    if (activeSyllabus.containsKey(savedMajor)) {
      currentMajor = savedMajor;
    } else if (activeSyllabus.isNotEmpty) {
      currentMajor = activeSyllabus.keys.first;
    }

    Map<String, dynamic> trackMap =
        activeSyllabus[currentMajor] as Map<String, dynamic>;
    if (trackMap.containsKey(savedTrack)) {
      currentTrack = savedTrack;
    } else if (trackMap.isNotEmpty) {
      currentTrack = trackMap.keys.first;
    }

    await _initializeDatabase();
    if (vaultPath.isNotEmpty) {
      await scanObsidianVault();
      _startRealTimeListener();
    } else {
      statusMessage = "Vui lòng cài đặt đường dẫn thư mục Vault.";
      notifyListeners();
    }
  }

  bool _rotateKeyOrModel({bool isChat = false}) {
    if (_currentKeyIndex < apiKeys.length - 1) {
      _currentKeyIndex++;
      return true;
    }
    _currentKeyIndex = 0;
    if (isChat) {
      if (_currentChatModelIndex < chatModels.length - 1) {
        _currentChatModelIndex++;
        return true;
      }
    } else {
      if (_currentEmbModelIndex < embeddingModels.length - 1) {
        _currentEmbModelIndex++;
        return true;
      }
    }
    return false;
  }

  Future<void> hardResetDatabase() async {
    if (_database != null) {
      isScanning = true;
      statusMessage = "Đang dọn dẹp toàn bộ bộ nhớ AI...";
      notifyListeners();

      await _database!.delete('knowledge');
      await _database!.delete('file_tracker');

      vectorizedFiles.clear();
      _calculateProgress();

      isScanning = false;
      statusMessage = "Đã dọn sạch não AI! Tất cả môn học đã trở về màu Cam. Hãy bấm SYNC VAULT.";
      notifyListeners();
    }
  }

  Future<void> saveFlmHistory(String code) async {
    String cleanCode = code.trim().toUpperCase();
    if (!_flmHistory.contains(cleanCode)) {
      _flmHistory.add(cleanCode);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('flmHistory', _flmHistory);
      notifyListeners();
    }
  }

  Future<void> loadLocalCurriculum(String code) async {
    if (activeSyllabus.containsKey(code)) {
      if (!Directory("$vaultPath${Platform.pathSeparator}$code").existsSync()) {
        statusMessage =
            "CẢNH BÁO: Thư mục '$code' đã bị xóa. Hãy tải lại từ Web!";
        notifyListeners();
        return;
      }

      currentMajor = code;
      Map<String, dynamic> trackMap =
          activeSyllabus[currentMajor] as Map<String, dynamic>;
      currentTrack = trackMap.keys.first;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentMajor', currentMajor);
      await prefs.setString('currentTrack', currentTrack);

      _calculateProgress();
      statusMessage = "Đã load dữ liệu $code từ máy cục bộ.";
      notifyListeners();
    }
  }

  Future<void> saveFlmCookie(String cookie) async {
    flmCookie = cookie.trim();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('flmCookie', flmCookie);
    notifyListeners();
  }

  Future<void> startFlmScraping(String code) async {
    if (vaultPath.isEmpty) {
      statusMessage = "LỖI: Bạn chưa cài đặt đường dẫn Vault!";
      notifyListeners();
      return;
    }

    flmCurriculumCode = code.trim().toUpperCase();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('flmCurriculumCode', flmCurriculumCode);

    isScanning = true;
    statusMessage = "Đang kết nối vào hệ thống bảo mật FLM...";
    notifyListeners();

    try {
      List<Map<String, dynamic>> scrapedData =
          await FLMScraper.fetchAndParseCurriculum(
            flmCurriculumCode,
            flmCookie,
            maxSemestersToScrape,
            (progressMsg) {
              statusMessage = progressMsg;
              notifyListeners();
            },
          );

      statusMessage =
          "Cào data thành công! Đang rải file Markdown vào Vault...";
      notifyListeners();

      Directory baseDir = Directory(vaultPath);
      Directory curriculumDir = Directory(
        "${baseDir.path}${Platform.pathSeparator}$flmCurriculumCode",
      );
      if (!await curriculumDir.exists()) {
        await curriculumDir.create(recursive: true);
      }

      for (var semester in scrapedData) {
        String semesterName = semester['ky'];
        List<dynamic> subjects = semester['mon'];

        Directory semesterDir = Directory(
          "${curriculumDir.path}${Platform.pathSeparator}$semesterName",
        );
        if (!await semesterDir.exists())
          await semesterDir.create(recursive: true);

        for (var subject in subjects) {
          String originalCode = subject['ma'];
          String subjectName = subject['ten'];

          String materials = subject['materials'] ?? "_Không có dữ liệu_\n";
          String los = subject['los'] ?? "_Không có dữ liệu_\n";
          String cqs = subject['cqs'] ?? "_Không có dữ liệu_\n";
          String assessments = subject['assessments'] ?? "_Không có dữ liệu_\n";
          String schedule = subject['schedule'] ?? "_Không có dữ liệu_\n";

          String totalSlots = subject['totalSlots']?.toString() ?? "0";
          String asmList = subject['asmList'] ?? "Không có";

          String safeCode = originalCode.replaceAll(
            RegExp(r'[<>:"/\\|?*]'),
            '_',
          );
          File mdFile = File(
            "${semesterDir.path}${Platform.pathSeparator}$safeCode.md",
          );

          if (!await mdFile.exists()) {
            // ĐÃ GẮN NHÃN #FLM ĐỂ LÀM DẤU
            String template =
                '''# $originalCode - $subjectName
> Dữ liệu được bóc tách tự động từ hệ thống FPTU FLM ($flmCurriculumCode).
#$safeCode #FLM

## 1. Thông tin tổng quan môn học
- **Mã môn:** $originalCode
- **Tên môn:** $subjectName
- **Học kỳ:** $semesterName
- **Tổng số Slot:** $totalSlots
- **Các bài đánh giá (Assessments):** $asmList

## 2. Mục tiêu đầu ra (Learning Outcomes)
$los
## 3. Tài liệu học tập (Materials)
$materials
## 4. Đánh giá và Điểm số (Assessments)
$assessments
## 5. Câu hỏi định hướng (Constructivist Questions)
$cqs
## 6. Đề cương chi tiết (Syllabus Schedule)
$schedule
---
## 7. Ghi chú cá nhân trên lớp
''';
            await mdFile.writeAsString(template);
          }
        }
      }

      activeSyllabus[flmCurriculumCode] = {"Lộ trình tự động": scrapedData};
      currentMajor = flmCurriculumCode;
      currentTrack = "Lộ trình tự động";

      await _saveSyllabusToDisk();
      await prefs.setString('currentMajor', currentMajor);
      await prefs.setString('currentTrack', currentTrack);

      await saveFlmHistory(flmCurriculumCode);

      statusMessage =
          "Rải file hoàn tất! Bắt đầu đồng bộ Vector lên Gemini AI...";
      notifyListeners();

      await scanObsidianVault();
    } catch (e) {
      statusMessage = "Lỗi: $e";
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _saveSyllabusToDisk() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_syllabus', jsonEncode(activeSyllabus));
  }

  Future<void> createNewMajor(String majorName) async {
    String cleanName = majorName.trim();
    if (cleanName.isEmpty) return;

    if (!activeSyllabus.containsKey(cleanName)) {
      activeSyllabus[cleanName] = <String, dynamic>{
        "Unassigned Track": <dynamic>[],
      };
    }

    currentMajor = cleanName;
    currentTrack = "Unassigned Track";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentMajor', currentMajor);
    await prefs.setString('currentTrack', currentTrack);

    await _saveSyllabusToDisk();
    _calculateProgress();
    notifyListeners();
  }

  Future<void> createNewTrack(String trackName) async {
    String cleanName = trackName.trim();
    if (cleanName.isEmpty) return;

    if (!activeSyllabus.containsKey(currentMajor)) {
      activeSyllabus[currentMajor] = <String, dynamic>{};
    }

    Map<String, dynamic> trackMap =
        activeSyllabus[currentMajor] as Map<String, dynamic>;

    if (!trackMap.containsKey(cleanName)) {
      trackMap[cleanName] = <dynamic>[];
    }

    currentTrack = cleanName;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTrack', currentTrack);

    await _saveSyllabusToDisk();
    _calculateProgress();
    notifyListeners();
  }

  Future<void> addNewSemester(String semesterName) async {
    String cleanSemester = semesterName.trim();
    if (cleanSemester.isEmpty) return;

    var syllabusPath =
        activeSyllabus[currentMajor][currentTrack] as List<dynamic>;
    syllabusPath.add({"ky": cleanSemester, "mon": <dynamic>[]});

    await _saveSyllabusToDisk();
    _calculateProgress();
    notifyListeners();
  }

  Future<void> addSubjectToSemester(
    int semesterIndex,
    String subjectCode,
    String subjectName,
  ) async {
    var syllabusPath =
        activeSyllabus[currentMajor][currentTrack] as List<dynamic>;
    if (semesterIndex < 0 || semesterIndex >= syllabusPath.length) return;

    var subjectList = syllabusPath[semesterIndex]['mon'] as List<dynamic>;
    subjectList.add({
      "ma": subjectCode.trim().toUpperCase(),
      "ten": subjectName.trim(),
    });

    await _saveSyllabusToDisk();
    _calculateProgress();
    notifyListeners();
  }

  List<String> getAllFileNames() {
    Set<String> allFiles = {};
    for (var list in tagFileMap.values) {
      allFiles.addAll(list);
    }
    return allFiles.toList();
  }

  List<TaskItem> getAllTasks() {
    List<TaskItem> list = [];
    for (var tasks in fileTasksMap.values) {
      list.addAll(tasks);
    }
    list.sort((a, b) {
      if (a.isDone && !b.isDone) return 1;
      if (!a.isDone && b.isDone) return -1;
      return a.dueDate.compareTo(b.dueDate);
    });
    return list;
  }

  Future<void> toggleTaskStatus(TaskItem task) async {
    if (vaultPath.isEmpty) return;

    Directory vaultDir = Directory(vaultPath);
    List<FileSystemEntity> fileList = vaultDir.listSync(recursive: true);

    File? targetFile;
    for (var entity in fileList) {
      if (entity is File && entity.path.endsWith("${task.fileName}.md")) {
        targetFile = entity;
        break;
      }
    }

    if (targetFile == null || !await targetFile.exists()) return;

    String content = await targetFile.readAsString();
    String newLine;

    if (task.isDone) {
      newLine = task.originalLine.replaceFirst(RegExp(r'- \[[xX]\]'), '- [ ]');
    } else {
      newLine = task.originalLine.replaceFirst('- [ ]', '- [x]');
    }

    content = content.replaceFirst(task.originalLine, newLine);

    try {
      await targetFile.writeAsString(content);
      await scanObsidianVault();
    } catch (e) {
      statusMessage = "Error updating task: $e";
      notifyListeners();
    }
  }

  Future<String> readFileContent(String fileName) async {
    if (vaultPath.isEmpty) return "";

    Directory vaultDir = Directory(vaultPath);
    List<FileSystemEntity> fileList = vaultDir.listSync(recursive: true);

    for (var entity in fileList) {
      if (entity is File && entity.path.endsWith("$fileName.md")) {
        return await entity.readAsString();
      }
    }
    return "";
  }

  Future<void> saveNote(
    String fileName,
    String content,
    String subjectCode,
  ) async {
    if (fileName.trim().isEmpty || content.trim().isEmpty || vaultPath.isEmpty)
      return;

    String cleanFileName = fileName.replaceAll(".md", "").trim();
    cleanFileName = cleanFileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    Directory vaultDir = Directory(vaultPath);
    List<FileSystemEntity> fileList = vaultDir.listSync(recursive: true);

    File targetFile = File(
      "$vaultPath${Platform.pathSeparator}$cleanFileName.md",
    );
    for (var entity in fileList) {
      if (entity is File && entity.path.endsWith("$cleanFileName.md")) {
        targetFile = entity;
        break;
      }
    }

    String contentToSave = content;

    // Tự động dán thêm Tag nếu User quên
    if (!contentToSave.contains("#USER_NOTE")) {
      contentToSave = "#USER_NOTE\n" + contentToSave;
    }

    if (subjectCode.isNotEmpty && !contentToSave.contains("#$subjectCode")) {
      contentToSave = "#$subjectCode\n\n$contentToSave";
    }

    try {
      await targetFile.writeAsString(contentToSave);
      statusMessage = "Saved file: $cleanFileName.md";
      notifyListeners();
    } catch (e) {
      statusMessage = "Error saving file: $e";
      notifyListeners();
    }
  }

  Future<void> _initializeDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbName = dotenv.env['DB_NAME'] ?? 'fptu_second_brain.db';
    final dbPath = p.join(appDocDir.path, dbName);

    _database = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE knowledge (id INTEGER PRIMARY KEY AUTOINCREMENT, file_name TEXT, content TEXT, vector TEXT)',
          );
          await db.execute(
            'CREATE TABLE file_tracker (file_name TEXT PRIMARY KEY, last_modified INTEGER)',
          );
        },
      ),
    );
    await _database!.execute(
      'CREATE TABLE IF NOT EXISTS file_tracker (file_name TEXT PRIMARY KEY, last_modified INTEGER)',
    );
  }

  void changeMajorAndTrack(String newMajor, String newTrack) async {
    currentMajor = newMajor;
    currentTrack = newTrack;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentMajor', currentMajor);
    await prefs.setString('currentTrack', currentTrack);

    _calculateProgress();
    notifyListeners();
  }

  void _calculateProgress() {
    if (!activeSyllabus.containsKey(currentMajor) ||
        !(activeSyllabus[currentMajor] as Map).containsKey(currentTrack)) {
      learningProgress = 0.0;
      return;
    }

    var syllabusPath =
        activeSyllabus[currentMajor][currentTrack] as List<dynamic>;
    int totalSubjects = 0;
    int completedSubjects = 0;

    for (var semester in syllabusPath) {
      for (var subject in (semester['mon'] as List)) {
        totalSubjects++;
        String rawCode = subject['ma'].toString().toUpperCase();
        String safeCode = rawCode.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

        if (tagFileMap.containsKey(safeCode) &&
            tagFileMap[safeCode]!.isNotEmpty) {
          completedSubjects++;
        }
      }
    }

    learningProgress = (totalSubjects == 0)
        ? 0.0
        : (completedSubjects / totalSubjects);
  }

  Future<void> scanObsidianVault() async {
    if (vaultPath.isEmpty || apiKeys.isEmpty || embeddingModels.isEmpty) {
      statusMessage =
          "Vui lòng cấu hình Vault Path và cấu hình .env (Key & Model).";
      notifyListeners();
      return;
    }

    isScanning = true;
    notifyListeners();

    Directory vaultDir = Directory(vaultPath);
    if (!vaultDir.existsSync()) {
      isScanning = false;
      statusMessage = "Lỗi: Không tìm thấy Vault tại $vaultPath";
      notifyListeners();
      return;
    }

    RegExp tagRegex = RegExp(r'#([a-zA-Z0-9_]+)');
    RegExp taskRegex = RegExp(
      r'^[ \t]*- \[(x|X| )\] (.*?)@due\s*(\d{1,2})/(\d{1,2})/(\d{4}).*$',
      multiLine: true,
    );

    List<FileSystemEntity> fileList = vaultDir.listSync(recursive: true);

    tagFileMap.clear();
    fileTasksMap.clear();
    flmFiles.clear();
    userFiles.clear();

    for (var file in fileList) {
      if (file is File && file.path.endsWith(".md")) {
        String content = file.readAsStringSync();
        String originalFileName = file.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.md', '');

        // LOGIC PHÂN LOẠI FILE CHÍNH XÁC 100%
        bool isFLM =
            content.contains('> Dữ liệu được bóc tách tự động') ||
            content.contains('#FLM');

        if (isFLM) {
          flmFiles.add(originalFileName);
          // File FLM: Cấm quét tag rác, chỉ lấy đúng tên môn học làm Tag
          String safeCode = originalFileName
              .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
              .toUpperCase();
          if (!tagFileMap.containsKey(safeCode)) tagFileMap[safeCode] = [];
          if (!tagFileMap[safeCode]!.contains(originalFileName)) {
            tagFileMap[safeCode]!.add(originalFileName);
          }
        } else {
          userFiles.add(originalFileName);
          // File User: Cho phép quét mọi tag (Ví dụ: #CEA201) để gom nhóm
          Iterable<Match> tagMatches = tagRegex.allMatches(content);
          for (var match in tagMatches) {
            String tagName = match.group(1)!.toUpperCase();
            if (!tagFileMap.containsKey(tagName)) tagFileMap[tagName] = [];
            if (!tagFileMap[tagName]!.contains(originalFileName)) {
              tagFileMap[tagName]!.add(originalFileName);
            }
          }
        }

        List<TaskItem> fileTasks = [];
        Iterable<Match> taskMatches = taskRegex.allMatches(content);
        for (var match in taskMatches) {
          String originalLine = match.group(0)!;
          bool isDone = match.group(1)?.toLowerCase() == 'x';
          String taskContent = match.group(2)?.trim() ?? '';
          int d = int.parse(match.group(3)!);
          int m = int.parse(match.group(4)!);
          int y = int.parse(match.group(5)!);

          fileTasks.add(
            TaskItem(
              fileName: originalFileName,
              content: taskContent,
              dueDate: DateTime(y, m, d),
              isDone: isDone,
              originalLine: originalLine,
            ),
          );
        }
        if (fileTasks.isNotEmpty) {
          fileTasksMap[originalFileName] = fileTasks;
        }
      }
    }

    activeSyllabus.forEach((major, trackMap) {
      (trackMap as Map).forEach((track, semesterList) {
        for (var semester in (semesterList as List)) {
          for (var subject in (semester['mon'] as List)) {
            String rawCode = subject['ma'].toString().toUpperCase();
            String safeCode = rawCode.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

            if (rawCode != safeCode && tagFileMap.containsKey(safeCode)) {
              tagFileMap[rawCode] = tagFileMap[safeCode]!;
            }
          }
        }
      });
    });

    var dbRecordsInit = await _database!.query(
      'knowledge',
      columns: ['file_name'],
      distinct: true,
    );
    vectorizedFiles = dbRecordsInit
        .map((e) => e['file_name'] as String)
        .toSet();

    _calculateProgress();
    statusMessage =
        "Bắt đầu nhúng dữ liệu bằng Model: ${embeddingModels[_currentEmbModelIndex]}...";
    notifyListeners();

    int updatedFilesCount = 0;
    int skippedFilesCount = 0;

    for (var file in fileList) {
      if (file is File && file.path.endsWith(".md")) {
        String originalFileName = file.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.md', '');
        int currentModifiedTime = file
            .lastModifiedSync()
            .millisecondsSinceEpoch;

        var dbRecord = await _database!.query(
          'file_tracker',
          where: 'file_name = ?',
          whereArgs: [originalFileName],
        );

        bool needsUpdate =
            dbRecord.isEmpty ||
            (currentModifiedTime > (dbRecord.first['last_modified'] as int));

        if (!needsUpdate) {
          skippedFilesCount++;
          continue;
        }

        vectorizedFiles.remove(originalFileName);
        notifyListeners();

        String content = file.readAsStringSync();
        await _database!.delete(
          'knowledge',
          where: 'file_name = ?',
          whereArgs: [originalFileName],
        );

        List<String> chunks = content.split(RegExp(r'\n\n+'));
        bool hasAtLeastOneSuccess = false;

        for (String chunk in chunks) {
          if (chunk.trim().isEmpty) continue;
          bool chunkSuccess = false;
          int chunkAttempt = 0;

          while (chunkAttempt < maxRetries && !chunkSuccess) {
            try {
              chunkAttempt++;
              String activeKey = apiKeys[_currentKeyIndex];
              String activeModel = embeddingModels[_currentEmbModelIndex];

              final embModel = GenerativeModel(
                model: activeModel,
                apiKey: activeKey,
              );

              String enrichedChunk =
                  "[Ngữ cảnh thuộc môn học: $originalFileName]\n${chunk.trim()}";

              final embRes = await embModel.embedContent(
                Content.text(enrichedChunk),
              );

              await _database!.insert('knowledge', {
                'file_name': originalFileName,
                'content': enrichedChunk,
                'vector': jsonEncode(embRes.embedding.values),
              });
              chunkSuccess = true;
              hasAtLeastOneSuccess = true;
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              String errStr = e.toString().toLowerCase();
              if (errStr.contains('quota') || errStr.contains('429')) {
                bool rotated = _rotateKeyOrModel(isChat: false);

                if (rotated) {
                  statusMessage =
                      "Đổi sang Key ${_currentKeyIndex + 1} / Model ${embeddingModels[_currentEmbModelIndex]}...";
                  notifyListeners();
                  chunkAttempt--;
                } else {
                  isScanning = false;
                  statusMessage =
                      "Đã cạn kiệt toàn bộ hạn mức. Hãy quay lại vào ngày mai!";
                  notifyListeners();
                  return;
                }
              } else if (chunkAttempt >= maxRetries) {
                isScanning = false;
                statusMessage = "Vector Error:\n$e";
                notifyListeners();
                return;
              } else {
                await Future.delayed(Duration(seconds: retryDelaySeconds));
              }
            }
          }
        }
        await _database!.insert('file_tracker', {
          'file_name': originalFileName,
          'last_modified': currentModifiedTime,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        if (hasAtLeastOneSuccess) {
          vectorizedFiles.add(originalFileName);
        }
        notifyListeners();

        updatedFilesCount++;
      }
    }

    isScanning = false;
    statusMessage =
        "Đồng bộ hoàn tất: Cập nhật $updatedFilesCount môn (Bỏ qua $skippedFilesCount).";
    notifyListeners();
  }

  double calculateVectorDistance(List<double> vecA, List<double> vecB) {
    double dotProduct = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;
    if (apiKeys.isEmpty) {
      chatHistory.add({
        "role": "bot",
        "text": "Vui lòng cấu hình API_KEYS trong .env.",
      });
      notifyListeners();
      return;
    }

    String recentSubjectContext = "";
    int lookbackLimit = min(4, chatHistory.length);
    List<String> knownSubjects = tagFileMap.keys.toList();

    for (
      int i = chatHistory.length - 1;
      i >= chatHistory.length - lookbackLimit;
      i--
    ) {
      String pastMsg = (chatHistory[i]['text'] ?? "").toUpperCase();
      for (String sub in knownSubjects) {
        if (pastMsg.contains(sub)) {
          recentSubjectContext = sub;
          break;
        }
      }
      if (recentSubjectContext.isNotEmpty) break;
    }

    String embeddingQuery = message;
    bool currentMsgHasSubject = false;

    for (String sub in knownSubjects) {
      if (message.toUpperCase().contains(sub)) {
        currentMsgHasSubject = true;
        break;
      }
    }

    if (recentSubjectContext.isNotEmpty && !currentMsgHasSubject) {
      embeddingQuery = "$message $recentSubjectContext";
    }

    chatHistory.add({"role": "user", "text": message});
    if (!isChatWindowOpen) isChatWindowOpen = true;

    isChatting = true;
    notifyListeners();

    bool success = false;
    int attempt = 0;

    while (attempt < maxRetries && !success) {
      try {
        attempt++;
        String activeKey = apiKeys[_currentKeyIndex];
        String activeEmbModel = embeddingModels[_currentEmbModelIndex];
        String activeChatModel = chatModels[_currentChatModelIndex];

        final embModel = GenerativeModel(
          model: activeEmbModel,
          apiKey: activeKey,
        );

        List<double> qVec = (await embModel.embedContent(
          Content.text(embeddingQuery),
        )).embedding.values;

        List<Map<String, dynamic>> records = await _database!.query(
          'knowledge',
        );
        List<Map<String, dynamic>> scoredChunks = [];

        for (var record in records) {
          double score = calculateVectorDistance(
            qVec,
            jsonDecode(record['vector']).cast<double>(),
          );
          scoredChunks.add({
            'file_name': record['file_name'],
            'content': record['content'],
            'score': score,
          });
        }
        scoredChunks.sort((a, b) => b['score'].compareTo(a['score']));

        String ragContext = "";
        int topK = min(30, scoredChunks.length);
        for (int i = 0; i < topK; i++) {
          ragContext +=
              "Source: [${scoredChunks[i]['file_name']}]\nDetails: ${scoredChunks[i]['content']}\n\n";
        }

        if (ragContext.isEmpty) {
          chatHistory.add({
            "role": "bot",
            "text": "Không tìm thấy dữ liệu trong Vault.",
          });
          success = true;
          break;
        }

        int historyLimit = min(6, chatHistory.length - 1);
        String conversationHistory = "";
        if (historyLimit > 0) {
          conversationHistory = "RECENT CONVERSATION HISTORY:\n";
          for (
            int i = chatHistory.length - 1 - historyLimit;
            i < chatHistory.length - 1;
            i++
          ) {
            String role = chatHistory[i]['role'] == 'user'
                ? 'User'
                : 'AI Tutor';
            conversationHistory += "$role: ${chatHistory[i]['text']}\n";
          }
        }

        String curriculumOverview =
            "CẤU TRÚC CHƯƠNG TRÌNH HỌC HIỆN TẠI (LUÔN ĐÚNG):\n";
        if (activeSyllabus.containsKey(currentMajor) &&
            (activeSyllabus[currentMajor] as Map).containsKey(currentTrack)) {
          var syllabusPath =
              activeSyllabus[currentMajor][currentTrack] as List<dynamic>;
          for (var semester in syllabusPath) {
            curriculumOverview += "- ${semester['ky']}: ";
            var subjects = semester['mon'] as List<dynamic>;
            var subNames = subjects
                .map(
                  (s) => s['ma'].toString() + " (" + s['ten'].toString() + ")",
                )
                .join(", ");
            curriculumOverview += "$subNames\n";
          }
        }

        final chatModel = GenerativeModel(
          model: activeChatModel,
          apiKey: activeKey,
        );
        String prompt =
            '''
You are an AI Tutor for FPTU Second Brain.

$curriculumOverview

$conversationHistory

EXTRACTED KNOWLEDGE (RAG CONTEXT):
<CONTEXT>
$ragContext
</CONTEXT>

TASK:
1. Use the RECENT CONVERSATION HISTORY to understand the context of the user's latest query.
2. Answer the latest query: "$message" based STRICTLY on the <CONTEXT> section and the "CẤU TRÚC CHƯƠNG TRÌNH HỌC HIỆN TẠI".
3. If the <CONTEXT> does not contain the answer, explicitly state that the information is not in the notes. Do not invent information.
4. Format your response clearly using Markdown.
''';
        final response = await chatModel.generateContent([
          Content.text(prompt),
        ]);
        chatHistory.add({"role": "bot", "text": response.text ?? "Error."});
        success = true;
      } catch (e) {
        String errStr = e.toString().toLowerCase();
        if (errStr.contains("429") || errStr.contains("quota")) {
          bool rotated = _rotateKeyOrModel(isChat: true);
          if (rotated) {
            attempt--;
          } else {
            chatHistory.add({
              "role": "bot",
              "text": "⚠️ Toàn bộ Key và Model đều đã hết hạn mức. Vui lòng chờ 24h.",
            });
            break;
          }
        } else if (attempt >= maxRetries) {
          chatHistory.add({"role": "bot", "text": "Server Error: $e"});
        } else {
          await Future.delayed(Duration(seconds: retryDelaySeconds * attempt));
        }
      }
    }
    isChatting = false;
    notifyListeners();
  }

  void _startRealTimeListener() {
    if (vaultPath.isEmpty) return;
    Directory vaultDir = Directory(vaultPath);
    if (vaultDir.existsSync()) {
      _directoryWatcher = vaultDir.watch(events: FileSystemEvent.all).listen((
        event,
      ) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(Duration(milliseconds: debounceMs), () {
          statusMessage = "Changes detected. Syncing...";
          notifyListeners();
          scanObsidianVault();
        });
      });
    }
  }

  Future<void> openObsidianFile(String fileName) async {
    if (vaultPath.isEmpty) return;
    String vaultName = vaultPath.split(Platform.pathSeparator).last;
    final Uri url = Uri.parse(
      "obsidian://open?vault=${Uri.encodeComponent(vaultName)}&file=${Uri.encodeComponent(fileName)}",
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> saveSettings(String newPath, String newKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vaultPath', newPath);
    await prefs.setString('apiKey', newKey);
    if (newKey.isNotEmpty) apiKeys = [newKey];
    vaultPath = newPath;
    _directoryWatcher?.cancel();
    if (vaultPath.isNotEmpty && apiKeys.isNotEmpty) {
      await scanObsidianVault();
      _startRealTimeListener();
    }
  }

  @override
  void dispose() {
    _directoryWatcher?.cancel();
    _debounceTimer?.cancel();
    _database?.close();
    super.dispose();
  }
}
