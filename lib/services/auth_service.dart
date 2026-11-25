import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import '../models/business_member.dart';
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
  /// Creates a Supabase Auth user without creating a business.
  ///
  /// Errors are rethrown as plain [Exception]s with a user-readable message
  /// (the auth error's message, or a connection hint).
  Future<AuthResponse> createAuthUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(
        'Failed to create account. Please check your connection.',
      );
    }
  }

  /// Sign up a new user and create their business row.
  /// Returns the created Business on success.
  Future<Business> signUp({
    required String email,
    required String password,
    required String businessName,
    required String businessType,
  }) async {
    // 1. Create the auth user
    final authResponse = await createAuthUser(
      email: email,
      password: password,
    );

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

  /// Fetch the business and membership linked to the given user ID.
  /// Returns null if no business/member is found.
  Future<({Business business, BusinessMember member})?> fetchMemberAndBusiness(String userId) async {
    try {
      // 1. Fetch business_members row for this user
      final memberResponse = await _client
          .from('business_members')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (memberResponse == null) {
        // Fallback: check if user is owner of a business
        final ownerBusiness = await _client
            .from('businesses')
            .select()
            .eq('owner_id', userId)
            .maybeSingle();

        if (ownerBusiness == null) return null;

        final business = Business.fromJson(ownerBusiness);
        final syntheticMember = BusinessMember(
          id: 'owner_$userId',
          businessId: business.id,
          userId: userId,
          role: 'admin',
          permissions: {'all': true},
          status: 'active',
        );
        return (business: business, member: syntheticMember);
      }

      final member = BusinessMember.fromJson(memberResponse);

      // 2. Fetch the corresponding business
      final businessResponse = await _client
          .from('businesses')
          .select()
          .eq('id', member.businessId)
          .single();

      final business = Business.fromJson(businessResponse);

      // If user is owner_id, force role to admin
      if (business.ownerId == userId) {
        final adminMember = BusinessMember(
          id: member.id,
          businessId: member.businessId,
          userId: member.userId,
          role: 'admin',
          permissions: {'all': true},
          status: member.status,
        );
        return (business: business, member: adminMember);
      }

      return (business: business, member: member);
    } catch (e) {
      throw Exception('Failed to load business data. Please try again.');
    }
  }

  /// Legacy fetch business method.
  Future<Business?> fetchBusiness(String userId) async {
    final result = await fetchMemberAndBusiness(userId);
    return result?.business;
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
