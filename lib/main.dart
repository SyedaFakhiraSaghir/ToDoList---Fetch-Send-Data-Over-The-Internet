/*
Assignment #1 - 
22k4413 - syeda fakhira saghir
22k4461 - Rakhshanda Parveen
22K-4301 - Ali Jafar
22K-4473 - Jaswant Lal
*/

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo List API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 179, 125),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// Data classes for JSON serialization (manual, no build_runner)
class Todo {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.createdAt,
  });

  // From JSON with better parsing
  factory Todo.fromJson(Map<String, dynamic> json) {
    print('📦 Parsing Todo JSON: $json'); // Debug print
    
    // Handle different possible response formats
    String title = 'Untitled';
    if (json['title'] != null && json['title'].toString().isNotEmpty) {
      title = json['title'].toString();
    }
    
    String description = '';
    if (json['description'] != null && json['description'].toString().isNotEmpty) {
      description = json['description'].toString();
    }
    
    bool completed = false;
    if (json['completed'] != null) {
      completed = json['completed'] == true || json['completed'] == 'true';
    }
    
    DateTime createdAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    return Todo(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      completed: completed,
      createdAt: createdAt,
    );
  }

  // To JSON for POST/PUT requests
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
    };
  }

  // Copy with method for updating
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Response class with pagination
class TodoResponse {
  final List<Todo> todos;
  final int total;
  final int page;
  final int limit;

  TodoResponse({
    required this.todos,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TodoResponse.fromJson(Map<String, dynamic> json) {
    List<Todo> todoList = [];
    if (json['data'] != null && json['data'] is List) {
      todoList = List<Map<String, dynamic>>.from(json['data'])
          .map((todoJson) => Todo.fromJson(todoJson))
          .toList();
    }
    
    // Extract pagination info from the nested object
    final pagination = json['pagination'] ?? {};
    
    return TodoResponse(
      todos: todoList,
      total: pagination['total'] ?? 0,
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 10,
    );
  }
}

// Request class for creating new todo
class CreateTodoRequest {
  final String title;
  final String description;

  CreateTodoRequest({
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'completed': false,
    };
  }
}

// API Service class with improved error handling
class ApiService {
  static const String baseUrl = 'https://apimocker.com/todos';
  static const int pageSize = 10;

  // Get todos with pagination
  static Future<TodoResponse> getTodos({int page = 1}) async {
    try {
      print('📡 Fetching todos page $page');
      final response = await http.get(
        Uri.parse('$baseUrl?page=$page&limit=$pageSize'),
      );

      if (response.statusCode == 200) {
        print('✅ Got response: ${response.body.substring(0, min(100, response.body.length))}...');
        return TodoResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load todos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching todos: $e');
      throw Exception('Network error: $e');
    }
  }

  // Create new todo
  static Future<Todo> createTodo(CreateTodoRequest request) async {
    try {
      print('📤 Creating todo: ${request.title}');
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      print('📥 Create response status: ${response.statusCode}');
      print('📥 Create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Todo.fromJson(json.decode(response.body));
      } else {
        // Create a local todo with the data we have
        print('⚠️ API POST failed, using local todo');
        return Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: request.title,
          description: request.description,
          completed: false,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('❌ Network error in createTodo: $e');
      // Return a local todo so the UI still shows the item
      return Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: request.title,
        description: request.description,
        completed: false,
        createdAt: DateTime.now(),
      );
    }
  }

  // Update todo
  static Future<Todo> updateTodo(String id, bool completed) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'completed': completed}),
      );

      if (response.statusCode == 200) {
        return Todo.fromJson(json.decode(response.body));
      } else {
        // Return a todo with the updated state
        return Todo(
          id: id,
          title: 'Updated Todo',
          description: '',
          completed: completed,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Network error: $e, using local update');
      return Todo(
        id: id,
        title: 'Updated Todo',
        description: '',
        completed: completed,
        createdAt: DateTime.now(),
      );
    }
  }
}

