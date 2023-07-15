import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TodoStatus {
  all,
  done,
  progress,
  canceled,
  undone,
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(
        primaryColor: Color(0xFFAB47BC),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color.fromARGB(255, 191, 143, 199),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToHome();
  }

  void navigateToHome() async {
    await Future.delayed(const Duration(seconds: 5));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.secondary,
          margin: EdgeInsets.all(0.0),
          padding: EdgeInsets.all(20.0),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 50.0,
                  backgroundImage: AssetImage('images/logo.jpg'),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  'Welcome to ToDo App',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TodoItem> todos = [];
  TodoStatus selectedStatus = TodoStatus.all;
  List<TodoItem> filteredTodos = [];
  TextEditingController _editingController = TextEditingController();
  int _editingIndex = -1;

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  void loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      todos = TodoItem.getListFromPrefs(prefs) ?? [];
      filteredTodos = List.from(todos);
    });
  }

  void saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', TodoItem.convertListToStrings(todos));
  }

  void addTodo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTodo = '';

        return AlertDialog(
          title: Text('Add ToDo'),
          content: TextField(
            onChanged: (value) {
              newTodo = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  todos
                      .add(TodoItem(title: newTodo, status: TodoStatus.undone));
                  saveTodos();
                  filterTodos();
                  Navigator.pop(context);
                });
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void removeTodoAtIndex(int index) {
    setState(() {
      todos.removeAt(index);
      saveTodos();
      filterTodos();
    });
  }

  void updateTodoStatus(int index, TodoStatus status) {
    setState(() {
      todos[index].status = status;
      saveTodos();
      filterTodos();
    });
  }

  void startEditing(BuildContext context, int index) {
    _editingController.text = todos[index].title;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Todo'),
          content: TextField(
            controller: _editingController,
            decoration: InputDecoration(hintText: 'Enter task'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                cancelEditing();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                saveEditing(index);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void cancelEditing() {
    setState(() {
      _editingIndex = -1;
      _editingController.text = '';
    });
  }

  void saveEditing(int index) {
    setState(() {
      _editingIndex = -1;
      todos[index].title = _editingController.text;
    });
  }

  void updateTodoTitle() {
    if (_editingIndex >= 0 && _editingIndex < todos.length) {
      setState(() {
        todos[_editingIndex].title = _editingController.text;
        _editingIndex = -1;
        _editingController.text = '';
        saveTodos();
      });
    }
  }

  void filterTodos() {
    filteredTodos = List.from(todos);
  }

  void updateFilter(TodoStatus status) {
    setState(() {
      if (status == TodoStatus.all) {
        filteredTodos = List.from(todos);
      } else {
        filteredTodos = todos.where((todo) => todo.status == status).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: const CircleAvatar(
            backgroundImage: AssetImage('images/logo.jpg'),
          ),
        ),
        title: const Text('ToDo App'),
        actions: [
          DropdownButton<TodoStatus>(
            value: selectedStatus,
            onChanged: (TodoStatus? newValue) {
              if (newValue != null) {
                updateFilter(newValue);
              }
            },
            items: const [
              DropdownMenuItem<TodoStatus>(
                value: TodoStatus.all,
                child: Row(
                  children: [
                    Icon(Icons.menu),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              DropdownMenuItem<TodoStatus>(
                value: TodoStatus.done,
                child: Text('Done'),
              ),
              DropdownMenuItem<TodoStatus>(
                value: TodoStatus.progress,
                child: Text('Progress'),
              ),
              DropdownMenuItem<TodoStatus>(
                value: TodoStatus.canceled,
                child: Text('Canceled'),
              ),
              DropdownMenuItem<TodoStatus>(
                value: TodoStatus.undone,
                child: Text('Undone'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredTodos.length,
              itemBuilder: (BuildContext context, int index) {
                final todo = filteredTodos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 25.0),
                  child: ListTile(
                    title: _editingIndex == index
                        ? TextField(
                            controller: _editingController,
                            onSubmitted: (_) => updateTodoTitle(),
                          )
                        : Text(todo.title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color.fromARGB(255, 188, 32, 32),
                          ),
                          onPressed: () {
                            removeTodoAtIndex(index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            startEditing(context, index);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            todo.status == TodoStatus.undone
                                ? Icons.circle_outlined
                                : todo.status == TodoStatus.progress
                                    ? Icons.circle
                                    : todo.status == TodoStatus.done
                                        ? Icons.check_circle
                                        : Icons.cancel,
                            color: todo.status == TodoStatus.done
                                ? Colors.green
                                : todo.status == TodoStatus.progress
                                    ? Colors.blue
                                    : todo.status == TodoStatus.canceled
                                        ? Colors.red
                                        : Colors.grey,
                          ),
                          onPressed: () {
                            TodoStatus newStatus;
                            if (todo.status == TodoStatus.undone) {
                              newStatus = TodoStatus.progress;
                            } else if (todo.status == TodoStatus.progress) {
                              newStatus = TodoStatus.done;
                            } else if (todo.status == TodoStatus.done) {
                              newStatus = TodoStatus.canceled;
                            } else {
                              newStatus = TodoStatus.undone;
                            }
                            updateTodoStatus(index, newStatus);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: addTodo,
        child: Icon(Icons.add),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const FilterButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class TodoItem {
  String title;
  TodoStatus status;

  TodoItem({
    required this.title,
    required this.status,
  });

  static List<TodoItem> getListFromPrefs(SharedPreferences prefs) {
    List<String>? todoStrings = prefs.getStringList('todos');
    if (todoStrings != null) {
      return todoStrings.map((todoString) {
        List<String> values = todoString.split('|');
        return TodoItem(
          title: values[0],
          status: TodoStatus.values[int.parse(values[1])],
        );
      }).toList();
    }
    return [];
  }

  static List<String> convertListToStrings(List<TodoItem> todos) {
    return todos.map((todo) => '${todo.title}|${todo.status.index}').toList();
  }
}
