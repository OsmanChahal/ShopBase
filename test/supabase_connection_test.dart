import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Connect to Supabase and query businesses', () async {
    final client = SupabaseClient(
      'https://efxgqkiyorfcmosvklob.supabase.co',
      'sb_publishable_Tr9g1uq3jeP1DqHjwny3Mw_dN167AUO',
    );

    final businesses = await client.from('businesses').select().limit(5);
    //print('Fetched businesses: $businesses');
    expect(businesses, isA<List>());
  });
}
