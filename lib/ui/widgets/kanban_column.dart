// Single kanban column: lists tasks of one status, supports drag targets and paging.
import 'package:flutter/material.dart';
import '../../data/database.dart';
import '../widgets/task_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onAddRequested,
    required this.onTaskTap,
    required this.onTaskDropped,
    required this.onLoadMore,
    required this.isLoading,
    required this.hasMore,
  });

  final String status;
  final List<Task> tasks;
  final VoidCallback onAddRequested;
  final void Function(Task) onTaskTap;
  final void Function(Task) onTaskDropped;
  final VoidCallback onLoadMore;
  final bool isLoading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddRequested,
                  tooltip: 'Add task to $status',
                )
              ],
            ),
          ),
          Expanded(
            child: DragTarget<Task>(
              // Accept drops from other statuses; DragTarget used to change status on drop.
              onWillAcceptWithDetails: (details) =>
                  details.data.status != status,
              onAcceptWithDetails: (details) => onTaskDropped(details.data),
              builder: (context, candidate, rejected) {
                if (tasks.isEmpty && candidate.isEmpty) {
                  return _EmptyState(status: status);
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Pagination: when near bottom, trigger onLoadMore if more pages exist.
                    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 60) {
                      if (hasMore && !isLoading) onLoadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: tasks.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= tasks.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final task = tasks[index];
                      return LongPressDraggable<Task>(
                        // Draggable wraps each card so it can be moved across columns.
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 280,
                            child: Opacity(
                              opacity: 0.85,
                              child: TaskCard(task: task, onTap: () {}),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: TaskCard(task: task, onTap: () => onTaskTap(task)),
                        ),
                        child: TaskCard(task: task, onTap: () => onTaskTap(task)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48),
          const SizedBox(height: 8),
          Text('No $status tasks yet'),
          const SizedBox(height: 12),
          Text(
            'Drag tasks here or tap + to add',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
