import '../models/user_model.dart';
import '../storage/storage_service.dart';
import '../../core/constants/strings.dart';

class AuthService {
  // Dummy users for login
  final List<UserModel> dummyUsers = [
    UserModel(
      id: '1',
      username: 'admin',
      password: 'admin123',
      role: 'admin',
      name: 'Admin',
      createdAt: DateTime.now(),
    ),
    UserModel(
      id: '2',
      username: 'user',
      password: 'user123',
      role: 'user',
      name: 'User',
      createdAt: DateTime.now(),
    ),
  ];

  Future<void> initializeDummyUsers() async {
    try {
      final existingUsers = await StorageService.getUsers();
      if (existingUsers.isEmpty) {
        await StorageService.saveUsers(dummyUsers);
      }
    } catch (e) {
      // Box might not be opened yet, will be initialized later
      await StorageService.saveUsers(dummyUsers);
    }
  }

  Future<UserModel?> login(String username, String password) async {
    try {
      await initializeDummyUsers();
      final users = await StorageService.getUsers();
      
      if (users.isEmpty) {
        await StorageService.saveUsers(dummyUsers);
        // Retry after saving
        final retryUsers = await StorageService.getUsers();
        final user = retryUsers.firstWhere(
          (u) => u.username == username && u.password == password,
          orElse: () => throw Exception(AppStrings.invalidCredentials),
        );
        return user;
      }
      
      final user = users.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => throw Exception(AppStrings.invalidCredentials),
      );
      
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    // Clear session data if needed
  }

  bool isAdmin(UserModel? user) {
    return user?.role == 'admin';
  }

  bool isUser(UserModel? user) {
    return user?.role == 'user';
  }
}

