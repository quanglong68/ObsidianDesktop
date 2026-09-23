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

  String statusMessage = "System is starting...";
  bool isScanning = false;
  List<Map<String, String>> chatHistory = [];
  bool isChatting = false;
  bool isChatWindowOpen = false;

  String apiKey = "";
  String vaultPath = "";

  Map<String, dynamic> activeSyllabus = {};

  String currentMajor = "Software Engineering";
  String currentTrack = "ReactJS Track";
  double learningProgress = 0.0;

  late final int maxRetries;
  late final int retryDelaySeconds;
  late final int debounceMs;

  StreamSubscription? _directoryWatcher;
  Timer? _debounceTimer;
  Database? _database;

  AppProvider() {
    maxRetries = int.tryParse(dotenv.env['MAX_RETRIES'] ?? '3') ?? 3;
    retryDelaySeconds = int.tryParse(dotenv.env['RETRY_DELAY_SEC'] ?? '2') ?? 2;
    debounceMs = int.tryParse(dotenv.env['DEBOUNCE_MS'] ?? '2000') ?? 2000;
    _initializeSystem();
  }

  void toggleChatWindow() {
    isChatWindowOpen = !isChatWindowOpen;
    notifyListeners();
  }

  Future<void> _initializeSystem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    apiKey = prefs.getString('apiKey') ?? dotenv.env['API_KEY'] ?? "";
    vaultPath = prefs.getString('vaultPath') ?? "";

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
      statusMessage = "Please set Obsidian Vault Path in Settings.";
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
    String filePath = "$vaultPath${Platform.pathSeparator}${task.fileName}.md";
    File file = File(filePath);

    if (!await file.exists()) return;

    String content = await file.readAsString();
    String newLine;

    if (task.isDone) {
      newLine = task.originalLine.replaceFirst(RegExp(r'- \[[xX]\]'), '- [ ]');
    } else {
      newLine = task.originalLine.replaceFirst('- [ ]', '- [x]');
    }

    content = content.replaceFirst(task.originalLine, newLine);

    try {
      await file.writeAsString(content);
      await scanObsidianVault();
    } catch (e) {
      statusMessage = "Error updating task: $e";
      notifyListeners();
    }
  }

  Future<String> readFileContent(String fileName) async {
    if (vaultPath.isEmpty) return "";
    String filePath = "$vaultPath${Platform.pathSeparator}$fileName.md";
    File file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
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
    String filePath = "$vaultPath${Platform.pathSeparator}$cleanFileName.md";
    File file = File(filePath);

    String contentToSave = content;

    if (subjectCode.isNotEmpty && !contentToSave.contains("#$subjectCode")) {
      contentToSave = "#$subjectCode\n\n$contentToSave";
    }

    try {
      await file.writeAsString(contentToSave);
      statusMessage = "Saved file: $cleanFileName.md";
      notifyListeners();
    } catch (e) {
      statusMessage = "Error saving file: $e";
      notifyListeners();
    }
  }

  List<String> getPersonalTags() {
    Set<String> allKnownCodes = {};
    activeSyllabus.forEach((major, trackMap) {
      (trackMap as Map).forEach((track, semesterList) {
        for (var semester in (semesterList as List)) {
          for (var subject in (semester['mon'] as List)) {
            allKnownCodes.add(subject['ma'].toString().toUpperCase());
          }
        }
      });
    });

    List<String> orphans = [];
    for (String tag in tagFileMap.keys) {
      if (!allKnownCodes.contains(tag)) {
        orphans.add(tag);
      }
    }
    return orphans;
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
        String code = subject['ma'].toString().toUpperCase();
        if (tagFileMap.containsKey(code) && tagFileMap[code]!.isNotEmpty) {
          completedSubjects++;
        }
      }
    }

    learningProgress = (totalSubjects == 0)
        ? 0.0
        : (completedSubjects / totalSubjects);
  }

  Future<void> scanObsidianVault() async {
    if (vaultPath.isEmpty) {
      statusMessage = "Please set Obsidian Vault Path in Settings.";
      notifyListeners();
      return;
    }
    if (apiKey.isEmpty) {
      statusMessage = "Please set Gemini API Key in Settings or .env file.";
      notifyListeners();
      return;
    }

    isScanning = true;
    notifyListeners();

    Directory vaultDir = Directory(vaultPath);
    if (!vaultDir.existsSync()) {
      isScanning = false;
      statusMessage = "Error: Vault not found at $vaultPath";
      notifyListeners();
      return;
    }

    RegExp tagRegex = RegExp(r'#([a-zA-Z0-9_]+)');
    RegExp taskRegex = RegExp(
      r'^[ \t]*- \[(x|X| )\] (.*?)@due\s*(\d{1,2})/(\d{1,2})/(\d{4}).*$',
      multiLine: true,
    );

    List<FileSystemEntity> fileList = vaultDir.listSync(recursive: true);
    final embeddingModel = GenerativeModel(
      model: dotenv.env['EMBEDDING_MODEL'] ?? 'gemini-embedding-001',
      apiKey: apiKey,
    );

    int updatedFilesCount = 0;
    int skippedFilesCount = 0;

    tagFileMap.clear();
    fileTasksMap.clear();

    for (var file in fileList) {
      if (file is File && file.path.endsWith(".md")) {
        String content = file.readAsStringSync();
        String originalFileName = file.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.md', '');

        Iterable<Match> tagMatches = tagRegex.allMatches(content);
        for (var match in tagMatches) {
          String tagName = match.group(0)!.replaceAll('#', '').toUpperCase();
          if (!tagFileMap.containsKey(tagName)) tagFileMap[tagName] = [];
          if (!tagFileMap[tagName]!.contains(originalFileName)) {
            tagFileMap[tagName]!.add(originalFileName);
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

        await _database!.delete(
          'knowledge',
          where: 'file_name = ?',
          whereArgs: [originalFileName],
        );
        List<String> chunks = content.split(RegExp(r'\n\n+'));

        for (String chunk in chunks) {
          if (chunk.trim().isEmpty) continue;
          bool chunkSuccess = false;
          int chunkAttempt = 0;

          while (chunkAttempt < maxRetries && !chunkSuccess) {
            try {
              chunkAttempt++;
              final embRes = await embeddingModel.embedContent(
                Content.text(chunk),
              );
              await _database!.insert('knowledge', {
                'file_name': originalFileName,
                'content': chunk.trim(),
                'vector': jsonEncode(embRes.embedding.values),
              });
              chunkSuccess = true;
              await Future.delayed(const Duration(milliseconds: 300));
            } catch (e) {
              if (chunkAttempt == maxRetries) {
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
        updatedFilesCount++;
      }
    }

    isScanning = false;
    statusMessage =
        "Sync: Updated $updatedFilesCount files (Skipped $skippedFilesCount).";
    _calculateProgress();
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
    if (apiKey.isEmpty) {
      chatHistory.add({
        "role": "bot",
        "text": "Please configure your Gemini API Key in Settings first.",
      });
      notifyListeners();
      return;
    }

    chatHistory.add({"role": "user", "text": message});

    if (!isChatWindowOpen) isChatWindowOpen = true;

    isChatting = true;
    notifyListeners();

    bool success = false;
    int attempt = 0;
    String errorMessage = "";

    while (attempt < maxRetries && !success) {
      try {
        attempt++;
        final embModel = GenerativeModel(
          model: dotenv.env['EMBEDDING_MODEL'] ?? 'gemini-embedding-001',
          apiKey: apiKey,
        );
        List<double> qVec = (await embModel.embedContent(Content.text(message)))
            .embedding
            .values;
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
        int topK = min(10, scoredChunks.length);
        for (int i = 0; i < topK; i++) {
          ragContext +=
              "Source: [${scoredChunks[i]['file_name']}]\nDetails: ${scoredChunks[i]['content']}\n\n";
        }

        if (ragContext.isEmpty) {
          chatHistory.add({
            "role": "bot",
            "text": "No data found. Please add more notes or ensure your vault is synced.",
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

        final chatModel = GenerativeModel(
          model: dotenv.env['CHAT_MODEL'] ?? 'gemini-2.5-flash',
          apiKey: apiKey,
        );
        String prompt =
            '''
You are an AI Tutor for FPTU Second Brain.

$conversationHistory

EXTRACTED KNOWLEDGE (RAG CONTEXT):
<CONTEXT>
$ragContext
</CONTEXT>

TASK:
1. Use the RECENT CONVERSATION HISTORY to understand the context of the user's latest query.
2. Answer the latest query: "$message" based STRICTLY on the <CONTEXT> section.
3. If the <CONTEXT> does not contain the answer, explicitly state that the information is not in the notes. Do not invent information.
4. Format your response clearly using Markdown.
''';
        final response = await chatModel.generateContent([
          Content.text(prompt),
        ]);
        chatHistory.add({"role": "bot", "text": response.text ?? "Error."});
        success = true;
      } catch (e) {
        errorMessage = e.toString();
        if (errorMessage.contains("429") || errorMessage.contains("quota")) {
          chatHistory.add({
            "role": "bot",
            "text": "⚠️ Đã hết hạn mức hoặc gửi quá nhanh. Vui lòng chờ 10-15s rồi thử lại.",
          });
          break;
        }
        if (attempt == maxRetries) {
          chatHistory.add({
            "role": "bot",
            "text": "Server Error: $errorMessage",
          });
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
    apiKey = newKey;
    vaultPath = newPath;
    _directoryWatcher?.cancel();
    if (vaultPath.isNotEmpty && apiKey.isNotEmpty) {
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
