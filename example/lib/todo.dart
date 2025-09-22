import 'package:flutter/material.dart';
import 'package:oref/oref.dart';

class Todo {
  final String title;
  final String? description;

  Todo({required this.title, this.description});
}

class TodoStore extends ReactiveList<Todo> {
  TodoStore()
    : super([
        Todo(title: 'Buy milk', description: 'Go to the store and buy milk'),
        Todo(
          title: 'Call mom',
          description: 'Call mom and tell her how much you love her',
        ),
        Todo(
          title: 'Finish homework',
          description: 'Finish all the homework for the week',
        ),
      ]);

  void insertTodo(String title, [String? description]) {
    add(Todo(title: title, description: description));
  }
}

final store = TodoStore();

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo App')),
      body: const TodoListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddTodoDialog());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoListView extends StatelessWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context) {
    final count = computed(context, (_) => store.length);

    return ListView.builder(
      itemCount: count(),
      itemBuilder: (context, index) {
        final todo = store[index];
        return ListTile(
          title: Text(todo.title),
          subtitle: todo.description != null ? Text(todo.description!) : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => store.removeAt(index),
          ),
        );
      },
    );
  }
}

class AddTodoDialog extends StatelessWidget {
  const AddTodoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final title = signal(context, "");
    final description = signal(context, "");

    return AlertDialog(
      title: const Text('Add Todo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: title,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: title,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        SignalBuilder(
          getter: title,
          builder: (context, title) => TextButton(
            onPressed: title.trim().isNotEmpty
                ? () {
                    store.insertTodo(title.trim(), description());
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}
