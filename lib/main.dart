// Entry point wiring up providers for persistence, state, and UI screens.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'data/task_repository.dart';
import 'state/board_controller.dart';
import 'state/undo_redo_controller.dart';
import 'ui/screens/board_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final repo = TaskRepository(db);
  final history = UndoRedoController();
  runApp(KanbanApp(
    repository: repo,
    history: history,
  ));
}

class KanbanApp extends StatelessWidget {
  const KanbanApp({super.key, required this.repository, required this.history});
  final TaskRepository repository;
  final UndoRedoController history;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TaskRepository>.value(value: repository),
        ChangeNotifierProvider<UndoRedoController>.value(value: history),
        ChangeNotifierProvider<BoardController>(
          create: (context) => BoardController(
            repository: repository,
            history: history,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'KanBan',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
        ),
        home: const BoardPage(),
      ),
    );
  }
}
