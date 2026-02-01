// Simple command pattern stack to support undo/redo across task actions.
import 'package:flutter/foundation.dart';

abstract class Command {
  // Each concrete command knows how to redo and undo a specific change.
  const Command({required this.label});
  final String label;
  Future<void> redo();
  Future<void> undo();
}

class UndoRedoController extends ChangeNotifier {
  // Stacks store executed and undone commands to navigate history.
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Future<void> execute(Command command) async {
    // Executes and records a new command; clears redo history.
    await command.redo();
    _undoStack.add(command);
    _redoStack.clear();
    notifyListeners();
  }

  Future<void> undo() async {
    if (!canUndo) return;
    final cmd = _undoStack.removeLast();
    await cmd.undo();
    _redoStack.add(cmd);
    notifyListeners();
  }

  Future<void> redoLast() async {
    if (!canRedo) return;
    final cmd = _redoStack.removeLast();
    await cmd.redo();
    _undoStack.add(cmd);
    notifyListeners();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
