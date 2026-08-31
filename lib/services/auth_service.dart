import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Sign in with email and password.
  /// Returns the session on success, throws on failure.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in. Please check your connection.');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out.');
    }
  }

  /// Sign up a new user and create their business row.
  /// Returns the created Business on success.
  Future<Business> signUp({
    required String email,
    required String password,
    required String businessName,
  }) async {
    // 1. Create the auth user
    AuthResponse authResponse;
    try {
      authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to create account. Please check your connection.');
    }

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw Exception('Account created but user ID not returned. Please try logging in.');
    }

    // 2. Create the business row
    try {
      final response = await _client
          .from('businesses')
          .insert({
            'owner_id': userId,
            'name': businessName,
            'currency_rate': 89500,
            'currency_rate_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      return Business.fromJson(response);
    } catch (e) {
      throw Exception(
        'Account created successfully, but business setup failed: '
        '${e.toString().replaceAll('Exception: ', '')}. '
        'Please try logging in — if the issue persists, contact support.',
      );
    }
  }

  /// Get the current session, or null if not authenticated.
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  /// Get the current user ID, or null if not authenticated.
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Fetch the business linked to the given user ID.
  /// Returns null if no business is found.
  Future<Business?> fetchBusiness(String userId) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Business.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load business data. Please try again.');
    }
  }

  /// Update the business name.
  Future<Business> updateBusinessName(String businessId, String name) async {
    try {
      final response = await _client
          .from('businesses')
          .update({
            'name': name,
          })
          .eq('id', businessId)
          .select()
          .single();

      return Business.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update business name. Please try again.');
    }
  }

  /// Update the currency rate for a business.
  /// Sets currency_rate and currency_rate_updated_at (to now).
  Future<Business> updateCurrencyRate(String businessId, double rate) async {
    try {
      final response = await _client
          .from('businesses')
          .update({
            'currency_rate': rate,
            'currency_rate_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', businessId)
          .select()
          .single();

      return Business.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update exchange rate. Please try again.');
    }
  }
}

