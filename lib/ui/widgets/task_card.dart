// Visual representation of a task card in a column; shows tags, contact, and last update.
import 'package:flutter/material.dart';
import '../../data/database.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  List<Widget> _buildChips(BuildContext context) {
    // Render tags as compact chips for quick scanning.
    if (task.tags == null || task.tags!.trim().isEmpty) return [];
    final tags = task.tags!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    return tags
        .map((t) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text(t),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildChips(context);
    final updatedLabel = _formatUpdated(task.updatedAt);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(_iconForStatus(task.status), size: 18),
                ],
              ),
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(children: chips),
              ],
              const SizedBox(height: 6),
              Text(
                'Updated: $updatedLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(task.contactName ?? 'No name'),
                    ],
                  ),
                  Text(
                    _statusLabel(task.status),
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForStatus(String status) {
  switch (status) {
    case 'Todo':
      return Icons.radio_button_unchecked;
    case 'Doing':
      return Icons.timelapse;
    case 'Done':
      return Icons.check_circle_outline;
    default:
      return Icons.radio_button_unchecked;
  }
}

String _statusLabel(String status) {
  return status;
}

String _formatUpdated(DateTime updatedAt) {
  // Human-friendly timestamp; highlights recent edits/moves that change updatedAt.
  final now = DateTime.now();
  final diff = now.difference(updatedAt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final day = updatedAt.day.toString().padLeft(2, '0');
  final month = months[updatedAt.month - 1];
  final year = updatedAt.year != now.year ? ' ${updatedAt.year}' : '';
  return '$day $month$year';
}