// Main Home Page Widget
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Todo> _todos = [];
  List<Todo> _allFetchedTodos = [];
  int _currentPage = 1;
  int _totalTodos = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSubmitting = false;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadInitialTodos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTodos();
    }
  }

  Future<void> _loadInitialTodos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1;
    });

    try {
      final response = await ApiService.getTodos(page: 1);
      setState(() {
        _allFetchedTodos = response.todos;
        _todos = List.from(_allFetchedTodos);
        _totalTodos = response.total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTodos() async {
    if (_isLoadingMore || 
        _todos.length >= _totalTodos ||
        _currentPage * 10 >= _totalTodos) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await ApiService.getTodos(page: nextPage);
      
      setState(() {
        _allFetchedTodos.addAll(response.todos);
        _todos.addAll(response.todos);
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showSideSnackBar('Failed to load more todos', isError: true);
    }
  }

  Future<void> _refreshTodos() async {
    setState(() {
      _currentPage = 1;
    });
    await _loadInitialTodos();
  }

  Future<void> _addTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CreateTodoRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      final newTodo = await ApiService.createTodo(request);
      
      // Ensure the todo has the correct data
      final todoToAdd = newTodo.copyWith(
        title: request.title,
        description: request.description,
      );
      
      setState(() {
        _todos.insert(0, todoToAdd);
        _allFetchedTodos.insert(0, todoToAdd);
        _totalTodos++;
        _isSubmitting = false;
      });

      _titleController.clear();
      _descriptionController.clear();
      
      Navigator.pop(context);
      
      _showSideSnackBar('Todo added successfully');
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showSideSnackBar('Failed to add todo', isError: true);
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    final newCompletedState = !todo.completed;
    final originalTodo = todo;
    
    setState(() {
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo.copyWith(completed: newCompletedState);
      }
      
      final allIndex = _allFetchedTodos.indexWhere((t) => t.id == todo.id);
      if (allIndex != -1) {
        _allFetchedTodos[allIndex] = todo.copyWith(completed: newCompletedState);
      }
    });

    try {
      await ApiService.updateTodo(todo.id, newCompletedState);
      _showSideSnackBar('Todo updated successfully');
    } catch (e) {
      setState(() {
        final index = _todos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _todos[index] = originalTodo;
        }
        
        final allIndex = _allFetchedTodos.indexWhere((t) => t.id == todo.id);
        if (allIndex != -1) {
          _allFetchedTodos[allIndex] = originalTodo;
        }
      });
      _showSideSnackBar('Failed to update todo', isError: true);
    }
  }

void _showAddTodoDialog() {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add New Todo',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.description),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        _titleController.clear();
                                        _descriptionController.clear();
                                        Navigator.pop(context);
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _addTodo,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Add Todo'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
  void _showAddTodoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add New Todo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _addTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Todo'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // New side snackbar method
  void _showSideSnackBar(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // Keep original snackbar methods for compatibility
  void _showErrorSnackBar(String message) {
    _showSideSnackBar(message, isError: true);
  }

  void _showSuccessSnackBar(String message) {
    _showSideSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List API'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTodos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTodos,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading todos...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialTodos,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No todos yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showAddTodoBottomSheet,
              child: const Text('Add Your First Todo'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _todos.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _todos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final todo = _todos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: todo.completed,
              onChanged: (_) => _toggleTodo(todo),
            ),
            title: Text(
              todo.title.isNotEmpty ? todo.title : 'Untitled',
              style: TextStyle(
                decoration: todo.completed ? TextDecoration.lineThrough : null,
                color: todo.completed ? Colors.grey : null,
                fontWeight: todo.completed ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              todo.description.isNotEmpty ? todo.description : 'No description',
              style: TextStyle(
                color: todo.completed ? Colors.grey : null,
              ),
            ),
            trailing: Text(
              _formatDate(todo.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Helper function for substring
int min(int a, int b) => a < b ? a : b;