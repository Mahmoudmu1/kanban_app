// Task create/edit form; validates input and forwards actions to the board controller.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../state/board_controller.dart';

class TaskFormPage extends StatefulWidget {
  // Opens as a modal route for creating or editing a task.
  const TaskFormPage({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _company;
  String _status = 'Todo';

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _tags = TextEditingController(text: t?.tags ?? '');
    _name = TextEditingController(text: t?.contactName ?? '');
    _phone = TextEditingController(text: t?.contactPhone ?? '');
    _email = TextEditingController(text: t?.contactEmail ?? '');
    _address = TextEditingController(text: t?.contactAddress ?? '');
    _company = TextEditingController(text: t?.contactCompany ?? '');
    _status = t?.status ?? 'Todo';
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _tags.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete task',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete this task?'),
                    content: const Text('This cannot be undone (but you can use Undo from the board).'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                if (!context.mounted) return;
                final board = context.read<BoardController>();
                await board.deleteTask(widget.task!);
                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
            ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() != true) return;
              final draft = TaskDraft(
                title: _title.text.trim(),
                notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                tags: _tags.text.trim().isEmpty ? null : _tags.text.trim(),
                status: _status,
                contactName: _name.text.trim().isEmpty ? null : _name.text.trim(),
                contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                contactEmail: _email.text.trim(),
                contactAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
                contactCompany: _company.text.trim().isEmpty ? null : _company.text.trim(),
              );
              final board = context.read<BoardController>();
              if (isEditing) {
                // Persist edit path through controller; updates updatedAt.
                await board.editTask(widget.task!, draft);
              } else {
                // Create path.
                await board.createTask(draft);
              }
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
            ),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: kStatuses
                  .map((s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'Todo'),
            ),
            const SizedBox(height: 12),
            Text('Contact', style: Theme.of(context).textTheme.titleMedium),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                final email = v.trim();
                final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!regex.hasMatch(email)) return 'Invalid email';
                return null;
              },
            ),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextFormField(
              controller: _company,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                final draft = TaskDraft(
                  title: _title.text.trim(),
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                  tags: _tags.text.trim().isEmpty ? null : _tags.text.trim(),
                  status: _status,
                  contactName: _name.text.trim().isEmpty ? null : _name.text.trim(),
                  contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                  contactEmail: _email.text.trim(),
                  contactAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
                  contactCompany: _company.text.trim().isEmpty ? null : _company.text.trim(),
                );
                final board = context.read<BoardController>();
                if (isEditing) {
                  await board.editTask(widget.task!, draft);
                } else {
                  await board.createTask(draft);
                }
                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Task'),
            )
          ],
        ),
      ),
    );
  }
}
