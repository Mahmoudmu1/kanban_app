# KanBan Flutter App

A Trello-like Kanban board with Todo/Doing/Done columns, drag & drop, local persistence via Drift (SQLite), pagination, undo/redo history, and Material 3 UI.

## How to run

1. Ensure Flutter SDK is installed (tested with Flutter 3.24/Dart 3.9).
2. From project root run:
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter run
   ```

## Features
- Three columns (Todo, Doing, Done) with horizontal scrollable board.
- Tasks persisted locally using Drift/SQLite; survives app restarts.
- Create, edit, delete tasks with validation (title required, email required + format check).
- Drag & drop tasks between columns using native `Draggable`/`DragTarget`, updating status and timestamps.
- Undo/Redo stack for create, edit, delete, and moves (AppBar buttons).
- Pagination per column (20 per page) with infinite scroll and sort by last updated DESC.
- Inline search box filters loaded tasks by title or contact email (case-insensitive).
- Tags (comma-separated), notes, and contact info displayed on cards; chips for tags.
- Material 3 styling, FAB to add tasks, snackbars for key actions, empty states per column.

## Assumptions / Limitations
- Simple in-memory pagination caches per column; refreshes after each mutation to keep data consistent.
- While a search query is active, filtering is performed on already loaded tasks per column; load-more is paused until the search box is cleared.
- No remote sync or authentication; purely local storage.
- Basic email regex validation (RFC-lite).
- Drag feedback uses card preview; long-press to start drag.
