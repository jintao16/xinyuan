import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'widgets/theme.dart';
import 'main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XinyuanApp());
}

class XinyuanApp extends StatelessWidget {
  const XinyuanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: '鑫源订餐',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainScaffold(),
      ),
    );
  }
}
