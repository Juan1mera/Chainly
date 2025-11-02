import 'package:flutter/material.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomHeader(title: 'Tienda'),
    body: Column(
      children: [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Próximamente nuevas funcionalidades',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}