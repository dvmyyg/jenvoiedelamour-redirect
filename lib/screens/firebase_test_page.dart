// lib/screens/firebase_test_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  FirebaseTestPageState createState() => FirebaseTestPageState();
}

class FirebaseTestPageState extends State<FirebaseTestPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Auth Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mot de passe'),
            ),
            ElevatedButton(
              onPressed: () async {
                await testSignup(
                  _emailController.text,
                  _passwordController.text,
                );
              },
              child: Text("Test Inscription"),
            ),
            ElevatedButton(
              onPressed: () async {
                await testSignin(
                  _emailController.text,
                  _passwordController.text,
                );
              },
              child: Text("Test Connexion"),
            ),
            SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }

  Future<void> testSignup(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      setState(() {
        _message = "✅ Inscription réussie pour ${userCredential.user?.email}";
      });
    } catch (e) {
      setState(() {
        _message = "❌ Erreur lors de l'inscription : $e";
      });
    }
  }

  Future<void> testSignin(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      setState(() {
        _message = "✅ Connexion réussie pour ${userCredential.user?.email}";
      });
    } catch (e) {
      setState(() {
        _message = "❌ Erreur lors de la connexion : $e";
      });
    }
  }
}
