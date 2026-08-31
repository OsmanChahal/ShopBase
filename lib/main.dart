import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://efxgqkiyorfcmosvklob.supabase.co',
    publishableKey: 'sb_publishable_Tr9g1uq3jeP1DqHjwny3Mw_dN167AUO',
  );

  runApp(const ProviderScope(child: CrmPosApp()));
}
