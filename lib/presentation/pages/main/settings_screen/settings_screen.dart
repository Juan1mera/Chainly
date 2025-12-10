import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Setting Screens',
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