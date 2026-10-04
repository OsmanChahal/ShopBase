import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import '../models/business_member.dart';
import '../services/auth_service.dart';

/// Provides the Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Represents the three possible auth + business states.
enum AppAuthState {
  loading,
  unauthenticated,
  authenticated,
  noBusinessFound,
}

/// Combined auth + business + member role state.
class AuthBusinessState {
  final AppAuthState status;
  final Business? business;
  final BusinessMember? member;
  final String? errorMessage;

  const AuthBusinessState({
    required this.status,
    this.business,
    this.member,
    this.errorMessage,
  });

  const AuthBusinessState.loading()
      : status = AppAuthState.loading,
        business = null,
        member = null,
        errorMessage = null;

  const AuthBusinessState.unauthenticated()
      : status = AppAuthState.unauthenticated,
        business = null,
        member = null,
        errorMessage = null;

  const AuthBusinessState.authenticated(this.business, this.member)
      : status = AppAuthState.authenticated,
        errorMessage = null;

  const AuthBusinessState.noBusinessFound()
      : status = AppAuthState.noBusinessFound,
        business = null,
        member = null,
        errorMessage = null;

  const AuthBusinessState.error(this.errorMessage)
      : status = AppAuthState.unauthenticated,
        business = null,
        member = null;
}

/// Notifier that manages auth state and business lookup.
class AuthNotifier extends StateNotifier<AuthBusinessState> {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isSigningUp = false;

  AuthNotifier(this._authService)
      : super(const AuthBusinessState.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Check current session first
    final session = _authService.getCurrentSession();
    if (session != null) {
      await _loadBusiness(session.user.id);
    } else {
      state = const AuthBusinessState.unauthenticated();
    }

    // Listen for auth state changes
    _authSubscription = _authService.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        if (_isSigningUp) return;

        final userId = data.session?.user.id;
        if (userId != null) {
          await _loadBusiness(userId);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthBusinessState.unauthenticated();
      }
    });
  }

  Future<void> _loadBusiness(String userId) async {
    state = const AuthBusinessState.loading();
    try {
      final result = await _authService.fetchMemberAndBusiness(userId);
      if (result != null) {
        state = AuthBusinessState.authenticated(result.business, result.member);
      } else {
        state = const AuthBusinessState.noBusinessFound();
      }
    } catch (e) {
      state = AuthBusinessState.error(e.toString());
    }
  }

  /// Sign in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthBusinessState.loading();
    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId != null) {
        await _loadBusiness(userId);
      } else {
        state = const AuthBusinessState.unauthenticated();
      }
    } catch (e) {
      state = const AuthBusinessState.unauthenticated();
      rethrow;
    }
  }

  /// Sign up a new user, create their business, and set authenticated state.
  Future<void> signUp({
    required String email,
    required String password,
    required String businessName,
    required String businessType,
  }) async {
    _isSigningUp = true;
    state = const AuthBusinessState.loading();
    try {
      final business = await _authService.signUp(
        email: email,
        password: password,
        businessName: businessName,
        businessType: businessType,
      );
      final ownerMember = BusinessMember(
        id: 'owner_${business.ownerId}',
        businessId: business.id,
        userId: business.ownerId,
        role: 'admin',
        permissions: {'all': true},
        status: 'active',
      );
      state = AuthBusinessState.authenticated(business, ownerMember);
    } catch (e) {
      state = const AuthBusinessState.unauthenticated();
      rethrow;
    } finally {
      _isSigningUp = false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthBusinessState.unauthenticated();
    } catch (e) {
      rethrow;
    }
  }

  /// Update the currency rate for the current business.
  Future<void> updateCurrencyRate(double rate) async {
    final business = state.business;
    final member = state.member;
    if (business == null) {
      throw Exception('No business loaded.');
    }
    try {
      final updated = await _authService.updateCurrencyRate(business.id, rate);
      state = AuthBusinessState.authenticated(updated, member);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the name of the current business.
  Future<void> updateBusinessName(String name) async {
    final business = state.business;
    final member = state.member;
    if (business == null) {
      throw Exception('No business loaded.');
    }
    try {
      final updated = await _authService.updateBusinessName(business.id, name);
      state = AuthBusinessState.authenticated(updated, member);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the type of the current business.
  Future<void> updateBusinessType(String businessType) async {
    final business = state.business;
    final member = state.member;
    if (business == null) {
      throw Exception('No business loaded.');
    }
    try {
      final updated = await _authService.updateBusinessType(business.id, businessType);
      state = AuthBusinessState.authenticated(updated, member);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// The main auth state provider.
final authProvider =
    StateNotifierProvider<AuthNotifier, AuthBusinessState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// Convenience provider to get the current business (or null).
final currentBusinessProvider = Provider<Business?>((ref) {
  return ref.watch(authProvider).business;
});

/// Convenience provider to get the current member (or null).
final currentMemberProvider = Provider<BusinessMember?>((ref) {
  return ref.watch(authProvider).member;
});

/// Returns true if the user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  final member = ref.watch(currentMemberProvider);
  if (member != null) {
    return member.role == 'admin';
  }
  final business = ref.watch(currentBusinessProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (business != null && userId != null) {
    return business.ownerId == userId;
  }
  return false;
});

/// Convenience provider to check if the current user has a specific permission.
final hasPermissionProvider = Provider.family<bool, String>((ref, key) {
  final member = ref.watch(currentMemberProvider);
  if (member == null) {
    final business = ref.watch(currentBusinessProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (business != null && userId != null && business.ownerId == userId) {
      return true;
    }
    return false;
  }
  return member.hasPermission(key);
});

