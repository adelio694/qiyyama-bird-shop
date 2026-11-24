import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const QiyyamaBirdShop());
}

class QiyyamaBirdShop extends StatelessWidget {
  const QiyyamaBirdShop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Qiyyama Bird Shop',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF245C3A),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
