import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final SupabaseClient _client;
  static const _uuid = Uuid();
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
  /// Sign up a new user and create their business row.
  /// Returns the created Business on success.
  Future<Business> signUp({
    required String email,
    required String password,
    required String businessName,
    required String businessType,
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
      throw Exception(
        'Failed to create account. Please check your connection.',
      );
    }

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw Exception(
        'Account created but user ID not returned. Please try logging in.',
      );
    }

    // Generate the business ID on the client so we never need to rely on
    // Postgres's RETURNING clause before a business_members row exists to
    // satisfy the businesses table's SELECT policy.
    final businessId = _uuid.v4();

    // 2. Create the business row (plain insert, no .select() — avoids
    // triggering a SELECT-policy check before membership exists)
    try {
      await _client.from('businesses').insert({
        'id': businessId,
        'owner_id': userId,
        'name': businessName,
        'business_type': businessType,
        'currency_rate': 89500,
        'currency_rate_updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create your business. Please try again.');
    }

    // 3. Create the business_members row
    try {
      await _client.from('business_members').insert({
        'business_id': businessId,
        'user_id': userId,
        'permissions': {'all': true},
        'role': 'admin',
        'status': 'active',
      });
    } catch (e) {
      throw Exception(
        'Your account and business were created, but we couldn\'t finish '
        'setup. Please contact support with this business name: '
        '$businessName',
      );
    }

    // 4. Now fetch the business — membership exists, so the SELECT policy
    // correctly passes this time
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('id', businessId)
          .single();
      return Business.fromJson(response);
    } catch (e) {
      throw Exception(
        'Setup completed, but failed to load your business. '
        'Please try logging in.',
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
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Fetch the business linked to the given user ID.
  /// Returns null if no business is found.
  Future<Business?> fetchBusiness(String userId) async {
    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .maybeSingle();

      if (response == null) {
        final businessMembers = await _client
            .from('business_members')
            .select()
            .eq('user_id', userId)
            .eq('status', 'active')
            .maybeSingle();
        if (businessMembers == null) {
          return null;
        }
        final businessResponse = await _client
            .from('businesses')
            .select()
            .eq('id', businessMembers['business_id'])
            .maybeSingle();
        if (businessResponse == null) {
          return null;
        }
        return Business.fromJson(businessResponse);
      }
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
          .update({'name': name})
          .eq('id', businessId)
          .select()
          .single();

      return Business.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update business name. Please try again.');
    }
  }

  /// Update the business type.
  Future<Business> updateBusinessType(
    String businessId,
    String businessType,
  ) async {
    try {
      final response = await _client
          .from('businesses')
          .update({'business_type': businessType})
          .eq('id', businessId)
          .select()
          .single();

      return Business.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update business type. Please try again.');
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
            'currency_rate_updated_at': DateTime.now()
                .toUtc()
                .toIso8601String(),
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
