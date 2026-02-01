// Central state holder for board data: pagination, search, undo/redo commands, and task mutations.
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../data/task_repository.dart';
import '../data/database.dart';
import 'undo_redo_controller.dart';

const List<String> kStatuses = ['Todo', 'Doing', 'Done'];
const int kPageSize = 20;

class BoardController extends ChangeNotifier {
  BoardController({required this.repository, required this.history});

  final TaskRepository repository;
  final UndoRedoController history;

  final Map<String, List<Task>> _tasks = {
    for (final status in kStatuses) status: <Task>[],
  };
  final Map<String, int> _pages = {for (final status in kStatuses) status: 0};
  final Map<String, bool> _hasMore = {for (final status in kStatuses) status: true};
  final Map<String, bool> _loading = {for (final status in kStatuses) status: false};
  String _searchQuery = '';

  List<Task> tasksFor(String status) {
    // When a search query exists, filter the already-loaded page data in memory.
    final list = _tasks[status] ?? const [];
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((t) {
      final titleMatch = t.title.toLowerCase().contains(q);
      final emailMatch = t.contactEmail.toLowerCase().contains(q);
      return titleMatch || emailMatch;
    }).toList();
  }

  bool get isSearching => _searchQuery.isNotEmpty;
  String get searchQuery => _searchQuery;
  void setSearchQuery(String value) {
    // Search is applied on demand from UI; notify to rebuild filtered lists.
    _searchQuery = value;
    notifyListeners();
  }

  bool isLoading(String status) => _loading[status] ?? false;
  bool hasMore(String status) => _hasMore[status] ?? false;

  Future<void> initialize() async {
    // Initial paged load for each status column.
    for (final status in kStatuses) {
      await _loadPage(status, reset: true);
    }
    notifyListeners();
  }

  Future<void> loadMore(String status) async {
    if (isSearching) return;
    await _loadPage(status);
    notifyListeners();
  }

  Future<void> _loadPage(String status, {bool reset = false}) async {
    // Paginates tasks by status using limit/offset; updates hasMore flags.
    if (_loading[status] == true) return;
    if (!reset && _hasMore[status] == false) return;
    _loading[status] = true;
    if (reset) {
      _tasks[status] = [];
      _pages[status] = 0;
      _hasMore[status] = true;
    }
    final offset = (_pages[status] ?? 0) * kPageSize;
    final newTasks = await repository.fetchTasks(
      status: status,
      limit: kPageSize,
      offset: offset,
    );
    _tasks[status] = [...?_tasks[status], ...newTasks];
    _pages[status] = (_pages[status] ?? 0) + 1;
    _hasMore[status] = newTasks.length == kPageSize;
    _loading[status] = false;
  }

  Future<void> refreshStatus(String status) async {
    await _loadPage(status, reset: true);
    notifyListeners();
  }

  Future<void> refreshStatuses(Iterable<String> statuses) async {
    for (final status in statuses) {
      await _loadPage(status, reset: true);
    }
    notifyListeners();
  }

  Future<void> createTask(TaskDraft draft) async {
    // Wrap create in a command so it can be undone/redone.
    final command = _CreateTaskCommand(
      repository: repository,
      board: this,
      data: draft,
    );
    await history.execute(command);
  }

  Future<void> editTask(Task original, TaskDraft draft) async {
    // Update task with undo/redo support.
    final command = _UpdateTaskCommand(
      repository: repository,
      board: this,
      before: original,
      draft: draft,
    );
    await history.execute(command);
  }

  Future<void> deleteTask(Task task) async {
    // Delete task with undo/redo support.
    final command = _DeleteTaskCommand(
      repository: repository,
      board: this,
      task: task,
    );
    await history.execute(command);
  }

  Future<void> moveTask(Task task, String newStatus) async {
    // Drag/drop status changes also go through the command stack for undo/redo.
    if (task.status == newStatus) return;
    final command = _MoveTaskCommand(
      repository: repository,
      board: this,
      task: task,
      newStatus: newStatus,
    );
    await history.execute(command);
  }
}

