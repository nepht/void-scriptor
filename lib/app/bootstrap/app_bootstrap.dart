import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: VoidScriptorApp());
  }
}
