import 'package:flutter/material.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

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