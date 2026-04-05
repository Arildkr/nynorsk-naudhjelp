import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartlegging'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const SizedBox(height: 40),
              const Icon(Icons.psychology_alt, size: 120, color: Colors.deepPurple),
              const SizedBox(height: 32),
              const Text(
                'Er du klar?',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Me skal no finne ut kor mykje nynorsk du allereie kan. Ikkje stress om du ikkje veit svaret på alt - det hjelper oss berre med å tilpasse øvingane for deg!',
                style: TextStyle(fontSize: 18, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => context.pushReplacement('/assessment/flow'),
                child: const Text(
                  'Start testen!', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Kanskje seinare', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
