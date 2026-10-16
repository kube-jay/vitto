import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean, shareable URLs (/l/<id>) instead of hash routes.
  usePathUrlStrategy();
  // context.push() must update the address bar so Listing and profile
  // pages always have a shareable URL (Part II §35).
  GoRouter.optionURLReflectsImperativeAPIs = true;
  if (Env.hasBackend) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }
  runApp(const ProviderScope(child: VittoApp()));
}
