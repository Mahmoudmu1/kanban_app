// Repository that mediates between controllers and Drift, handling queries/pagination.
import 'package:drift/drift.dart';

import 'database.dart';

class TaskRepository {
  TaskRepository(this.db);

  final AppDatabase db;

  Future<Task> createTask({
    // Inserts a new task with created/updated timestamps set.
    required String title,
    String? notes,
    String? tags,
    required String status,
    String? contactName,
    String? contactPhone,
    required String contactEmail,
    String? contactAddress,
    String? contactCompany,
  }) async {
    final now = DateTime.now();
    final id = await db.into(db.tasks).insert(TasksCompanion.insert(
      title: title,
      notes: Value(notes),
      tags: Value(tags),
      status: status,
      contactName: Value(contactName),
      contactPhone: Value(contactPhone),
      contactEmail: contactEmail,
      contactAddress: Value(contactAddress),
      contactCompany: Value(contactCompany),
      createdAt: now,
      updatedAt: now,
    ));
    return getTask(id);
  }

  Future<Task> getTask(int id) async {
    // Fetch a single task by id.
    return (db.select(db.tasks)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<List<Task>> fetchTasks({
    // Paged fetch filtered by status and sorted by updatedAt DESC.
    required String status,
    int limit = 20,
    int offset = 0,
  }) async {
    return (db.select(db.tasks)
          ..where((tbl) => tbl.status.equals(status))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<void> updateTask(Task task) async {
    // Replaces task row and bumps updatedAt to now.
    final updated = task.copyWith(updatedAt: DateTime.now());
    await db.update(db.tasks).replace(updated);
  }

  Future<void> deleteTask(int id) async {
    // Permanently removes a task.
    await (db.delete(db.tasks)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> countByStatus(String status) async {
    final exp = db.tasks.id.count();
    final query = (db.selectOnly(db.tasks)
      ..addColumns([exp])
      ..where(db.tasks.status.equals(status)));
    final row = await query.getSingle();
    return row.read(exp) ?? 0;
  }
}