class TaskDraft {
  TaskDraft({
    required this.title,
    this.notes,
    this.tags,
    required this.status,
    this.contactName,
    this.contactPhone,
    required this.contactEmail,
    this.contactAddress,
    this.contactCompany,
  });

  final String title;
  final String? notes;
  final String? tags;
  final String status;
  final String? contactName;
  final String? contactPhone;
  final String contactEmail;
  final String? contactAddress;
  final String? contactCompany;
}

class _CreateTaskCommand extends Command {
  _CreateTaskCommand({
    required this.repository,
    required this.board,
    required this.data,
  }) : super(label: 'Create task');

  final TaskRepository repository;
  final BoardController board;
  final TaskDraft data;

  Task? _created;

  @override
  Future<void> redo() async {
    // Persist new task; updatedAt reflects creation time.
    final task = await repository.createTask(
      title: data.title,
      notes: data.notes,
      tags: data.tags,
      status: data.status,
      contactName: data.contactName,
      contactPhone: data.contactPhone,
      contactEmail: data.contactEmail,
      contactAddress: data.contactAddress,
      contactCompany: data.contactCompany,
    );
    _created = task;
    await board.refreshStatus(task.status);
  }

  @override
  Future<void> undo() async {
    if (_created == null) return;
    await repository.deleteTask(_created!.id);
    await board.refreshStatus(_created!.status);
  }
}

class _UpdateTaskCommand extends Command {
  _UpdateTaskCommand({
    required this.repository,
    required this.board,
    required this.before,
    required this.draft,
  }) : super(label: 'Update task');

  final TaskRepository repository;
  final BoardController board;
  final Task before;
  final TaskDraft draft;
  Task? _after;

  Task _buildUpdated() => before.copyWith(
        title: draft.title,
        notes: Value(draft.notes),
        tags: Value(draft.tags),
        status: draft.status,
        contactName: Value(draft.contactName),
        contactPhone: Value(draft.contactPhone),
        contactEmail: draft.contactEmail,
        contactAddress: Value(draft.contactAddress),
        contactCompany: Value(draft.contactCompany),
      );

  @override
  Future<void> redo() async {
    // Update task and refresh affected columns; updatedAt bumped in repository.
    final updated = _buildUpdated();
    await repository.updateTask(updated);
    _after = await repository.getTask(updated.id);
    await board.refreshStatuses({before.status, updated.status});
  }

  @override
  Future<void> undo() async {
    await repository.updateTask(before);
    await board.refreshStatuses({before.status, _after?.status ?? before.status});
  }
}

class _DeleteTaskCommand extends Command {
  _DeleteTaskCommand({
    required this.repository,
    required this.board,
    required this.task,
  }) : super(label: 'Delete task');

  final TaskRepository repository;
  final BoardController board;
  final Task task;

  @override
  Future<void> redo() async {
    // Delete from DB; board reloads the status column.
    await repository.deleteTask(task.id);
    await board.refreshStatus(task.status);
  }

  @override
  Future<void> undo() async {
    // Recreate the deleted task (undo path).
    await repository.createTask(
      title: task.title,
      notes: task.notes,
      tags: task.tags,
      status: task.status,
      contactName: task.contactName,
      contactPhone: task.contactPhone,
      contactEmail: task.contactEmail,
      contactAddress: task.contactAddress,
      contactCompany: task.contactCompany,
    );
    await board.refreshStatus(task.status);
  }
}

class _MoveTaskCommand extends Command {
  _MoveTaskCommand({
    required this.repository,
    required this.board,
    required this.task,
    required this.newStatus,
  }) : super(label: 'Move task');

  final TaskRepository repository;
  final BoardController board;
  final Task task;
  final String newStatus;

  @override
  Future<void> redo() async {
    // Status change comes from drag/drop; repository bumps updatedAt.
    final updated = task.copyWith(status: newStatus);
    await repository.updateTask(updated);
    await board.refreshStatuses({task.status, newStatus});
  }

  @override
  Future<void> undo() async {
    // Restore original status.
    await repository.updateTask(task);
    await board.refreshStatuses({task.status, newStatus});
  }
}
