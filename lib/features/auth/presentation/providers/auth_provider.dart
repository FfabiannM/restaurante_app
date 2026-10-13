import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/features/auth/data/supabase_auth_repository.dart';
import 'package:restaurante_app/features/auth/domain/user_profile.dart';

final authRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

class AuthNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    Future.microtask(() => checkCurrentUser());
    return SupabaseAuthRepository.demoEmpleado;
  }

  Future<void> checkCurrentUser() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.getCurrentUser();
    state = user;
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmailPassword(email, password);
      state = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      state = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = null;
  }

  void setDemoUser(UserProfile demoUser) {
    final repo = ref.read(authRepositoryProvider);
    repo.switchDemoUser(demoUser);
    state = demoUser;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserProfile?>(
  AuthNotifier.new,
);
