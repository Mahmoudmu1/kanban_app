// Board screen: columns, search UI, navigation to task forms, and drag/drop handling.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../state/board_controller.dart';
import '../../state/undo_redo_controller.dart';
import '../widgets/kanban_column.dart';
import 'task_form_page.dart';

class BoardPage extends StatefulWidget {
  // Root board view with all columns.
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  bool _initialized = false;
  bool _searchOpen = false;
  String _query = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final board = context.read<BoardController>();
      board.initialize(); // initial paginated load per status
      _searchController.text = board.searchQuery;
      _query = board.searchQuery;
      _searchOpen = board.searchQuery.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String raw) {
    // Apply search when user submits; controller filters in-memory data.
    final q = raw.trim();
    setState(() {
      _query = q;
    });
    context.read<BoardController>().setSearchQuery(q);
  }

  void _clearSearch() {
    // Reset query and results.
    _searchController.clear();
    _applySearch('');
  }

  void _toggleSearch() {
    // Open/close the search panel; closing also clears filter.
    setState(() {
      if (_searchOpen) {
        _searchOpen = false;
        _clearSearch();
      } else {
        _searchOpen = true;
      }
    });
  }

  Future<void> _openForm({Task? task}) async {
    // Navigates to create/edit form; shows snackbar on success.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormPage(task: task)),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(task == null ? 'Task created' : 'Task updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<BoardController>();
    final history = context.watch<UndoRedoController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('KanBan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: history.canUndo ? () => history.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: history.canRedo ? () => history.redoLast() : null,
          ),
          IconButton(
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Column(
        children: [
          if (_searchOpen)
            Material(
              elevation: 2,
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _applySearch,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search by title or email',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Search',
                          icon: const Icon(Icons.search),
                          onPressed: () => _applySearch(_searchController.text),
                        ),
                        IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        ),
                      ],
                    ),
                    if (_query.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Chip(
                        label: Text('Showing results for: $_query'),
                        visualDensity: VisualDensity.compact,
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: _clearSearch,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _NoGlowScrollBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kStatuses
                      .map(
                        (status) => SizedBox(
                          width: 340,
                          child: KanbanColumn(
                            status: status,
                            tasks: board.tasksFor(status),
                            isLoading: board.isLoading(status),
                            hasMore: board.isSearching ? false : board.hasMore(status),
                            onAddRequested: () => _openForm(),
                            onTaskTap: (task) => _openForm(task: task),
                            onTaskDropped: (task) async {
                              // Drag/drop: moving status goes through controller for undo/redo.
                              await board.moveTask(task, status);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Moved to $status')),
                              );
                            },
                            onLoadMore: () {
                              // Pagination: only fetch more when not searching.
                              if (!board.isSearching) {
                                board.loadMore(status);
                              }
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
