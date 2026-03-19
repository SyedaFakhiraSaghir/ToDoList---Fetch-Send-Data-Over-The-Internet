
Assignment #1 - 
22k4413 - syeda fakhira saghir
22k4461 - Rakhshanda Parveen
22K-4301 - Ali Jafar
22K-4473 - Jaswant Lal

A new Flutter project.

# 📝 Todo List App - Fetch & Send Data Over The Internet

A feature-rich Todo List application built with Flutter that demonstrates best practices around fetching and sending data over the internet using REST APIs.


## ✨ Features

- ✅ **Lazy Loading with Pagination** - Loads 10 items per page with infinite scroll
- ✅ **Add New Todos** - Create todos with title and description (both required)
- ✅ **Mark as Done/Undo** - Toggle completion status with optimistic updates
- ✅ **Pull to Refresh** - Refresh the todo list by pulling down
- ✅ **Most Recent First** - New todos appear at the top of the list
- ✅ **Responsive UI** - Material Design 3 with clean, intuitive interface
- ✅ **Error Handling** - User-friendly error messages and retry options
- ✅ **Loading Indicators** - Visual feedback during network operations
- ✅ **Side Snackbars** - Non-intrusive notifications at bottom-right

<img width="407" height="789" alt="image" src="https://github.com/user-attachments/assets/17711e60-de7a-42a1-a833-1e965eddc9ee" />


<img width="426" height="808" alt="image" src="https://github.com/user-attachments/assets/b5bcb947-c3d0-4f0b-9893-c8ef1e6ba727" />

## 🛠️ Technologies Used

- **Flutter** - UI framework
- **Dart** - Programming language
- **HTTP Package** - For REST API calls
- **Material Design 3** - Modern UI components
- **REST API** - Backend communication

## 📡 API Integration

The app communicates with a mock REST API at:
- **Base URL**: `https://apimocker.com/todos`
- **Documentation**: [https://apimocker.com/](https://apimocker.com/)

### API Endpoints Used

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/todos?page={page}&limit={limit}` | Fetch paginated todos |
| POST | `/todos` | Create a new todo |
| PUT | `/todos/{id}` | Update todo status |

## 📂 Project Structure

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
